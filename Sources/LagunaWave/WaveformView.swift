import AppKit

@MainActor
final class WaveformView: NSView {
    private var level: CGFloat = 0
    private var phase: CGFloat = 0
    private var timer: Timer?
    private let barCount = 8
    var barColor: NSColor = .systemGreen

    override var intrinsicContentSize: NSSize {
        NSSize(width: 80, height: 22)
    }

    func start() {
        if timer != nil { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.phase += 0.35
                if self.phase > .pi * 2 { self.phase = 0 }
                self.needsDisplay = true
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        level = 0
        needsDisplay = true
    }

    func updateLevel(_ newValue: CGFloat) {
        let clamped = min(1, max(0, newValue))
        level = level * 0.75 + clamped * 0.25
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let context = NSGraphicsContext.current?.cgContext
        context?.clear(bounds)

        let barWidth: CGFloat = 3
        let spacing: CGFloat = 4
        let totalWidth = CGFloat(barCount) * barWidth + CGFloat(barCount - 1) * spacing
        let originX = (bounds.width - totalWidth) / 2
        let midY = bounds.midY
        let maxHeight = bounds.height * 0.9

        let base = max(0.08, level)
        for i in 0..<barCount {
            let wave = abs(sin(phase + CGFloat(i) * 0.6))
            let height = max(2, maxHeight * base * (0.35 + 0.65 * wave))
            let x = originX + CGFloat(i) * (barWidth + spacing)
            let rect = CGRect(x: x, y: midY - height / 2, width: barWidth, height: height)
            let path = CGPath(roundedRect: rect, cornerWidth: 1.5, cornerHeight: 1.5, transform: nil)
            context?.setFillColor(barColor.withAlphaComponent(0.9).cgColor)
            context?.addPath(path)
            context?.fillPath()
        }
    }
}
