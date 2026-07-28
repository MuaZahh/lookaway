import Foundation

public enum BreakSchedulerEvent: Equatable, Sendable {
    case breakStarted
    case breakCompleted
    case naturalBreakCompleted
    case emergencyOverrideCompleted
    case emergencyOverrideCancelled
}

public struct BreakSchedulerSnapshot: Equatable, Sendable {
    public var activeElapsed: TimeInterval
    public var breakRemaining: TimeInterval
    public var emergencyOverrideProgress: TimeInterval
    public var snoozeRemaining: TimeInterval
    public var isBreakActive: Bool
    public var isEmergencyOverrideActive: Bool

    public init(
        activeElapsed: TimeInterval,
        breakRemaining: TimeInterval,
        emergencyOverrideProgress: TimeInterval,
        snoozeRemaining: TimeInterval = 0,
        isBreakActive: Bool,
        isEmergencyOverrideActive: Bool
    ) {
        self.activeElapsed = activeElapsed
        self.breakRemaining = breakRemaining
        self.emergencyOverrideProgress = emergencyOverrideProgress
        self.snoozeRemaining = snoozeRemaining
        self.isBreakActive = isBreakActive
        self.isEmergencyOverrideActive = isEmergencyOverrideActive
    }
}

public struct BreakSchedulerPersistedState: Codable, Equatable, Sendable {
    public var activeElapsed: TimeInterval
    public var breakElapsed: TimeInterval
    public var isBreakActive: Bool
    public var snoozeRemaining: TimeInterval?

    public init(
        activeElapsed: TimeInterval,
        breakElapsed: TimeInterval,
        isBreakActive: Bool,
        snoozeRemaining: TimeInterval? = nil
    ) {
        self.activeElapsed = activeElapsed
        self.breakElapsed = breakElapsed
        self.isBreakActive = isBreakActive
        self.snoozeRemaining = snoozeRemaining
    }
}

public struct BreakScheduler: Sendable {
    public private(set) var settings: BreakSettings
    private var lastTick: TimeInterval?
    private var activeElapsed: TimeInterval
    private var breakElapsed: TimeInterval
    private var emergencyOverrideElapsed: TimeInterval
    private var snoozeRemaining: TimeInterval
    private var isBreakActive: Bool
    private var isEmergencyOverrideActive: Bool

    public init(settings: BreakSettings = BreakSettings()) {
        self.settings = settings.normalized
        self.activeElapsed = 0
        self.breakElapsed = 0
        self.emergencyOverrideElapsed = 0
        self.snoozeRemaining = 0
        self.isBreakActive = false
        self.isEmergencyOverrideActive = false
    }

    public var snapshot: BreakSchedulerSnapshot {
        BreakSchedulerSnapshot(
            activeElapsed: activeElapsed,
            breakRemaining: max(0, settings.breakDuration - breakElapsed),
            emergencyOverrideProgress: emergencyOverrideElapsed,
            snoozeRemaining: snoozeRemaining,
            isBreakActive: isBreakActive,
            isEmergencyOverrideActive: isEmergencyOverrideActive
        )
    }

    public var persistedState: BreakSchedulerPersistedState {
        BreakSchedulerPersistedState(
            activeElapsed: activeElapsed,
            breakElapsed: breakElapsed,
            isBreakActive: isBreakActive,
            snoozeRemaining: snoozeRemaining
        )
    }

    public mutating func updateSettings(_ settings: BreakSettings) {
        self.settings = settings.normalized
        activeElapsed = min(activeElapsed, self.settings.workInterval)
        breakElapsed = min(breakElapsed, self.settings.breakDuration)
        emergencyOverrideElapsed = min(emergencyOverrideElapsed, self.settings.emergencyHoldDuration)
    }

    public mutating func reset(now: TimeInterval? = nil) {
        lastTick = now
        activeElapsed = 0
        breakElapsed = 0
        emergencyOverrideElapsed = 0
        snoozeRemaining = 0
        isBreakActive = false
        isEmergencyOverrideActive = false
    }

    public mutating func rebaseClock(now: TimeInterval) {
        lastTick = now
    }

