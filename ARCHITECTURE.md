# Throttle — Architecture

This document is the source of truth for how Throttle is built. It exists because the
original product brief assumes capabilities iOS does not grant third-party apps, and
shipping anything to the App Store requires a design that respects those limits.

## 1. The constraints, stated honestly

The brief asks for four things that conflict with the iOS platform:

1. **"Show a list of installed apps and let the user pick one."**
   iOS does not expose installed third-party apps to other apps. There is no public
   API for enumeration. The only sanctioned picker is `FamilyActivityPicker` from
   the **Screen Time / Family Controls** framework, which returns opaque
   `ApplicationToken` / `WebDomainToken` / `ActivityCategoryToken` values — not
   bundle IDs, not names, not icons we can read.

2. **"Throttle the traffic of a specific app."**
   `NEPacketTunnelProvider` operates on a system-wide tunnel. Packets arrive without
   originating-process attribution. **Per-app VPN exists only via MDM** (enterprise
   / supervised devices) and is not available to App Store apps. There is no public
   API that says "this packet came from TikTok."

3. **"Real-time speed display per app."**
   Same root cause: we can measure bytes/sec through the tunnel, but we cannot
   split them by app.

4. **"Works on iOS 14+."**
   The Screen Time / `ManagedSettings` / `DeviceActivity` APIs require **iOS 15+**
   (and `FamilyActivityPicker` is iOS 15+; `ManagedSettings` shields are iOS 15+).
   `NEPacketTunnelProvider` is older but the entitlement story (Personal VPN vs
   Network Extensions) still applies.

Pretending otherwise produces an app that either (a) gets rejected from review,
(b) requires MDM enrollment users will not do, or (c) ships features that don't
work. We pick a design that ships.

## 2. Revised product design

Throttle's behavioral thesis — "make the app painful, not blocked" — survives. The
mechanism changes:

- **App selection** → `FamilyActivityPicker` (Screen Time). User taps Throttle's
  picker; iOS presents a system-rendered list of *their* apps; we receive opaque
  tokens. We never learn the bundle ID, but we can act on the token.
- **Throttling mechanism** → a **system-wide `NEPacketTunnelProvider`** (Personal
  VPN, on-device loopback — no remote server) that engages a token-bucket
  bandwidth cap **only while the user has a throttled app in the foreground**.
  Foreground detection comes from `DeviceActivityMonitor` events on the selected
  `FamilyActivitySelection`. When the user closes the app, the tunnel returns to
  unthrottled passthrough.
- **Honesty about scope** → the App Store description and onboarding both state
  plainly: *"Throttle slows your whole connection while a chosen app is open. It
  cannot slow one app and leave others fast at the same time."* This avoids
  review rejections for misleading claims and avoids user confusion when their
  music streaming stutters.
- **Real-time speed display** → kbps through the tunnel, labeled as
  "current connection speed" — not "TikTok speed." Truthful.
- **Lockout** → unchanged. 24-hour timestamp in `UserDefaults`
  (App Group–shared so the extension sees it too). The Disable button is the only
  way out, and it commits to the lockout.
- **Dashboard** → "Throttling time" per day (we know when the tunnel was active,
  per selection). "Frustration metric" becomes "sessions started under throttle"
  — a count of `DeviceActivityEvent` firings for the selected apps. No
  per-app-bundle-ID stats.

## 3. Components

```
┌──────────────────────────────────────────────────────────────┐
│  Throttle.app (main target, SwiftUI)                         │
│  • Onboarding & permission flow                              │
│  • FamilyActivityPicker → FamilyActivitySelection            │
│  • Throttle level picker (Slow / Medium / Fast)              │
│  • Enable/Disable toggle (+ lockout enforcement)             │
│  • Dashboard (Charts framework on iOS 16+, custom Canvas <16)│
│  • Reads/writes to:                                          │
│      - App Group UserDefaults (shared config)                │
│      - Core Data (metrics, events)                           │
└─────────────┬────────────────────────────────────┬───────────┘
              │                                    │
              │ NEVPNManager / NETunnelProviderMgr │ ManagedSettingsStore +
              ▼                                    │ DeviceActivityCenter
┌──────────────────────────────────────┐           │
│  ThrottleVPN (Packet Tunnel Ext.)    │           ▼
│  • NEPacketTunnelProvider            │  ┌────────────────────────────┐
│  • On-device loopback (no server)    │  │ ThrottleMonitor             │
│  • Token bucket per direction        │  │ (DeviceActivityMonitorExt)  │
│  • Reads "active level" from App     │  │ • intervalDidStart/End      │
│    Group; recomputes bucket rate     │  │ • eventDidReachThreshold    │
│  • Writes byte counters to App Group │  │ • Flips "throttle active"   │
│  • Reports kbps via Darwin notif.    │  │   flag in App Group         │
└──────────────────────────────────────┘  └────────────────────────────┘
```

### App Group

`group.app.throttle.shared` — the only sane IPC between the main app, the packet
tunnel, and the device-activity monitor. Holds:

- `throttleLevel: Int` (256 / 1000 / 5000, kbps)
- `throttleActive: Bool` (set by `ThrottleMonitor` based on app foreground)
- `tunnelEnabled: Bool` (set by main app)
- `lockoutUntil: Date?`
- Atomic byte counters (`bytesUp`, `bytesDown`, rolling) for kbps calc
- The `FamilyActivitySelection` (encoded `Data`)

