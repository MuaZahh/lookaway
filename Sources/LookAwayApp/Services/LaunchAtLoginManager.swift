import ServiceManagement

enum LaunchAtLoginManager {
    static func ensureEnabled() -> String {
        let service = SMAppService.mainApp

        switch service.status {
        case .enabled:
            return "Starts automatically when you log in"
        case .notRegistered:
            do {
                try service.register()
                return "Starts automatically when you log in"
            } catch {
                return "Could not enable start at login"
            }
        case .requiresApproval:
            return "Allow LookAway in System Settings → General → Login Items"
        case .notFound:
            return "Start at login becomes available from the packaged app"
        @unknown default:
            return "Start-at-login status is unavailable"
        }
    }
}
