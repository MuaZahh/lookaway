import AppKit
import SwiftUI

@main
struct LookAwayApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            SettingsView(
                settings: appDelegate.settingsStore,
                state: appDelegate.stateStore,
                onTakeBreakNow: {
                    appDelegate.takeBreakNow()
                },
                onTestNotification: {
                    appDelegate.sendTestNotification()
                }
            )
        }
    }
}
