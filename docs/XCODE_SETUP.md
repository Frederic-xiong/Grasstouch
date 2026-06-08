# Xcode project setup

The Xcode project is generated from `project.yml` by [XcodeGen](https://github.com/yonki/xcodegen). It is not committed; one command after clone produces it.

## First time on a new Mac

```bash
brew install xcodegen
make project          # runs `xcodegen generate`
open Throttle.xcodeproj
```

That's it — all three targets, embedded extensions, App Groups, Family Controls, and Network Extensions capabilities are wired by the spec.

## After pulling changes

If `project.yml` changed, re-run `make project`. Otherwise the existing `.xcodeproj` is fine.

## What still needs your developer account

- Set `DEVELOPMENT_TEAM` before generating, or set it once in Xcode → Signing & Capabilities after generation: `DEVELOPMENT_TEAM=ABCD123456 make project`.
- The Family Controls entitlement on `Throttle` and `ThrottleMonitor` requires Apple to grant the distribution entitlement to your team — request it at <https://developer.apple.com/contact/request/family-controls-distribution> before TestFlight.
- A real device is required to run — NetworkExtension does not run in the iOS Simulator.

## Troubleshooting

- **"Could not save VPN configuration"** → Network Extensions capability or `packet-tunnel-provider` entitlement is missing from the provisioning profile.
- **`FamilyActivityPicker` is blank** → Family Controls authorization not granted, or the distribution entitlement hasn't been granted by Apple.
- **Tunnel runs but speed isn't capped** → `ThrottleMonitor` isn't firing `eventDidReachThreshold`. Add an `os_log` line and check the device console. Without it, `throttleActive` stays false and the tunnel passes through at line rate.
