#if os(macOS)
import Carbon
import AppKit

final class GlobalHotkeyManager {
    static let shared = GlobalHotkeyManager()
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private var onTrigger: (() -> Void)?

    private init() {
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { _ in
            GlobalHotkeyManager.shared.unregister()
        }
    }

    func register(keyCode: UInt32 = UInt32(kVK_ANSI_N),
                  modifiers: UInt32 = UInt32(cmdKey | shiftKey),
                  handler: @escaping () -> Void) {
        unregister()
        onTrigger = handler
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(0x48564E51) // "HVNQ"
        hotKeyID.id = 1
        var eventType = EventTypeSpec()
        eventType.eventClass = OSType(kEventClassKeyboard)
        eventType.eventKind = UInt32(kEventHotKeyPressed)
        InstallEventHandler(GetApplicationEventTarget(), { _, _, _ -> OSStatus in
            GlobalHotkeyManager.shared.onTrigger?()
            return noErr
        }, 1, &eventType, nil, &eventHandlerRef)
        RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
    }

    func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
        if let handlerRef = eventHandlerRef {
            RemoveEventHandler(handlerRef)
            eventHandlerRef = nil
        }
        onTrigger = nil
    }
}
#endif
