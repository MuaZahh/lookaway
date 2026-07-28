import Foundation

public struct LookAwayPreferences: Equatable, Sendable {
    public var workIntervalMinutes: Double
    public var breakDurationSeconds: Double
    public var idleResetMinutes: Double
    public var activeInputWindowSeconds: Double
    public var emergencyHoldSeconds: Double
    public var mode: BreakMode
    public var snoozeDurationMinutes: Double
    public var playBreakSound: Bool
    public var playBreakCompleteSound: Bool
    public var showCountdown: Bool
    public var allowSnooze: Bool
    public var breakTitle: String
    public var breakSubtitle: String
    public var launchAtLogin: Bool
    public var preBreakNotificationEnabled: Bool
    public var notificationLeadMinutes: Double
    public var extensionShortcutEnabled: Bool
    public var extensionShortcutKeyCode: Int
    public var extensionShortcutModifiers: Int

    public init(
        workIntervalMinutes: Double = 25,
        breakDurationSeconds: Double = 60,
        idleResetMinutes: Double = 2,
        activeInputWindowSeconds: Double = 3,
        emergencyHoldSeconds: Double = 5,
        mode: BreakMode = .strict,
        snoozeDurationMinutes: Double = 5,
        playBreakSound: Bool = true,
        playBreakCompleteSound: Bool = true,
        showCountdown: Bool = true,
        allowSnooze: Bool = true,
        breakTitle: String = "Look far away",
        breakSubtitle: String = "Blink slowly",
        launchAtLogin: Bool = true,
        preBreakNotificationEnabled: Bool = true,
        notificationLeadMinutes: Double = 1,
        extensionShortcutEnabled: Bool = true,
        extensionShortcutKeyCode: Int = 1,
        extensionShortcutModifiers: Int = 2_304
    ) {
        self.workIntervalMinutes = workIntervalMinutes
        self.breakDurationSeconds = breakDurationSeconds
        self.idleResetMinutes = idleResetMinutes
        self.activeInputWindowSeconds = activeInputWindowSeconds
        self.emergencyHoldSeconds = emergencyHoldSeconds
        self.mode = mode
        self.snoozeDurationMinutes = snoozeDurationMinutes
        self.playBreakSound = playBreakSound
        self.playBreakCompleteSound = playBreakCompleteSound
        self.showCountdown = showCountdown
        self.allowSnooze = allowSnooze
        self.breakTitle = breakTitle
        self.breakSubtitle = breakSubtitle
        self.launchAtLogin = launchAtLogin
        self.preBreakNotificationEnabled = preBreakNotificationEnabled
        self.notificationLeadMinutes = notificationLeadMinutes
        self.extensionShortcutEnabled = extensionShortcutEnabled
        self.extensionShortcutKeyCode = extensionShortcutKeyCode
        self.extensionShortcutModifiers = extensionShortcutModifiers
    }

    public static func load(from defaults: UserDefaults) -> LookAwayPreferences {
        let fallback = LookAwayPreferences()

        return LookAwayPreferences(
            workIntervalMinutes: double(defaults, key: Keys.workIntervalMinutes, fallback: fallback.workIntervalMinutes),
            breakDurationSeconds: double(defaults, key: Keys.breakDurationSeconds, fallback: fallback.breakDurationSeconds),
            idleResetMinutes: double(defaults, key: Keys.idleResetMinutes, fallback: fallback.idleResetMinutes),
            activeInputWindowSeconds: double(defaults, key: Keys.activeInputWindowSeconds, fallback: fallback.activeInputWindowSeconds),
            emergencyHoldSeconds: double(defaults, key: Keys.emergencyHoldSeconds, fallback: fallback.emergencyHoldSeconds),
            mode: defaults.string(forKey: Keys.mode).flatMap(BreakMode.init(rawValue:)) ?? fallback.mode,
            snoozeDurationMinutes: double(defaults, key: Keys.snoozeDurationMinutes, fallback: fallback.snoozeDurationMinutes),
            playBreakSound: bool(defaults, key: Keys.playBreakSound, fallback: fallback.playBreakSound),
            playBreakCompleteSound: bool(defaults, key: Keys.playBreakCompleteSound, fallback: fallback.playBreakCompleteSound),
            showCountdown: bool(defaults, key: Keys.showCountdown, fallback: fallback.showCountdown),
            allowSnooze: bool(defaults, key: Keys.allowSnooze, fallback: fallback.allowSnooze),
            breakTitle: defaults.string(forKey: Keys.breakTitle) ?? fallback.breakTitle,
            breakSubtitle: defaults.string(forKey: Keys.breakSubtitle) ?? fallback.breakSubtitle,
            launchAtLogin: bool(defaults, key: Keys.launchAtLogin, fallback: fallback.launchAtLogin),
            preBreakNotificationEnabled: bool(defaults, key: Keys.preBreakNotificationEnabled, fallback: fallback.preBreakNotificationEnabled),
            notificationLeadMinutes: double(defaults, key: Keys.notificationLeadMinutes, fallback: fallback.notificationLeadMinutes),
            extensionShortcutEnabled: bool(defaults, key: Keys.extensionShortcutEnabled, fallback: fallback.extensionShortcutEnabled),
            extensionShortcutKeyCode: integer(defaults, key: Keys.extensionShortcutKeyCode, fallback: fallback.extensionShortcutKeyCode),
            extensionShortcutModifiers: integer(defaults, key: Keys.extensionShortcutModifiers, fallback: fallback.extensionShortcutModifiers)
        )
    }

