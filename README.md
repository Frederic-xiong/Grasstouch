# Grasstouch

iOS app that slows your connection while a chosen addictive app is in the foreground, so you stop reaching for it. Honest about what iOS allows — see [ARCHITECTURE.md](./ARCHITECTURE.md).

## What it actually does

- You pick apps through the system Screen Time picker (`FamilyActivityPicker`).
- When one of those apps is open, Grasstouch engages a token-bucket bandwidth cap (256 kbps / 1 Mbps / 5 Mbps) on the device's connection via an on-device VPN tunnel.
- When you close the app, full speed returns.
- Disabling Grasstouch starts a 24-hour lockout. You can't re-enable until it expires.

It does **not** throttle one app while leaving others at full speed — iOS does not expose per-process packet attribution to App Store apps. The whole device gets slow while the chosen app is up.

## Requirements

- iOS 15+ (Family Controls / ManagedSettings / DeviceActivity require it)
- Xcode 15+
- Apple Developer account
- **Family Controls entitlement** — request via the [developer portal](https://developer.apple.com/contact/request/family-controls-distribution) *before* TestFlight. Apple gates this.

## Project layout

See [ARCHITECTURE.md §3](./ARCHITECTURE.md#3-components). Targets:

- `Grasstouch` — main SwiftUI app
- `GrasstouchVPN` — packet tunnel network extension
- `GrasstouchMonitor` — DeviceActivityMonitor extension

All three share App Group `group.app.grasstouch.shared`.

## Building locally

The Xcode project is generated from [`project.yml`](./project.yml) by [XcodeGen](https://github.com/yonkov/XcodeGen). It is not committed.

```bash
brew install xcodegen
make project          # runs xcodegen generate
open Grasstouch.xcodeproj
# select a real device — NetworkExtension does not run in the simulator
# Cmd+R
```

Set your dev team once, either by exporting `DEVELOPMENT_TEAM=ABCD123456` before `make project`, or in Xcode → Signing & Capabilities after opening. Targets, embedded extensions, App Groups, Family Controls, and Network Extensions are wired by the spec — no manual capability clicks. Full notes in [docs/XCODE_SETUP.md](./docs/XCODE_SETUP.md).

## CI / TestFlight

Push to `main` triggers `.github/workflows/build.yml`, which archives and uploads to TestFlight on a `macos-14` runner. Required secrets:

| Secret | What it is |
| --- | --- |
| `APPLE_API_KEY_ID` | App Store Connect API key ID |
| `APPLE_API_ISSUER_ID` | ASC API issuer ID |
| `APPLE_API_KEY_P8` | The `.p8` file contents |
| `BUILD_CERTIFICATE_BASE64` | base64'd distribution `.p12` |
| `P12_PASSWORD` | password for the `.p12` |
| `PROVISIONING_PROFILE_BASE64` | base64'd `.mobileprovision` for the app |
| `PROVISIONING_PROFILE_VPN_BASE64` | base64'd `.mobileprovision` for the VPN extension |
| `PROVISIONING_PROFILE_MONITOR_BASE64` | base64'd `.mobileprovision` for the monitor extension |
| `KEYCHAIN_PASSWORD` | any string, used to unlock the temporary keychain |

The workflow has not been exercised end-to-end from this repo — it is written to the spec in ARCHITECTURE.md §10 and will need its first run on a real macOS runner.

## Privacy

All data stays on device. The VPN is on-device loopback; no traffic leaves through Grasstouch's servers (there are no Grasstouch servers). Full statement: [docs/PRIVACY_POLICY.md](./docs/PRIVACY_POLICY.md).
