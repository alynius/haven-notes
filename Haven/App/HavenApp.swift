import SwiftUI

@main
struct HavenApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var container = DependencyContainer()

    var body: some Scene {
        WindowGroup {
            HavenNavigationStack()
                .environmentObject(appState)
                .environmentObject(container)
                .onAppear {
                    do {
                        try container.initialize()
                    } catch {
                        print("Failed to initialize Haven: \(error)")
                    }
                }
                .preferredColorScheme(appState.preferredColorScheme)
        }
    }
}
