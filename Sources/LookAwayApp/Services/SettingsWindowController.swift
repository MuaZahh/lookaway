import AppKit
import SwiftUI

final class SettingsWindowController: NSWindowController {
    init(
        settings: SettingsStore,
        state: AppStateStore,
        onTakeBreakNow: @escaping () -> Void,
        onTestNotification: @escaping () -> Void
    ) {
        let rootView = SettingsView(
            settings: settings,
            state: state,
            onTakeBreakNow: onTakeBreakNow,
            onTestNotification: onTestNotification
        )
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 620, height: 680),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.title = "LookAway Settings"
        window.contentView = NSHostingView(rootView: rootView)
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 560, height: 560)
        window.center()

        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        NSApp.activate(ignoringOtherApps: true)
        window?.center()
        window?.makeKeyAndOrderFront(sender)
    }
}
