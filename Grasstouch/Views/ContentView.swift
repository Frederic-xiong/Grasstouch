import SwiftUI
import FamilyControls

struct ContentView: View {
    @EnvironmentObject private var state: GrasstouchState
    @State private var pickerShown = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    speedCard
                    levelPicker
                    appsCard
                    enableButton
                    if let errorMessage {
                        Text(errorMessage).font(.footnote).foregroundStyle(.red)
                    }
                }
                .padding()
            }
            .navigationTitle("Grasstouch")
            .familyActivityPicker(isPresented: $pickerShown, selection: Binding(
                get: { state.selection },
                set: { state.setSelection($0) }
            ))
        }
    }

    private var speedCard: some View {
        VStack(spacing: 4) {
            Text(state.tunnelEnabled ? "Active" : "Off")
                .font(.headline)
                .foregroundStyle(state.tunnelEnabled ? .green : .secondary)
            Text(String(format: "%.0f kbps", state.currentKbpsDown))
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .monospacedDigit()
            Text("current download")
                .font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    private var levelPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Throttle level").font(.headline)
            HStack(spacing: 8) {
                ForEach(ThrottleLevel.allCases) { level in
                    LevelChip(level: level, selected: state.throttleLevel == level) {
                        state.setLevel(level)
                    }
                }
            }
            Text(state.throttleLevel.subtitle)
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private var appsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Throttled apps").font(.headline)
                Spacer()
                Button("Edit") { pickerShown = true }
                    .font(.subheadline)
            }
            let count = state.selection.applicationTokens.count + state.selection.categoryTokens.count
            if count == 0 {
                Text("No apps selected.").foregroundStyle(.secondary)
            } else {
                Text("\(count) app\(count == 1 ? "" : "s") / categories selected")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    @ViewBuilder
    private var enableButton: some View {
        if state.isLockedOut {
            NavigationLink {
                LockoutView()
            } label: {
                LockoutBanner(remaining: state.lockoutRemaining)
            }
            .buttonStyle(.plain)
        } else if state.tunnelEnabled {
            Button(role: .destructive) {
                Task { await state.disableTunnel() }
            } label: {
                Text("Disable (starts 24h lockout)").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        } else {
            Button {
                Task {
                    do {
                        try await state.enableTunnel()
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
            } label: {
                Text("Enable throttling").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(state.selection.applicationTokens.isEmpty
                      && state.selection.categoryTokens.isEmpty)
        }
    }
}

private struct LevelChip: View {
    let level: ThrottleLevel
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(level.title).font(.subheadline).bold()
                Text("\(level.kbps) kbps").font(.caption2).monospacedDigit()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(selected ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.1),
                        in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(selected ? Color.accentColor : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct LockoutBanner: View {
    let remaining: TimeInterval
    var body: some View {
        HStack {
            Image(systemName: "lock.fill")
            VStack(alignment: .leading) {
                Text("Locked").bold()
                Text(LockoutManager.formatRemaining(remaining))
                    .monospacedDigit().font(.caption)
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.orange.opacity(0.15), in: RoundedRectangle(cornerRadius: 16))
    }
}
