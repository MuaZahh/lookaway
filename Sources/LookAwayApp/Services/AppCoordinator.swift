import AppKit
import Foundation
import LookAwayCore

final class AppCoordinator {
    private let settingsStore: SettingsStore
    private let stateStore: AppStateStore
    private let schedulerStateStore: SchedulerStateStore
    private let activityMonitor: ActivityMonitor
    private let overlayController: BreakOverlayController
    private let emergencyMonitor: EmergencyOverrideMonitor
    private let statusItemController: StatusItemController
    private let clock: ClockProviding

    private var scheduler: BreakScheduler

    init(
        settingsStore: SettingsStore,
        stateStore: AppStateStore,
        schedulerStateStore: SchedulerStateStore = SchedulerStateStore(),
        activityMonitor: ActivityMonitor = ActivityMonitor(),
        overlayController: BreakOverlayController = BreakOverlayController(),
        emergencyMonitor: EmergencyOverrideMonitor = EmergencyOverrideMonitor(),
        statusItemController: StatusItemController = StatusItemController(),
        clock: ClockProviding = SystemClock()
    ) {
        self.settingsStore = settingsStore
        self.stateStore = stateStore
        self.schedulerStateStore = schedulerStateStore
        self.activityMonitor = activityMonitor
        self.overlayController = overlayController
        self.emergencyMonitor = emergencyMonitor
        self.statusItemController = statusItemController
        self.clock = clock
        var scheduler = BreakScheduler(settings: settingsStore.breakSettings)
        if let persistedState = schedulerStateStore.load() {
            scheduler.restore(persistedState, now: clock.uptime)
        }
        self.scheduler = scheduler
    }

    func start() {
        settingsStore.onChange = { [weak self] in
            self?.settingsDidChange()
        }

        statusItemController.onToggleEnabled = { [weak self] in
            self?.settingsStore.isEnabled.toggle()
        }
        statusItemController.onTakeBreakNow = { [weak self] in
            self?.takeBreakNow()
        }
        statusItemController.onOpenSettings = {
            NSApp.activate(ignoringOtherApps: true)
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        }
        statusItemController.onQuit = {
            NSApp.terminate(nil)
        }

        emergencyMonitor.onOverrideChanged = { [weak self] isActive in
            self?.setEmergencyOverrideActive(isActive)
        }

        emergencyMonitor.start()
        activityMonitor.start { [weak self] sample in
            self?.handle(sample)
        }
        syncState()

        if scheduler.snapshot.isBreakActive {
            beginBreakPresentation()
        }
    }

    func stop() {
        schedulerStateStore.save(scheduler.persistedState)
        activityMonitor.stop()
        emergencyMonitor.stop()
        overlayController.hide()
    }

    func takeBreakNow() {
        guard settingsStore.isEnabled else { return }

        let events = scheduler.startBreak(now: clock.uptime)
        process(events: events)
        syncState()
    }

    private func settingsDidChange() {
        let wasEnabled = stateStore.isEnabled
        scheduler.updateSettings(settingsStore.breakSettings)
        scheduler.rebaseClock(now: clock.uptime)

        if !settingsStore.isEnabled {
            overlayController.hide()
            stateStore.lastEventMessage = "Paused"
        } else if !wasEnabled && scheduler.snapshot.isBreakActive {
            beginBreakPresentation()
        }

        syncState()
    }

    private func handle(_ sample: UsageSample) {
        stateStore.idleSeconds = sample.idleSeconds

        guard settingsStore.isEnabled else {
            syncState()
            return
        }

        let events = scheduler.tick(now: sample.now, idleSeconds: sample.idleSeconds)
        process(events: events)
        syncState()
    }

    private func setEmergencyOverrideActive(_ isActive: Bool) {
        guard scheduler.snapshot.isBreakActive else { return }

        let events = scheduler.setEmergencyOverrideActive(isActive)
        process(events: events)
        syncState()
    }

    private func process(events: [BreakSchedulerEvent]) {
        for event in events {
            switch event {
            case .breakStarted:
                beginBreakPresentation()
            case .breakCompleted:
                stateStore.completedBreaks += 1
                stateStore.lastEventMessage = "Break complete"
                overlayController.hide()
            case .naturalBreakCompleted:
                stateStore.naturalBreaks += 1
                stateStore.lastEventMessage = "Natural break counted"
            case .emergencyOverrideCompleted:
                stateStore.skippedBreaks += 1
                stateStore.lastEventMessage = "Emergency override used"
                overlayController.hide()
            case .emergencyOverrideCancelled:
                stateStore.lastEventMessage = "Emergency override cancelled"
            }
        }
    }

    private func beginBreakPresentation() {
        stateStore.lastEventMessage = "Break started"
        NSSound.beep()

        guard settingsStore.mode.showsOverlay else {
            return
        }

        NSApp.activate(ignoringOtherApps: true)
        overlayController.show(
            mode: settingsStore.mode,
            stateStore: stateStore,
            settingsStore: settingsStore,
            onDismiss: { [weak self] in
                self?.dismissFocusedBreak()
            },
            onSnooze: { [weak self] in
                self?.snoozeBreak()
            }
        )
    }

    private func snoozeBreak() {
        guard scheduler.snapshot.isBreakActive else { return }

        scheduler.snoozeBreak(now: clock.uptime, duration: 5 * 60)
        stateStore.skippedBreaks += 1
        stateStore.lastEventMessage = "Break snoozed for 5 minutes"
        overlayController.hide()
        overlayController.showSnoozeConfirmation()
        syncState()
    }

    private func dismissFocusedBreak() {
        guard settingsStore.mode.allowsVisibleDismiss else { return }

        scheduler.reset(now: clock.uptime)
        stateStore.skippedBreaks += 1
        stateStore.lastEventMessage = "Break dismissed"
        overlayController.hide()
        syncState()
    }

    private func syncState() {
        stateStore.snapshot = scheduler.snapshot
        stateStore.mode = settingsStore.mode
        stateStore.isEnabled = settingsStore.isEnabled
        stateStore.statusText = statusText()
        schedulerStateStore.save(scheduler.persistedState)
        statusItemController.update(settings: settingsStore, state: stateStore)
    }

    private func statusText() -> String {
        guard settingsStore.isEnabled else { return "Paused" }

        let snapshot = scheduler.snapshot
        if snapshot.isBreakActive {
            return "Break \(Self.shortTime(snapshot.breakRemaining))"
        }

        let remaining = max(0, scheduler.settings.workInterval - snapshot.activeElapsed)
        return "\(Self.shortTime(remaining)) left"
    }

    private static func shortTime(_ seconds: TimeInterval) -> String {
        let wholeSeconds = max(0, Int(ceil(seconds)))
        let minutes = wholeSeconds / 60
        let seconds = wholeSeconds % 60

        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }

        return "\(seconds)s"
    }
}
