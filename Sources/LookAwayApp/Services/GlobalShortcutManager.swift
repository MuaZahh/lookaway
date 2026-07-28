import AppKit
import Carbon
import Foundation

final class GlobalShortcutManager {
    var onTrigger: (() -> Void)?

    private var eventHandlerRef: EventHandlerRef?
    private var hotKeyRef: EventHotKeyRef?

    init() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let context = Unmanaged.passUnretained(self).toOpaque()

        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, _, context in
                guard let context else { return noErr }
                let manager = Unmanaged<GlobalShortcutManager>
                    .fromOpaque(context)
                    .takeUnretainedValue()
                manager.onTrigger?()
                return noErr
            },
            1,
            &eventType,
            context,
            &eventHandlerRef
        )
    }

    deinit {
        unregister()
        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
        }
    }

    func configure(enabled: Bool, keyCode: Int, modifiers: Int) -> String {
        unregister()

        guard enabled else {
            return "Extension shortcut is off"
        }

        let hotKeyID = EventHotKeyID(signature: 0x4C_41_57_59, id: 1)
        let status = RegisterEventHotKey(
            UInt32(keyCode),
            UInt32(modifiers),
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        guard status == noErr else {
            hotKeyRef = nil
            return "That shortcut is already used by macOS or another app"
        }

        return "\(ShortcutFormatter.display(keyCode: keyCode, modifiers: modifiers)) adds more time"
    }

    private func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
    }
}

enum ShortcutFormatter {
    static func display(keyCode: Int, modifiers: Int) -> String {
        var result = ""
        if modifiers & Int(controlKey) != 0 { result += "⌃" }
        if modifiers & Int(optionKey) != 0 { result += "⌥" }
        if modifiers & Int(shiftKey) != 0 { result += "⇧" }
        if modifiers & Int(cmdKey) != 0 { result += "⌘" }
        result += keyName(keyCode)
        return result
    }

    static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> Int {
        var result = 0
        if flags.contains(.control) { result |= Int(controlKey) }
        if flags.contains(.option) { result |= Int(optionKey) }
        if flags.contains(.shift) { result |= Int(shiftKey) }
        if flags.contains(.command) { result |= Int(cmdKey) }
        return result
    }

    static func hasSafeModifier(_ modifiers: Int) -> Bool {
        modifiers & (Int(controlKey) | Int(optionKey) | Int(cmdKey)) != 0
    }

    private static func keyName(_ keyCode: Int) -> String {
        let names: [Int: String] = [
            Int(kVK_ANSI_A): "A", Int(kVK_ANSI_B): "B", Int(kVK_ANSI_C): "C",
            Int(kVK_ANSI_D): "D", Int(kVK_ANSI_E): "E", Int(kVK_ANSI_F): "F",
            Int(kVK_ANSI_G): "G", Int(kVK_ANSI_H): "H", Int(kVK_ANSI_I): "I",
            Int(kVK_ANSI_J): "J", Int(kVK_ANSI_K): "K", Int(kVK_ANSI_L): "L",
            Int(kVK_ANSI_M): "M", Int(kVK_ANSI_N): "N", Int(kVK_ANSI_O): "O",
            Int(kVK_ANSI_P): "P", Int(kVK_ANSI_Q): "Q", Int(kVK_ANSI_R): "R",
            Int(kVK_ANSI_S): "S", Int(kVK_ANSI_T): "T", Int(kVK_ANSI_U): "U",
            Int(kVK_ANSI_V): "V", Int(kVK_ANSI_W): "W", Int(kVK_ANSI_X): "X",
            Int(kVK_ANSI_Y): "Y", Int(kVK_ANSI_Z): "Z",
            Int(kVK_ANSI_0): "0", Int(kVK_ANSI_1): "1", Int(kVK_ANSI_2): "2",
            Int(kVK_ANSI_3): "3", Int(kVK_ANSI_4): "4", Int(kVK_ANSI_5): "5",
            Int(kVK_ANSI_6): "6", Int(kVK_ANSI_7): "7", Int(kVK_ANSI_8): "8",
            Int(kVK_ANSI_9): "9", Int(kVK_Space): "Space",
            Int(kVK_Return): "Return", Int(kVK_Tab): "Tab",
            Int(kVK_F1): "F1", Int(kVK_F2): "F2", Int(kVK_F3): "F3",
            Int(kVK_F4): "F4", Int(kVK_F5): "F5", Int(kVK_F6): "F6",
            Int(kVK_F7): "F7", Int(kVK_F8): "F8", Int(kVK_F9): "F9",
            Int(kVK_F10): "F10", Int(kVK_F11): "F11", Int(kVK_F12): "F12"
        ]
        return names[keyCode] ?? "Key \(keyCode)"
    }
}
