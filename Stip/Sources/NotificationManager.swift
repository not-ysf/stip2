import Foundation
import UserNotifications

final class NotificationManager: ObservableObject {

    static let shared = NotificationManager()

    @Published var notificationsEnabled: Bool = true

    private let center   = UNUserNotificationCenter.current()
    private let defaults = UserDefaults.standard

    // Notification IDs
    private enum ID {
        static let morning      = "stip.morning"
        static let halfway      = "stip.halfway"
        static let lunchtime    = "stip.lunchtime"
        static let evening      = "stip.evening"
        static let streakDanger = "stip.streakDanger"
        static let congrats     = "stip.congrats"
        static let comeback     = "stip.comeback"
        static let personalBest = "stip.personalBest"
        static let weeklyReport = "stip.weeklyReport"
        static let milestone    = "stip.milestone"
        static let restDay      = "stip.restDay"
    }

    // UserDefaults keys to prevent duplicate fires
    private enum Fired {
        static let halfwayDate    = "stip.fired.halfway"
        static let congratsDate   = "stip.fired.congrats"
        static let personalBest   = "stip.fired.personalBest"
        static let milestoneStreak = "stip.fired.milestone"
        static let weeklyReport   = "stip.fired.weeklyReport"
        static let comebackDate   = "stip.fired.comeback"
        static let morningDate    = "stip.fired.morning"
    }

