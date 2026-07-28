import AppKit
import Foundation
import OSLog
import UserNotifications

final class PreBreakNotificationManager: NSObject, UNUserNotificationCenterDelegate {
    var onStatusChange: ((String) -> Void)?

    private let center = UNUserNotificationCenter.current()
    private let logger = Logger(
        subsystem: "app.lookaway.LookAway",
        category: "notifications"
    )

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
            self?.logger.info("Authorization status: \(settings.authorizationStatus.rawValue)")
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                self?.publishStatus("macOS break warnings are on")
            case .denied:
                self?.publishStatus("Allow notifications in System Settings → Notifications → LookAway")
            case .notDetermined:
                self?.center.requestAuthorization(options: [.alert, .sound]) { granted, error in
                    self?.handleAuthorizationResult(granted: granted, error: error)
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
            extensionMinutes: extensionMinutes,
            isTest: false
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
                    extensionMinutes: extensionMinutes,
                    isTest: true
                )
            case .notDetermined:
                self.center.requestAuthorization(options: [.alert, .sound]) { granted, error in
                    self.handleAuthorizationResult(granted: granted, error: error)
                    guard granted else { return }
                    self.addBreakWarning(
                        remaining: remaining,
                        shortcut: shortcut,
                        extensionMinutes: extensionMinutes,
                        isTest: true
                    )
                }
            case .denied:
                self.publishStatus("Notifications are off — opening macOS Notification Settings")
                self.openNotificationSettings()
            @unknown default:
                self.publishStatus("Notification status is unavailable")
            }
        }
    }

    private func addBreakWarning(
        remaining: TimeInterval,
        shortcut: String?,
        extensionMinutes: Double,
        isTest: Bool
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
        center.add(request) { [weak self] error in
            if let error {
                self?.logger.error("Notification request failed: \(error.localizedDescription, privacy: .public)")
                self?.publishStatus("Notification failed: \(error.localizedDescription)")
                return
            }

            self?.logger.info("Notification request accepted")
            if isTest {
                self?.publishStatus("Test notification sent")
            }
        }
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

    private func handleAuthorizationResult(granted: Bool, error: Error?) {
        if let error {
            logger.error("Authorization failed: \(error.localizedDescription, privacy: .public)")
            publishStatus("Notification permission failed: \(error.localizedDescription)")
        } else if granted {
            logger.info("Notification permission granted")
            publishStatus("macOS break warnings are on")
        } else {
            logger.info("Notification permission denied")
            publishStatus("Notifications were not allowed")
        }
    }

    private func openNotificationSettings() {
        guard let url = URL(
            string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension"
        ) else {
            return
        }

        DispatchQueue.main.async {
            NSWorkspace.shared.open(url)
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
