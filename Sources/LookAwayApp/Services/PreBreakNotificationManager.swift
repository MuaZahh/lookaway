import Foundation
import UserNotifications

final class PreBreakNotificationManager: NSObject, UNUserNotificationCenterDelegate {
    var onStatusChange: ((String) -> Void)?

    private let center = UNUserNotificationCenter.current()

    override init() {
        super.init()
        center.delegate = self
    }

    func updateAuthorization(enabled: Bool) {
        guard enabled else {
            onStatusChange?("One-minute warning is off")
            return
        }

        center.getNotificationSettings { [weak self] settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                self?.publishStatus("macOS break warnings are on")
            case .denied:
                self?.publishStatus("Allow notifications in System Settings → Notifications → LookAway")
            case .notDetermined:
                self?.center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
                    self?.publishStatus(
                        granted
                            ? "macOS break warnings are on"
                            : "Notifications were not allowed"
                    )
                }
            @unknown default:
                self?.publishStatus("Notification status is unavailable")
            }
        }
    }

    func sendBreakWarning(
        remaining: TimeInterval,
        shortcut: String?,
        extensionMinutes: Double
    ) {
        addBreakWarning(
            remaining: remaining,
            shortcut: shortcut,
            extensionMinutes: extensionMinutes
        )
    }

    func sendTestBreakWarning(
        remaining: TimeInterval,
        shortcut: String?,
        extensionMinutes: Double
    ) {
        center.getNotificationSettings { [weak self] settings in
            guard let self else { return }

            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                self.addBreakWarning(
                    remaining: remaining,
                    shortcut: shortcut,
                    extensionMinutes: extensionMinutes
                )
            case .notDetermined:
                self.center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
                    self.publishStatus(
                        granted
                            ? "macOS break warnings are on"
                            : "Notifications were not allowed"
                    )
                    guard granted else { return }
                    self.addBreakWarning(
                        remaining: remaining,
                        shortcut: shortcut,
                        extensionMinutes: extensionMinutes
                    )
                }
            case .denied:
                self.publishStatus("Allow notifications in System Settings → Notifications → LookAway")
            @unknown default:
                self.publishStatus("Notification status is unavailable")
            }
        }
    }

    private func addBreakWarning(
        remaining: TimeInterval,
        shortcut: String?,
        extensionMinutes: Double
    ) {
        let content = UNMutableNotificationContent()
        content.title = Self.warningTitle(remaining: remaining)

        if let shortcut {
            content.body = "Press \(shortcut) to add \(Self.minutesText(extensionMinutes))."
        } else {
            content.body = "Finish up what you’re doing. Your screen break is coming up."
        }

        let request = UNNotificationRequest(
            identifier: "lookaway.pre-break.\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        center.add(request)
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound])
    }

    private func publishStatus(_ status: String) {
        DispatchQueue.main.async { [weak self] in
            self?.onStatusChange?(status)
        }
    }

    private static func warningTitle(remaining: TimeInterval) -> String {
        let seconds = max(1, Int(ceil(remaining)))
        if seconds >= 60 {
            let minutes = max(1, Int(ceil(Double(seconds) / 60)))
            return "Break in \(minutes) \(minutes == 1 ? "minute" : "minutes")"
        }
        return "Break in \(seconds) seconds"
    }

    private static func minutesText(_ minutes: Double) -> String {
        if minutes.rounded() == minutes {
            let whole = Int(minutes)
            return "\(whole) \(whole == 1 ? "minute" : "minutes")"
        }
        return String(format: "%.1f minutes", minutes)
    }
}
