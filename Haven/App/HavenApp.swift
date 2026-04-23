import SwiftUI
import SQLite3

@main
struct HavenApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var container = DependencyContainer()
    @StateObject private var toastManager = ToastManager()
    #if os(macOS)
    @StateObject private var quickNotePanelController = QuickNotePanelController()
    #endif
    @State private var initializationFailed = false
    @State private var hasCompletedOnboarding: Bool = {
        #if DEBUG
        let isUITesting = ProcessInfo.processInfo.arguments.contains("--uitesting")
        #else
        let isUITesting = false
        #endif
        return UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") || isUITesting
    }()
    @State private var isLocked: Bool = {
        #if DEBUG
        let isUITesting = ProcessInfo.processInfo.arguments.contains("--uitesting")
        #else
        let isUITesting = false
        #endif
        return !isUITesting
    }()
    @State private var showPaywallAfterOnboarding = false
    @Environment(\.scenePhase) var scenePhase

    var body: some Scene {
        WindowGroup {
            Group {
                if container.biometricService.isEnabled && isLocked {
                    #if os(iOS)
                    LockScreenView(
                        onUnlock: { attemptUnlock() },
                        biometricType: container.biometricService.availableBiometric
                    )
                    #else
                    // Simple lock overlay for macOS
                    VStack(spacing: Spacing.xl) {
                        Text("H").font(.system(size: 72, design: .serif)).foregroundColor(Color.havenPrimary)
                        Text("Haven is Locked").font(.havenHeadline)
                        Button("Unlock") { Task { await attemptUnlockAsync() } }
                            .keyboardShortcut(.return, modifiers: [])
                            .buttonStyle(.borderedProminent)
                            .tint(Color.havenPrimary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.havenBackground)
                    #endif
                } else if hasCompletedOnboarding {
                    HavenNavigationStack()
                        .environmentObject(appState)
                        .environmentObject(container)
                        .environmentObject(toastManager)
                        .preferredColorScheme(appState.preferredColorScheme)
                        .sheet(isPresented: $showPaywallAfterOnboarding) {
                            SubscriptionView(viewModel: SubscriptionViewModel(subscriptionManager: container.subscriptionManager))
                        }
                } else {
                    OnboardingView(
                        hasCompletedOnboarding: $hasCompletedOnboarding,
                        showPaywallAfterOnboarding: $showPaywallAfterOnboarding
                    )
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
                if container.biometricService.isEnabled {
                    attemptUnlock()
                }
                #if os(macOS)
                setupQuickNotePanel()
                GlobalHotkeyManager.shared.register {
                    NotificationCenter.default.post(name: .havenQuickNote, object: nil)
                }
                #endif
            }
            #if os(macOS)
            .onReceive(NotificationCenter.default.publisher(for: .havenQuickNote)) { _ in
                quickNotePanelController.toggle()
            }
            #endif
            .onOpenURL { url in
                DeepLink.handle(url: url, appState: appState)
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .background && container.biometricService.isEnabled {
                    isLocked = true
                }
                if newPhase == .active && container.biometricService.isEnabled && isLocked {
                    attemptUnlock()
                }
            }
            .alert("Haven cannot start", isPresented: $initializationFailed) {
                Button("Try Again") {
                    initializationFailed = false
                    do {
                        try container.initialize()
                        loadSavedTheme()
                    } catch {
                        initializationFailed = true
                    }
                }
                Button("Quit", role: .destructive) {
                    exit(0)
                }
            } message: {
                Text("The database could not be opened. Please restart the app or reinstall.")
            }
        }
        #if os(macOS)
        .commands {
            HavenMenuCommands()
        }
        #endif

        #if os(macOS)
        Settings {
            MacSettingsView()
                .environmentObject(container)
        }
        #endif
    }

    private func attemptUnlock() {
        Task {
            let success = await container.biometricService.authenticate()
            await MainActor.run {
                if success {
                    isLocked = false
                }
            }
        }
    }

    @MainActor
    private func attemptUnlockAsync() async {
        let success = await container.biometricService.authenticate()
        if success {
            isLocked = false
        }
    }

    #if os(macOS)
    private func setupQuickNotePanel() {
        let view = QuickNoteView(
            onSave: { title, body in
                Task {
                    let noteTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
                    let noteBody = body.trimmingCharacters(in: .whitespacesAndNewlines)
                    _ = try? await container.noteRepository.create(
                        title: noteTitle.isEmpty ? "Quick Note" : noteTitle,
                        bodyHTML: noteBody
                    )
                    await MainActor.run {
                        quickNotePanelController.hide()
                    }
                }
            },
            onDismiss: {
                quickNotePanelController.hide()
            }
        )
        quickNotePanelController.setContent(view)
    }
    #endif

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

#if os(iOS)
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
                .accessibilityHint("Authenticates with Face ID or passcode")

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
#endif
