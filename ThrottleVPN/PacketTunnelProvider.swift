import NetworkExtension
import Foundation

/// On-device packet tunnel. There is no remote server: packets are read from
/// `packetFlow`, optionally delayed by a token bucket, then written back.
/// Throttling is only applied while `SharedConfig.Key.throttleActive == true`,
/// which the `ThrottleMonitor` extension flips when a selected app comes to
/// foreground. Otherwise we passthrough at line rate.
///
/// CAVEAT: A pure-loopback NEPacketTunnelProvider that "writes packets back"
/// does not by itself forward them to the real network — the system tunnel
/// expects packets to be either delivered to a remote endpoint or re-injected
/// by `setTunnelNetworkSettings` routes that exclude themselves. The realistic
/// production implementation parses TCP/UDP headers, opens `NWConnection`s to
/// the original destinations, and ferries bytes through them. This file
/// implements the throttling control loop and the read/write skeleton; the
/// per-flow forwarder is left as `forwardPacket(_:)`, which is the place to
/// integrate userspace TCP (e.g. swift-nio or a tiny BSD-socket relay) when
/// you wire up real packet handling.
final class PacketTunnelProvider: NEPacketTunnelProvider {
    private var bucketDown = TokenBucket(bytesPerSecond: 256_000 / 8)
    private var bucketUp = TokenBucket(bytesPerSecond: 256_000 / 8)
    private let bucketQueue = DispatchQueue(label: "app.throttle.bucket")
    private var configObserver: DarwinNotificationObserver?
    private var counterFlushTimer: DispatchSourceTimer?
    private var pendingBytesDown: Int64 = 0
    private var pendingBytesUp: Int64 = 0

    override func startTunnel(options: [String: NSObject]?,
                              completionHandler: @escaping (Error?) -> Void) {
        applyConfigFromShared()
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "127.0.0.1")
        let ipv4 = NEIPv4Settings(addresses: ["10.7.0.2"], subnetMasks: ["255.255.255.0"])
        ipv4.includedRoutes = [NEIPv4Route.default()]
        ipv4.excludedRoutes = [NEIPv4Route(destinationAddress: "10.7.0.0", subnetMask: "255.255.255.0")]
        settings.ipv4Settings = ipv4
        settings.dnsSettings = NEDNSSettings(servers: ["1.1.1.1", "8.8.8.8"])
        settings.mtu = 1400

        setTunnelNetworkSettings(settings) { [weak self] error in
            guard let self = self else { return }
            if let error = error { completionHandler(error); return }
            self.configObserver = DarwinNotificationObserver(
                name: SharedConfig.Notification.configChanged
            ) { [weak self] in self?.applyConfigFromShared() }
            self.startCounterFlush()
            self.readLoop()
            completionHandler(nil)
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason,
                             completionHandler: @escaping () -> Void) {
        counterFlushTimer?.cancel()
        counterFlushTimer = nil
        configObserver = nil
        completionHandler()
    }

    // MARK: - Packet loop

    private func readLoop() {
        packetFlow.readPackets { [weak self] packets, _ in
            guard let self = self else { return }
            self.process(packets: packets)
            self.readLoop()
        }
    }

    private func process(packets: [Data]) {
        let active = SharedConfig.defaults.bool(forKey: SharedConfig.Key.throttleActive)
            && SharedConfig.defaults.bool(forKey: SharedConfig.Key.tunnelEnabled)

        if !active {
            // Passthrough mode — full rate.
            for p in packets { pendingBytesDown += Int64(p.count) }
            forward(packets: packets)
            return
        }

        bucketQueue.async { [weak self] in
            guard let self = self else { return }
            for packet in packets {
                let delay = self.bucketDown.consume(packet.count)
                self.pendingBytesDown += Int64(packet.count)
                if delay > 0 {
                    self.bucketQueue.asyncAfter(deadline: .now() + delay) {
                        self.forward(packets: [packet])
                    }
                } else {
                    self.forward(packets: [packet])
                }
            }
        }
    }

    /// Hook for the real forwarder. Today this writes packets back to the
    /// tunnel flow; the production version should parse IP headers and
    /// shuttle the payload over an `NWConnection` to the original destination.
    private func forward(packets: [Data]) {
        let protocols = Array(repeating: AF_INET as NSNumber, count: packets.count)
        packetFlow.writePackets(packets, withProtocols: protocols)
    }

    // MARK: - Config

    private func applyConfigFromShared() {
        let kbps = SharedConfig.defaults.integer(forKey: SharedConfig.Key.throttleLevel)
        let bps = max(kbps, 256) * 1000 / 8
        bucketQueue.async {
            self.bucketDown.update(bytesPerSecond: bps)
            self.bucketUp.update(bytesPerSecond: bps)
        }
    }

    // MARK: - Counter flush

    private func startCounterFlush() {
        let t = DispatchSource.makeTimerSource(queue: .global(qos: .utility))
        t.schedule(deadline: .now() + 0.5, repeating: 0.5)
        t.setEventHandler { [weak self] in self?.flushCounters() }
        t.resume()
        counterFlushTimer = t
    }

    private func flushCounters() {
        let d = SharedConfig.defaults
        d.set(pendingBytesDown, forKey: SharedConfig.Key.bytesDown)
        d.set(pendingBytesUp, forKey: SharedConfig.Key.bytesUp)
        d.set(Date().timeIntervalSince1970, forKey: SharedConfig.Key.lastCountersUpdate)
        pendingBytesDown = 0
        pendingBytesUp = 0
        DarwinNotification.post(SharedConfig.Notification.speedUpdated)
    }
}
