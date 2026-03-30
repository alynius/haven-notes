import SwiftUI

enum Route: Hashable {
    case noteEditor(noteID: String?)   // nil = new note
    case search
    case settings
    case syncSettings
    case subscription
    case encryption
    case notionImport
    case graph
}

enum NoteFilter: Hashable {
    case allNotes
    case folder(id: String, name: String)
    case tag(id: String, name: String)
}

enum PendingAction {
    case openDailyNote
    case none
}

@MainActor
final class AppState: ObservableObject {
    @Published var navigationPath = NavigationPath()
    @Published var selectedNoteID: String?
    @Published var preferredColorScheme: ColorScheme? = nil
    @Published var activeFilter: NoteFilter = .allNotes
    @Published var pendingAction: PendingAction = .none

    func navigateTo(_ route: Route) {
        navigationPath.append(route)
    }

    func popToRoot() {
        navigationPath = NavigationPath()
    }

    func pop() {
        guard !navigationPath.isEmpty else { return }
        navigationPath.removeLast()
    }

    func applyTheme(_ mode: String) {
        switch mode {
        case "light": preferredColorScheme = .light
        case "dark": preferredColorScheme = .dark
        default: preferredColorScheme = nil  // system
        }
    }
}
