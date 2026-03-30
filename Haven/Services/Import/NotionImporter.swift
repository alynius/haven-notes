import Foundation

struct ImportResult {
    let imported: Int
    let skipped: Int
    let errors: [String]
}

@MainActor
final class NotionImporter: ObservableObject {
    @Published var isImporting = false
    @Published var progress: Double = 0  // 0.0 to 1.0
    @Published var currentFile: String = ""
    @Published var result: ImportResult?
    @Published var errorMessage: String?

    private let noteRepo: NoteRepositoryProtocol

    init(noteRepo: NoteRepositoryProtocol) {
        self.noteRepo = noteRepo
    }

    /// Import from a ZIP file URL (e.g. shared via Share Sheet).
    func importFromZip(url: URL) async {
        isImporting = true
        progress = 0
        result = nil
        errorMessage = nil

        do {
            let accessing = url.startAccessingSecurityScopedResource()
            defer { if accessing { url.stopAccessingSecurityScopedResource() } }

            // Create temp directory
            let tempDir = FileManager.default.temporaryDirectory
                .appendingPathComponent("notion-import-\(UUID().uuidString)")
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: tempDir) }

            // Copy the ZIP into temp so we own the file
            let zipCopy = tempDir.appendingPathComponent("export.zip")
            try FileManager.default.copyItem(at: url, to: zipCopy)

            // Unzip using NSFileCoordinator / Process is unavailable on iOS.
            // Use Apple's built-in support: on iOS 16+ we can use
            // FileManager to iterate a ZIP via a coordinator, but the simplest
            // cross-version approach is to shell out to the Archive utility —
            // which isn't available on iOS either.
            //
            // Recommended: use the system-provided decompression. On iOS the
            // document picker can open ZIP files and the system may auto-extract.
            // For direct ZIP handling, consider adding a lightweight dependency
            // like ZIPFoundation. For now, treat the URL as a directory if the
            // system already extracted it, otherwise surface an error asking the
            // user to unzip first.

