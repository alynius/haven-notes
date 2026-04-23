import Foundation
import LocalAuthentication

final class BiometricService {

    enum BiometricType {
        case faceID, touchID, none
    }

    var availableBiometric: BiometricType {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        #if os(iOS)
        return context.biometryType == .faceID ? .faceID : .touchID
        #elseif os(macOS)
        return .touchID
        #endif
    }

    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "biometricLockEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "biometricLockEnabled") }
    }

    func authenticate() async -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = "Use Passcode"

        do {
            return try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Unlock Haven to access your notes"
            )
        } catch {
            // Fall back to device passcode
            do {
                return try await context.evaluatePolicy(
                    .deviceOwnerAuthentication,
                    localizedReason: "Unlock Haven to access your notes"
                )
            } catch {
                return false
            }
        }
    }
}
