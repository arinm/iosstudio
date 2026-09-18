import Foundation
import HealthKit

/// Daily activity pulled from Apple Health, so the Consistency panel can be
/// coloured by what the user actually did — not only by todos ticked inside
/// this app.
///
/// Read-only: the app never writes to Health.
protocol HealthProviding: Sendable {
    /// False on devices with no Health data (iPad, some regions).
    var isAvailable: Bool { get }
    func currentlyAuthorized() async -> Bool
    func requestAccess() async -> Bool
    /// Step totals keyed by `Calendar.startOfDay`, covering `from...to`.
    /// Days with no samples are absent from the dictionary.
    func dailyStepCounts(from: Date, to: Date) async -> [Date: Int]
}

/// HealthKit adapter. Steps are the signal on purpose: every iPhone records
/// them without a Watch, so the heatmap has something to show for the majority
/// of users. Exercise minutes would be richer but are mostly Watch-only.
final class HealthService: HealthProviding, @unchecked Sendable {

    static let shared = HealthService()

    private let store = HKHealthStore()

    private var stepType: HKQuantityType? {
        HKQuantityType.quantityType(forIdentifier: .stepCount)
    }

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    /// HealthKit deliberately refuses to reveal read authorization — asking
    /// returns `.notDetermined` even after the user has granted it, to avoid
    /// leaking that a condition is being tracked. So "authorized" here means
    /// "a query came back without an authorization error", which is the only
    /// honest signal available.
    func currentlyAuthorized() async -> Bool {
        guard isAvailable, stepType != nil else { return false }
        let today = Calendar.current.startOfDay(for: .now)
        let counts = await dailyStepCounts(from: today, to: today)
        return counts[today] != nil
    }

    func requestAccess() async -> Bool {
        guard isAvailable, let stepType else { return false }
        do {
            try await store.requestAuthorization(toShare: [], read: [stepType])
            return true
        } catch {
            return false
        }
    }

    func dailyStepCounts(from: Date, to: Date) async -> [Date: Int] {
        guard isAvailable, let stepType else { return [:] }

        let calendar = Calendar.current
        let start = calendar.startOfDay(for: from)
        guard let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: to))
        else { return [:] }

        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: start,
                intervalComponents: DateComponents(day: 1)
            )

            query.initialResultsHandler = { _, results, _ in
                guard let results else {
                    continuation.resume(returning: [:])
                    return
                }
                var counts: [Date: Int] = [:]
                results.enumerateStatistics(from: start, to: end) { statistics, _ in
                    guard let sum = statistics.sumQuantity() else { return }
                    let day = calendar.startOfDay(for: statistics.startDate)
                    counts[day] = Int(sum.doubleValue(for: .count()))
                }
                continuation.resume(returning: counts)
            }

            store.execute(query)
        }
    }
}
