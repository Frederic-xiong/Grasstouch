# Screenshot plan

Five 6.7" iPhone screenshots, plus the same five at 6.5" and 5.5" (App Store requirements). Capture from a real device with a real `FamilyActivitySelection` so the system-rendered app rows look authentic.

| # | Screen | Caption overlay | Why |
| --- | --- | --- | --- |
| 1 | `ContentView` with throttling Off, no apps selected | "Pick the apps that pull at you" | Hero shot |
| 2 | `FamilyActivityPicker` open | "Tap the apps. iOS handles the picker." | Sets expectations about the system UI |
| 3 | `ContentView` with throttling Active, kbps readout live | "Active — 256 kbps. Videos won't load." | The mechanic |
| 4 | `DashboardView` with 7-day chart | "See your week of friction." | Habit reinforcement |
| 5 | `LockoutView` with countdown | "Disable starts a 24-hour lockout." | Commitment device |

## Capture process

1. Real device, iPhone 15 Pro Max (6.7"). Settings → Battery → enable maximum.
2. Tunnel must be active for shots 3 and 5 — open TikTok in another window first so `throttleActive` flips.
3. Use Xcode → Devices → Take Screenshot, not the simulator (the simulator can't run NetworkExtension).
4. For 6.5" and 5.5" sets, downscale via `sips -Z 1242 input.png` then re-pad to App Store dimensions, or capture on a smaller real device if available.

Drop the final PNGs in `docs/screenshots/<size>/`. Do not commit them as binary blobs to this repo — host on a private bucket or attach directly in App Store Connect.
