import SwiftUI

enum DeepLink {
    static let scheme = "haven"
    static let newNote = "haven://new-note"
    static let dailyNote = "haven://daily-note"

    @MainActor
    static func handle(url: URL, appState: AppState) {
        guard url.scheme == scheme else { return }

        switch url.host {
        case "new-note":
            appState.navigateTo(.noteEditor(noteID: nil))
        case "daily-note":
            appState.pendingAction = .openDailyNote
        default:
            break
        }
    }
}
