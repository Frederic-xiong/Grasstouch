import Foundation

struct LockoutManager {
    func isLockedOut(until lockoutUntil: Date?) -> Bool {
        guard let until = lockoutUntil else { return false }
        return Date() < until
    }

    func remaining(until lockoutUntil: Date?) -> TimeInterval {
        guard let until = lockoutUntil else { return 0 }
        return max(0, until.timeIntervalSinceNow)
    }

    static func formatRemaining(_ seconds: TimeInterval) -> String {
        let h = Int(seconds) / 3600
        let m = (Int(seconds) % 3600) / 60
        let s = Int(seconds) % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
}
