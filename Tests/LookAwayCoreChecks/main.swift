import Darwin
import Foundation
import LookAwayCore

func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fputs("FAIL: \(message)\n", stderr)
        exit(1)
    }
}

func expectClose(_ actual: TimeInterval, _ expected: TimeInterval, _ message: String) {
    expect(abs(actual - expected) < 0.0001, "\(message). Expected \(expected), got \(actual)")
}

func startsBreakAtExactWorkInterval() {
    var scheduler = BreakScheduler(settings: BreakSettings(workInterval: 20, breakDuration: 5))

    expect(scheduler.tick(now: 0, idleSeconds: 0) == [], "initial tick should not start break")
    expect(scheduler.tick(now: 19.99, idleSeconds: 0) == [], "19.99 seconds should not start break")
    expect(scheduler.tick(now: 20, idleSeconds: 0) == [.breakStarted], "20.00 seconds should start break")
    expect(scheduler.snapshot.isBreakActive, "break should be active")
}

func activeTimeDoesNotAccumulatePastInputWindow() {
    let settings = BreakSettings(workInterval: 20, breakDuration: 5, activeInputWindow: 1)
    var scheduler = BreakScheduler(settings: settings)

    expect(scheduler.tick(now: 0, idleSeconds: 0) == [], "initial tick should not start break")
    expect(scheduler.tick(now: 10, idleSeconds: 1.1) == [], "idle past active input window should pause active accumulation")
    expect(scheduler.snapshot.activeElapsed == 0, "active elapsed should stay paused")
    expect(scheduler.tick(now: 30, idleSeconds: 0) == [.breakStarted], "activity should resume accumulation")
}

func naturalBreakResetsAtExactIdleThreshold() {
    let settings = BreakSettings(workInterval: 20, breakDuration: 5, idleResetThreshold: 2, activeInputWindow: 1)
    var scheduler = BreakScheduler(settings: settings)

    expect(scheduler.tick(now: 0, idleSeconds: 0) == [], "initial tick should not start break")
    expect(scheduler.tick(now: 19.99, idleSeconds: 0) == [], "19.99 seconds should not start break")
    expect(scheduler.tick(now: 21.98, idleSeconds: 1.99) == [], "idle 1.99 should not reset")
    expectClose(scheduler.snapshot.activeElapsed, 19.99, "active elapsed should still be 19.99")
    expect(scheduler.tick(now: 21.99, idleSeconds: 2) == [.naturalBreakCompleted], "idle 2.00 should reset")
    expect(scheduler.snapshot.activeElapsed == 0, "active elapsed should reset")
}

func breakCompletesAtExactDuration() {
    var scheduler = BreakScheduler(settings: BreakSettings(workInterval: 20, breakDuration: 5))

    expect(scheduler.startBreak(now: 100) == [.breakStarted], "manual break should start")
    expect(scheduler.tick(now: 104.99, idleSeconds: 0) == [], "break 4.99 should stay locked")
    expect(scheduler.snapshot.isBreakActive, "break should remain active")
    expect(scheduler.tick(now: 105, idleSeconds: 0) == [.breakCompleted], "break 5.00 should complete")
    expect(!scheduler.snapshot.isBreakActive, "break should be inactive")
}

func emergencyOverrideRequiresExactHoldDuration() {
    var scheduler = BreakScheduler(
        settings: BreakSettings(workInterval: 20, breakDuration: 60, emergencyHoldDuration: 5)
    )

    expect(scheduler.startBreak(now: 200) == [.breakStarted], "manual break should start")
    expect(scheduler.setEmergencyOverrideActive(true) == [], "starting override should not emit")
    expect(scheduler.tick(now: 204.99, idleSeconds: 0) == [], "override 4.99 should not unlock")
    expect(scheduler.snapshot.isBreakActive, "break should remain active")
    expect(scheduler.tick(now: 205, idleSeconds: 0) == [.emergencyOverrideCompleted], "override 5.00 should unlock")
    expect(!scheduler.snapshot.isBreakActive, "break should be inactive")
}

func emergencyOverrideCancelResetsProgress() {
    var scheduler = BreakScheduler(
        settings: BreakSettings(workInterval: 20, breakDuration: 60, emergencyHoldDuration: 5)
    )

    expect(scheduler.startBreak(now: 300) == [.breakStarted], "manual break should start")
    expect(scheduler.setEmergencyOverrideActive(true) == [], "starting override should not emit")
    expect(scheduler.tick(now: 304.99, idleSeconds: 0) == [], "override 4.99 should not unlock")
    expect(scheduler.setEmergencyOverrideActive(false) == [.emergencyOverrideCancelled], "release should cancel override")
    expect(scheduler.setEmergencyOverrideActive(true) == [], "restarting override should not emit")
    expect(scheduler.tick(now: 305, idleSeconds: 0) == [], "new override should start from zero")
    expectClose(scheduler.snapshot.emergencyOverrideProgress, 0.01, "override progress should reset after cancel")
}

