# Throttle Privacy Policy

**Effective date:** 2026-06-08

## TL;DR

Throttle keeps everything on your device. There is no Throttle account, no Throttle server, no analytics SDK, and no data sold or shared.

## What Throttle stores, and where

| Data | Where it lives | Why |
| --- | --- | --- |
| Your app selection (opaque Screen Time tokens) | On-device App Group container | So Throttle knows which apps to react to |
| Throttle level (256 / 1000 / 5000 kbps) | On-device App Group container | Configures the bandwidth cap |
| Session history (start/end times, level, byte counts) | On-device Core Data store | Powers the 7-day dashboard |
| Lockout expiry timestamp | On-device App Group container | Enforces the 24-hour disable lockout |

Throttle does not collect: your name, email, IP address, location, contacts, identifiers for advertisers, or the names/icons of the apps you select. The Screen Time framework returns opaque tokens; Throttle never sees bundle identifiers.

## What the VPN does

Throttle installs a local VPN profile so it can pace your traffic. The tunnel is on-device only — there is no remote Throttle server. Packets are read, optionally delayed by a token-bucket bandwidth limiter, and written back. No traffic is logged or sent to us.

## Permissions Throttle requests

- **Screen Time / Family Controls** — to know when a selected app comes to the foreground.
- **VPN configuration** — to engage the on-device bandwidth limiter.
- **Local Network** — to measure bytes through the tunnel for the speed display.

Throttle does **not** request: notifications, App Tracking Transparency, location, photos, contacts, or microphone.

## Children

Throttle is not directed at children under 13 and does not knowingly collect their information.

## Third parties

None. Throttle has no third-party SDKs.

## Changes

If this policy changes, the updated version will ship in a future app update and the effective date above will change.

## Contact

freddyxiong02@gmail.com
