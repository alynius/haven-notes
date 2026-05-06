#if os(macOS)
import SwiftUI

// MARK: - Notification Names

extension Notification.Name {
    static let havenNewNote  = Notification.Name("haven.newNote")
    static let havenDailyNote = Notification.Name("haven.dailyNote")
    static let havenQuickNote = Notification.Name("haven.quickNote")
    static let havenShowGraph = Notification.Name("haven.showGraph")
    static let havenSearch    = Notification.Name("haven.search")
}

// MARK: - FocusedValue for active editor

struct ActiveEditorKey: FocusedValueKey {
    typealias Value = MacTextViewCoordinator
}

extension FocusedValues {
    var activeEditor: MacTextViewCoordinator? {
        get { self[ActiveEditorKey.self] }
        set { self[ActiveEditorKey.self] = newValue }
    }
}

// MARK: - Menu Commands

struct HavenMenuCommands: Commands {
    @FocusedValue(\.activeEditor) var activeEditor: MacTextViewCoordinator?

    var body: some Commands {
        // Replace default New Item
        CommandGroup(replacing: .newItem) {
            Button("New Note") {
                NotificationCenter.default.post(name: .havenNewNote, object: nil)
            }
            .keyboardShortcut("n", modifiers: .command)

            Button("New Daily Note") {
                NotificationCenter.default.post(name: .havenDailyNote, object: nil)
            }
            .keyboardShortcut("d", modifiers: [.command, .shift])

            Divider()

            Button("Quick Note") {
                NotificationCenter.default.post(name: .havenQuickNote, object: nil)
            }
            .keyboardShortcut("n", modifiers: [.command, .shift])
        }

        // Format menu
        CommandMenu("Format") {
            Button("Bold") { activeEditor?.toggleBold() }
                .keyboardShortcut("b", modifiers: .command)

            Button("Italic") { activeEditor?.toggleItalic() }
                .keyboardShortcut("i", modifiers: .command)

            Divider()

            Button("Heading") { activeEditor?.toggleHeading() }
                .keyboardShortcut("h", modifiers: [.command, .shift])

            Button("List") { activeEditor?.toggleList() }
                .keyboardShortcut("l", modifiers: [.command, .shift])

            Button("Task") { activeEditor?.toggleTask() }
                .keyboardShortcut("t", modifiers: [.command, .shift])

            Button("Code") { activeEditor?.toggleCode() }
                .keyboardShortcut("c", modifiers: [.command, .shift])

            Divider()

            Button("Wiki Link") { activeEditor?.insertWikiLink() }
                .keyboardShortcut("k", modifiers: .command)
        }

        // View commands
        CommandGroup(after: .sidebar) {
            Button("Knowledge Graph") {
                NotificationCenter.default.post(name: .havenShowGraph, object: nil)
            }
            .keyboardShortcut("g", modifiers: .command)
        }

        // Search
        CommandGroup(after: .textEditing) {
            Button("Find in All Notes") {
                NotificationCenter.default.post(name: .havenSearch, object: nil)
            }
            .keyboardShortcut("f", modifiers: [.command, .shift])
        }
    }
}
#endif
