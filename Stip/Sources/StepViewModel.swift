import Foundation
import HealthKit

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
    private let healthStore   = HKHealthStore()
    private let streakManager = StreakManager()
    private let stepType      = HKQuantityType.quantityType(forIdentifier: .stepCount)!

    // MARK: - Computed
    var progress: Double       { min(Double(todaySteps) / Double(dailyGoal), 1.0) }
    var stepsRemaining: Int    { max(0, dailyGoal - todaySteps) }
    var goalReached: Bool      { todaySteps >= dailyGoal }
    var percentageText: String { "\(Int(progress * 100))%" }

    init() {
        personalBest = UserDefaults.standard.integer(forKey: "stip.personalBest")
        // Check health auth status immediately so background delivery can be set up
        checkHealthKitAuthorizationStatus()
    }

    // MARK: - Check existing auth (no dialog — called on every launch)
    func checkHealthKitAuthorizationStatus() {
        guard HKHealthStore.isHealthDataAvailable() else {
            authStatus = "unavailable"
            return
        }
        let status = healthStore.authorizationStatus(for: stepType)
        switch status {
        case .sharingAuthorized:
            // Already authorized — go straight to fetching
            isAuthorized = true
            authStatus = "authorized"
            setupBackgroundDelivery()
            refreshAll()
        case .sharingDenied:
            isAuthorized = false
            authStatus = "denied"
        default:
            // notDetermined — show prompt
            isAuthorized = false
            authStatus = "notDetermined"
            requestHealthKitAuthorization()
        }
    }

    // MARK: - Request auth (shows the system dialog)
    func requestHealthKitAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        // We need to read steps — must pass the type in the toShare set too for the
        // authorization dialog to appear correctly even when only reading
        let readTypes: Set<HKObjectType> = [stepType]
        healthStore.requestAuthorization(toShare: [], read: readTypes) { [weak self] granted, error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isAuthorized = granted
                self.authStatus   = granted ? "authorized" : "denied"
                if granted {
                    self.setupBackgroundDelivery()
                    self.refreshAll()
                }
            }
        }
    }

    // MARK: - Background Delivery
    private func setupBackgroundDelivery() {
        let query = HKObserverQuery(sampleType: stepType, predicate: nil) { [weak self] _, completionHandler, error in
            guard error == nil else {
                completionHandler()
                return
            }
            Task { @MainActor [weak self] in
                self?.refreshAll()
                completionHandler()
            }
        }
        healthStore.execute(query)
        
        healthStore.enableBackgroundDelivery(for: stepType, frequency: .hourly) { success, error in
            if let error = error {
                print("Failed to enable background delivery: \(error)")
            }
        }
    }

    // MARK: - Refresh all data from HealthKit
    func refreshAll() {
        // If not authorized yet, silently re-check status first
        if !isAuthorized {
            let status = healthStore.authorizationStatus(for: stepType)
            if status == .sharingAuthorized {
                isAuthorized = true
            } else {
                return
            }
        }
        fetchToday()
        fetchYesterday()
        fetchWeekTotal()
        fetchWeekDaily()
        fetchPeriod(.month) { [weak self] v in Task { @MainActor [weak self] in self?.monthSteps = v } }
        fetchPeriod(.year)  { [weak self] v in Task { @MainActor [weak self] in self?.yearSteps  = v } }
    }

    // MARK: - Today
    private func fetchToday() {
        let cal   = Calendar.current
        let start = cal.startOfDay(for: Date())
        fetchSum(from: start, to: Date()) { [weak self] count in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.todaySteps = count

                // Update personal best
                if count > self.personalBest {
                    self.personalBest = count
                    UserDefaults.standard.set(count, forKey: "stip.personalBest")
                }

                // Update streak
                self.streakManager.update(todaySteps: count, goal: self.dailyGoal)
                self.streakCount = self.streakManager.currentStreak

                // Fire all smart notifications
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

    // MARK: - Yesterday (needed for comeback notification)
    private func fetchYesterday() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        guard let yStart = cal.date(byAdding: .day, value: -1, to: today),
              let yEnd   = cal.date(byAdding: .day, value:  1, to: yStart) else { return }
        fetchSum(from: yStart, to: yEnd) { [weak self] count in
            Task { @MainActor [weak self] in self?.yesterdaySteps = count }
        }
    }

    // MARK: - Week total
    private func fetchWeekTotal() {
        let cal   = Calendar.current
        let today = cal.startOfDay(for: Date())
        guard let start = cal.date(byAdding: .day, value: -6, to: today) else { return }
        fetchSum(from: start, to: Date()) { [weak self] v in
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
            fetchSum(from: dayStart, to: min(dayEnd, Date())) { steps in
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
            // Re-evaluate notifications now that weekDaily is populated
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
    private func fetchPeriod(_ component: Calendar.Component, completion: @escaping (Int) -> Void) {
        guard let start = Calendar.current.dateInterval(of: component, for: Date())?.start else {
            completion(0); return
        }
        fetchSum(from: start, to: Date(), completion: completion)
    }

    // MARK: - Core HK query
    private func fetchSum(from start: Date, to end: Date, completion: @escaping (Int) -> Void) {
        let predicate = HKQuery.predicateForSamples(
            withStart: start, end: end, options: .strictStartDate)
        let query = HKStatisticsQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, stats, _ in
            let count = Int(stats?.sumQuantity()?.doubleValue(for: .count()) ?? 0)
            completion(count)
        }
        healthStore.execute(query)
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
