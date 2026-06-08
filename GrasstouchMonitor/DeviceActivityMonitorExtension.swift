import DeviceActivity
import Foundation

/// Receives DeviceActivity callbacks. When a selected app's usage threshold
/// fires, we flip `throttleActive` in the shared App Group; the packet tunnel
/// reads it on every batch of packets and engages the token bucket.
///
/// "Foreground end" is not directly observable; iOS calls `intervalDidEnd`
/// only at the schedule boundary. We approximate "app no longer in foreground"
/// by clearing the flag on a short timeout from a follow-up event. In
/// practice the monitor fires `eventDidReachThreshold` repeatedly while the
/// user is in the app, so we use a "decay" heuristic in the tunnel.
final class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    private let defaults = SharedConfig.defaults

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        defaults.set(false, forKey: SharedConfig.Key.throttleActive)
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        defaults.set(false, forKey: SharedConfig.Key.throttleActive)
        DarwinNotification.post(SharedConfig.Notification.configChanged)
    }

    override func eventDidReachThreshold(
        _ event: DeviceActivityEvent.Name,
        activity: DeviceActivityName
    ) {
        super.eventDidReachThreshold(event, activity: activity)
        defaults.set(true, forKey: SharedConfig.Key.throttleActive)
        defaults.set(Date().timeIntervalSince1970,
                     forKey: "throttleActiveSince")
        DarwinNotification.post(SharedConfig.Notification.configChanged)
    }
}
