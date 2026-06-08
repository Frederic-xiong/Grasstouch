# Grasstouch Privacy Policy

**Effective date:** 2026-06-08

## TL;DR

Grasstouch keeps everything on your device. There is no Grasstouch account, no Grasstouch server, no analytics SDK, and no data sold or shared.

## What Grasstouch stores, and where

| Data | Where it lives | Why |
| --- | --- | --- |
| Your app selection (opaque Screen Time tokens) | On-device App Group container | So Grasstouch knows which apps to react to |
| Grasstouch level (256 / 1000 / 5000 kbps) | On-device App Group container | Configures the bandwidth cap |
| Session history (start/end times, level, byte counts) | On-device Core Data store | Powers the 7-day dashboard |
| Lockout expiry timestamp | On-device App Group container | Enforces the 24-hour disable lockout |

Grasstouch does not collect: your name, email, IP address, location, contacts, identifiers for advertisers, or the names/icons of the apps you select. The Screen Time framework returns opaque tokens; Grasstouch never sees bundle identifiers.

## What the VPN does

Grasstouch installs a local VPN profile so it can pace your traffic. The tunnel is on-device only — there is no remote Grasstouch server. Packets are read, optionally delayed by a token-bucket bandwidth limiter, and written back. No traffic is logged or sent to us.

## Permissions Grasstouch requests

- **Screen Time / Family Controls** — to know when a selected app comes to the foreground.
- **VPN configuration** — to engage the on-device bandwidth limiter.
- **Local Network** — to measure bytes through the tunnel for the speed display.

Grasstouch does **not** request: notifications, App Tracking Transparency, location, photos, contacts, or microphone.

## Children

Grasstouch is not directed at children under 13 and does not knowingly collect their information.

## Third parties

None. Grasstouch has no third-party SDKs.

## Changes

If this policy changes, the updated version will ship in a future app update and the effective date above will change.

## Contact

freddyxiong02@gmail.com
