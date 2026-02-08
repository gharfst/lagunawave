import AppKit

@MainActor
final class SettingsWindowController: NSWindowController {
    private let viewController = SettingsViewController()

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 400),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "LagunaWave Settings"
        window.isReleasedWhenClosed = false
        window.toolbarStyle = .preference
        window.contentViewController = viewController
        window.center()
        super.init(window: window)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