            var isDir: ObjCBool = false
            let exists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir)

            if exists && isDir.boolValue {
                // Already a directory — import directly
                await importMarkdownFiles(from: url)
            } else if url.pathExtension.lowercased() == "zip" {
                errorMessage = "Please unzip the Notion export first, then select the folder. iOS does not support direct ZIP import yet."
            } else {
                // Single file
                await importMarkdownFiles(from: url)
            }

        } catch {
            errorMessage = error.localizedDescription
        }

        isImporting = false
    }

    /// Import from a directory (the unzipped Notion export folder) or individual files.
    func importFromDirectory(url: URL) async {
        isImporting = true
        progress = 0
        result = nil
        errorMessage = nil

        do {
            let accessing = url.startAccessingSecurityScopedResource()
            defer { if accessing { url.stopAccessingSecurityScopedResource() } }

            await importMarkdownFiles(from: url)
        }

        isImporting = false
    }

    /// Import from multiple selected file URLs.
    func importFromFiles(urls: [URL]) async {
        isImporting = true
        progress = 0
        result = nil
        errorMessage = nil

        var allMDFiles: [URL] = []

        for url in urls {
            let accessing = url.startAccessingSecurityScopedResource()
            defer { if accessing { url.stopAccessingSecurityScopedResource() } }

            do {
                let found = try findMarkdownFiles(in: url)
                allMDFiles.append(contentsOf: found)
            } catch {
                // Skip URLs that fail
            }
        }

        if allMDFiles.isEmpty {
            errorMessage = "No Markdown files found in the selected items."
            isImporting = false
            return
        }

        await processMarkdownFiles(allMDFiles)
        isImporting = false
    }

    /// Reset state for a new import session.
    func reset() {
        isImporting = false
        progress = 0
        currentFile = ""
        result = nil
        errorMessage = nil
    }

    // MARK: - Private Helpers

    private func importMarkdownFiles(from url: URL) async {
        do {
            let mdFiles = try findMarkdownFiles(in: url)

            guard !mdFiles.isEmpty else {
                errorMessage = "No Markdown files found in the selected location."
                return
            }

            await processMarkdownFiles(mdFiles)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func processMarkdownFiles(_ mdFiles: [URL]) async {
        let total = mdFiles.count
        var imported = 0
        var skipped = 0
        var errors: [String] = []

        for (index, mdFile) in mdFiles.enumerated() {
            currentFile = mdFile.lastPathComponent
            progress = Double(index) / Double(max(total, 1))

            do {
                let content = try String(contentsOf: mdFile, encoding: .utf8)
                let title = extractTitle(from: mdFile.lastPathComponent)

                // Skip empty files
                guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    skipped += 1
                    continue
                }

                // Skip files with no meaningful title
                guard !title.isEmpty else {
                    skipped += 1
                    continue
                }

                let cleanedMarkdown = cleanNotionMarkdown(content)

                let _ = try await noteRepo.create(
                    title: title,
                    bodyHTML: cleanedMarkdown,
                    folderID: nil
                )
                imported += 1
            } catch {
                errors.append("\(mdFile.lastPathComponent): \(error.localizedDescription)")
            }
        }

        progress = 1.0
        result = ImportResult(imported: imported, skipped: skipped, errors: errors)
    }

    private func findMarkdownFiles(in directory: URL) throws -> [URL] {
        var mdFiles: [URL] = []

        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: directory.path, isDirectory: &isDir) {
            if isDir.boolValue {
                if let enumerator = FileManager.default.enumerator(
                    at: directory,
                    includingPropertiesForKeys: [.isRegularFileKey],
                    options: [.skipsHiddenFiles]
                ) {
                    for case let fileURL as URL in enumerator {
                        if fileURL.pathExtension.lowercased() == "md" {
                            mdFiles.append(fileURL)
                        }
                    }
                }
            } else if directory.pathExtension.lowercased() == "md" {
                mdFiles.append(directory)
            }
        }

        return mdFiles.sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    /// Extract a clean title from a Notion export filename.
    /// Notion uses the format: "Page Title abc123def456.md" where the hash
    /// is a 32-character hex string appended after the last space.
    func extractTitle(from filename: String) -> String {
        var title = filename

        // Remove .md extension
        if title.hasSuffix(".md") {
            title = String(title.dropLast(3))
        }

        // Notion appends a hex hash to filenames: "Page Title abc123def456.md"
        // The hash is typically 32 hex chars after the last space.
        let parts = title.components(separatedBy: " ")
        if let lastPart = parts.last,
           lastPart.count >= 20,
           lastPart.allSatisfy({ $0.isHexDigit }) {
            title = parts.dropLast().joined(separator: " ")
        }

        // Also handle URL-encoded spaces (%20) in filenames
        title = title.removingPercentEncoding ?? title

        return title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Clean Notion-specific markdown artifacts for a cleaner note.
    func cleanNotionMarkdown(_ markdown: String) -> String {
        var text = markdown

        // Remove empty links that Notion generates
        text = text.replacingOccurrences(of: "[]()", with: "")

        // Clean up excessive blank lines (Notion often adds many)
        if let regex = try? NSRegularExpression(pattern: "\\n{4,}") {
            let range = NSRange(text.startIndex..., in: text)
            text = regex.stringByReplacingMatches(in: text, range: range, withTemplate: "\n\n\n")
        }

        // Remove Notion page links that won't resolve in Haven
        // Pattern: [Page Name](notion://...) or [Page Name](https://www.notion.so/...)
        if let regex = try? NSRegularExpression(
            pattern: "\\[([^\\]]+)\\]\\((?:notion://|https?://(?:www\\.)?notion\\.so/)[^)]*\\)"
        ) {
            let range = NSRange(text.startIndex..., in: text)
            text = regex.stringByReplacingMatches(in: text, range: range, withTemplate: "$1")
        }

        // Remove Notion's inline database references like {{notion-db-id}}
        if let regex = try? NSRegularExpression(pattern: "\\{\\{[a-f0-9-]+\\}\\}") {
            let range = NSRange(text.startIndex..., in: text)
            text = regex.stringByReplacingMatches(in: text, range: range, withTemplate: "")
        }

        // Notion checkbox format (- [ ] and - [x]) is standard markdown, keep as-is

        // Notion callout blocks (> emoji text) are valid blockquotes, keep as-is

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
