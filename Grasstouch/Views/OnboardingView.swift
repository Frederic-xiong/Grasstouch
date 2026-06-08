import SwiftUI
import FamilyControls

struct OnboardingView: View {
    @EnvironmentObject private var state: GrasstouchState
    @State private var pickerShown = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "tortoise.fill")
                .font(.system(size: 72))
                .foregroundStyle(.green)
            Text("Grasstouch")
                .font(.largeTitle).bold()
            Text("Slow your connection while a chosen app is open. Friction beats willpower.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)

            VStack(alignment: .leading, spacing: 12) {
                HonestRow(icon: "exclamationmark.triangle.fill",
                          tint: .orange,
                          text: "While a chosen app is open, your whole connection is throttled — not just that app. iOS does not allow per-app throttling.")
                HonestRow(icon: "lock.fill",
                          tint: .blue,
                          text: "Disabling Grasstouch starts a 24-hour lockout. You cannot re-enable until it expires.")
                HonestRow(icon: "hand.raised.fill",
                          tint: .gray,
                          text: "All data stays on your device. No accounts, no servers.")
            }
            .padding(.horizontal)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    Task {
                        await state.requestFamilyControlsAuthorization()
                        if state.familyControlsAuthorized { pickerShown = true }
                    }
                } label: {
                    Text(state.familyControlsAuthorized ? "Pick apps" : "Grant Screen Time access")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button("I'll set this up later") { state.completeOnboarding() }
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .familyActivityPicker(isPresented: $pickerShown, selection: Binding(
            get: { state.selection },
            set: { state.setSelection($0) }
        ))
        .onChange(of: pickerShown) { newValue in
            if !newValue && !state.selection.applicationTokens.isEmpty {
                state.completeOnboarding()
            }
        }
    }
}

private struct HonestRow: View {
    let icon: String
    let tint: Color
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon).foregroundStyle(tint).frame(width: 24)
            Text(text).font(.callout).foregroundStyle(.primary.opacity(0.85))
        }
    }
}
