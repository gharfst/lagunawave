import AppKit

@MainActor
final class HistoryWindowController: NSWindowController {
    private let viewController = HistoryViewController()

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 700, height: 500),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Transcription History"
        window.isReleasedWhenClosed = false
        window.contentMinSize = NSSize(width: 500, height: 400)
        window.contentViewController = viewController
        window.setContentSize(NSSize(width: 700, height: 500))
        window.center()
        super.init(window: window)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
