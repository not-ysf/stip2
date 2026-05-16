import Foundation
import CoreMotion
import SwiftUI

@MainActor
final class StepViewModel: ObservableObject {

    // MARK: - Published
    @Published var todaySteps:   Int = 0
    @Published var yesterdaySteps: Int = 0
    @Published var weekSteps:    Int = 0
    @Published var monthSteps:   Int = 0
    @Published var yearSteps:    Int = 0
    @Published var weekDaily:    [DaySteps] = []
    @Published var streakCount:  Int = 0
    @Published var isAuthorized: Bool = false
    @Published var authStatus:   String = "unknown"  // for UI feedback

    // Personal best stored in UserDefaults
    @Published var personalBest: Int = 0

    let dailyGoal = 2000

    // MARK: - Dependencies
    private let pedometer     = CMPedometer()
    private let streakManager = StreakManager()

    // MARK: - Computed
    var progress: Double       { min(Double(todaySteps) / Double(dailyGoal), 1.0) }
    var stepsRemaining: Int    { max(0, dailyGoal - todaySteps) }
    var goalReached: Bool      { todaySteps >= dailyGoal }
    var percentageText: String { "\(Int(progress * 100))%" }

    init() {
        personalBest = UserDefaults.standard.integer(forKey: "stip.personalBest")
    }

    // MARK: - Check auth (called from onAppear)
    func checkHealthKitAuthorizationStatus() {
        guard CMPedometer.isStepCountingAvailable() else {
            authStatus = "unavailable"
            return
        }
        let status = CMPedometer.authorizationStatus()
        switch status {
        case .authorized:
            isAuthorized = true
            authStatus = "authorized"
            refreshAll()
        case .denied, .restricted:
            isAuthorized = false
            authStatus = "denied"
        default:
            // .notDetermined — querying will trigger the permission dialog
            requestHealthKitAuthorization()
        }
    }

