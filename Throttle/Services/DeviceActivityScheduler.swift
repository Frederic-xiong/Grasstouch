import Foundation
import DeviceActivity
import FamilyControls
import ManagedSettings

/// Schedules a continuous DeviceActivity monitoring window for the user's
/// `FamilyActivitySelection`. The `ThrottleMonitor` extension receives the
/// `eventDidReachThreshold` / `intervalDidStart` callbacks and flips the
/// shared `throttleActive` flag the tunnel reads.
struct DeviceActivityScheduler {
    static let shared = DeviceActivityScheduler()

    private let center = DeviceActivityCenter()
    private let activityName = DeviceActivityName("app.throttle.allDay")
    private let eventName = DeviceActivityEvent.Name("app.throttle.appOpened")

    func reschedule(for selection: FamilyActivitySelection) {
        center.stopMonitoring([activityName])
        guard !selection.applicationTokens.isEmpty || !selection.categoryTokens.isEmpty else {
            return
        }

        // A 24-hour rolling window with start/end at midnight. iOS recreates it daily.
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )

        // Threshold of 1 second of usage — we want a callback as soon as the
        // user opens any selected app, not a usage-quota gate.
        let event = DeviceActivityEvent(
            applications: selection.applicationTokens,
            categories: selection.categoryTokens,
            threshold: DateComponents(second: 1)
        )

        do {
            try center.startMonitoring(activityName, during: schedule, events: [eventName: event])
        } catch {
            // Auth not granted yet, or no selection — silently no-op; the UI
            // already gates on `familyControlsAuthorized`.
        }
    }
}
