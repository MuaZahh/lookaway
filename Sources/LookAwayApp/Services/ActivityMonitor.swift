import CoreGraphics
import Foundation

struct UsageSample {
    let now: TimeInterval
    let idleSeconds: TimeInterval
}

protocol ClockProviding {
    var uptime: TimeInterval { get }
}

struct SystemClock: ClockProviding {
    var uptime: TimeInterval {
        ProcessInfo.processInfo.systemUptime
    }
}

protocol IdleProviding {
    var idleSeconds: TimeInterval { get }
}

struct SystemIdleProvider: IdleProviding {
    private let eventTypes: [CGEventType] = [
        .leftMouseDown,
        .rightMouseDown,
        .otherMouseDown,
        .mouseMoved,
        .leftMouseDragged,
        .rightMouseDragged,
        .otherMouseDragged,
        .keyDown,
        .scrollWheel
    ]

    var idleSeconds: TimeInterval {
        let samples = eventTypes
            .map { CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: $0) }
            .filter { $0.isFinite && $0 >= 0 }

        return samples.min() ?? 0
    }
}

final class ActivityMonitor {
    private let clock: ClockProviding
    private let idleProvider: IdleProviding
    private var timer: Timer?

    init(
        clock: ClockProviding = SystemClock(),
        idleProvider: IdleProviding = SystemIdleProvider()
    ) {
        self.clock = clock
        self.idleProvider = idleProvider
    }

    func start(interval: TimeInterval = 1, handler: @escaping (UsageSample) -> Void) {
        stop()

        let timer = Timer(timeInterval: interval, repeats: true) { [clock, idleProvider] _ in
            handler(
                UsageSample(
                    now: clock.uptime,
                    idleSeconds: idleProvider.idleSeconds
                )
            )
        }

        self.timer = timer
        RunLoop.main.add(timer, forMode: .common)
        handler(UsageSample(now: clock.uptime, idleSeconds: idleProvider.idleSeconds))
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }
}