    // MARK: - Request auth (triggers the Motion & Fitness dialog)
    func requestHealthKitAuthorization() {
        guard CMPedometer.isStepCountingAvailable() else {
            authStatus = "unavailable"
            return
        }
        // Querying pedometer data automatically triggers the permission dialog
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        pedometer.queryPedometerData(from: start, to: Date()) { [weak self] data, error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let error = error {
                    print("Pedometer error: \(error.localizedDescription)")
                    self.isAuthorized = false
                    self.authStatus = "denied"
                    return
                }
                self.isAuthorized = true
                self.authStatus = "authorized"
                self.refreshAll()
            }
        }
    }

    // MARK: - Refresh all data
    func refreshAll() {
        guard CMPedometer.isStepCountingAvailable() else { return }
        fetchToday()
        fetchYesterday()
        fetchWeekTotal()
        fetchWeekDaily()
        fetchPeriod(days: 30)  { [weak self] v in Task { @MainActor [weak self] in self?.monthSteps = v } }
        fetchPeriod(days: 365) { [weak self] v in Task { @MainActor [weak self] in self?.yearSteps  = v } }
        startLiveUpdates()
    }

    // MARK: - Live updates (foreground)
    private func startLiveUpdates() {
        let cal = Calendar.current
        let startOfToday = cal.startOfDay(for: Date())
        pedometer.startUpdates(from: startOfToday) { [weak self] data, error in
            guard let data = data, error == nil else { return }
            let count = data.numberOfSteps.intValue
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.todaySteps = count

                if count > self.personalBest {
                    self.personalBest = count
                    UserDefaults.standard.set(count, forKey: "stip.personalBest")
                }

                self.streakManager.update(todaySteps: count, goal: self.dailyGoal)
                self.streakCount = self.streakManager.currentStreak

                NotificationManager.shared.evaluateAndSchedule(
                    todaySteps:    count,
                    yesterdaySteps: self.yesterdaySteps,
                    goal:          self.dailyGoal,
                    streakCount:   self.streakManager.currentStreak,
                    personalBest:  self.personalBest,
                    weekDaily:     self.weekDaily
                )
            }
        }
    }

    // MARK: - Today
    private func fetchToday() {
        let cal   = Calendar.current
        let start = cal.startOfDay(for: Date())
        fetchSteps(from: start, to: Date()) { [weak self] count in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.todaySteps = count

                if count > self.personalBest {
                    self.personalBest = count
                    UserDefaults.standard.set(count, forKey: "stip.personalBest")
                }

                self.streakManager.update(todaySteps: count, goal: self.dailyGoal)
                self.streakCount = self.streakManager.currentStreak

                NotificationManager.shared.evaluateAndSchedule(
                    todaySteps:    count,
                    yesterdaySteps: self.yesterdaySteps,
                    goal:          self.dailyGoal,
                    streakCount:   self.streakManager.currentStreak,
                    personalBest:  self.personalBest,
                    weekDaily:     self.weekDaily
                )
            }
        }
    }

    // MARK: - Yesterday
    private func fetchYesterday() {
        let cal   = Calendar.current
        let today = cal.startOfDay(for: Date())
        guard let yStart = cal.date(byAdding: .day, value: -1, to: today) else { return }
        fetchSteps(from: yStart, to: today) { [weak self] count in
            Task { @MainActor [weak self] in self?.yesterdaySteps = count }
        }
    }

    // MARK: - Week total
    private func fetchWeekTotal() {
        let cal   = Calendar.current
        let today = cal.startOfDay(for: Date())
        guard let start = cal.date(byAdding: .day, value: -6, to: today) else { return }
        fetchSteps(from: start, to: Date()) { [weak self] v in
            Task { @MainActor [weak self] in self?.weekSteps = v }
        }
    }

    // MARK: - Weekly bar data
    private func fetchWeekDaily() {
        let cal   = Calendar.current
        let today = cal.startOfDay(for: Date())
        var results: [(index: Int, day: DaySteps)] = []
        let group = DispatchGroup()
        let lock  = NSLock()

        for offset in (0...6).reversed() {
            guard let dayStart = cal.date(byAdding: .day, value: -offset, to: today),
                  let dayEnd   = cal.date(byAdding: .day, value: 1, to: dayStart) else { continue }
            let isToday = (offset == 0)
            let symbol  = cal.veryShortWeekdaySymbols[cal.component(.weekday, from: dayStart) - 1]
            let idx     = 6 - offset
            group.enter()
            fetchSteps(from: dayStart, to: min(dayEnd, Date())) { steps in
                lock.lock()
                results.append((index: idx, day: DaySteps(
                    day: symbol, steps: steps,
                    isToday: isToday, goalReached: steps >= 2000)))
                lock.unlock()
                group.leave()
            }
        }
        group.notify(queue: .main) { [weak self] in
            guard let self else { return }
            self.weekDaily = results.sorted { $0.index < $1.index }.map { $0.day }
            NotificationManager.shared.evaluateAndSchedule(
                todaySteps:    self.todaySteps,
                yesterdaySteps: self.yesterdaySteps,
                goal:          self.dailyGoal,
                streakCount:   self.streakCount,
                personalBest:  self.personalBest,
                weekDaily:     self.weekDaily
            )
        }
    }

    // MARK: - Period fetch
    private func fetchPeriod(days: Int, completion: @escaping (Int) -> Void) {
        guard let start = Calendar.current.date(byAdding: .day, value: -days, to: Date()) else {
            completion(0); return
        }
        fetchSteps(from: start, to: Date(), completion: completion)
    }

    // MARK: - Core pedometer query
    private func fetchSteps(from start: Date, to end: Date, completion: @escaping (Int) -> Void) {
        pedometer.queryPedometerData(from: start, to: end) { data, error in
            let count = data?.numberOfSteps.intValue ?? 0
            completion(count)
        }
    }
}

// MARK: - Model
struct DaySteps: Identifiable {
    let id          = UUID()
    let day:        String
    let steps:      Int
    let isToday:    Bool
    let goalReached: Bool
}
