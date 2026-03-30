import SwiftUI

struct SettingsView: View {
    @StateObject var viewModel: SettingsViewModel
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var container: DependencyContainer
    @State private var showNotionImport = false
    private let biometricService = BiometricService()

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
                        get: { biometricService.isEnabled },
                        set: { biometricService.isEnabled = $0 }
                    )) {
                        HStack {
                            Image(systemName: biometricService.availableBiometric == .faceID ? "faceid" : "touchid")
                                .foregroundColor(Color.havenAccent)
                            Text(biometricService.availableBiometric == .faceID ? "Face ID Lock" : "Touch ID Lock")
                                .font(.havenBody)
                        }
                    }
                    .tint(Color.havenAccent)
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
                    .onChange(of: viewModel.themeMode) { newValue in
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
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showNotionImport) {
            NotionImportView(importer: container.notionImporter)
        }
        .task {
            await viewModel.load()
        }
    }
}
