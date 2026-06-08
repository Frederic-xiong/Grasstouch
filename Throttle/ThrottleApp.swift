import SwiftUI

@main
struct ThrottleApp: App {
    @StateObject private var state = ThrottleState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(state)
                .environment(\.managedObjectContext, CoreDataStack.shared.viewContext)
                .task { await state.bootstrap() }
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var state: ThrottleState

    var body: some View {
        if !state.hasCompletedOnboarding {
            OnboardingView()
        } else {
            TabView {
                ContentView()
                    .tabItem { Label("Throttle", systemImage: "tortoise.fill") }
                DashboardView()
                    .tabItem { Label("Dashboard", systemImage: "chart.bar.fill") }
                SettingsView()
                    .tabItem { Label("Settings", systemImage: "gearshape.fill") }
            }
        }
    }
}
