import Foundation
import LookAwayCore

final class SettingsStore: ObservableObject {
    var onChange: (() -> Void)?

    @Published var isEnabled: Bool {
        didSet { persistAndNotify() }
    }

    @Published var workIntervalMinutes: Double {
        didSet { persistAndNotify() }
    }

    @Published var breakDurationSeconds: Double {
        didSet { persistAndNotify() }
    }

    @Published var idleResetMinutes: Double {
        didSet { persistAndNotify() }
    }

    @Published var activeInputWindowSeconds: Double {
        didSet { persistAndNotify() }
    }

    @Published var emergencyHoldSeconds: Double {
        didSet { persistAndNotify() }
    }

    @Published var mode: BreakMode {
        didSet { persistAndNotify() }
    }

    @Published var snoozeDurationMinutes: Double {
        didSet { persistAndNotify() }
    }

    @Published var playBreakSound: Bool {
        didSet { persistAndNotify() }
    }

    @Published var showCountdown: Bool {
        didSet { persistAndNotify() }
    }

    @Published var allowSnooze: Bool {
        didSet { persistAndNotify() }
    }

    @Published var breakTitle: String {
        didSet { persistAndNotify() }
    }

    @Published var breakSubtitle: String {
        didSet { persistAndNotify() }
    }

    @Published var launchAtLogin: Bool {
        didSet { persistAndNotify() }
    }

    @Published var preBreakNotificationEnabled: Bool {
        didSet { persistAndNotify() }
    }

    @Published var notificationLeadMinutes: Double {
        didSet { persistAndNotify() }
    }

    @Published var extensionShortcutEnabled: Bool {
        didSet { persistAndNotify() }
    }

    @Published var extensionShortcutKeyCode: Int {
        didSet { persistAndNotify() }
    }

    @Published var extensionShortcutModifiers: Int {
        didSet { persistAndNotify() }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let preferences = LookAwayPreferences.load(from: defaults)
        // Pause is deliberately session-only. A relaunch or Mac restart always resumes protection.
        self.isEnabled = true
        self.workIntervalMinutes = preferences.workIntervalMinutes
        self.breakDurationSeconds = preferences.breakDurationSeconds
        self.idleResetMinutes = preferences.idleResetMinutes
        self.activeInputWindowSeconds = preferences.activeInputWindowSeconds
        self.emergencyHoldSeconds = preferences.emergencyHoldSeconds
        self.snoozeDurationMinutes = preferences.snoozeDurationMinutes
        self.playBreakSound = preferences.playBreakSound
        self.showCountdown = preferences.showCountdown
        self.allowSnooze = preferences.allowSnooze
        self.breakTitle = preferences.breakTitle
        self.breakSubtitle = preferences.breakSubtitle
        self.launchAtLogin = preferences.launchAtLogin
        self.preBreakNotificationEnabled = preferences.preBreakNotificationEnabled
        self.notificationLeadMinutes = preferences.notificationLeadMinutes
        self.extensionShortcutEnabled = preferences.extensionShortcutEnabled
        self.extensionShortcutKeyCode = preferences.extensionShortcutKeyCode
        self.extensionShortcutModifiers = preferences.extensionShortcutModifiers
        self.mode = preferences.mode
    }

    var breakSettings: BreakSettings {
        BreakSettings(
            workInterval: workIntervalMinutes * 60,
            breakDuration: breakDurationSeconds,
            idleResetThreshold: idleResetMinutes * 60,
            activeInputWindow: activeInputWindowSeconds,
            emergencyHoldDuration: emergencyHoldSeconds,
            mode: mode
        )
    }

    func resetDefaults() {
        let fallback = BreakSettings()
        let preferences = LookAwayPreferences()

        isEnabled = true
        workIntervalMinutes = fallback.workInterval / 60
        breakDurationSeconds = fallback.breakDuration
        idleResetMinutes = fallback.idleResetThreshold / 60
        activeInputWindowSeconds = fallback.activeInputWindow
        emergencyHoldSeconds = fallback.emergencyHoldDuration
        mode = fallback.mode
        snoozeDurationMinutes = preferences.snoozeDurationMinutes
        playBreakSound = preferences.playBreakSound
        showCountdown = preferences.showCountdown
        allowSnooze = preferences.allowSnooze
        breakTitle = preferences.breakTitle
        breakSubtitle = preferences.breakSubtitle
        launchAtLogin = preferences.launchAtLogin
        preBreakNotificationEnabled = preferences.preBreakNotificationEnabled
        notificationLeadMinutes = preferences.notificationLeadMinutes
        extensionShortcutEnabled = preferences.extensionShortcutEnabled
        extensionShortcutKeyCode = preferences.extensionShortcutKeyCode
        extensionShortcutModifiers = preferences.extensionShortcutModifiers
    }

    private func persistAndNotify() {
        LookAwayPreferences(
            workIntervalMinutes: workIntervalMinutes,
            breakDurationSeconds: breakDurationSeconds,
            idleResetMinutes: idleResetMinutes,
            activeInputWindowSeconds: activeInputWindowSeconds,
            emergencyHoldSeconds: emergencyHoldSeconds,
            mode: mode,
            snoozeDurationMinutes: snoozeDurationMinutes,
            playBreakSound: playBreakSound,
            showCountdown: showCountdown,
            allowSnooze: allowSnooze,
            breakTitle: breakTitle,
            breakSubtitle: breakSubtitle,
            launchAtLogin: launchAtLogin,
            preBreakNotificationEnabled: preBreakNotificationEnabled,
            notificationLeadMinutes: notificationLeadMinutes,
            extensionShortcutEnabled: extensionShortcutEnabled,
            extensionShortcutKeyCode: extensionShortcutKeyCode,
            extensionShortcutModifiers: extensionShortcutModifiers
        ).save(to: defaults)
        onChange?()
    }
}
