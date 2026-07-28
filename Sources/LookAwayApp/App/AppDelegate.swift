import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    let settingsStore = SettingsStore()
    let stateStore = AppStateStore()

    private lazy var coordinator = AppCoordinator(
        settingsStore: settingsStore,
        stateStore: stateStore
    )
    private lazy var settingsWindowController = SettingsWindowController(
        settings: settingsStore,
        state: stateStore,
        onTakeBreakNow: { [weak self] in
            self?.coordinator.takeBreakNow()
        },
        onTestNotification: { [weak self] in
            self?.coordinator.sendTestNotification()
        }
    )

    func applicationDidFinishLaunching(_ notification: Notification) {
        ProcessInfo.processInfo.disableAutomaticTermination("LookAway monitors active screen use from the menu bar.")
        NSApp.setActivationPolicy(.accessory)
        stateStore.launchAtLoginMessage = LaunchAtLoginManager.apply(
            enabled: settingsStore.launchAtLogin
        )
        coordinator.onOpenSettings = { [weak self] in
            self?.settingsWindowController.showWindow(nil)
        }
        coordinator.start()

        if CommandLine.arguments.contains("--show-settings") {
            settingsWindowController.showWindow(nil)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        coordinator.stop()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func takeBreakNow() {
        coordinator.takeBreakNow()
    }

    func sendTestNotification() {
        coordinator.sendTestNotification()
    }
}
