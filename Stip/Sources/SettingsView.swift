import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject var vm:    StepViewModel
    @EnvironmentObject var notif: NotificationManager
    @State private var showResetAlert = false

    var body: some View {
        ZStack { Color.black.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header
                    HStack(spacing: 10) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white.opacity(0.07)).frame(width: 36, height: 36)
                                .overlay(RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 0.5))
                            Image(systemName: "diamond.fill")
                                .font(.system(size: 14, weight: .thin)).foregroundColor(.white)
                        }
                        Text("stip")
                            .font(.system(size: 26, weight: .bold)).foregroundColor(.white).kerning(-0.5)
                        Spacer()
                        Text("Settings")
                            .font(.system(size: 15, weight: .semibold)).foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.horizontal, 24).padding(.top, 12).padding(.bottom, 20)

                    // ── Health ───────────────────────────────────────────
                    sectionHeader("HEALTH")
                    VStack(spacing: 0) {
                        // Status row
                        HStack(spacing: 14) {
                            iconBox("heart.fill")
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text("Apple Health")
                                        .font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                                    Circle()
                                        .fill(vm.isAuthorized ? Color.white : Color.white.opacity(0.2))
                                        .frame(width: 6, height: 6)
                                }
                                Text(healthStatusText)
                                    .font(.system(size: 12, weight: .light)).foregroundColor(.white.opacity(0.4))
                            }
                            Spacer()
                            if !vm.isAuthorized {
                                Button {
                                    if vm.authStatus == "denied" {
                                        // Open Health app directly so user can enable Stip
                                        if let url = URL(string: "x-apple-health://"),
                                           UIApplication.shared.canOpenURL(url) {
                                            UIApplication.shared.open(url)
                                        } else {
                                            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                                        }
                                    } else {
                                        vm.requestHealthKitAuthorization()
                                    }
                                } label: {
                                    Text(vm.authStatus == "denied" ? "Open Health" : "Connect")
                                        .font(.system(size: 12, weight: .semibold)).foregroundColor(.black)
                                        .padding(.horizontal, 12).padding(.vertical, 6)
                                        .background(Capsule().fill(Color.white))
                                }
                            }
                        }
                        .padding(.vertical, 14).padding(.horizontal, 18)

                        if vm.isAuthorized {
                            Divider().background(Color.white.opacity(0.06)).padding(.horizontal, 18)
                            Button { vm.refreshAll() } label: {
                                HStack(spacing: 14) {
                                    iconBox("arrow.clockwise")
                                    Text("Refresh from Health")
                                        .font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .thin)).foregroundColor(.white.opacity(0.2))
                                }
                                .padding(.vertical, 14).padding(.horizontal, 18)
                            }.buttonStyle(.plain)
                        }
                    }
                    .glassCard().padding(.horizontal, 16).padding(.bottom, 16)

                    // ── Notifications ────────────────────────────────────
                    sectionHeader("NOTIFICATIONS")
                    VStack(spacing: 0) {
                        // Master toggle
                        HStack(spacing: 14) {
                            iconBox("bell.fill")
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Smart Notifications")
                                    .font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                                Text("All 11 smart notification types")
                                    .font(.system(size: 12, weight: .light)).foregroundColor(.white.opacity(0.4))
                            }
                            Spacer()
                            Toggle("", isOn: $notif.notificationsEnabled)
                                .labelsHidden().tint(.white)
                                .onChange(of: notif.notificationsEnabled) { enabled in
                                    if !enabled { notif.cancelAll() }
                                }
                        }
                        .padding(.vertical, 14).padding(.horizontal, 18)

                        Divider().background(Color.white.opacity(0.06)).padding(.horizontal, 18)

                        // List all notification types
                        ForEach(notificationTypes, id: \.title) { n in
                            HStack(spacing: 12) {
                                Text(n.emoji).font(.system(size: 16))
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(n.title)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(notif.notificationsEnabled ? .white : .white.opacity(0.3))
                                    Text(n.timing)
                                        .font(.system(size: 11, weight: .ultraLight))
                                        .foregroundColor(.white.opacity(0.25))
                                }
                                Spacer()
                            }
                            .padding(.vertical, 10).padding(.horizontal, 18)
                            if n.title != notificationTypes.last?.title {
                                Divider().background(Color.white.opacity(0.04)).padding(.horizontal, 18)
                            }
                        }
                    }
                    .glassCard().padding(.horizontal, 16).padding(.bottom, 16)

                    // ── Stats ────────────────────────────────────────────
                    sectionHeader("YOUR STATS")
                    VStack(spacing: 0) {
                        infoRow("figure.walk",   "Daily Goal",      "2,000 steps")
                        Divider().background(Color.white.opacity(0.06)).padding(.horizontal, 18)
                        infoRow("flame.fill",    "Current Streak",  "\(vm.streakCount) day\(vm.streakCount == 1 ? "" : "s")")
                        Divider().background(Color.white.opacity(0.06)).padding(.horizontal, 18)
                        infoRow("trophy.fill",   "Personal Best",   vm.personalBest > 0 ? "\(vm.personalBest.formatted()) steps" : "—")
                        Divider().background(Color.white.opacity(0.06)).padding(.horizontal, 18)
                        infoRow("chart.bar.fill","This Year",       vm.isAuthorized ? "\(vm.yearSteps.formatted()) steps" : "—")
                    }
                    .glassCard().padding(.horizontal, 16).padding(.bottom, 16)

                    // ── Danger ───────────────────────────────────────────
                    sectionHeader("DATA")
                    Button { showResetAlert = true } label: {
                        HStack(spacing: 14) {
                            iconBox("trash")
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Reset Streak")
                                    .font(.system(size: 14, weight: .semibold)).foregroundColor(.white.opacity(0.7))
                                Text("Clears your current streak — cannot be undone")
                                    .font(.system(size: 12, weight: .light)).foregroundColor(.white.opacity(0.3))
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .thin)).foregroundColor(.white.opacity(0.2))
                        }
                        .padding(.vertical, 14).padding(.horizontal, 18)
                        .glassCard()
                    }
                    .buttonStyle(.plain).padding(.horizontal, 16).padding(.bottom, 16)

                    VStack(spacing: 4) {
                        Text("Stip v1.0")
                            .font(.system(size: 12, weight: .light)).foregroundColor(.white.opacity(0.2))
                        Text("Steps read directly from Apple Health")
                            .font(.system(size: 11, weight: .ultraLight)).foregroundColor(.white.opacity(0.15))
                    }
                    .padding(.bottom, 120)
                }
            }
        }
        .alert("Reset Streak?", isPresented: $showResetAlert) {
            Button("Reset", role: .destructive) {
                UserDefaults.standard.set(0, forKey: "stip.streak.count")
                UserDefaults.standard.removeObject(forKey: "stip.streak.lastGoalDate")
                vm.refreshAll()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will reset your streak to 0.")
        }
    }

    // MARK: - Helpers
    private var healthStatusText: String {
        switch vm.authStatus {
        case "authorized":     return "Connected — reading steps from Health"
        case "denied":         return "Denied — tap Settings to re-enable"
        case "unavailable":    return "HealthKit not available on this device"
        default:               return "Not connected — tap Connect to grant access"
        }
    }

    private func sectionHeader(_ t: String) -> some View {
        HStack {
            Text(t).font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.4)).kerning(1.2)
            Spacer()
        }
        .padding(.horizontal, 24).padding(.bottom, 8)
    }

    private func infoRow(_ icon: String, _ title: String, _ value: String) -> some View {
        HStack(spacing: 14) {
            iconBox(icon)
            Text(title).font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
            Spacer()
            Text(value).font(.system(size: 13, weight: .light)).foregroundColor(.white.opacity(0.45))
        }
        .padding(.vertical, 14).padding(.horizontal, 18)
    }

    private func iconBox(_ sf: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.08)).frame(width: 32, height: 32)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.12), lineWidth: 0.5))
            Image(systemName: sf).font(.system(size: 13, weight: .thin)).foregroundColor(.white.opacity(0.7))
        }
    }

    private struct NotifType { let emoji: String; let title: String; let timing: String }
    private let notificationTypes: [NotifType] = [
        .init(emoji: "🌅", title: "Morning Intention",   timing: "Random 7–8:30 AM daily"),
        .init(emoji: "🚶", title: "Halfway Nudge",       timing: "When you hit 1,000 steps"),
        .init(emoji: "🥗", title: "Lunchtime Check-in",  timing: "Random 12–1:30 PM if under 800 steps"),
        .init(emoji: "🌇", title: "Evening Countdown",   timing: "Random 7–8 PM if goal not reached"),
        .init(emoji: "🔥", title: "Streak Danger",       timing: "9 PM if streak active and goal not done"),
        .init(emoji: "🎉", title: "Goal Reached",        timing: "Immediately on goal completion"),
        .init(emoji: "💪", title: "Comeback Message",    timing: "Morning after a missed day"),
        .init(emoji: "🏆", title: "Personal Best",       timing: "Immediately when record broken"),
        .init(emoji: "📊", title: "Weekly Report",       timing: "Sunday morning"),
        .init(emoji: "⭐️", title: "Milestone Badge",    timing: "At 3, 7, 14, 30, 60, 100 days"),
        .init(emoji: "🔗", title: "Rest Day Reminder",   timing: "Midday after 6+ consecutive days"),
    ]
}
