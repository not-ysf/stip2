import SwiftUI

// MARK: - Root with Tab Navigation
struct ContentView: View {
    @EnvironmentObject var vm:    StepViewModel
    @EnvironmentObject var notif: NotificationManager
    @State private var selectedTab: Tab = .home

    enum Tab { case home, stats, streaks, settings }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.ignoresSafeArea()

            Group {
                switch selectedTab {
                case .home:     HomeView()
                case .stats:    StatsView()
                case .streaks:  StreaksView()
                case .settings: SettingsView()
                }
            }
            .environmentObject(vm)
            .environmentObject(notif)

            tabBar
        }
        .onAppear { vm.refreshAll() }
        .onReceive(
            NotificationCenter.default.publisher(
                for: UIApplication.willEnterForegroundNotification)
        ) { _ in vm.refreshAll() }
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            tabBtn(.home,     "house.fill", "Home")
            tabBtn(.stats,    "chart.bar",  "Stats")
            tabBtn(.streaks,  "flame",      "Streaks")
            tabBtn(.settings, "gearshape",  "Settings")
        }
        .padding(.top, 12).padding(.bottom, 28).frame(maxWidth: .infinity)
        .background(
            Rectangle().fill(.ultraThinMaterial).ignoresSafeArea(edges: .bottom)
                .overlay(Rectangle().frame(height: 0.5)
                    .foregroundColor(Color.white.opacity(0.12)), alignment: .top)
        )
    }

    private func tabBtn(_ tab: Tab, _ icon: String, _ label: String) -> some View {
        let active = selectedTab == tab
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) { selectedTab = tab }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: active ? .semibold : .ultraLight))
                    .foregroundColor(active ? .white : .white.opacity(0.35))
                Text(label)
                    .font(.system(size: 10, weight: active ? .medium : .light))
                    .foregroundColor(active ? .white : .white.opacity(0.35))
                    .kerning(0.3)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}
