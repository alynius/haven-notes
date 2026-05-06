import SwiftUI
import SQLite3

@main
struct HavenApp: App {
    @State private var appState = AppState()
    @StateObject private var container = DependencyContainer()
    @State private var toastManager = ToastManager()
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
        #if os(macOS)
        WindowGroup {
            mainContent
        }
        .defaultSize(width: 1200, height: 800)
        .commands {
            HavenMenuCommands()
        }

        Settings {
            MacSettingsView()
                .environmentObject(container)
        }
        #else
        WindowGroup {
            mainContent
        }
        #endif
    }

    @ViewBuilder
    private var mainContent: some View {
            Group {
                if container.biometricService.isEnabled && isLocked {
                    LockScreenView(
                        onUnlock: { attemptUnlock() },
                        biometricType: container.biometricService.availableBiometric
                    )
                } else if hasCompletedOnboarding {
                    HavenNavigationStack()
                        .environment(appState)
                        .environmentObject(container)
                        .environment(toastManager)
                        .preferredColorScheme(appState.preferredColorScheme)
                        .sheet(isPresented: $showPaywallAfterOnboarding) {
                            SubscriptionView(
                                viewModel: SubscriptionViewModel(subscriptionManager: container.subscriptionManager),
                                isModal: true
                            )
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
                if hasCompletedOnboarding {
                    createStarterNoteIfNeeded()
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
                if container.biometricService.isEnabled && isLocked { return }
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
            .onChange(of: hasCompletedOnboarding) { _, finished in
                if finished {
                    createStarterNoteIfNeeded()
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

    /// Seed a "Welcome to Haven" note on first launch only.
    /// Skips if the user already has notes (pre-feature install) or if we've already seeded once.
    private func createStarterNoteIfNeeded() {
        let key = "hasCreatedStarterNote"
        guard !UserDefaults.standard.bool(forKey: key) else { return }

        Task {
            let count = await container.noteRepository.countAll()
            guard count == 0 else {
                // Existing user — flip the flag silently so we never seed for them.
                UserDefaults.standard.set(true, forKey: key)
                return
            }

            let body = """
            # Welcome to Haven

            This is your first note. Edit or delete it any time.

            Haven understands markdown:
            - **Bold** and *italic*
            - # Headings (one to three #)
            - [[Wiki links]] — type `[[` to link to another note
            - Tasks live below the editor; the daily note lives in the sidebar

            Your notes stay on this device. Pro unlocks encrypted sync across devices.
            """

            _ = try? await container.noteRepository.create(
                title: "Welcome to Haven",
                bodyHTML: body,
                folderID: nil
            )
            UserDefaults.standard.set(true, forKey: key)
        }
    }
}

// MARK: - Lock Screen

struct LockScreenView: View {
    let onUnlock: () -> Void
    let biometricType: BiometricService.BiometricType
    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    private var iconName: String {
        switch biometricType {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        case .none: return "lock"
        }
    }

    private var hint: String {
        switch biometricType {
        case .faceID: return "Tap to use Face ID or your passcode"
        case .touchID: return "Tap to use Touch ID or your passcode"
        case .none: return "Tap to enter your passcode"
        }
    }

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
                        Image(systemName: iconName)
                        Text("Unlock")
                    }
                    .font(.body.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.xxxl)
                    .padding(.vertical, Spacing.md)
                    .background(Color.havenPrimary)
                    .clipShape(.rect(cornerRadius: CornerRadius.sm))
                }
                .keyboardShortcut(.return, modifiers: [])
                .accessibilityLabel("Unlock Haven")
                .accessibilityHint("Authenticates with biometrics or your passcode")

                Text(hint)
                    .font(.caption2)
                    .foregroundColor(Color.havenTextSecondary)
                    .opacity(appeared ? 1.0 : 0)
            }
        }
        .onAppear {
            if reduceMotion {
                appeared = true
            } else {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                    appeared = true
                }
            }
        }
    }
}
