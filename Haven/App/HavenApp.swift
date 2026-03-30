import SwiftUI
import SQLite3

@main
struct HavenApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var container = DependencyContainer()
    @StateObject private var toastManager = ToastManager()
    @State private var initializationFailed = false
    @State private var hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    @State private var isLocked = true
    @Environment(\.scenePhase) var scenePhase

    private let biometricService = BiometricService()

    var body: some Scene {
        WindowGroup {
            Group {
                if biometricService.isEnabled && isLocked {
                    LockScreenView(
                        onUnlock: { attemptUnlock() },
                        biometricType: biometricService.availableBiometric
                    )
                } else if hasCompletedOnboarding {
                    HavenNavigationStack()
                        .environmentObject(appState)
                        .environmentObject(container)
                        .environmentObject(toastManager)
                        .preferredColorScheme(appState.preferredColorScheme)
                } else {
                    OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                        .environmentObject(container)
                        .preferredColorScheme(appState.preferredColorScheme)
                }
            }
            .onAppear {
                do {
                    try container.initialize()
                    // Load saved theme preference
                    loadSavedTheme()
                } catch {
                    initializationFailed = true
                }
                // Auto-trigger biometric authentication on launch
                if biometricService.isEnabled {
                    attemptUnlock()
                }
            }
            .onOpenURL { url in
                DeepLink.handle(url: url, appState: appState)
            }
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .background && biometricService.isEnabled {
                    isLocked = true
                }
                if newPhase == .active && biometricService.isEnabled && isLocked {
                    attemptUnlock()
                }
            }
            .alert("Haven cannot start", isPresented: $initializationFailed) {
                Button("Quit") {
                    fatalError("Database initialization failed")
                }
            } message: {
                Text("The database could not be opened. Please restart the app or reinstall.")
            }
        }
    }

    private func attemptUnlock() {
        Task {
            let success = await biometricService.authenticate()
            await MainActor.run {
                if success {
                    isLocked = false
                }
            }
        }
    }

    private func loadSavedTheme() {
        try? container.databaseManager.query("SELECT value FROM app_settings WHERE key = 'theme_mode'") { stmt in
            if let cStr = sqlite3_column_text(stmt, 0) {
                let mode = String(cString: cStr)
                appState.applyTheme(mode)
            }
        }
    }
}

// MARK: - Lock Screen

struct LockScreenView: View {
    let onUnlock: () -> Void
    let biometricType: BiometricService.BiometricType
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.havenBackground
                .ignoresSafeArea()

            VStack(spacing: Spacing.xxl) {
                Text("H")
                    .font(.system(size: 72, design: .serif).weight(.bold))
                    .foregroundColor(Color.havenPrimary)
                    .scaleEffect(appeared ? 1.0 : 0.8)
                    .opacity(appeared ? 1.0 : 0)

                Text("Haven is locked")
                    .font(.havenHeadline)
                    .foregroundColor(Color.havenTextPrimary)
                    .opacity(appeared ? 1.0 : 0)

                Button {
                    onUnlock()
                } label: {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: biometricType == .faceID ? "faceid" : "touchid")
                        Text("Unlock")
                    }
                    .font(.body.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.xxxl)
                    .padding(.vertical, Spacing.md)
                    .background(Color.havenPrimary)
                    .clipShape(.rect(cornerRadius: CornerRadius.sm))
                }
                .accessibilityLabel("Unlock Haven")

                Text("Tap to use \(biometricType == .faceID ? "Face ID" : "Touch ID") or your passcode")
                    .font(.caption2)
                    .foregroundColor(Color.havenTextSecondary)
                    .opacity(appeared ? 1.0 : 0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                appeared = true
            }
        }
    }
}
