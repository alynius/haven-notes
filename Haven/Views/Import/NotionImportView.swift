import SwiftUI
import UniformTypeIdentifiers

struct NotionImportView: View {
    @StateObject var importer: NotionImporter
    @Environment(\.dismiss) var dismiss
    @State private var showFilePicker = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xxl) {
                    // Header
                    VStack(spacing: Spacing.sm) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(.largeTitle))
                            .foregroundStyle(.tertiary)

                        Text("Import from Notion")
                            .font(.havenContentTitle)
                            .foregroundColor(Color.havenTextPrimary)

                        Text("Bring your Notion notes into Haven")
                            .font(.havenBody)
                            .foregroundColor(Color.havenTextSecondary)
                    }
                    .padding(.top, Spacing.xxxl)

                    // Instructions
                    VStack(alignment: .leading, spacing: Spacing.lg) {
                        Text("How to export from Notion:")
                            .font(.havenBody.weight(.semibold))
                            .foregroundColor(Color.havenTextPrimary)

                        instructionRow(number: "1", text: "Open Notion on your computer")
                        instructionRow(number: "2", text: "Go to Settings \u{2192} Export all workspace content")
                        instructionRow(number: "3", text: "Choose \"Markdown & CSV\" format")
                        instructionRow(number: "4", text: "Unzip the downloaded file")
                        instructionRow(number: "5", text: "Share the folder to Haven, or pick files below")
                    }
                    .padding(Spacing.lg)
                    .background(Color.havenSurface)
                    .clipShape(.rect(cornerRadius: CornerRadius.md))

                    // Main action area
                    if !importer.isImporting {
                        if let result = importer.result {
                            resultView(result)
                        } else {
                            selectButton
                        }
                    } else {
                        progressView
                    }

                    if let error = importer.errorMessage {
                        Text(error)
                            .font(.havenCaption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }

                    // What gets imported
                    supportInfoSection
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.xxxl)
            }
            .background(Color.havenBackground)
            .navigationTitle("Import")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [.folder, .plainText, UTType(filenameExtension: "md") ?? .plainText],
                allowsMultipleSelection: true
            ) { pickerResult in
                switch pickerResult {
                case .success(let urls):
                    Task {
                        await importer.importFromFiles(urls: urls)
                    }
                case .failure(let error):
                    importer.errorMessage = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Subviews

    private var selectButton: some View {
        Button {
            showFilePicker = true
        } label: {
            Label("Select Notion Export", systemImage: "folder")
                .font(.body.weight(.semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(Color.havenPrimary)
                .clipShape(.rect(cornerRadius: CornerRadius.sm))
        }
        .accessibilityIdentifier("notionImport_button_select")
    }

    private var progressView: some View {
        VStack(spacing: Spacing.md) {
            ProgressView(value: importer.progress)
                .tint(Color.havenPrimary)

            Text("Importing \(importer.currentFile)...")
                .font(.havenCaption)
                .foregroundColor(Color.havenTextSecondary)
                .lineLimit(1)

            Text("\(Int(importer.progress * 100))%")
                .font(.havenBody.weight(.medium))
                .foregroundColor(Color.havenTextPrimary)
        }
        .padding(Spacing.lg)
    }

    private func resultView(_ result: ImportResult) -> some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(.title))
                .foregroundColor(.green)

            Text("Import Complete")
                .font(.havenHeadline)
                .foregroundColor(Color.havenTextPrimary)

            Text("\(result.imported) notes imported")
                .font(.havenBody)
                .foregroundColor(Color.havenTextSecondary)

            if result.skipped > 0 {
                Text("\(result.skipped) empty files skipped")
                    .font(.havenCaption)
                    .foregroundColor(Color.havenTextSecondary)
            }

            if !result.errors.isEmpty {
                Text("\(result.errors.count) errors")
                    .font(.havenCaption)
                    .foregroundColor(.red)
            }

            Button("Done") { dismiss() }
                .font(.body.weight(.semibold))
                .foregroundColor(.white)
                .frame(maxWidth: 200)
                .padding(.vertical, Spacing.md)
                .background(Color.havenPrimary)
                .clipShape(.rect(cornerRadius: CornerRadius.sm))
                .accessibilityIdentifier("notionImport_button_done")
                .padding(.top, Spacing.sm)
        }
    }

    private var supportInfoSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("What gets imported:")
                .font(.havenCaption.weight(.medium))
                .foregroundColor(Color.havenTextSecondary)

            supportRow(text: "Text, headings, lists", supported: true)
            supportRow(text: "Bold, italic, code blocks", supported: true)
            supportRow(text: "Checkboxes / to-dos", supported: true)
            supportRow(text: "Links and blockquotes", supported: true)
            supportRow(text: "Database tables", supported: false)
            supportRow(text: "Embedded files and images", supported: false)
        }
        .padding(Spacing.lg)
        .background(Color.havenSurface)
        .clipShape(.rect(cornerRadius: CornerRadius.md))
    }

    // MARK: - Row Helpers

    private func instructionRow(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Text(number)
                .font(.havenCaption.weight(.bold))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Color.havenPrimary)
                .clipShape(Circle())

            Text(text)
                .font(.havenBody)
                .foregroundColor(Color.havenTextPrimary)
        }
    }

    private func supportRow(text: String, supported: Bool) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: supported ? "checkmark.circle.fill" : "xmark.circle")
                .font(.caption)
                .foregroundColor(supported ? .green : Color.havenTextSecondary.opacity(0.5))
            Text(text)
                .font(.havenCaption)
                .foregroundColor(supported ? Color.havenTextPrimary : Color.havenTextSecondary)
        }
    }
}
