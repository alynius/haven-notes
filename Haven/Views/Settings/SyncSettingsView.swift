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
                } header: {
                    Text("Sync")
                } footer: {
                    Text("When enabled, notes sync to your server. Your data never touches our servers.")
                        .font(.caption2)
                        .foregroundStyle(.havenTextSecondary)
                }
                .listRowBackground(Color.havenSurface)

                if viewModel.isEnabled {
                    Section {
                        TextField("Server URL", text: $viewModel.serverURL)
                            .font(.havenBody)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)

                        SecureField("Auth Token", text: $viewModel.authToken)
                            .font(.havenBody)

                        Button {
                            Task { await viewModel.saveConfiguration() }
                        } label: {
                            Text("Save Configuration")
                                .font(.havenBody)
                                .foregroundStyle(.havenPrimary)
                        }
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
                                .foregroundStyle(.havenTextSecondary)
                        }

                        Button {
                            Task { await viewModel.syncNow() }
                        } label: {
                            HStack {
                                Text("Sync Now")
                                    .font(.havenBody)
                                    .foregroundStyle(.havenPrimary)
                                Spacer()
                                if case .syncing = viewModel.syncStatus {
                                    ProgressView()
                                        .tint(Color.havenPrimary)
                                }
                            }
                        }
                    } header: {
                        Text("Status")
                    }
                    .listRowBackground(Color.havenSurface)
                }

                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .font(.havenCaption)
                            .foregroundStyle(.red)
                    }
                    .listRowBackground(Color.havenSurface)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Sync")
        .navigationBarTitleDisplayMode(.inline)
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
                .foregroundStyle(.havenAccent)
        case .syncing:
            Label("Syncing", systemImage: "arrow.triangle.2.circlepath")
                .font(.havenCaption)
                .foregroundStyle(.havenPrimary)
        case .error:
            Label("Error", systemImage: "exclamationmark.triangle")
                .font(.havenCaption)
                .foregroundStyle(.red)
        case .disabled:
            Label("Disabled", systemImage: "minus.circle")
                .font(.havenCaption)
                .foregroundStyle(.havenTextSecondary)
        }
    }
}
