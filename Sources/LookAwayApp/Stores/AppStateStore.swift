import Foundation
import LookAwayCore

final class AppStateStore: ObservableObject {
    @Published var snapshot = BreakScheduler().snapshot
    @Published var statusText = "Starting"
    @Published var lastEventMessage = ""
    @Published var launchAtLoginMessage = "Checking start at login…"
    @Published var notificationStatus = "Checking notification permission…"
    @Published var shortcutStatus = "Setting up extension shortcut…"
    @Published var isEnabled = true
    @Published var mode: BreakMode = .strict
    @Published var idleSeconds: TimeInterval = 0
    @Published var completedBreaks = 0
    @Published var skippedBreaks = 0
    @Published var naturalBreaks = 0
}
