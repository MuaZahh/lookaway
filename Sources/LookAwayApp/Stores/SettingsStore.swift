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

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let fallback = BreakSettings()
        // Pause is deliberately session-only. A relaunch or Mac restart always resumes protection.
        self.isEnabled = true
        self.workIntervalMinutes = defaults.object(forKey: Keys.workIntervalMinutes) as? Double ?? fallback.workInterval / 60
        self.breakDurationSeconds = defaults.object(forKey: Keys.breakDurationSeconds) as? Double ?? fallback.breakDuration
        self.idleResetMinutes = defaults.object(forKey: Keys.idleResetMinutes) as? Double ?? fallback.idleResetThreshold / 60
        self.activeInputWindowSeconds = defaults.object(forKey: Keys.activeInputWindowSeconds) as? Double ?? fallback.activeInputWindow
        self.emergencyHoldSeconds = defaults.object(forKey: Keys.emergencyHoldSeconds) as? Double ?? fallback.emergencyHoldDuration

        if let rawMode = defaults.string(forKey: Keys.mode), let mode = BreakMode(rawValue: rawMode) {
            self.mode = mode
        } else {
            self.mode = fallback.mode
        }
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

        isEnabled = true
        workIntervalMinutes = fallback.workInterval / 60
        breakDurationSeconds = fallback.breakDuration
        idleResetMinutes = fallback.idleResetThreshold / 60
        activeInputWindowSeconds = fallback.activeInputWindow
        emergencyHoldSeconds = fallback.emergencyHoldDuration
        mode = fallback.mode
    }

    private func persistAndNotify() {
        defaults.set(workIntervalMinutes, forKey: Keys.workIntervalMinutes)
        defaults.set(breakDurationSeconds, forKey: Keys.breakDurationSeconds)
        defaults.set(idleResetMinutes, forKey: Keys.idleResetMinutes)
        defaults.set(activeInputWindowSeconds, forKey: Keys.activeInputWindowSeconds)
        defaults.set(emergencyHoldSeconds, forKey: Keys.emergencyHoldSeconds)
        defaults.set(mode.rawValue, forKey: Keys.mode)
        onChange?()
    }

    private enum Keys {
        static let workIntervalMinutes = "workIntervalMinutes"
        static let breakDurationSeconds = "breakDurationSeconds"
        static let idleResetMinutes = "idleResetMinutes"
        static let activeInputWindowSeconds = "activeInputWindowSeconds"
        static let emergencyHoldSeconds = "emergencyHoldSeconds"
        static let mode = "mode"
    }
}
