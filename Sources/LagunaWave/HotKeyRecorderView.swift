import AppKit
import Carbon

@MainActor
final class HotKeyRecorderView: NSView {
    var onHotKeyChange: ((HotKey) -> Void)?

    private let button = NSButton(title: "Record Hotkey", target: nil, action: nil)
    private let label = NSTextField(labelWithString: "")
    private var isRecording = false

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        layer?.cornerRadius = 8

        button.bezelStyle = .rounded
        button.target = self
        button.action = #selector(toggleRecording)

        label.font = NSFont.systemFont(ofSize: 13)
        label.textColor = .secondaryLabelColor

        let stack = NSStackView(views: [button, label])
        stack.orientation = .horizontal
        stack.alignment = .centerY
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -12),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10)
        ])

        updateUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setHotKey(_ hotKey: HotKey) {
        label.stringValue = hotKey.displayString
    }

    @objc private func toggleRecording() {
        isRecording.toggle()
        updateUI()
        if isRecording {
            window?.makeFirstResponder(self)
        }
    }

    private func updateUI() {
        if isRecording {
            button.title = "Press Keys…"
            label.stringValue = ""
        } else {
            button.title = "Record Hotkey"
        }
    }

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        guard isRecording else { return }
        let keyCode = UInt32(event.keyCode)
        let modifiers = event.carbonModifiers
        if isModifierKeyCode(keyCode) {
            return
        }
        if modifiers == 0 {
            NSSound.beep()
            label.stringValue = "Use at least one modifier (⌘⌥⌃⇧)"
            return
        }
        let hotKey = HotKey(keyCode: keyCode, modifiers: modifiers)
        isRecording = false
        setHotKey(hotKey)
        updateUI()
        onHotKeyChange?(hotKey)
    }
}

private extension NSEvent {
    var carbonModifiers: UInt32 {
        var mods: UInt32 = 0
        if modifierFlags.contains(.command) { mods |= UInt32(cmdKey) }
        if modifierFlags.contains(.control) { mods |= UInt32(controlKey) }
        if modifierFlags.contains(.option) { mods |= UInt32(optionKey) }
        if modifierFlags.contains(.shift) { mods |= UInt32(shiftKey) }
        return mods
    }
}

private func isModifierKeyCode(_ keyCode: UInt32) -> Bool {
    switch keyCode {
    case UInt32(kVK_Command), UInt32(kVK_Shift), UInt32(kVK_Option), UInt32(kVK_Control),
         UInt32(kVK_RightCommand), UInt32(kVK_RightShift), UInt32(kVK_RightOption), UInt32(kVK_RightControl):
        return true
    default:
        return false
    }
}