    public func save(to defaults: UserDefaults) {
        defaults.set(workIntervalMinutes, forKey: Keys.workIntervalMinutes)
        defaults.set(breakDurationSeconds, forKey: Keys.breakDurationSeconds)
        defaults.set(idleResetMinutes, forKey: Keys.idleResetMinutes)
        defaults.set(activeInputWindowSeconds, forKey: Keys.activeInputWindowSeconds)
        defaults.set(emergencyHoldSeconds, forKey: Keys.emergencyHoldSeconds)
        defaults.set(mode.rawValue, forKey: Keys.mode)
        defaults.set(snoozeDurationMinutes, forKey: Keys.snoozeDurationMinutes)
        defaults.set(playBreakSound, forKey: Keys.playBreakSound)
        defaults.set(playBreakCompleteSound, forKey: Keys.playBreakCompleteSound)
        defaults.set(showCountdown, forKey: Keys.showCountdown)
        defaults.set(allowSnooze, forKey: Keys.allowSnooze)
        defaults.set(breakTitle, forKey: Keys.breakTitle)
        defaults.set(breakSubtitle, forKey: Keys.breakSubtitle)
        defaults.set(launchAtLogin, forKey: Keys.launchAtLogin)
        defaults.set(preBreakNotificationEnabled, forKey: Keys.preBreakNotificationEnabled)
        defaults.set(notificationLeadMinutes, forKey: Keys.notificationLeadMinutes)
        defaults.set(extensionShortcutEnabled, forKey: Keys.extensionShortcutEnabled)
        defaults.set(extensionShortcutKeyCode, forKey: Keys.extensionShortcutKeyCode)
        defaults.set(extensionShortcutModifiers, forKey: Keys.extensionShortcutModifiers)
    }

    private static func double(
        _ defaults: UserDefaults,
        key: String,
        fallback: Double
    ) -> Double {
        guard defaults.object(forKey: key) != nil else { return fallback }
        return defaults.double(forKey: key)
    }

    private static func bool(
        _ defaults: UserDefaults,
        key: String,
        fallback: Bool
    ) -> Bool {
        guard defaults.object(forKey: key) != nil else { return fallback }
        return defaults.bool(forKey: key)
    }

    private static func integer(
        _ defaults: UserDefaults,
        key: String,
        fallback: Int
    ) -> Int {
        guard defaults.object(forKey: key) != nil else { return fallback }
        return defaults.integer(forKey: key)
    }

    private enum Keys {
        static let workIntervalMinutes = "workIntervalMinutes"
        static let breakDurationSeconds = "breakDurationSeconds"
        static let idleResetMinutes = "idleResetMinutes"
        static let activeInputWindowSeconds = "activeInputWindowSeconds"
        static let emergencyHoldSeconds = "emergencyHoldSeconds"
        static let mode = "mode"
        static let snoozeDurationMinutes = "snoozeDurationMinutes"
        static let playBreakSound = "playBreakSound"
        static let playBreakCompleteSound = "playBreakCompleteSound"
        static let showCountdown = "showCountdown"
        static let allowSnooze = "allowSnooze"
        static let breakTitle = "breakTitle"
        static let breakSubtitle = "breakSubtitle"
        static let launchAtLogin = "launchAtLogin"
        static let preBreakNotificationEnabled = "preBreakNotificationEnabled"
        static let notificationLeadMinutes = "notificationLeadMinutes"
        static let extensionShortcutEnabled = "extensionShortcutEnabled"
        static let extensionShortcutKeyCode = "extensionShortcutKeyCode"
        static let extensionShortcutModifiers = "extensionShortcutModifiers"
    }
}
