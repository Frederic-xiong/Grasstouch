import Foundation
import Combine
import FamilyControls
import ManagedSettings

@MainActor
final class ThrottleState: ObservableObject {
    @Published var hasCompletedOnboarding: Bool
    @Published var throttleLevel: ThrottleLevel
    @Published var tunnelEnabled: Bool
    @Published var selection: FamilyActivitySelection
    @Published var lockoutUntil: Date?
    @Published var currentKbpsDown: Double = 0
    @Published var currentKbpsUp: Double = 0
    @Published var familyControlsAuthorized: Bool = false

    private let tunnel = TunnelController()
    private let lockout = LockoutManager()
    private var speedObserver: DarwinNotificationObserver?

    init() {
        let d = SharedConfig.defaults
        self.hasCompletedOnboarding = d.bool(forKey: SharedConfig.Key.hasCompletedOnboarding)
        let level = d.integer(forKey: SharedConfig.Key.throttleLevel)
        self.throttleLevel = ThrottleLevel(rawValue: level) ?? .slow
        self.tunnelEnabled = d.bool(forKey: SharedConfig.Key.tunnelEnabled)
        self.lockoutUntil = d.object(forKey: SharedConfig.Key.lockoutUntil) as? Date
        if let data = d.data(forKey: SharedConfig.Key.selectionData),
           let decoded = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) {
            self.selection = decoded
        } else {
            self.selection = FamilyActivitySelection()
        }
    }

    func bootstrap() async {
        familyControlsAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
        speedObserver = DarwinNotificationObserver(name: SharedConfig.Notification.speedUpdated) { [weak self] in
            Task { @MainActor in self?.refreshSpeed() }
        }
        refreshSpeed()
    }

    func requestFamilyControlsAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            familyControlsAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
        } catch {
            familyControlsAuthorized = false
        }
    }

    func setLevel(_ level: ThrottleLevel) {
        throttleLevel = level
        SharedConfig.defaults.set(level.rawValue, forKey: SharedConfig.Key.throttleLevel)
        DarwinNotification.post(SharedConfig.Notification.configChanged)
    }

    func setSelection(_ new: FamilyActivitySelection) {
        selection = new
        if let data = try? JSONEncoder().encode(new) {
            SharedConfig.defaults.set(data, forKey: SharedConfig.Key.selectionData)
        }
        DeviceActivityScheduler.shared.reschedule(for: new)
        DarwinNotification.post(SharedConfig.Notification.configChanged)
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        SharedConfig.defaults.set(true, forKey: SharedConfig.Key.hasCompletedOnboarding)
    }

    var isLockedOut: Bool { lockout.isLockedOut(until: lockoutUntil) }
    var lockoutRemaining: TimeInterval { lockout.remaining(until: lockoutUntil) }

    func enableTunnel() async throws {
        try await tunnel.start()
        tunnelEnabled = true
        SharedConfig.defaults.set(true, forKey: SharedConfig.Key.tunnelEnabled)
    }

    func disableTunnel() async {
        await tunnel.stop()
        tunnelEnabled = false
        SharedConfig.defaults.set(false, forKey: SharedConfig.Key.tunnelEnabled)
        let until = Date().addingTimeInterval(24 * 60 * 60)
        lockoutUntil = until
        SharedConfig.defaults.set(until, forKey: SharedConfig.Key.lockoutUntil)
    }

    private func refreshSpeed() {
        let d = SharedConfig.defaults
        let now = Date().timeIntervalSince1970
        let last = d.double(forKey: SharedConfig.Key.lastCountersUpdate)
        let dt = max(now - last, 0.001)
        let down = Double(d.integer(forKey: SharedConfig.Key.bytesDown))
        let up = Double(d.integer(forKey: SharedConfig.Key.bytesUp))
        currentKbpsDown = (down * 8 / 1000) / dt
        currentKbpsUp = (up * 8 / 1000) / dt
    }
}