func duplicateAndNegativeTicksDoNotMoveTimeForward() {
    var scheduler = BreakScheduler(settings: BreakSettings(workInterval: 20, breakDuration: 5))

    expect(scheduler.tick(now: 10, idleSeconds: 0) == [], "initial tick should not move time")
    expect(scheduler.tick(now: 10, idleSeconds: 0) == [], "duplicate tick should be ignored")
    expect(scheduler.tick(now: 9, idleSeconds: 0) == [], "negative delta should be ignored")
    expect(scheduler.snapshot.activeElapsed == 0, "active elapsed should still be zero")
    expect(scheduler.tick(now: 29.99, idleSeconds: 0) == [], "19.99 effective seconds should not start")
    expect(scheduler.tick(now: 30, idleSeconds: 0) == [.breakStarted], "20.00 effective seconds should start")
}

func settingsAreNormalizedAndClampProgress() {
    var scheduler = BreakScheduler(settings: BreakSettings(workInterval: -10, breakDuration: -10))

    expect(scheduler.settings.workInterval == 1, "work interval should normalize to one second")
    expect(scheduler.settings.breakDuration == 1, "break duration should normalize to one second")
    expect(scheduler.tick(now: 0, idleSeconds: 0) == [], "initial tick should not start break")
    expect(scheduler.tick(now: 10, idleSeconds: 0) == [.breakStarted], "normalized interval should start break")

    scheduler.updateSettings(BreakSettings(workInterval: 30, breakDuration: 2, emergencyHoldDuration: 2))
    expect(scheduler.snapshot.breakRemaining == 2, "settings update should clamp break progress")
}

func schedulerCanSnoozeAndStartAgainFiveMinutesLater() {
    var scheduler = BreakScheduler(
        settings: BreakSettings(workInterval: 25 * 60, breakDuration: 60)
    )

    expect(scheduler.startBreak(now: 100) == [.breakStarted], "manual break should start")
    scheduler.snoozeBreak(now: 101, duration: 5 * 60)

    expect(!scheduler.snapshot.isBreakActive, "snooze should close the active break")
    expectClose(scheduler.snapshot.snoozeRemaining, 5 * 60, "snooze should leave five minutes")
    expect(scheduler.tick(now: 400.99, idleSeconds: 0) == [], "snooze should not end early")
    expect(scheduler.tick(now: 401, idleSeconds: 0) == [.breakStarted], "break should return after five minutes")
}

func snoozeCanBeLongerThanWorkInterval() {
    var scheduler = BreakScheduler(
        settings: BreakSettings(workInterval: 60, breakDuration: 10)
    )

    expect(scheduler.startBreak(now: 0) == [.breakStarted], "manual break should start")
    scheduler.snoozeBreak(now: 1, duration: 5 * 60)

    expect(scheduler.tick(now: 300.99, idleSeconds: 0) == [], "long snooze should not use the shorter work interval")
    expect(scheduler.tick(now: 301, idleSeconds: 0) == [.breakStarted], "long snooze should honor its exact duration")
}

func snoozeSurvivesRestart() {
    var original = BreakScheduler(settings: BreakSettings(workInterval: 60, breakDuration: 10))
    expect(original.startBreak(now: 0) == [.breakStarted], "manual break should start")
    original.snoozeBreak(now: 1, duration: 5 * 60)

    var restored = BreakScheduler(settings: BreakSettings(workInterval: 60, breakDuration: 10))
    restored.restore(original.persistedState, now: 1_000)

    expectClose(restored.snapshot.snoozeRemaining, 5 * 60, "restored snooze should preserve its duration")
    expect(restored.tick(now: 1_299.99, idleSeconds: 0) == [], "restored snooze should not end early")
    expect(restored.tick(now: 1_300, idleSeconds: 0) == [.breakStarted], "restored snooze should finish on time")
}

func shortcutPostponesCurrentCountdownByExactDuration() {
    var scheduler = BreakScheduler(settings: BreakSettings(workInterval: 20, breakDuration: 5))

    expect(scheduler.tick(now: 0, idleSeconds: 0) == [], "initial tick should initialize")
    expect(scheduler.tick(now: 12, idleSeconds: 0) == [], "partial work should accumulate")
    scheduler.postpone(now: 12, duration: 10)

    expectClose(scheduler.snapshot.snoozeRemaining, 18, "shortcut should add ten seconds to the existing eight")
    expect(scheduler.tick(now: 29.99, idleSeconds: 0) == [], "extended countdown should not end early")
    expect(scheduler.tick(now: 30, idleSeconds: 0) == [.breakStarted], "extended countdown should finish exactly on time")
}

