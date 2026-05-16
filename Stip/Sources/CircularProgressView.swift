import SwiftUI

struct CircularProgressView: View {
    let steps:  Int
    let goal:   Int
    let streak: Int

    private var progress: Double { min(Double(steps) / Double(goal), 1.0) }
    private var remaining: Int   { max(0, goal - steps) }
    private var goalReached: Bool { steps >= goal }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 16)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.8), value: progress)

                VStack(spacing: 5) {
                    Text(steps.formatted())
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .animation(.easeInOut(duration: 0.5), value: steps)

                    Text("STEPS")
                        .font(.system(size: 11, weight: .light))
                        .foregroundColor(.white.opacity(0.4))
                        .kerning(2)

                    Text("of \(goal.formatted())")
                        .font(.system(size: 11, weight: .ultraLight))
                        .foregroundColor(.white.opacity(0.28))
                }
            }
            .frame(width: 200, height: 200)
            .padding(.bottom, 24)

            HStack(spacing: 0) {
                statCell("\(Int(progress * 100))%", "Done")
                divider
                statCell(remaining.formatted(), "Left")
                divider
                statCell(goalReached ? "🔥 \(streak)d" : "2K", goalReached ? "Streak" : "Goal")
            }
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.12))
            .frame(width: 0.5, height: 36)
            .padding(.horizontal, 20)
    }

    private func statCell(_ value: String, _ label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 11, weight: .light))
                .foregroundColor(.white.opacity(0.4))
                .kerning(0.5)
        }
    }
}
