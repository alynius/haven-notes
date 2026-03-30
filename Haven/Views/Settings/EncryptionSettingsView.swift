import SwiftUI

struct EncryptionSettingsView: View {
    @EnvironmentObject var container: DependencyContainer
    @EnvironmentObject var toastManager: ToastManager
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isEnabled = false
    @State private var isSettingUp = false
    @State private var showDisableConfirm = false

    var body: some View {
        ZStack {
            Color.havenBackground
                .ignoresSafeArea()

            List {
                // Status section
                Section {
                    HStack {
                        Image(systemName: isEnabled ? "lock.fill" : "lock.open")
                            .foregroundColor(isEnabled ? Color.havenAccent : Color.havenTextSecondary)
                        Text(isEnabled ? "Encryption is ON" : "Encryption is OFF")
                            .font(.havenBody)
                            .foregroundColor(Color.havenTextPrimary)
                        Spacer()
                        if isEnabled {
                            Text("AES-256")
                                .font(.havenCaption)
                                .foregroundColor(Color.havenAccent)
                        }
                    }
                } header: {
                    Text("Status")
                } footer: {
                    Text(isEnabled
                         ? "Your notes are encrypted before leaving your device. Not even Haven's server can read them."
                         : "Enable encryption to protect your synced notes with a password. Notes are encrypted on your device before being sent to the server.")
                        .font(.caption2)
                }
                .listRowBackground(Color.havenSurface)

                if !isEnabled {
                    // Setup section
                    Section {
                        SecureField("Encryption password", text: $password)
                            .font(.havenBody)
                            .textContentType(.newPassword)

                        SecureField("Confirm password", text: $confirmPassword)
                            .font(.havenBody)
                            .textContentType(.newPassword)

                        Button {
                            setupEncryption()
                        } label: {
                            HStack {
                                Text("Enable Encryption")
                                    .font(.havenBody.weight(.semibold))
                                Spacer()
                                if isSettingUp {
                                    ProgressView()
                                }
                            }
                        }
                        .disabled(password.count < 8 || password != confirmPassword || isSettingUp)
                    } header: {
                        Text("Set Up")
                    } footer: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Minimum 8 characters.")
                            Text("If you forget this password, your encrypted notes cannot be recovered. There is no password reset.")
                                .fontWeight(.medium)
                        }
                        .font(.caption2)
                    }
                    .listRowBackground(Color.havenSurface)
                } else {
                    // Disable section
                    Section {
                        Button(role: .destructive) {
                            showDisableConfirm = true
                        } label: {
                            Text("Disable Encryption")
                                .font(.havenBody)
                        }
                    } header: {
                        Text("Manage")
                    } footer: {
                        Text("Disabling encryption will remove the encryption key. Previously synced encrypted notes will remain encrypted on the server until re-synced.")
                            .font(.caption2)
                    }
                    .listRowBackground(Color.havenSurface)
                }

                // Error/success shown via ToastManager
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Encryption")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            isEnabled = container.encryptionService.hasKey
        }
        .confirmationDialog("Disable Encryption?", isPresented: $showDisableConfirm, titleVisibility: .visible) {
            Button("Disable", role: .destructive) {
                container.encryptionService.deleteKeyFromKeychain()
                isEnabled = false
                toastManager.showSuccess("Encryption disabled")
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your encryption key will be deleted. Encrypted notes on the server will become unreadable.")
        }
    }

    private func setupEncryption() {
        guard password.count >= 8 else {
            toastManager.showError("Password must be at least 8 characters")
            return
        }
        guard password == confirmPassword else {
            toastManager.showError("Passwords don't match")
            return
        }

        isSettingUp = true

        // Derive key on background thread (PBKDF2 is intentionally slow)
        Task.detached(priority: .userInitiated) {
            let service = await MainActor.run { self.container.encryptionService }
            let result = service.deriveKey(from: self.password)

            do {
                try service.saveKeyToKeychain(
                    keyData: result.key.withUnsafeBytes { Data($0) },
                    salt: result.salt
                )

                await MainActor.run {
                    self.isSettingUp = false
                    self.isEnabled = true
                    self.password = ""
                    self.confirmPassword = ""
                    self.toastManager.showSuccess("Encryption enabled")
                }
            } catch {
                await MainActor.run {
                    self.isSettingUp = false
                    self.toastManager.showError(error.localizedDescription)
                }
            }
        }
    }
}
