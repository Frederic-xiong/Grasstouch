import SwiftUI

struct LockoutView: View {
    @EnvironmentObject private var state: GrasstouchState
    @State private var now = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.fill")
                .font(.system(size: 64))
                .foregroundStyle(.orange)
            Text("Locked out").font(.title2).bold()
            Text("You disabled Grasstouch. To re-enable, wait out the 24-hour lockout.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)
            Text(LockoutManager.formatRemaining(state.lockoutRemaining))
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .monospacedDigit()
            if let until = state.lockoutUntil {
                Text("Unlocks at \(until.formatted(date: .omitted, time: .shortened))")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.top, 40)
        .onReceive(timer) { _ in now = Date() }
        .navigationTitle("Lockout")
    }
}
