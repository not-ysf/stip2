import SwiftUI

// MARK: - Stat Card
struct DashboardCard: View {
    let icon:     String
    let value:    String
    let label:    String
    let sublabel: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .thin))
                .foregroundColor(.white.opacity(0.55))
                .padding(.bottom, 14)

            Spacer()

            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(label)
                .font(.system(size: 12, weight: .light))
                .foregroundColor(.white.opacity(0.6))
                .padding(.top, 3)

            Text(sublabel)
                .font(.system(size: 11, weight: .ultraLight))
                .foregroundColor(.white.opacity(0.28))
                .padding(.top, 2)
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 128, alignment: .leading)
        .glassCard()
    }
}

// MARK: - Week Bar Chart
struct WeekBarCard: View {
    let days: [DaySteps]
    let goal: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("THIS WEEK")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.4))
                .kerning(1.2)

            HStack(alignment: .bottom, spacing: 8) {
                let maxSteps = max((days.map { $0.steps }.max() ?? goal), goal)
                ForEach(days) { day in
                    let h = max(4, CGFloat(day.steps) / CGFloat(maxSteps) * 72)
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(barColor(day))
                            .frame(height: h)
                            .animation(.interpolatingSpring(stiffness: 180, damping: 18), value: h)
                        Text(day.day)
                            .font(.system(size: 10, weight: .light))
                            .foregroundColor(.white.opacity(day.isToday ? 0.9 : 0.35))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 84, alignment: .bottom)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .glassCard()
    }

    private func barColor(_ day: DaySteps) -> Color {
        if day.goalReached { return .white }
        if day.isToday     { return .white.opacity(0.45) }
        return .white.opacity(0.12)
    }
}

// MARK: - Streak Dots Card
struct StreakDotsCard: View {
    let streak:    Int
    let todayDone: Bool
    private let total = 7

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("🔗 Streak")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Text("\(streak) day\(streak == 1 ? "" : "s")")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.white))
            }

            HStack(spacing: 6) {
                ForEach(0..<total, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(dotColor(i))
                        .frame(maxWidth: .infinity)
                        .frame(height: 6)
                        .animation(.easeInOut(duration: 0.4).delay(Double(i) * 0.05), value: streak)
                }
            }

            Text(todayDone
                 ? "Amazing! Streak extended to \(streak) day\(streak == 1 ? "" : "s")! 🔥"
                 : "Hit 2,000 steps today to extend your streak to \(streak + 1)!")
                .font(.system(size: 12, weight: .ultraLight))
                .foregroundColor(.white.opacity(0.35))
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .glassCard()
    }

    private func dotColor(_ i: Int) -> Color {
        let completed = min(streak, total)
        if i < completed  { return .white }
        if i == completed { return todayDone ? .white : .white.opacity(0.45) }
        return .white.opacity(0.12)
    }
}

// MARK: - Glass Card Modifier
struct GlassCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color.white.opacity(0.04))
                    .overlay(RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.white.opacity(0.10), lineWidth: 0.5))
            )
    }
}

extension View {
    func glassCard() -> some View { modifier(GlassCard()) }
}
