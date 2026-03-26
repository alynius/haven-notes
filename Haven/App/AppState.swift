import SwiftUI

enum Route: Hashable {
    case noteEditor(noteID: String?)   // nil = new note
    case search
    case settings
    case syncSettings
    case subscription
}

@MainActor
final class AppState: ObservableObject {
    @Published var navigationPath = NavigationPath()
    @Published var selectedNoteID: String?
    @Published var preferredColorScheme: ColorScheme? = nil

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
