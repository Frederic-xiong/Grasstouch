import Foundation

/// Single point of access to App-Group-shared state. Used by the main app,
/// `ThrottleVPN` (packet tunnel), and `ThrottleMonitor` (DeviceActivityMonitor).
/// All three targets must have the App Groups capability with this identifier.
enum SharedConfig {
    static let appGroup = "group.app.throttle.shared"

    enum Key {
        static let throttleLevel       = "throttleLevel"        // Int (kbps)
        static let tunnelEnabled       = "tunnelEnabled"        // Bool
        static let throttleActive      = "throttleActive"       // Bool — set by monitor
        static let lockoutUntil        = "lockoutUntil"         // Date
        static let selectionData       = "familyActivitySelection" // Data
        static let bytesDown           = "bytesDown"            // Int64 rolling counter
        static let bytesUp             = "bytesUp"              // Int64 rolling counter
        static let lastCountersUpdate  = "lastCountersUpdate"   // TimeInterval
        static let hasCompletedOnboarding = "hasCompletedOnboarding" // Bool
    }

    enum Notification {
        /// Posted via `CFNotificationCenterGetDarwinNotifyCenter` by the tunnel
        /// when counters are refreshed. Main app listens to update the speed UI.
        static let speedUpdated = "app.throttle.speed.updated" as CFString
        /// Posted by the main app when config changes so the tunnel can re-read.
        static let configChanged = "app.throttle.config.changed" as CFString
    }

    static var defaults: UserDefaults {
        // Force-unwrap is acceptable here: an incorrect App Group ID is a build
        // misconfiguration that should crash loudly in development.
        UserDefaults(suiteName: appGroup)!
    }
}
