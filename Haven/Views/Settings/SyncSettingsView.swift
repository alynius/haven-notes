import SwiftUI

struct SyncSettingsView: View {
    @StateObject var viewModel: SyncSettingsViewModel

    var body: some View {
        ZStack {
            Color.havenBackground
                .ignoresSafeArea()

            List {
                Section {
                    Toggle("Enable Sync", isOn: Binding(
                        get: { viewModel.isEnabled },
                        set: { _ in Task { await viewModel.toggleSync() } }
                    ))
                    .font(.havenBody)
                    .tint(Color.havenAccent)
                    .accessibilityIdentifier("syncSettings_toggle_enableSync")
                } header: {
                    Text("Sync")
                } footer: {
                    Text("When enabled, notes sync to your server. Your data never touches our servers.")
                        .font(.caption2)
                        .foregroundColor(Color.havenTextSecondary)
                }
                .listRowBackground(Color.havenSurface)

                if viewModel.isEnabled {
                    Section {
                        TextField("Server URL", text: $viewModel.serverURL)
                            .font(.havenBody)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .keyboardType(.URL)
                            .textContentType(.URL)
                            .accessibilityIdentifier("syncSettings_textField_serverURL")

                        SecureField("Auth Token", text: $viewModel.authToken)
                            .font(.havenBody)
                            .accessibilityIdentifier("syncSettings_secureField_authToken")

                        Button {
                            Task { await viewModel.saveConfiguration() }
                        } label: {
                            Text("Save Configuration")
                                .font(.havenBody)
                                .foregroundColor(Color.havenPrimary)
                        }
                        .accessibilityIdentifier("syncSettings_button_save")
                    } header: {
                        Text("Server Configuration")
                    }
                    .listRowBackground(Color.havenSurface)

                    Section {
                        HStack {
                            Text("Status")
                                .font(.havenBody)
                            Spacer()
                            statusBadge
                        }

                        HStack {
                            Text("Pending Changes")
                                .font(.havenBody)
                            Spacer()
                            Text("\(viewModel.unsyncedCount)")
                                .font(.havenBody)
                                .foregroundColor(Color.havenTextSecondary)
                        }

                        Button {
                            Task { await viewModel.syncNow() }
                        } label: {
                            HStack {
                                Text("Sync Now")
                                    .font(.havenBody)
                                    .foregroundColor(Color.havenPrimary)
                                Spacer()
                                if case .syncing = viewModel.syncStatus {
                                    ProgressView()
                                        .tint(Color.havenPrimary)
                                }
                            }
                        }
                        .accessibilityIdentifier("syncSettings_button_syncNow")
                    } header: {
                        Text("Status")
                    }
                    .listRowBackground(Color.havenSurface)
                }

            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Sync")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Sync Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "An error occurred")
        }
        .task {
            await viewModel.loadUnsyncedCount()
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch viewModel.syncStatus {
        case .idle:
            Label("Idle", systemImage: "checkmark.circle")
                .font(.havenCaption)
                .foregroundColor(Color.havenAccent)
        case .syncing:
            Label("Syncing", systemImage: "arrow.triangle.2.circlepath")
                .font(.havenCaption)
                .foregroundColor(Color.havenPrimary)
        case .error:
            Label("Error", systemImage: "exclamationmark.triangle")
                .font(.havenCaption)
                .foregroundStyle(.red)
        case .disabled:
            Label("Disabled", systemImage: "minus.circle")
                .font(.havenCaption)
                .foregroundColor(Color.havenTextSecondary)
        }
    }
}
