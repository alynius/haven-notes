import SwiftUI

struct SettingsView: View {
    @StateObject var viewModel: SettingsViewModel
    @EnvironmentObject var appState: AppState

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
                            .foregroundStyle(.havenTextPrimary)
                        Spacer()
                        Text("\(viewModel.noteCount)")
                            .font(.havenBody)
                            .foregroundStyle(.havenTextSecondary)
                    }
                } header: {
                    Text("Library")
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
                    .foregroundStyle(.havenTextPrimary)
                    .onChange(of: viewModel.themeMode) { newValue in
                        viewModel.setThemeMode(newValue)
                    }
                } header: {
                    Text("Appearance")
                }
                .listRowBackground(Color.havenSurface)

                // Sync section
                Section {
                    NavigationLink(value: Route.syncSettings) {
                        Text("Sync Settings")
                            .font(.havenBody)
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
                            .foregroundStyle(.havenTextPrimary)
                        Text("Fast. Private. Solid.")
                            .font(.havenCaption)
                            .foregroundStyle(.havenTextSecondary)
                        Text("Your notes stay on your device.")
                            .font(.havenCaption)
                            .foregroundStyle(.havenTextSecondary)
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
        .task {
            await viewModel.load()
        }
    }
}
