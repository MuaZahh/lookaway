import Foundation

public struct BreakWarningGate: Sendable {
    private var hasWarned = false

    public init() {}

    public mutating func shouldNotify(
        remaining: TimeInterval,
        leadTime: TimeInterval,
        isBreakActive: Bool,
        isEnabled: Bool
    ) -> Bool {
        guard isEnabled, !isBreakActive else { return false }

        if remaining > leadTime {
            hasWarned = false
            return false
        }

        guard remaining > 0, !hasWarned else { return false }
        hasWarned = true
        return true
    }

    public mutating func reset() {
        hasWarned = false
    }
}
