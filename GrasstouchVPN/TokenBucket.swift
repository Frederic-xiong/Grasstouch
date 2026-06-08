import Foundation
import QuartzCore

/// Classic token bucket. Not thread-safe; callers must serialize.
struct TokenBucket {
    var ratePerSecond: Double
    var capacity: Double
    private var tokens: Double
    private var lastRefill: TimeInterval

    init(bytesPerSecond: Int) {
        self.ratePerSecond = Double(bytesPerSecond)
        self.capacity = Double(bytesPerSecond)
        self.tokens = capacity
        self.lastRefill = CACurrentMediaTime()
    }

    mutating func update(bytesPerSecond: Int) {
        self.ratePerSecond = Double(bytesPerSecond)
        self.capacity = Double(bytesPerSecond)
        self.tokens = min(tokens, capacity)
    }

    /// Returns 0 if the packet can be forwarded immediately. Otherwise returns
    /// seconds the caller should delay before forwarding.
    mutating func consume(_ bytes: Int) -> TimeInterval {
        let now = CACurrentMediaTime()
        tokens = min(capacity, tokens + ratePerSecond * (now - lastRefill))
        lastRefill = now
        if tokens >= Double(bytes) {
            tokens -= Double(bytes)
            return 0
        }
        let deficit = Double(bytes) - tokens
        tokens = 0
        return deficit / ratePerSecond
    }
}
