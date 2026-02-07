import Carbon
import Foundation

@MainActor
protocol HotKeyDelegate: AnyObject {
    func hotKeyPressed(kind: HotKeyKind)
    func hotKeyReleased(kind: HotKeyKind)
}

final class HotKeyManager {
    private weak var delegate: HotKeyDelegate?
    private var handlerRef: EventHandlerRef?
    private var hotKeyRefs: [HotKeyKind: EventHotKeyRef] = [:]
    private var currentHotKeys: [HotKeyKind: HotKey] = [:]

    init(delegate: HotKeyDelegate?) {
        self.delegate = delegate
    }

    func register(hotKeys: [HotKeyKind: HotKey]) {
        currentHotKeys = hotKeys
        unregister()
        installHandlerIfNeeded()

        var seen: Set<String> = []
        for kind in HotKeyKind.allCases {
            guard let hotKey = hotKeys[kind] else { continue }
            let signature = "\(hotKey.keyCode):\(hotKey.modifiers)"
            if seen.contains(signature) {
                Log.shared.write("HotKeyManager: duplicate hotkey for \(kind); skipping registration")
                continue
            }
            seen.insert(signature)
            registerHotKey(kind: kind, hotKey: hotKey)
        }
    }

    func updateHotKey(kind: HotKeyKind, hotKey: HotKey) {
        currentHotKeys[kind] = hotKey
        register(hotKeys: currentHotKeys)
    }

    func unregister() {
        for (_, ref) in hotKeyRefs {
            UnregisterEventHotKey(ref)
        }
        hotKeyRefs.removeAll()
        if let handlerRef = handlerRef {
            RemoveEventHandler(handlerRef)
            self.handlerRef = nil
        }
    }

    private func installHandlerIfNeeded() {
        guard handlerRef == nil else { return }
        var eventTypes = [
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed)),
            EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyReleased))
        ]

        let handler: EventHandlerUPP = { _, event, userData in
            guard let event = event, let userData = userData else { return noErr }
            var hotKeyID = EventHotKeyID()
            let status = GetEventParameter(
                event,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID
            )
            guard status == noErr, let kind = HotKeyKind(rawValue: hotKeyID.id) else { return noErr }
            let data = UInt(bitPattern: userData)
            let eventKind = GetEventKind(event)
            if eventKind == kEventHotKeyPressed {
                DispatchQueue.main.async {
                    guard let pointer = UnsafeMutableRawPointer(bitPattern: data) else { return }
                    let manager = Unmanaged<HotKeyManager>.fromOpaque(pointer).takeUnretainedValue()
                    manager.delegate?.hotKeyPressed(kind: kind)
                }
            } else if eventKind == kEventHotKeyReleased {
                DispatchQueue.main.async {
                    guard let pointer = UnsafeMutableRawPointer(bitPattern: data) else { return }
                    let manager = Unmanaged<HotKeyManager>.fromOpaque(pointer).takeUnretainedValue()
                    manager.delegate?.hotKeyReleased(kind: kind)
                }
            }
            return noErr
        }

        InstallEventHandler(
            GetApplicationEventTarget(),
            handler,
            2,
            &eventTypes,
            UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            &handlerRef
        )
    }

    private func registerHotKey(kind: HotKeyKind, hotKey: HotKey) {
        let hotKeyID = EventHotKeyID(signature: OSType(0x4C574156), id: kind.rawValue) // "LWAV"
        var ref: EventHotKeyRef?
        RegisterEventHotKey(
            hotKey.keyCode,
            hotKey.modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &ref
        )
        if let ref = ref {
            hotKeyRefs[kind] = ref
        }
    }
}
