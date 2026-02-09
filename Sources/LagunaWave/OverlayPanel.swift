import AppKit
import QuartzCore

private class NonActivatingPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

private class BorderView: NSView {
    override func viewDidChangeEffectiveAppearance() {
        super.viewDidChangeEffectiveAppearance()
        layer?.borderColor = NSColor.separatorColor.withAlphaComponent(0.35).cgColor
    }
}

@MainActor
final class OverlayPanel {
    private let panel: NSPanel
    private let container: NSView
    private let visualEffect: NSVisualEffectView
    private let titleLabel: NSTextField
    private let textField: NSTextField
    private let hintLabel: NSTextField
    private let waveformView: WaveformView
    private let stateDot: NSView
    private let spinner: NSProgressIndicator
    private var hideWorkItem: DispatchWorkItem?
    private var isShowing = false

    init() {
        // Title row: "LagunaWave"
        titleLabel = NSTextField(labelWithString: "LagunaWave")
        titleLabel.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        titleLabel.textColor = .tertiaryLabelColor
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        // Status text
        textField = NSTextField(labelWithString: "")
        textField.font = NSFont.systemFont(ofSize: 18, weight: .medium)
        textField.textColor = .labelColor
        textField.alignment = .left
        textField.maximumNumberOfLines = 2
        textField.lineBreakMode = .byWordWrapping
        textField.translatesAutoresizingMaskIntoConstraints = false

        // Hint row
        hintLabel = NSTextField(labelWithString: "")
        hintLabel.font = NSFont.systemFont(ofSize: 11, weight: .regular)
        hintLabel.textColor = .secondaryLabelColor
        hintLabel.translatesAutoresizingMaskIntoConstraints = false
        hintLabel.isHidden = true

        waveformView = WaveformView()
        waveformView.translatesAutoresizingMaskIntoConstraints = false

        stateDot = NSView()
        stateDot.wantsLayer = true
        stateDot.layer?.cornerRadius = 6
        stateDot.translatesAutoresizingMaskIntoConstraints = false
        stateDot.isHidden = true

        spinner = NSProgressIndicator()
        spinner.style = .spinning
        spinner.controlSize = .small
        spinner.isDisplayedWhenStopped = false
        spinner.translatesAutoresizingMaskIntoConstraints = false

        // Middle row: dot + waveform + text + spinner
        let statusRow = NSStackView(views: [stateDot, waveformView, textField, spinner])
        statusRow.orientation = .horizontal
        statusRow.alignment = .centerY
        statusRow.spacing = 10
        statusRow.translatesAutoresizingMaskIntoConstraints = false

        // Vertical stack: title, status row, hint
        let mainStack = NSStackView(views: [titleLabel, statusRow, hintLabel])
        mainStack.orientation = .vertical
        mainStack.alignment = .leading
        mainStack.spacing = 4
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        visualEffect = NSVisualEffectView()
        visualEffect.material = .sidebar
        visualEffect.state = .active
        visualEffect.blendingMode = .withinWindow
        visualEffect.translatesAutoresizingMaskIntoConstraints = false
        visualEffect.addSubview(mainStack)

        NSLayoutConstraint.activate([
            stateDot.widthAnchor.constraint(equalToConstant: 12),
            stateDot.heightAnchor.constraint(equalToConstant: 12),
            waveformView.widthAnchor.constraint(equalToConstant: 100),
            waveformView.heightAnchor.constraint(equalToConstant: 28),

            mainStack.leadingAnchor.constraint(equalTo: visualEffect.leadingAnchor, constant: 20),
            mainStack.trailingAnchor.constraint(equalTo: visualEffect.trailingAnchor, constant: -20),
            mainStack.topAnchor.constraint(equalTo: visualEffect.topAnchor, constant: 14),
            mainStack.bottomAnchor.constraint(equalTo: visualEffect.bottomAnchor, constant: -14)
        ])

        container = BorderView()
        container.wantsLayer = true
        container.layer?.cornerRadius = 16
        container.layer?.masksToBounds = true
        container.layer?.borderWidth = 0.5
        container.layer?.borderColor = NSColor.separatorColor.withAlphaComponent(0.35).cgColor
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(visualEffect)

        NSLayoutConstraint.activate([
            visualEffect.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            visualEffect.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            visualEffect.topAnchor.constraint(equalTo: container.topAnchor),
            visualEffect.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        panel = NonActivatingPanel(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 80),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovable = false
        panel.hasShadow = true
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.ignoresMouseEvents = true
        panel.contentView = container
    }

    func showListening(hint: String? = nil) {
        updateUI(text: "", waveform: true, spinner: false, dotColor: .systemGreen, hint: hint)
    }

    func showTranscribing(loading: Bool) {
        let text = loading ? "Loading model…" : "Transcribing…"
        updateUI(text: text, waveform: false, spinner: true, dotColor: .systemOrange)
    }

    func showCleaningUp(loading: Bool) {
        let text = loading ? "Loading cleanup model\u{2026}" : "Cleaning up text\u{2026}"
        updateUI(text: text, waveform: false, spinner: true, dotColor: .systemPurple)
    }

    func showTyping() {
        updateUI(text: "Typing…", waveform: false, spinner: false, dotColor: .systemBlue)
    }

    func showProgress(_ text: String) {
        updateUI(text: text, waveform: false, spinner: true)
    }

    func showMessage(_ text: String) {
        updateUI(text: text, waveform: false, spinner: false)
    }

    func updateLevel(_ level: Float) {
        waveformView.updateLevel(CGFloat(level))
    }

    private func updateUI(text: String, waveform: Bool, spinner: Bool, dotColor: NSColor? = nil, hint: String? = nil) {
        hideWorkItem?.cancel()
        textField.stringValue = text
        textField.isHidden = text.isEmpty
        if let color = dotColor {
            stateDot.layer?.backgroundColor = color.cgColor
            stateDot.isHidden = false
        } else {
            stateDot.isHidden = true
        }
        if let hint = hint, !hint.isEmpty {
            hintLabel.stringValue = hint
            hintLabel.isHidden = false
        } else {
            hintLabel.isHidden = true
        }
        setWaveformVisible(waveform)
        setSpinnerVisible(spinner)
        layoutAndPosition()
        present()
    }

    func hide(after delay: TimeInterval? = nil) {
        hideWorkItem?.cancel()
        if let delay = delay {
            let workItem = DispatchWorkItem { [weak self] in
                self?.dismiss()
            }
            hideWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem)
        } else {
            dismiss()
        }
        setWaveformVisible(false)
    }

    private func present() {
        if isShowing {
            panel.orderFrontRegardless()
            return
        }
        isShowing = true
        panel.alphaValue = 0
        panel.orderFrontRegardless()
        animateIn()
    }

    private func dismiss() {
        guard isShowing else { return }
        isShowing = false
        animateOut()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
            self?.panel.orderOut(nil)
            self?.panel.alphaValue = 1
        }
    }

