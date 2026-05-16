import SwiftUI
import UIKit

struct HomeView: View {
    @EnvironmentObject var vm:    StepViewModel
    @EnvironmentObject var notif: NotificationManager

    var body: some View {
        ZStack { Color.black.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    // ── Header ───────────────────────────────────────────
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
                    }
                    .padding(.horizontal, 24).padding(.top, 12).padding(.bottom, 4)

                    HStack {
                        Text(greetingText)
                            .font(.system(size: 14, weight: .light)).foregroundColor(.white.opacity(0.4))
                        Spacer()
                    }
                    .padding(.horizontal, 24).padding(.bottom, 18)

                    // ── HealthKit NOT authorized ─────────────────────────
                    if !vm.isAuthorized {
                        healthKitPrompt
                            .padding(.horizontal, 16).padding(.bottom, 16)
                    }

                    // ── Congrats banner ──────────────────────────────────
                    if vm.goalReached && vm.isAuthorized {
                        HStack(spacing: 12) {
                            Text("🎉").font(.system(size: 22))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Goal crushed! 🔥 Day \(vm.streakCount) streak!")
                                    .font(.system(size: 14, weight: .semibold)).foregroundColor(.white)
                                Text("You've walked 2,000+ steps today!")
                                    .font(.system(size: 12, weight: .light)).foregroundColor(.white.opacity(0.45))
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 18).padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 22).fill(Color.white.opacity(0.08))
                            .overlay(RoundedRectangle(cornerRadius: 22)
                                .stroke(Color.white.opacity(0.20), lineWidth: 0.5)))
                        .padding(.horizontal, 16).padding(.bottom, 14)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // ── Ring Card ────────────────────────────────────────
                    ZStack {
                        RoundedRectangle(cornerRadius: 28).fill(Color.white.opacity(0.04))
                            .overlay(RoundedRectangle(cornerRadius: 28)
                                .stroke(Color.white.opacity(0.12), lineWidth: 0.5))
                        VStack {
                            RadialGradient(colors: [Color.white.opacity(0.05), Color.clear],
                                           center: .center, startRadius: 0, endRadius: 100)
                            .frame(height: 160).offset(y: -10)
                            Spacer()
                        }.clipShape(RoundedRectangle(cornerRadius: 28))

                        CircularProgressView(
                            steps: vm.todaySteps,
                            goal:  vm.dailyGoal,
                            streak: vm.streakCount
                        )
                        .padding(.vertical, 28).padding(.horizontal, 20)
                    }
                    .padding(.horizontal, 16).padding(.bottom, 16)

                    // ── Today's Stats ────────────────────────────────────
                    HStack {
                        Text("TODAY'S STATS")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.4)).kerning(1.2)
                        Spacer()
                        if vm.isAuthorized {
                            Button { vm.refreshAll() } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 11, weight: .thin))
                                    Text("Refresh")
                                        .font(.system(size: 11, weight: .light))
                                }
                                .foregroundColor(.white.opacity(0.35))
                            }
                        }
                    }
                    .padding(.horizontal, 24).padding(.bottom, 10)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        DashboardCard(icon: "figure.walk",
                                      value: vm.isAuthorized ? vm.todaySteps.formatted() : "—",
                                      label: "Steps Today",
                                      sublabel: vm.isAuthorized ? "\(vm.percentageText) of goal" : "No access")
                        DashboardCard(icon: "calendar.badge.clock",
                                      value: vm.isAuthorized ? vm.weekSteps.formatted() : "—",
                                      label: "This Week",
                                      sublabel: "7-day total")
                        DashboardCard(icon: "calendar",
                                      value: vm.isAuthorized ? compact(vm.monthSteps) : "—",
                                      label: "This Month",
                                      sublabel: monthName)
                        DashboardCard(icon: "chart.bar.fill",
                                      value: vm.isAuthorized ? compact(vm.yearSteps) : "—",
                                      label: "This Year",
                                      sublabel: "\(currentYear)")
                    }
                    .padding(.horizontal, 16).padding(.bottom, 16)
                    .animation(.easeInOut(duration: 0.5), value: vm.todaySteps)

                    // Personal best badge
                    if vm.isAuthorized && vm.personalBest > 0 {
                        HStack(spacing: 12) {
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 16, weight: .thin)).foregroundColor(.white.opacity(0.5))
                            Text("Personal best: \(vm.personalBest.formatted()) steps")
                                .font(.system(size: 13, weight: .light)).foregroundColor(.white.opacity(0.5))
                            Spacer()
                        }
                        .padding(.horizontal, 24).padding(.bottom, 16)
                    }

                    Spacer(minLength: 110)
                }
            }
        }
        .animation(.easeInOut(duration: 0.4), value: vm.goalReached)
        .animation(.easeInOut(duration: 0.4), value: vm.isAuthorized)
    }

    // MARK: - HealthKit Prompt
    private var healthKitPrompt: some View {
        VStack(spacing: 16) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.08))
                        .frame(width: 44, height: 44)
                        .overlay(RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.15), lineWidth: 0.5))
                    Image(systemName: "heart.fill")
                        .font(.system(size: 18, weight: .thin)).foregroundColor(.white.opacity(0.7))
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("Connect Apple Health")
                        .font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                    Text(vm.authStatus == "denied"
                         ? "Access denied — open Settings → Privacy → Health → Stip"
                         : "Stip needs access to read your step count")
                        .font(.system(size: 12, weight: .light)).foregroundColor(.white.opacity(0.4))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
            }

            // Only show the button if not denied (denied requires going to Settings)
            if vm.authStatus != "denied" {
                Button {
                    vm.requestHealthKitAuthorization()
                } label: {
                    HStack {
                        Spacer()
                        Text("Grant Access to Health App")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.black)
                        Spacer()
                    }
                    .padding(.vertical, 13)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
                }
            } else {
                Button {
                    // Open Settings app
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack {
                        Spacer()
                        Text("Open Settings")
                            .font(.system(size: 14, weight: .semibold)).foregroundColor(.black)
                        Spacer()
                    }
                    .padding(.vertical, 13)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
                }
            }
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 22).fill(Color.white.opacity(0.05))
            .overlay(RoundedRectangle(cornerRadius: 22)
                .stroke(Color.white.opacity(0.15), lineWidth: 0.5)))
    }

    // MARK: - Helpers
    private var greetingText: String {
        let f = DateFormatter(); f.dateFormat = "EEEE, MMM d"
        let h = Calendar.current.component(.hour, from: Date())
        let mood = h < 12 ? "Good morning!" : h < 17 ? "Good afternoon!" : h < 21 ? "Good evening!" : "Keep going!"
        return "\(f.string(from: Date())) · \(mood)"
    }
    private var monthName: String { let f = DateFormatter(); f.dateFormat = "MMMM"; return f.string(from: Date()) }
    private var currentYear: Int  { Calendar.current.component(.year, from: Date()) }
    private func compact(_ n: Int) -> String {
        if n >= 1_000_000 { return String(format: "%.1fM", Double(n)/1_000_000) }
        if n >= 1_000     { return String(format: "%.1fK", Double(n)/1_000) }
        return "\(n)"
    }
}