func schedulerProgressRestoresWithoutCountingOfflineTime() {
    var original = BreakScheduler(settings: BreakSettings(workInterval: 20, breakDuration: 5))

    expect(original.tick(now: 0, idleSeconds: 0) == [], "initial tick should initialize")
    expect(original.tick(now: 12, idleSeconds: 0) == [], "partial work should accumulate")

    var restored = BreakScheduler(settings: BreakSettings(workInterval: 20, breakDuration: 5))
    restored.restore(original.persistedState, now: 1_000)

    expectClose(restored.snapshot.activeElapsed, 12, "restored work progress should be preserved")
    expect(restored.tick(now: 1_007.99, idleSeconds: 0) == [], "restored countdown should not end early")
    expect(restored.tick(now: 1_008, idleSeconds: 0) == [.breakStarted], "restored countdown should continue")
}

func rebasingClockDoesNotCountPausedTime() {
    var scheduler = BreakScheduler(settings: BreakSettings(workInterval: 20, breakDuration: 5))

    expect(scheduler.tick(now: 0, idleSeconds: 0) == [], "initial tick should initialize")
    expect(scheduler.tick(now: 12, idleSeconds: 0) == [], "partial work should accumulate")
    scheduler.rebaseClock(now: 1_000)

    expect(scheduler.tick(now: 1_007.99, idleSeconds: 0) == [], "paused time should not count")
    expect(scheduler.tick(now: 1_008, idleSeconds: 0) == [.breakStarted], "countdown should resume where it paused")
}

func preferencesRoundTripThroughUserDefaults() {
    let suiteName = "LookAwayCoreChecks.\(UUID().uuidString)"
    guard let defaults = UserDefaults(suiteName: suiteName) else {
        expect(false, "isolated user defaults should be available")
        return
    }
    defer { defaults.removePersistentDomain(forName: suiteName) }

    let expected = LookAwayPreferences(
        workIntervalMinutes: 42,
        breakDurationSeconds: 75,
        idleResetMinutes: 7.5,
        activeInputWindowSeconds: 12.5,
        emergencyHoldSeconds: 8,
        mode: .focused,
        snoozeDurationMinutes: 9.5,
        playBreakSound: false,
        showCountdown: false,
        allowSnooze: false,
        breakTitle: "Rest your eyes",
        breakSubtitle: "Look out a window",
        launchAtLogin: false,
        preBreakNotificationEnabled: false,
        notificationLeadMinutes: 2.5,
        extensionShortcutEnabled: false,
        extensionShortcutKeyCode: 49,
        extensionShortcutModifiers: 4_352
    )

    expected.save(to: defaults)
    expect(LookAwayPreferences.load(from: defaults) == expected, "every preference should persist and reload")
}

func preBreakWarningFiresOncePerCountdown() {
    var gate = BreakWarningGate()

    expect(!gate.shouldNotify(remaining: 61, leadTime: 60, isBreakActive: false, isEnabled: true), "warning should wait")
    expect(gate.shouldNotify(remaining: 60, leadTime: 60, isBreakActive: false, isEnabled: true), "warning should fire at threshold")
    expect(!gate.shouldNotify(remaining: 59, leadTime: 60, isBreakActive: false, isEnabled: true), "warning should only fire once")
    expect(!gate.shouldNotify(remaining: 300, leadTime: 60, isBreakActive: false, isEnabled: true), "extension should rearm warning")
    expect(gate.shouldNotify(remaining: 60, leadTime: 60, isBreakActive: false, isEnabled: true), "extended countdown should warn again")
    expect(!gate.shouldNotify(remaining: 60, leadTime: 60, isBreakActive: true, isEnabled: true), "active break should not warn")
    expect(!gate.shouldNotify(remaining: 60, leadTime: 60, isBreakActive: false, isEnabled: false), "disabled warning should not fire")
}

startsBreakAtExactWorkInterval()
activeTimeDoesNotAccumulatePastInputWindow()
naturalBreakResetsAtExactIdleThreshold()
breakCompletesAtExactDuration()
emergencyOverrideRequiresExactHoldDuration()
emergencyOverrideCancelResetsProgress()
duplicateAndNegativeTicksDoNotMoveTimeForward()
settingsAreNormalizedAndClampProgress()
schedulerCanSnoozeAndStartAgainFiveMinutesLater()
snoozeCanBeLongerThanWorkInterval()
snoozeSurvivesRestart()
shortcutPostponesCurrentCountdownByExactDuration()
schedulerProgressRestoresWithoutCountingOfflineTime()
rebasingClockDoesNotCountPausedTime()
preferencesRoundTripThroughUserDefaults()
preBreakWarningFiresOncePerCountdown()

print("LookAwayCoreChecks passed")