    private func layoutAndPosition() {
        guard let contentView = panel.contentView else { return }
        contentView.layoutSubtreeIfNeeded()
        let size = contentView.fittingSize
        panel.setContentSize(size)

        let screen = screenForFrontmostWindow() ?? NSScreen.main ?? NSScreen.screens.first
        let screenFrame = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        let x = screenFrame.midX - size.width / 2
        let y = screenFrame.maxY - size.height - 60
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }

    /// Returns the screen containing the frontmost application's focused window.
    private func screenForFrontmostWindow() -> NSScreen? {
        guard let app = NSWorkspace.shared.frontmostApplication else { return nil }
        let axApp = AXUIElementCreateApplication(app.processIdentifier)

        var focusedWindow: CFTypeRef?
        guard AXUIElementCopyAttributeValue(axApp, kAXFocusedWindowAttribute as CFString, &focusedWindow) == .success,
              let window = focusedWindow else { return nil }

        var positionValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(window as! AXUIElement, kAXPositionAttribute as CFString, &positionValue) == .success,
              let pv = positionValue else { return nil }

        var point = CGPoint.zero
        AXValueGetValue(pv as! AXValue, .cgPoint, &point)

        return NSScreen.screens.first { $0.frame.contains(point) }
    }

    private func setWaveformVisible(_ visible: Bool) {
        waveformView.isHidden = !visible
        if visible {
            waveformView.start()
        } else {
            waveformView.stop()
        }
    }

    private func setSpinnerVisible(_ visible: Bool) {
        spinner.isHidden = !visible
        if visible {
            spinner.startAnimation(nil)
        } else {
            spinner.stopAnimation(nil)
        }
    }

    private func animateIn() {
        if let layer = container.layer {
            layer.removeAllAnimations()
            let scale = CABasicAnimation(keyPath: "transform.scale")
            scale.fromValue = 0.98
            scale.toValue = 1.0
            scale.duration = 0.12
            scale.timingFunction = CAMediaTimingFunction(name: .easeOut)
            layer.add(scale, forKey: "scaleIn")
        }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.12
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 1
        }
    }

    private func animateOut() {
        if let layer = container.layer {
            layer.removeAllAnimations()
            let scale = CABasicAnimation(keyPath: "transform.scale")
            scale.fromValue = 1.0
            scale.toValue = 0.98
            scale.duration = 0.12
            scale.timingFunction = CAMediaTimingFunction(name: .easeIn)
            layer.add(scale, forKey: "scaleOut")
        }

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.12
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().alphaValue = 0
        })
    }
}
