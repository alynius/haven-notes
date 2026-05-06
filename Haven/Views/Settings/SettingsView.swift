import SwiftUI

struct SettingsView: View {
    @StateObject var viewModel: SettingsViewModel
    @Environment(AppState.self) var appState
    @EnvironmentObject var container: DependencyContainer
    @State private var showNotionImport = false

    var body: some View {
        ZStack {
            Color.havenBackground
                .ignoresSafeArea()

            List {
                // App info section
                Section {
                    HStack {
                        Text("Notes")
                            .font(.havenBody)
                            .foregroundColor(Color.havenTextPrimary)
                        Spacer()
                        Text("\(viewModel.noteCount)")
                            .font(.havenBody)
                            .foregroundColor(Color.havenTextSecondary)
                    }
                } header: {
                    Text("Library")
                }
                .listRowBackground(Color.havenSurface)

                // Security section
                Section {
                    Toggle(isOn: Binding(
                        get: { container.biometricService.isEnabled },
                        set: { container.biometricService.isEnabled = $0 }
                    )) {
                        HStack {
                            Image(systemName: container.biometricService.availableBiometric == .faceID ? "faceid" : "touchid")
                                .foregroundColor(Color.havenAccent)
                            Text(container.biometricService.availableBiometric == .faceID ? "Face ID Lock" : "Touch ID Lock")
                                .font(.havenBody)
                        }
                    }
                    .tint(Color.havenAccent)
                    .accessibilityIdentifier("settings_toggle_faceId")
                } header: {
                    Text("Security")
                } footer: {
                    Text("Require authentication to open Haven.")
                        .font(.caption2)
                }
                .listRowBackground(Color.havenSurface)

                // Appearance section
                Section {
                    Picker("Theme", selection: $viewModel.themeMode) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                    .font(.havenBody)
                    .foregroundColor(Color.havenTextPrimary)
                    .accessibilityIdentifier("settings_picker_theme")
                    .onChange(of: viewModel.themeMode) { _, newValue in
                        viewModel.setThemeMode(newValue)
                        appState.applyTheme(newValue)
                    }
                } header: {
                    Text("Appearance")
                }
                .listRowBackground(Color.havenSurface)

                // Import section
                Section {
                    Button {
                        showNotionImport = true
                    } label: {
                        HStack {
                            Label("Import from Notion", systemImage: "square.and.arrow.down")
                                .font(.havenBody)
                                .foregroundColor(Color.havenTextPrimary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(Color.havenTextSecondary)
                        }
                    }
                    .accessibilityIdentifier("settings_button_importNotion")
                } header: {
                    Text("Import")
                }
                .listRowBackground(Color.havenSurface)

                // Sync section
                Section {
                    NavigationLink(value: Route.syncSettings) {
                        Text("Sync Settings")
                            .font(.havenBody)
                    }
                    .accessibilityIdentifier("settings_navLink_sync")

                    NavigationLink(value: Route.encryption) {
                        HStack {
                            Text("Encryption")
                                .font(.havenBody)
                            Spacer()
                            Text(container.encryptionService.hasKey ? "On" : "Off")
                                .font(.havenCaption)
                                .foregroundColor(container.encryptionService.hasKey ? Color.havenAccent : Color.havenTextSecondary)
                        }
                    }
                    .accessibilityIdentifier("settings_navLink_encryption")
                } header: {
                    Text("Sync")
                }
                .listRowBackground(Color.havenSurface)

                // Subscription section
                Section {
                    NavigationLink(value: Route.subscription) {
                        Text("Haven Pro")
                            .font(.havenBody)
                    }
                    .accessibilityIdentifier("settings_navLink_subscription")
                } header: {
                    Text("Subscription")
                }
                .listRowBackground(Color.havenSurface)

                // About section
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Haven")
                            .font(.havenBody.weight(.medium))
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
                                .padding(.top, 2)
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("About")
                }
                .listRowBackground(Color.havenSurface)
            }
            #if os(iOS)
            .listStyle(.insetGrouped)
            #endif
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Settings")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .sheet(isPresented: $showNotionImport) {
            NotionImportView(importer: container.notionImporter)
        }
        .task {
            await viewModel.load()
        }
    }
}