### Darwin notifications

`CFNotificationCenterGetDarwinNotifyCenter` is the cross-process pub/sub we use to
wake the main app's speed display when the tunnel updates counters
(name: `app.throttle.speed.updated`). UserDefaults KVO across App Groups is
unreliable; Darwin notifications are not.

## 4. Throttling algorithm

Token bucket per direction (upload / download), evaluated per packet:

```
rate_bytes_per_sec = throttleLevel_kbps * 1000 / 8
bucket_capacity     = rate_bytes_per_sec  // 1 second of burst
tokens             += rate_bytes_per_sec * dt   // refill, capped at capacity
if tokens >= packet.size:
    tokens -= packet.size
    forward(packet)
else:
    delay = (packet.size - tokens) / rate_bytes_per_sec
    schedule forward(packet) after delay   // DispatchQueue with QoS .utility
```

When `throttleActive == false` (selected app not in foreground), the tunnel skips
the bucket entirely and forwards at line rate. This keeps the rest of the device
usable.

Packet I/O uses `NEPacketTunnelFlow.readPackets` / `writePackets` in a loop.
Forwarding goes through a UDP/TCP relay we build with `NWConnection` — the tunnel
is on-device only, so "forwarding" means re-injecting via the system's normal
networking stack against the real interface. We use `includeAllNetworks = false`
and `excludeLocalNetworks = true` so AirPlay, Handoff, etc. keep working.

## 5. Lockout

`lockoutUntil` is written when the user taps Disable. The main app's Enable
button is disabled while `Date() < lockoutUntil`. The packet tunnel itself does
not enforce lockout — it just stops when told. A user determined to defeat the
lockout can uninstall the app; we accept this. (The brief's "behavior reinforced"
goal is served by friction, not by adversarial resistance.)

## 6. Data model (Core Data)

Two entities. No per-app bundle IDs because we don't have them.

- **ThrottleSession**
  `id: UUID`, `startedAt: Date`, `endedAt: Date?`, `level: Int16`,
  `bytesThrottled: Int64`
- **MetricSample**
  `id: UUID`, `timestamp: Date`, `kbpsDown: Double`, `kbpsUp: Double`,
  `sessionId: UUID`

Dashboard queries: 7 days of `ThrottleSession` summed into a per-day bar.

## 7. Permissions & onboarding

In order:

1. **Family Controls authorization** — `AuthorizationCenter.requestAuthorization(for: .individual)`.
   User sees the iOS system prompt.
2. **App picker** — `FamilyActivityPicker` sheet.
3. **VPN configuration install** — `NETunnelProviderManager.saveToPreferences`
   triggers the iOS "Allow VPN configuration" sheet. We use a Personal VPN-style
   profile pointing at our own packet tunnel extension.
4. **Local Network usage** — declared in `Info.plist` (`NSLocalNetworkUsageDescription`)
   so the tunnel can observe LAN traffic for the speed metric.

We do **not** request: notifications, tracking transparency, location, contacts.

## 8. App Store review posture

This app's review risks, ranked:

1. **Misrepresentation** — claiming per-app throttling we can't deliver. Mitigated
   by truthful copy in description and onboarding (see §2).
2. **VPN abuse** — Apple rejects VPN apps that aren't transparent about what the
   tunnel does. Mitigated by being on-device-only and saying so in the privacy
   policy and in-app.
3. **Family Controls misuse** — the Family Controls entitlement is gated. We need
   to request it from Apple via the developer portal *before* the first review.
   This is captured as a build prerequisite in README, not a code task.
4. **Digital wellness category fit** — fine. Apps in this space (Opal, one sec)
   already use Screen Time APIs the same way.

## 9. What this design does NOT do

Stated up front so we don't drift back into the brief's promises:

- Does not enumerate installed apps.
- Does not throttle one app while leaving others at full speed.
- Does not measure per-app bandwidth.
- Does not work below iOS 15.
- Does not run a remote VPN server. No traffic leaves the device through us.

## 10. CI / release

GitHub Actions workflow (`.github/workflows/build.yml`):

- Trigger: push to `main`, manual dispatch.
- Runner: `macos-14` (Xcode 15+, needed for iOS 17 SDK and Family Controls).
- Steps: import signing cert + provisioning profile from secrets, `xcodebuild
  archive`, `xcodebuild -exportArchive`, upload to TestFlight via
  `xcrun altool` or `xcrun notarytool` + ASC API key.
- Required secrets (documented in README, not committed):
  `APPLE_API_KEY_ID`, `APPLE_API_ISSUER_ID`, `APPLE_API_KEY_P8`,
  `BUILD_CERTIFICATE_BASE64`, `P12_PASSWORD`, `PROVISIONING_PROFILE_BASE64`,
  `KEYCHAIN_PASSWORD`.

The workflow cannot be validated from this sandbox (no macOS, no Apple
credentials). It is written to the spec above and must be exercised by the user
on their first push.

## 11. Out of scope (post-MVP, listed for record)

Android, time-based schedules, accountability contacts, mentor unlock codes, web
throttling, backend sync, leaderboards. None of these influence the MVP design
above.