    // MARK: - Permission
    func requestPermission() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, _ in
            DispatchQueue.main.async { self?.notificationsEnabled = granted }
        }
    }

    // MARK: - Master evaluator — called every time step data refreshes
    func evaluateAndSchedule(
        todaySteps:     Int,
        yesterdaySteps: Int,
        goal:           Int,
        streakCount:    Int,
        personalBest:   Int,
        weekDaily:      [DaySteps]
    ) {
        guard notificationsEnabled else { return }

        let cal   = Calendar.current
        let today = cal.startOfDay(for: Date())
        let hour  = cal.component(.hour, from: Date())

        // 1. Morning intention (7–8:30 AM, once per day)
        scheduleMorningIfNeeded(yesterdaySteps: yesterdaySteps, today: today)

        // 2. Halfway nudge (fires immediately when crossing 50%)
        scheduleHalfwayIfNeeded(todaySteps: todaySteps, goal: goal, today: today)

        // 3. Lunchtime check-in (12–1:30 PM, only if under 800 steps)
        scheduleLunchtimeIfNeeded(todaySteps: todaySteps, today: today)

        // 4. Evening countdown (7–8 PM, only if goal not reached)
        if !goalReached(todaySteps, goal) {
            scheduleEveningIfNeeded(todaySteps: todaySteps, goal: goal, today: today)
        }

        // 5. Streak danger (9 PM, only if streak > 0 and goal not done)
        if streakCount > 0 && !goalReached(todaySteps, goal) {
            scheduleStreakDangerIfNeeded(stepsLeft: goal - todaySteps, streakCount: streakCount, today: today)
        }

        // 6. Congrats (immediate, once per day when goal reached)
        if goalReached(todaySteps, goal) {
            scheduleCongratsIfNeeded(streakCount: streakCount, today: today)
            // Cancel any pending reminders — goal is done
            cancelPending(ids: [ID.lunchtime, ID.evening, ID.streakDanger])
        }

        // 7. Comeback (morning after a missed day)
        if yesterdaySteps < goal && yesterdaySteps > 0 {
            scheduleComebackIfNeeded(streakCount: streakCount, today: today)
        }

        // 8. Personal best (immediate when broken)
        if todaySteps > personalBest && todaySteps > 0 {
            schedulePersonalBestIfNeeded(steps: todaySteps, today: today)
        }

        // 9. Weekly report (Sunday 10–11 AM)
        let weekday = cal.component(.weekday, from: Date())
        if weekday == 1 && hour >= 10 {
            scheduleWeeklyReportIfNeeded(weekDaily: weekDaily, today: today)
        }

        // 10. Milestone celebration
        scheduleMilestoneIfNeeded(streakCount: streakCount)

        // 11. Rest day reminder (after 6+ consecutive days, midday)
        if streakCount >= 6 {
            scheduleRestDayIfNeeded(streakCount: streakCount, today: today)
        }
    }

    // MARK: - 1. Morning Intention
    private func scheduleMorningIfNeeded(yesterdaySteps: Int, today: Date) {
        let lastFired = defaults.object(forKey: Fired.morningDate) as? Date
        guard !(lastFired.map { Calendar.current.isDate($0, inSameDayAs: today) } ?? false) else { return }

        let content = UNMutableNotificationContent()
        content.title = "Good morning 👋"
        content.body  = yesterdaySteps >= 2000
            ? "Yesterday: \(yesterdaySteps.formatted()) steps. Today's goal: 2,000. Keep it up!"
            : "New day, fresh start. Goal: 2,000 steps. You've got this."
        content.sound = .default

        // Random between 7:00 and 8:30 AM
        var comps = DateComponents()
        comps.hour   = 7
        comps.minute = Int.random(in: 0...90)
        if comps.minute! > 59 { comps.hour = 8; comps.minute = comps.minute! - 60 }

        schedule(id: ID.morning, content: content,
                 trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: false))
        defaults.set(today, forKey: Fired.morningDate)
    }

    // MARK: - 2. Halfway Nudge
    private func scheduleHalfwayIfNeeded(todaySteps: Int, goal: Int, today: Date) {
        guard todaySteps >= goal / 2 else { return }
        guard todaySteps < goal else { return }  // don't fire if already done
        let lastFired = defaults.object(forKey: Fired.halfwayDate) as? Date
        guard !(lastFired.map { Calendar.current.isDate($0, inSameDayAs: today) } ?? false) else { return }

        let content = UNMutableNotificationContent()
        content.title = "Halfway there! 🚶"
        content.body  = "\(todaySteps.formatted()) steps down, \((goal - todaySteps).formatted()) to go. A 10-min walk finishes it."
        content.sound = .default

        schedule(id: ID.halfway, content: content,
                 trigger: UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false))
        defaults.set(today, forKey: Fired.halfwayDate)
    }

    // MARK: - 3. Lunchtime Check-in
    private func scheduleLunchtimeIfNeeded(todaySteps: Int, today: Date) {
        guard todaySteps < 800 else { return }
        // Only schedule if it hasn't been scheduled today yet
        center.getPendingNotificationRequests { [weak self] pending in
            guard let self else { return }
            let alreadyPending = pending.contains { $0.identifier == ID.lunchtime }
            guard !alreadyPending else { return }

            let content = UNMutableNotificationContent()
            content.title = "Midday check-in 🥗"
            content.body  = todaySteps == 0
                ? "No steps recorded yet today. An afternoon walk would get you started!"
                : "Only \(todaySteps.formatted()) steps so far. A lunch walk would get you most of the way."
            content.sound = .default

            var comps = DateComponents()
            comps.hour   = 12
            comps.minute = Int.random(in: 0...89)
            if comps.minute! > 59 { comps.hour = 13; comps.minute = comps.minute! - 60 }

            self.schedule(id: ID.lunchtime, content: content,
                          trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: false))
        }
    }

    // MARK: - 4. Evening Countdown
    private func scheduleEveningIfNeeded(todaySteps: Int, goal: Int, today: Date) {
        center.getPendingNotificationRequests { [weak self] pending in
            guard let self else { return }
            let alreadyPending = pending.contains { $0.identifier == ID.evening }
            guard !alreadyPending else { return }

            let left = goal - todaySteps
            let content = UNMutableNotificationContent()
            content.title = "Evening push 🌇"
            content.body  = "\(left.formatted()) steps before bed. That's about \(left / 100 + 1) minutes of walking."
            content.sound = .default

            var comps = DateComponents()
            comps.hour   = 19
            comps.minute = Int.random(in: 0...59)

            self.schedule(id: ID.evening, content: content,
                          trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: false))
        }
    }

    // MARK: - 5. Streak Danger
    private func scheduleStreakDangerIfNeeded(stepsLeft: Int, streakCount: Int, today: Date) {
        center.getPendingNotificationRequests { [weak self] pending in
            guard let self else { return }
            let alreadyPending = pending.contains { $0.identifier == ID.streakDanger }
            guard !alreadyPending else { return }

            let content = UNMutableNotificationContent()
            content.title = "Streak in danger! 🔥"
            content.body  = "Your \(streakCount)-day streak ends tonight. \(stepsLeft.formatted()) steps left — you can do this."
            content.sound = .default

            var comps = DateComponents()
            comps.hour   = 21
            comps.minute = Int.random(in: 0...29)

            self.schedule(id: ID.streakDanger, content: content,
                          trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: false))
        }
    }

    // MARK: - 6. Congrats
    private func scheduleCongratsIfNeeded(streakCount: Int, today: Date) {
        let lastFired = defaults.object(forKey: Fired.congratsDate) as? Date
        guard !(lastFired.map { Calendar.current.isDate($0, inSameDayAs: today) } ?? false) else { return }

        let content = UNMutableNotificationContent()
        content.title = "Goal reached! 🎉"
        content.body  = streakCount > 1
            ? "You're on a \(streakCount)-day streak! Amazing work."
            : "You hit 2,000 steps today! Great start — keep it going tomorrow."
        content.sound = .default

        schedule(id: ID.congrats, content: content,
                 trigger: UNTimeIntervalNotificationTrigger(timeInterval: 4, repeats: false))
        defaults.set(today, forKey: Fired.congratsDate)
    }

    // MARK: - 7. Comeback
    private func scheduleComebackIfNeeded(streakCount: Int, today: Date) {
        let lastFired = defaults.object(forKey: Fired.comebackDate) as? Date
        guard !(lastFired.map { Calendar.current.isDate($0, inSameDayAs: today) } ?? false) else { return }

        let content = UNMutableNotificationContent()
        content.title = "Back at it 💪"
        content.body  = streakCount > 0
            ? "You missed yesterday, but your streak is intact. Today is what matters."
            : "You missed yesterday. Today is Day 1 of your next streak — make it count."
        content.sound = .default

        var comps = DateComponents()
        comps.hour   = 8
        comps.minute = Int.random(in: 0...59)

        schedule(id: ID.comeback, content: content,
                 trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: false))
        defaults.set(today, forKey: Fired.comebackDate)
    }

    // MARK: - 8. Personal Best
    private func schedulePersonalBestIfNeeded(steps: Int, today: Date) {
        let lastFired = defaults.object(forKey: Fired.personalBest) as? Date
        guard !(lastFired.map { Calendar.current.isDate($0, inSameDayAs: today) } ?? false) else { return }

        let content = UNMutableNotificationContent()
        content.title = "New personal best! 🏆"
        content.body  = "You just hit \(steps.formatted()) steps — your best day ever. Keep going!"
        content.sound = .default

        schedule(id: ID.personalBest, content: content,
                 trigger: UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false))
        defaults.set(today, forKey: Fired.personalBest)
    }

    // MARK: - 9. Weekly Report
    private func scheduleWeeklyReportIfNeeded(weekDaily: [DaySteps], today: Date) {
        let lastFired = defaults.object(forKey: Fired.weeklyReport) as? Date
        // Only fire once per week (use startOfWeek as key)
        let startOfWeek = Calendar.current.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        guard !(lastFired.map { Calendar.current.isDate($0, inSameDayAs: startOfWeek) } ?? false) else { return }

        let total     = weekDaily.reduce(0) { $0 + $1.steps }
        let daysHit   = weekDaily.filter { $0.goalReached }.count
        let bestDay   = weekDaily.max(by: { $0.steps < $1.steps })

        let content = UNMutableNotificationContent()
        content.title = "Weekly wrap 📊"
        content.body  = "This week: \(total.formatted()) steps total. Goal hit \(daysHit)/7 days.\(bestDay != nil ? " Best day: \(bestDay!.day)." : "")"
        content.sound = .default

        schedule(id: ID.weeklyReport, content: content,
                 trigger: UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false))
        defaults.set(startOfWeek, forKey: Fired.weeklyReport)
    }

    // MARK: - 10. Milestone Celebration
    private func scheduleMilestoneIfNeeded(streakCount: Int) {
        let milestones = [3, 7, 14, 30, 60, 100]
        guard milestones.contains(streakCount) else { return }

        let lastMilestone = defaults.integer(forKey: Fired.milestoneStreak)
        guard lastMilestone != streakCount else { return }

        let label: String
        switch streakCount {
        case 3:   label = "3 days — you're building a habit!"
        case 7:   label = "One full week — incredible!"
        case 14:  label = "Two weeks straight — you're unstoppable!"
        case 30:  label = "30 days — that's a real habit now! 🏆"
        case 60:  label = "Two months! You're a walking machine! 💎"
        case 100: label = "100 DAYS! Legendary. 👑"
        default:  label = "\(streakCount) days!"
        }

        let content = UNMutableNotificationContent()
        content.title = "Milestone unlocked! ⭐️"
        content.body  = label
        content.sound = .default

        schedule(id: ID.milestone, content: content,
                 trigger: UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false))
        defaults.set(streakCount, forKey: Fired.milestoneStreak)
    }

    // MARK: - 11. Rest Day Reminder
    private func scheduleRestDayIfNeeded(streakCount: Int, today: Date) {
        center.getPendingNotificationRequests { [weak self] pending in
            guard let self else { return }
            let alreadyPending = pending.contains { $0.identifier == ID.restDay }
            guard !alreadyPending else { return }

            let content = UNMutableNotificationContent()
            content.title = "Keep the chain alive 🔗"
            content.body  = "You've hit your goal \(streakCount) days in a row. Even a short walk today keeps the streak alive."
            content.sound = .default

            var comps = DateComponents()
            comps.hour   = 11
            comps.minute = Int.random(in: 0...119)
            if comps.minute! > 59 { comps.hour = 12; comps.minute = comps.minute! - 60 }

            self.schedule(id: ID.restDay, content: content,
                          trigger: UNCalendarNotificationTrigger(dateMatching: comps, repeats: false))
        }
    }

    // MARK: - Helpers
    private func goalReached(_ steps: Int, _ goal: Int) -> Bool { steps >= goal }

    private func schedule(id: String, content: UNMutableNotificationContent, trigger: UNNotificationTrigger) {
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request) { _ in }  // silent fail
    }

    private func cancelPending(ids: [String]) {
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }
}
