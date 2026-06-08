import SwiftUI
import FamilyControls

struct SettingsView: View {
    @EnvironmentObject private var state: GrasstouchState
    @State private var pickerShown = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Apps") {
                    Button("Edit throttled apps") { pickerShown = true }
                    let count = state.selection.applicationTokens.count
                              + state.selection.categoryTokens.count
                    Text("\(count) selected").foregroundStyle(.secondary)
                }
                Section("Throttle level") {
                    Picker("Level", selection: Binding(
                        get: { state.throttleLevel },
                        set: { state.setLevel($0) }
                    )) {
                        ForEach(ThrottleLevel.allCases) { l in
                            Text("\(l.title) — \(l.kbps) kbps").tag(l)
                        }
                    }
                }
                Section("About") {
                    LabeledContent("Version", value: appVersion)
                    NavigationLink("How Grasstouch works") { AboutView() }
                    Link("Privacy policy",
                         destination: URL(string: "https://grasstouch.app/privacy")!)
                }
                Section {
                    Text("Grasstouch does not throttle a single app — iOS does not expose per-app traffic to App Store apps. While a chosen app is open, your whole connection is slowed.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .familyActivityPicker(isPresented: $pickerShown, selection: Binding(
                get: { state.selection },
                set: { state.setSelection($0) }
            ))
        }
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(v) (\(b))"
    }
}

private struct AboutView: View {
    var body: some View {
        ScrollView {
            Text(
"""
Grasstouch uses iOS Screen Time to know when you open a chosen app. While that app is in the foreground, an on-device VPN caps your bandwidth using a token-bucket algorithm. When you close the app, full speed returns.

No traffic leaves your device through Grasstouch. There is no Grasstouch server. All metrics, settings, and lockout state are stored locally.

Grasstouch cannot slow one app while leaving others fast — iOS does not give App Store apps that ability. The whole device gets slow while a chosen app is open.
"""
            )
            .padding()
        }
        .navigationTitle("How Grasstouch works")
    }
}
