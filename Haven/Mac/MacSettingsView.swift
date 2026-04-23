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
        }
        .frame(width: 500, height: 400)
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

            Section("Security") {
                Toggle("Lock Haven with Touch ID", isOn: Binding(
                    get: { container.biometricService.isEnabled },
                    set: { container.biometricService.isEnabled = $0 }
                ))
            }
        }
        .padding()
    }
}
#endif
