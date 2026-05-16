import Foundation

final class StreakManager {
    private enum Key {
        static let streakCount   = "stip.streak.count"
        static let lastGoalDate  = "stip.streak.lastGoalDate"
        static let lastCheckDate = "stip.streak.lastCheckDate"
    }

    private let defaults = UserDefaults.standard
    private let calendar = Calendar.current

    var currentStreak: Int { defaults.integer(forKey: Key.streakCount) }

    func update(todaySteps: Int, goal: Int) {
        let today = calendar.startOfDay(for: Date())
        let lastCheck = defaults.object(forKey: Key.lastCheckDate) as? Date

        if let lastCheck = lastCheck {
            let dayGap = calendar.dateComponents([.day], from: lastCheck, to: today).day ?? 0
            if dayGap > 1 { resetStreak() }
        }

        defaults.set(today, forKey: Key.lastCheckDate)

        if todaySteps >= goal {
            let lastGoalDate = defaults.object(forKey: Key.lastGoalDate) as? Date
            let alreadyCounted = lastGoalDate.map { calendar.isDate($0, inSameDayAs: today) } ?? false
            if !alreadyCounted {
                defaults.set(currentStreak + 1, forKey: Key.streakCount)
                defaults.set(today, forKey: Key.lastGoalDate)
            }
        }
    }

    private func resetStreak() {
        defaults.set(0, forKey: Key.streakCount)
        defaults.removeObject(forKey: Key.lastGoalDate)
    }
}
