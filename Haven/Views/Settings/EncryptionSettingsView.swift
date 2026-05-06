import SwiftUI

struct EncryptionSettingsView: View {
    @EnvironmentObject var container: DependencyContainer
    @Environment(ToastManager.self) var toastManager
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var hasAcknowledged = false
    @State private var isEnabled = false
    @State private var isSettingUp = false
    @State private var showDisableConfirm = false
    @State private var setupErrorMessage: String?

    private var passwordIsLongEnough: Bool { password.count >= 8 }
    private var passwordsMatch: Bool { !confirmPassword.isEmpty && password == confirmPassword }
    private var canEnable: Bool { passwordIsLongEnough && passwordsMatch && hasAcknowledged }

    var body: some View {
        ZStack {
            Color.havenBackground
                .ignoresSafeArea()

            if case .free = container.subscriptionManager.entitlement {
                proUpgradePrompt
            } else {
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
                    // Prominent data-loss callout — placed before the form so it can't be missed.
                    Section {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            HStack(spacing: Spacing.sm) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.title3)
                                    .foregroundColor(.orange)
                                Text("Choose your password carefully")
                                    .font(.havenBody.weight(.semibold))
                                    .foregroundColor(Color.havenTextPrimary)
                            }
                            Text("If you forget this password, your encrypted notes cannot be recovered. There is no password reset.")
                                .font(.havenCaption)
                                .foregroundColor(Color.havenTextPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                            Text("We recommend storing it in a password manager.")
                                .font(.havenCaption)
                                .foregroundColor(Color.havenTextSecondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(Color.havenSurface)

                    // Setup section
                    Section {
                        VStack(alignment: .leading, spacing: 4) {
                            SecureField("Encryption password", text: $password)
                                .font(.havenBody)
                                .textContentType(.newPassword)
                                .accessibilityIdentifier("encryption_secureField_password")

                            passwordLengthIndicator
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            SecureField("Confirm password", text: $confirmPassword)
                                .font(.havenBody)
                                .textContentType(.newPassword)
                                .accessibilityIdentifier("encryption_secureField_confirmPassword")

                            passwordMatchIndicator
                        }

                        Toggle(isOn: $hasAcknowledged) {
                            Text("I understand my password cannot be recovered.")
                                .font(.havenCaption)
                                .foregroundColor(Color.havenTextPrimary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .tint(Color.havenAccent)
                        .accessibilityIdentifier("encryption_toggle_acknowledge")

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
                        .disabled(!canEnable || isSettingUp)
                        .accessibilityHint("Sets up end-to-end encryption for your notes")
                        .accessibilityIdentifier("encryption_button_enable")
                    } header: {
                        Text("Set Up")
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
                        .accessibilityHint("Removes end-to-end encryption from your notes")
                        .accessibilityIdentifier("encryption_button_disable")
                    } header: {
                        Text("Manage")
                    } footer: {
                        Text("Disabling encryption removes the encryption key from this device. Notes you've already synced encrypted will stay unreadable on the server until you re-enable encryption with the same password.")
                            .font(.caption2)
                    }
                    .listRowBackground(Color.havenSurface)
                }
            }
            #if os(iOS)
            .listStyle(.insetGrouped)
            #endif
            .scrollContentBackground(.hidden)
            } // end else (Pro)
        }
        .navigationTitle("Encryption")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
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
            Text("Your encryption key will be deleted from this device. Encrypted notes already on the server will remain unreadable until you re-enable encryption with the same password.")
        }
        .alert("Couldn't enable encryption", isPresented: Binding(
            get: { setupErrorMessage != nil },
            set: { if !$0 { setupErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(setupErrorMessage ?? "An error occurred during setup.")
        }
    }

    @ViewBuilder
    private var passwordLengthIndicator: some View {
        if password.isEmpty {
            Text("At least 8 characters.")
                .font(.caption2)
                .foregroundColor(Color.havenTextSecondary)
        } else if passwordIsLongEnough {
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption2)
                Text("8 or more characters")
                    .font(.caption2)
            }
            .foregroundColor(Color.havenAccent)
        } else {
            HStack(spacing: 4) {
                Image(systemName: "circle")
                    .font(.caption2)
                Text("\(password.count) of 8 characters")
                    .font(.caption2)
            }
            .foregroundColor(Color.havenTextSecondary)
        }
    }

    @ViewBuilder
    private var passwordMatchIndicator: some View {
        if confirmPassword.isEmpty {
            Color.clear.frame(height: 0)
        } else if passwordsMatch {
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption2)
                Text("Passwords match")
                    .font(.caption2)
            }
            .foregroundColor(Color.havenAccent)
        } else {
            HStack(spacing: 4) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption2)
                Text("Passwords don't match")
                    .font(.caption2)
            }
            .foregroundStyle(.red)
        }
    }

    @ViewBuilder
    private var proUpgradePrompt: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.fill")
                .font(.system(size: 44))
                .foregroundColor(Color.havenAccent)
            Text("Haven Pro Required")
                .font(.havenHeadline)
                .foregroundColor(Color.havenTextPrimary)
            Text("Upgrade to Haven Pro to unlock encryption.")
                .font(.havenBody)
                .foregroundColor(Color.havenTextSecondary)
                .multilineTextAlignment(.center)
            NavigationLink(value: Route.subscription) {
                Text("Upgrade to Pro")
                    .font(.havenBody.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.havenAccent)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(32)
    }

    private func setupEncryption() {
        // Button is gated on canEnable, so we shouldn't reach here invalid — but defend anyway.
        guard canEnable else { return }

        isSettingUp = true

        // Capture password on MainActor before hopping off — PBKDF2 is intentionally slow,
        // so derive off-main, then come back to MainActor for the keychain write.
        let pw = password
        let service = container.encryptionService

        Task.detached(priority: .userInitiated) {
            let result = service.deriveKey(from: pw)

            await MainActor.run {
                do {
                    try service.saveKeyToKeychain(
                        keyData: result.key.withUnsafeBytes { Data($0) },
                        salt: result.salt
                    )
                    service.setMasterKey(result.key)
                    self.isSettingUp = false
                    self.isEnabled = true
                    self.password = ""
                    self.confirmPassword = ""
                    self.hasAcknowledged = false
                    self.toastManager.showSuccess("Encryption enabled")
                } catch {
                    self.isSettingUp = false
                    self.setupErrorMessage = error.localizedDescription
                }
            }
        }
    }
}
