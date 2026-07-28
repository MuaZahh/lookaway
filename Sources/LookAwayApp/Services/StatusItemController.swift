import AppKit

final class StatusItemController: NSObject {
    var onToggleEnabled: (() -> Void)?
    var onTakeBreakNow: (() -> Void)?
    var onOpenSettings: (() -> Void)?
    var onQuit: (() -> Void)?

    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let menu = NSMenu()
    private let statusMenuItem = NSMenuItem(title: "Starting", action: nil, keyEquivalent: "")
    private let enabledItem = NSMenuItem(title: "Pause", action: #selector(toggleEnabled), keyEquivalent: "")
    private let breakItem = NSMenuItem(title: "Take Break Now", action: #selector(takeBreakNow), keyEquivalent: "")
    private let settingsItem = NSMenuItem(title: "Settings", action: #selector(openSettings), keyEquivalent: ",")
    private let quitItem = NSMenuItem(title: "Quit LookAway...", action: #selector(quit), keyEquivalent: "")

    override init() {
        super.init()
        configureMenu()
        updateButton(isEnabled: true, isBreakActive: false, statusText: "Starting")
    }

    func update(settings: SettingsStore, state: AppStateStore) {
        updateButton(
            isEnabled: settings.isEnabled,
            isBreakActive: state.snapshot.isBreakActive,
            statusText: state.statusText
        )
        updateMenu(settings: settings, state: state)
    }

    private func updateButton(isEnabled: Bool, isBreakActive: Bool, statusText: String) {
        guard let button = statusItem.button else { return }

        let symbolName: String
        if isBreakActive {
            symbolName = "eye.trianglebadge.exclamationmark"
        } else if isEnabled {
            symbolName = "eye"
        } else {
            symbolName = "eye.slash"
        }

        if let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "LookAway") {
            image.isTemplate = true
            button.image = image
            button.title = ""
        } else {
            button.image = nil
            button.title = "LookAway"
        }

        button.toolTip = "LookAway: \(statusText)"
    }

    private func configureMenu() {
        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)
        menu.addItem(.separator())

        enabledItem.target = self
        menu.addItem(enabledItem)

        breakItem.target = self
        menu.addItem(breakItem)

        menu.addItem(.separator())

        settingsItem.target = self
        menu.addItem(settingsItem)

        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    private func updateMenu(settings: SettingsStore, state: AppStateStore) {
        statusMenuItem.title = state.statusText
        enabledItem.title = settings.isEnabled ? "Pause" : "Resume"
        breakItem.isEnabled = settings.isEnabled && !state.snapshot.isBreakActive
        settingsItem.isEnabled = !state.snapshot.isBreakActive
        quitItem.isEnabled = !state.snapshot.isBreakActive
    }

    @objc private func toggleEnabled() {
        onToggleEnabled?()
    }

    @objc private func takeBreakNow() {
        onTakeBreakNow?()
    }

    @objc private func openSettings() {
        onOpenSettings?()
    }

    @objc private func quit() {
        NSApp.activate(ignoringOtherApps: true)

        let alert = NSAlert()
        alert.messageText = "Quit LookAway?"
        alert.informativeText = "Break monitoring will stop until you launch it again."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Cancel")
        alert.addButton(withTitle: "Quit")

        if alert.runModal() == .alertSecondButtonReturn {
            onQuit?()
        }
    }
}
