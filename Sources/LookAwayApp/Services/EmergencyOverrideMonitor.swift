import AppKit

final class EmergencyOverrideMonitor {
    var onOverrideChanged: ((Bool) -> Void)?

    private var localMonitor: Any?
    private var globalMonitor: Any?
    private var isEscapeDown = false
    private var areModifiersDown = false
    private var isOverrideActive = false

    func start() {
        stop()

        localMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.keyDown, .keyUp, .flagsChanged]
        ) { [weak self] event in
            self?.handle(event)
            return event
        }

        globalMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.keyDown, .keyUp, .flagsChanged]
        ) { [weak self] event in
            self?.handle(event)
        }
    }

    func stop() {
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }

        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
            self.globalMonitor = nil
        }

        isEscapeDown = false
        areModifiersDown = false
        setOverrideActive(false)
    }

    private func handle(_ event: NSEvent) {
        switch event.type {
        case .flagsChanged:
            areModifiersDown = event.modifierFlags.contains([.command, .option])
        case .keyDown:
            if event.keyCode == 53 {
                isEscapeDown = true
                areModifiersDown = event.modifierFlags.contains([.command, .option])
            }
        case .keyUp:
            if event.keyCode == 53 {
                isEscapeDown = false
            }
            areModifiersDown = event.modifierFlags.contains([.command, .option])
        default:
            break
        }

        setOverrideActive(isEscapeDown && areModifiersDown)
    }

    private func setOverrideActive(_ active: Bool) {
        guard active != isOverrideActive else { return }

        isOverrideActive = active
        onOverrideChanged?(active)
    }
}
