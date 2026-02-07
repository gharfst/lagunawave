import AppKit

@MainActor
final class SettingsWindowController: NSWindowController {
    private let viewController = SettingsViewController()

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 320),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "LagunaWave Settings"
        window.isReleasedWhenClosed = false
        window.contentViewController = viewController
        viewController.loadViewIfNeeded()
        let size = viewController.view.fittingSize
        window.setContentSize(NSSize(width: max(400, size.width), height: size.height))
        window.center()
        super.init(window: window)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
