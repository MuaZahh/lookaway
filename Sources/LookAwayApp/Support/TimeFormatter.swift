import Foundation

enum TimeFormatter {
    static func clock(_ seconds: TimeInterval) -> String {
        let wholeSeconds = max(0, Int(ceil(seconds)))
        let minutes = wholeSeconds / 60
        let seconds = wholeSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    static func compact(_ seconds: TimeInterval) -> String {
        let wholeSeconds = max(0, Int(ceil(seconds)))
        let minutes = wholeSeconds / 60
        let seconds = wholeSeconds % 60

        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }

        return "\(seconds)s"
    }
}
