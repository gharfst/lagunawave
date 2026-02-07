import Carbon
import Foundation

enum HotKeyKind: UInt32, CaseIterable {
    case pushToTalk = 1
    case toggle = 2
}

struct HotKey: Equatable, Codable {
    var keyCode: UInt32
    var modifiers: UInt32

    static let defaultPush = HotKey(keyCode: UInt32(kVK_Space), modifiers: UInt32(controlKey | optionKey))
    static let defaultToggle = HotKey(keyCode: UInt32(kVK_Space), modifiers: UInt32(controlKey | optionKey | shiftKey))
    static let `default` = defaultPush

    var displayString: String {
        var parts: [String] = []
        if (modifiers & UInt32(controlKey)) != 0 { parts.append("⌃") }
        if (modifiers & UInt32(optionKey)) != 0 { parts.append("⌥") }
        if (modifiers & UInt32(shiftKey)) != 0 { parts.append("⇧") }
        if (modifiers & UInt32(cmdKey)) != 0 { parts.append("⌘") }
        parts.append(keyCodeToString(keyCode))
        return parts.joined()
    }

    private func keyCodeToString(_ code: UInt32) -> String {
        switch code {
        case UInt32(kVK_Space): return "Space"
        case UInt32(kVK_Return): return "Return"
        case UInt32(kVK_Tab): return "Tab"
        case UInt32(kVK_Escape): return "Esc"
        case UInt32(kVK_Delete): return "Delete"
        case UInt32(kVK_ForwardDelete): return "FwdDelete"
        case UInt32(kVK_LeftArrow): return "←"
        case UInt32(kVK_RightArrow): return "→"
        case UInt32(kVK_UpArrow): return "↑"
        case UInt32(kVK_DownArrow): return "↓"
        default:
            if let key = keyCodeToCharacter(code) {
                return key.uppercased()
            }
            return String(format: "KeyCode(%d)", code)
        }
    }

    private func keyCodeToCharacter(_ keyCode: UInt32) -> String? {
        guard let source = TISCopyCurrentKeyboardLayoutInputSource()?.takeRetainedValue() else { return nil }
        guard let data = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData) else { return nil }
        let layoutData = unsafeBitCast(data, to: CFData.self)
        guard let ptr = CFDataGetBytePtr(layoutData) else { return nil }

        var deadKeyState: UInt32 = 0
        let maxStringLength = 4
        var chars = [UniChar](repeating: 0, count: maxStringLength)
        var actualLength: Int = 0

        let result = ptr.withMemoryRebound(to: UCKeyboardLayout.self, capacity: 1) { layoutPtr in
            UCKeyTranslate(
                layoutPtr,
                UInt16(keyCode),
                UInt16(kUCKeyActionDisplay),
                0,
                UInt32(LMGetKbdType()),
                UInt32(kUCKeyTranslateNoDeadKeysBit),
                &deadKeyState,
                maxStringLength,
                &actualLength,
                &chars
            )
        }

        if result == noErr, actualLength > 0 {
            return String(utf16CodeUnits: chars, count: actualLength)
        }
        return nil
    }
}
