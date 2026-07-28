import Foundation

public struct BreakSettings: Equatable, Codable, Sendable {
    public var workInterval: TimeInterval
    public var breakDuration: TimeInterval
    public var idleResetThreshold: TimeInterval
    public var activeInputWindow: TimeInterval
    public var emergencyHoldDuration: TimeInterval
    public var mode: BreakMode

    public init(
        workInterval: TimeInterval = 25 * 60,
        breakDuration: TimeInterval = 60,
        idleResetThreshold: TimeInterval = 2 * 60,
        activeInputWindow: TimeInterval = 3,
        emergencyHoldDuration: TimeInterval = 5,
        mode: BreakMode = .strict
    ) {
        self.workInterval = max(1, workInterval)
        self.breakDuration = max(1, breakDuration)
        self.idleResetThreshold = max(1, idleResetThreshold)
        self.activeInputWindow = max(0.1, activeInputWindow)
        self.emergencyHoldDuration = max(1, emergencyHoldDuration)
        self.mode = mode
    }

    public var normalized: BreakSettings {
        BreakSettings(
            workInterval: workInterval,
            breakDuration: breakDuration,
            idleResetThreshold: idleResetThreshold,
            activeInputWindow: activeInputWindow,
            emergencyHoldDuration: emergencyHoldDuration,
            mode: mode
        )
    }
}
