#if os(macOS)
import SwiftUI
import AppKit

// MARK: - QuickNotePanelController

@MainActor
final class QuickNotePanelController: NSObject, ObservableObject {
    private var panel: NSPanel?
    @Published var isVisible = false

    func toggle() {
        if isVisible {
            hide()
        } else {
            show()
        }
    }

    func show() {
        if panel == nil {
            panel = createPanel()
        }
        panel?.makeKeyAndOrderFront(nil)
        isVisible = true
    }

    func hide() {
        panel?.orderOut(nil)
        isVisible = false
    }

    private func createPanel() -> NSPanel {
        let p = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 320),
            styleMask: [.titled, .closable, .resizable, .utilityWindow, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        p.level = .floating
        p.isMovableByWindowBackground = true
        p.hidesOnDeactivate = false
        p.titlebarAppearsTransparent = true
        p.titleVisibility = .hidden
        p.minSize = NSSize(width: 360, height: 240)
        p.center()
        p.isReleasedWhenClosed = false
        return p
    }

    func setContent(_ view: some View) {
        if panel == nil {
            panel = createPanel()
        }
        let hosting = NSHostingView(rootView: view)
        panel?.contentView = hosting
    }
}

// MARK: - QuickNoteView

struct QuickNoteView: View {
    @State private var noteTitle = ""
    @State private var noteBody = ""
    @FocusState private var bodyFocused: Bool

    var onSave: (String, String) -> Void
    var onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: Spacing.sm) {
                Image(systemName: "note.text")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color.havenPrimary)
                Text("Quick Note")
                    .font(.havenHeadline)
                    .foregroundColor(Color.havenTextPrimary)
                Spacer()
                Text("⌘⏎ Save")
                    .font(.caption)
                    .foregroundColor(Color.havenTextSecondary)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xxs)
                    .background(Color.havenSurface)
                    .clipShape(.rect(cornerRadius: CornerRadius.xs))
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.lg)
            .padding(.bottom, Spacing.md)

            // Title field
            TextField("Title (optional)", text: $noteTitle)
                .font(.havenBody)
                .textFieldStyle(.plain)
                .foregroundColor(Color.havenTextPrimary)
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.sm)

            Divider()
                .background(Color.havenBorder)

            // Body editor
            TextEditor(text: $noteBody)
                .font(.havenBody)
                .foregroundColor(Color.havenTextPrimary)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .focused($bodyFocused)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()
                .background(Color.havenBorder)

            // Bottom action bar
            HStack(spacing: Spacing.sm) {
                Button("Discard") {
                    onDismiss()
                }
                .keyboardShortcut(.escape, modifiers: [])
                .foregroundColor(Color.havenTextSecondary)

                Spacer()

                Button("Save Note") {
                    onSave(noteTitle, noteBody)
                }
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(noteBody.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .buttonStyle(.borderedProminent)
                .tint(Color.havenPrimary)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
        }
        .background(Color.havenBackground)
        .onAppear {
            bodyFocused = true
        }
    }
}

#endif