    public mutating func restore(
        _ state: BreakSchedulerPersistedState,
        now: TimeInterval
    ) {
        lastTick = now
        activeElapsed = min(max(0, state.activeElapsed), settings.workInterval)
        breakElapsed = min(max(0, state.breakElapsed), settings.breakDuration)
        isBreakActive = state.isBreakActive && breakElapsed < settings.breakDuration
        snoozeRemaining = max(0, state.snoozeRemaining ?? 0)
        emergencyOverrideElapsed = 0
        isEmergencyOverrideActive = false
    }

    public mutating func startBreak(now: TimeInterval) -> [BreakSchedulerEvent] {
        lastTick = now
        beginBreak()
        return [.breakStarted]
    }

    public mutating func snoozeBreak(
        now: TimeInterval,
        duration: TimeInterval
    ) {
        guard isBreakActive else { return }
        postpone(now: now, duration: duration)
    }

    public mutating func postpone(
        now: TimeInterval,
        duration: TimeInterval
    ) {
        let remainingBeforePostpone: TimeInterval
        if isBreakActive {
            remainingBeforePostpone = 0
        } else if snoozeRemaining > 0 {
            remainingBeforePostpone = snoozeRemaining
        } else {
            remainingBeforePostpone = max(0, settings.workInterval - activeElapsed)
        }

        lastTick = now
        activeElapsed = 0
        snoozeRemaining = remainingBeforePostpone + max(1, duration)
        breakElapsed = 0
        emergencyOverrideElapsed = 0
        isBreakActive = false
        isEmergencyOverrideActive = false
    }

    public mutating func setEmergencyOverrideActive(_ active: Bool) -> [BreakSchedulerEvent] {
        guard active != isEmergencyOverrideActive else { return [] }
        isEmergencyOverrideActive = active
        if active {
            emergencyOverrideElapsed = 0
            return []
        }

        let hadProgress = emergencyOverrideElapsed > 0
        emergencyOverrideElapsed = 0
        return hadProgress ? [.emergencyOverrideCancelled] : []
    }

    public mutating func tick(now: TimeInterval, idleSeconds: TimeInterval) -> [BreakSchedulerEvent] {
        guard let lastTick else {
            self.lastTick = now
            return []
        }

        let delta = now - lastTick
        guard delta > 0 else { return [] }
        self.lastTick = now

        if isBreakActive {
            return tickActiveBreak(delta: delta)
        }

        if idleSeconds >= settings.idleResetThreshold {
            guard activeElapsed > 0 || snoozeRemaining > 0 else { return [] }
            activeElapsed = 0
            snoozeRemaining = 0
            return [.naturalBreakCompleted]
        }

        guard idleSeconds <= settings.activeInputWindow else { return [] }

        if snoozeRemaining > 0 {
            snoozeRemaining = max(0, snoozeRemaining - delta)
            if snoozeRemaining == 0 {
                beginBreak()
                return [.breakStarted]
            }
            return []
        }

        activeElapsed += delta
        if activeElapsed >= settings.workInterval {
            beginBreak()
            return [.breakStarted]
        }

        return []
    }

    private mutating func tickActiveBreak(delta: TimeInterval) -> [BreakSchedulerEvent] {
        if isEmergencyOverrideActive {
            emergencyOverrideElapsed += delta
            if emergencyOverrideElapsed >= settings.emergencyHoldDuration {
                finishBreak()
                return [.emergencyOverrideCompleted]
            }
        }

        breakElapsed += delta
        if breakElapsed >= settings.breakDuration {
            finishBreak()
            return [.breakCompleted]
        }

        return []
    }

    private mutating func beginBreak() {
        isBreakActive = true
        breakElapsed = 0
        emergencyOverrideElapsed = 0
        snoozeRemaining = 0
        isEmergencyOverrideActive = false
    }

    private mutating func finishBreak() {
        activeElapsed = 0
        breakElapsed = 0
        emergencyOverrideElapsed = 0
        snoozeRemaining = 0
        isBreakActive = false
        isEmergencyOverrideActive = false
    }
}
