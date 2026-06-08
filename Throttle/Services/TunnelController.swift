import Foundation
import NetworkExtension

/// Owns the `NETunnelProviderManager` instance. Creating the manager triggers
/// the system "Allow VPN configuration" prompt the first time.
actor TunnelController {
    private let providerBundleID = "app.throttle.Throttle.ThrottleVPN"

    func start() async throws {
        let manager = try await loadOrCreateManager()
        try manager.connection.startVPNTunnel()
    }

    func stop() async {
        guard let manager = try? await loadManager() else { return }
        manager.connection.stopVPNTunnel()
    }

    private func loadOrCreateManager() async throws -> NETunnelProviderManager {
        if let existing = try await loadManager() {
            return existing
        }
        let manager = NETunnelProviderManager()
        let proto = NETunnelProviderProtocol()
        proto.providerBundleIdentifier = providerBundleID
        // On-device loopback; the "server" string is required by the API but
        // is never contacted because the tunnel processes packets in-process.
        proto.serverAddress = "localhost"
        manager.protocolConfiguration = proto
        manager.localizedDescription = "Throttle"
        manager.isEnabled = true
        try await manager.saveToPreferences()
        try await manager.loadFromPreferences()
        return manager
    }

    private func loadManager() async throws -> NETunnelProviderManager? {
        let all = try await NETunnelProviderManager.loadAllFromPreferences()
        return all.first(where: {
            ($0.protocolConfiguration as? NETunnelProviderProtocol)?
                .providerBundleIdentifier == providerBundleID
        })
    }
}
