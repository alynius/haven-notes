#if os(macOS)
import SwiftUI

struct MacSettingsView: View {
    @EnvironmentObject var container: DependencyContainer

    var body: some View {
        TabView {
            GeneralSettingsTab()
                .environmentObject(container)
                .tabItem { Label("General", systemImage: "gear") }

            SyncSettingsView(viewModel: SyncSettingsViewModel(syncManager: container.syncManager))
                .environmentObject(container)
                .tabItem { Label("Sync", systemImage: "arrow.triangle.2.circlepath") }

            EncryptionSettingsView()
                .environmentObject(container)
                .environmentObject(ToastManager())
                .tabItem { Label("Encryption", systemImage: "lock.shield") }

            SubscriptionView(viewModel: SubscriptionViewModel(subscriptionManager: container.subscriptionManager))
                .environmentObject(container)
                .tabItem { Label("Subscription", systemImage: "star") }

            AboutTab()
                .tabItem { Label("About", systemImage: "info.circle") }
        }
        .frame(width: 500, height: 420)
    }
}

struct AboutTab: View {
    var body: some View {
        VStack(spacing: Spacing.md) {
            Text("H")
                .font(.system(size: 56, design: .serif).weight(.bold))
                .foregroundColor(Color.havenPrimary)
                .padding(.top, Spacing.lg)

            Text("Haven")
                .font(.havenHeadline)
                .foregroundColor(Color.havenTextPrimary)

            Text("Fast. Private. Solid.")
                .font(.havenCaption)
                .foregroundColor(Color.havenTextSecondary)

            Text("Your notes stay on your device.")
                .font(.havenCaption)
                .foregroundColor(Color.havenTextSecondary)

            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
               let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                Text("Version \(version) (\(build))")
                    .font(.caption2)
                    .foregroundColor(Color.havenTextSecondary)
                    .padding(.top, Spacing.xs)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

struct GeneralSettingsTab: View {
    @EnvironmentObject var container: DependencyContainer
    @AppStorage("preferredTheme") private var preferredTheme = "system"

    var body: some View {
        Form {
            Picker("Appearance", selection: $preferredTheme) {
                Text("System").tag("system")
                Text("Light").tag("light")
                Text("Dark").tag("dark")
            }
            .pickerStyle(.segmented)

            let biometric = container.biometricService.availableBiometric
            if biometric != .none {
                Section("Security") {
                    Toggle(biometricLabel(for: biometric), isOn: Binding(
                        get: { container.biometricService.isEnabled },
                        set: { container.biometricService.isEnabled = $0 }
                    ))
                }
            }
        }
        .padding()
    }

    private func biometricLabel(for type: BiometricService.BiometricType) -> String {
        switch type {
        case .faceID: return "Lock Haven with Face ID"
        case .touchID: return "Lock Haven with Touch ID"
        case .none: return "Lock Haven"
        }
    }
}
#endif
