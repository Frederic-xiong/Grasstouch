# Xcode project setup

The source tree in this repo is complete, but `Throttle.xcodeproj` itself is not committed. A `pbxproj` written by hand is fragile and breaks on the first typo. The 5-minute manual setup below is more reliable than a generated one, and you'll only do it once.

## One-time steps

1. **Create the project.** Xcode → File → New → Project → iOS App.
   - Product Name: `Throttle`
   - Interface: SwiftUI
   - Language: Swift
   - Storage: Core Data → **uncheck** (we ship our own stack)
   - Bundle ID: `app.throttle.Throttle`
   - Minimum deployment: iOS 15.0
   - Save the project at the repo root so `Throttle.xcodeproj` sits next to `Throttle/`.

2. **Delete the boilerplate** Xcode created (`ContentView.swift`, `ThrottleApp.swift`, etc.) and **drag in** the existing `Throttle/` folder as a group (uncheck "Copy items"; check "Create groups").

3. **Add the Core Data model**: drag `Throttle/Models/Throttle.xcdatamodeld` into the project.

4. **Add a Packet Tunnel target.** File → New → Target → iOS → Network Extension → Packet Tunnel Provider.
   - Product Name: `ThrottleVPN`
   - Bundle ID: `app.throttle.Throttle.ThrottleVPN`
   - Delete the generated `PacketTunnelProvider.swift` and add the existing `ThrottleVPN/` folder.
   - Set its Info.plist to `ThrottleVPN/Info.plist` and entitlements to `ThrottleVPN/ThrottleVPN.entitlements`.

5. **Add a Device Activity Monitor target.** File → New → Target → iOS → Device Activity Monitor Extension.
   - Product Name: `ThrottleMonitor`
   - Bundle ID: `app.throttle.Throttle.ThrottleMonitor`
   - Delete generated stub, add the existing `ThrottleMonitor/` folder.
   - Wire up Info.plist and entitlements like step 4.

6. **App Groups** on all three targets: Signing & Capabilities → + Capability → App Groups → `group.app.throttle.shared`.

7. **Family Controls** on `Throttle` and `ThrottleMonitor`: + Capability → Family Controls. (Requires the entitlement granted by Apple — see README.)

8. **Network Extensions** on `ThrottleVPN`: + Capability → Network Extensions → Packet Tunnel.

9. **Embed extensions**: `Throttle` target → Build Phases → "Embed App Extensions" should include both `ThrottleVPN.appex` and `ThrottleMonitor.appex`. Xcode usually does this automatically when you add the targets.

10. **Set entitlements file paths** in Build Settings → Code Signing Entitlements for each target:
    - `Throttle` → `Throttle/Throttle.entitlements`
    - `ThrottleVPN` → `ThrottleVPN/ThrottleVPN.entitlements`
    - `ThrottleMonitor` → `ThrottleMonitor/ThrottleMonitor.entitlements`

11. **Set the main app's Info.plist path** to `Throttle/Info.plist` and add `NSLocalNetworkUsageDescription` if not already there.

12. **Pick a real device** as the run destination. The Network Extension does not run in the iOS Simulator.

13. **Commit `Throttle.xcodeproj`** once the project builds. From then on, `git pull && open Throttle.xcodeproj` is enough.

## When something is wrong

- "Could not save VPN configuration" → you haven't enabled the Network Extensions capability or your provisioning profile doesn't include `packet-tunnel-provider`.
- `FamilyActivityPicker` is blank → Family Controls authorization wasn't granted, or your developer account doesn't have the Family Controls (distribution) entitlement yet.
- The tunnel runs but speed isn't capped → check that `ThrottleMonitor` is actually firing `eventDidReachThreshold` (add a `os_log` line). Without it, `throttleActive` stays false and the tunnel passes through.
