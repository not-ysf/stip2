import SwiftUI

struct StreaksView: View {
    @EnvironmentObject var vm: StepViewModel

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
                        Text("Streaks")
                            .font(.system(size: 15, weight: .semibold)).foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.horizontal, 24).padding(.top, 12).padding(.bottom, 20)

                    // Big streak hero
                    streakHero
                        .padding(.horizontal, 16).padding(.bottom, 20)

                    // Today's status
                    HStack {
                        Text("TODAY")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.4)).kerning(1.2)
                        Spacer()
                    }.padding(.horizontal, 24).padding(.bottom, 10)

                    todayStatusCard
                        .padding(.horizontal, 16).padding(.bottom, 20)

                    // 7-day dot map
                    HStack {
                        Text("LAST 7 DAYS")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.4)).kerning(1.2)
                        Spacer()
                    }.padding(.horizontal, 24).padding(.bottom, 10)

                    weekDotGrid
                        .padding(.horizontal, 16).padding(.bottom, 20)

                    // Milestones
                    HStack {
                        Text("MILESTONES")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.4)).kerning(1.2)
                        Spacer()
                    }.padding(.horizontal, 24).padding(.bottom, 10)

                    milestonesCard
                        .padding(.horizontal, 16).padding(.bottom, 20)

                    Spacer(minLength: 110)
                }
            }
        }
    }

    // MARK: - Streak Hero
    private var streakHero: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28).fill(Color.white.opacity(0.04))
                .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color.white.opacity(0.10), lineWidth: 0.5))

            // Glow
            if vm.streakCount > 0 {
                RadialGradient(colors: [Color.white.opacity(0.06), Color.clear],
                               center: .center, startRadius: 0, endRadius: 120)
                .clipShape(RoundedRectangle(cornerRadius: 28))
            }

            VStack(spacing: 10) {
                // Big flame icon
                ZStack {
                    Circle().fill(Color.white.opacity(0.06)).frame(width: 80, height: 80)
                        .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 0.5))
                    Image(systemName: "flame.fill")
                        .font(.system(size: 36, weight: .thin))
                        .foregroundColor(vm.streakCount > 0 ? .white : .white.opacity(0.25))
                }
                .padding(.top, 28)

                if #available(iOS 16.0, *) {
                    Text("\(vm.streakCount)")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.5), value: vm.streakCount)
                } else {
                    Text("\(vm.streakCount)")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .animation(.easeInOut(duration: 0.5), value: vm.streakCount)
                }

                Text(vm.streakCount == 1 ? "day streak" : "day streak")
                    .font(.system(size: 16, weight: .light))
                    .foregroundColor(.white.opacity(0.45))
                    .kerning(0.5)

                Text(vm.streakCount == 0
                     ? "Hit 2,000 steps today to start!"
                     : vm.goalReached
                        ? "Goal reached today! Keep going 🔥"
                        : "Walk \(max(0, vm.dailyGoal - vm.todaySteps).formatted()) more steps to extend!")
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(.white.opacity(0.35))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 28)
            }
        }
    }

    // MARK: - Today Status
    private var todayStatusCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(vm.goalReached ? Color.white : Color.white.opacity(0.06))
                    .frame(width: 48, height: 48)
                    .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 0.5))
                Image(systemName: vm.goalReached ? "checkmark" : "figure.walk")
                    .font(.system(size: 18, weight: vm.goalReached ? .semibold : .thin))
                    .foregroundColor(vm.goalReached ? .black : .white.opacity(0.5))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(vm.goalReached ? "Goal Reached! 🎉" : "In Progress")
                    .font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                Text("\(vm.todaySteps.formatted()) of \(vm.dailyGoal.formatted()) steps")
                    .font(.system(size: 13, weight: .light)).foregroundColor(.white.opacity(0.4))
            }

            Spacer()

            Text(vm.percentageText)
                .font(.system(size: 22, weight: .bold, design: .rounded)).foregroundColor(.white)
        }
        .padding(20).glassCard()
    }

    // MARK: - Week Dot Grid
    private var weekDotGrid: some View {
        VStack(spacing: 14) {
            HStack(spacing: 8) {
                ForEach(Array(vm.weekDaily.enumerated()), id: \.offset) { _, day in
                    VStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(day.goalReached ? Color.white : Color.white.opacity(0.06))
                                .frame(width: 38, height: 38)
                                .overlay(RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(day.isToday ? 0.4 : 0.08), lineWidth: day.isToday ? 1 : 0.5))
                            Image(systemName: day.goalReached ? "checkmark" : (day.isToday ? "circle" : "xmark"))
                                .font(.system(size: 13, weight: day.goalReached ? .semibold : .ultraLight))
                                .foregroundColor(day.goalReached ? .black : .white.opacity(day.isToday ? 0.6 : 0.2))
                        }
                        Text(day.day)
                            .font(.system(size: 10, weight: .light))
                            .foregroundColor(.white.opacity(day.isToday ? 0.8 : 0.3))
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            // Legend
            HStack(spacing: 16) {
                legendDot(.white, "Goal hit")
                legendDot(.white.opacity(0.15), "Missed")
                Spacer()
            }
        }
        .padding(20).glassCard()
    }

    private func legendDot(_ color: Color, _ label: String) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 3).fill(color).frame(width: 10, height: 10)
            Text(label).font(.system(size: 11, weight: .light)).foregroundColor(.white.opacity(0.3))
        }
    }

    // MARK: - Milestones
    private var milestonesCard: some View {
        VStack(spacing: 0) {
            ForEach(milestones, id: \.days) { m in
                let reached = vm.streakCount >= m.days
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(reached ? Color.white : Color.white.opacity(0.05))
                            .frame(width: 40, height: 40)
                            .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 0.5))
                        Text(m.emoji).font(.system(size: 18))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(m.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(reached ? .white : .white.opacity(0.4))
                        Text("\(m.days) days")
                            .font(.system(size: 11, weight: .light))
                            .foregroundColor(.white.opacity(0.25))
                    }
                    Spacer()
                    if reached {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18, weight: .thin))
                            .foregroundColor(.white.opacity(0.7))
                    } else {
                        Text("\(m.days - vm.streakCount)d left")
                            .font(.system(size: 11, weight: .light))
                            .foregroundColor(.white.opacity(0.2))
                    }
                }
                .padding(.vertical, 14)

                if m.days != milestones.last?.days {
                    Rectangle().fill(Color.white.opacity(0.06)).frame(height: 0.5)
                }
            }
        }
        .padding(.horizontal, 20).glassCard()
    }

    private struct Milestone { let days: Int; let title: String; let emoji: String }
    private let milestones: [Milestone] = [
        .init(days: 3,   title: "Getting Started",  emoji: "🌱"),
        .init(days: 7,   title: "One Week",          emoji: "⭐️"),
        .init(days: 14,  title: "Two Weeks",         emoji: "🔥"),
        .init(days: 30,  title: "One Month",         emoji: "🏆"),
        .init(days: 60,  title: "Two Months",        emoji: "💎"),
        .init(days: 100, title: "100 Days",          emoji: "👑"),
    ]
}
