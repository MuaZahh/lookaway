import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    let settingsStore = SettingsStore()
    let stateStore = AppStateStore()

    private lazy var coordinator = AppCoordinator(
        settingsStore: settingsStore,
        stateStore: stateStore
    )

    func applicationDidFinishLaunching(_ notification: Notification) {
        ProcessInfo.processInfo.disableAutomaticTermination("LookAway monitors active screen use from the menu bar.")
        NSApp.setActivationPolicy(.accessory)
        stateStore.launchAtLoginMessage = LaunchAtLoginManager.ensureEnabled()
        coordinator.start()
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
}
