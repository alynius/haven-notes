import SwiftUI

extension Animation {
    /// High-frequency UI feedback (toasts, popovers, button press, list inserts).
    /// macOS: 0.15s easeOut — feels instant, no spring weight.
    /// iOS: spring with light bounce — matches touch-driven expectations.
    static var havenSnappy: Animation {
        #if os(macOS)
        return .easeOut(duration: 0.15)
        #else
        return .spring(response: 0.3, dampingFraction: 0.8)
        #endif
    }

    /// One-shot polished motion (onboarding, lock screen reveal).
    /// Same on both platforms — bouncy springs read fine when they fire once.
    static var havenSpring: Animation {
        .spring(response: 0.4, dampingFraction: 0.8)
    }
}
