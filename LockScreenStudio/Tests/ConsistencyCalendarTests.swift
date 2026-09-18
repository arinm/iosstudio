import XCTest
@testable import LockScreenStudio

final class ConsistencyStreakTests: XCTestCase {

    private let cal = Calendar.current

    private func day(_ offset: Int, from today: Date) -> Date {
        cal.date(byAdding: .day, value: offset, to: today)!
    }

    private func levels(_ offsets: [Int], from today: Date) -> [Date: Int] {
        Dictionary(uniqueKeysWithValues: offsets.map { (day($0, from: today), 1) })
    }

    func testStreakCountsConsecutiveDaysEndingToday() {
        let today = cal.startOfDay(for: .now)
        let streak = ConsistencyCalendar.streak(
            endingAt: today,
            levels: levels([0, -1, -2, -3], from: today),
            calendar: cal
        )
        XCTAssertEqual(streak, 4)
    }

    /// The day isn't over yet, so an empty today must not wipe out a live
    /// streak — that would show "0" every morning until the user did something.
    func testEmptyTodayDoesNotBreakStreak() {
        let today = cal.startOfDay(for: .now)
        let streak = ConsistencyCalendar.streak(
            endingAt: today,
            levels: levels([-1, -2, -3], from: today),
            calendar: cal
        )
        XCTAssertEqual(streak, 3)
    }

    /// An empty yesterday does break it — that day is genuinely over.
    func testEmptyTodayAndYesterdayIsZero() {
        let today = cal.startOfDay(for: .now)
        let streak = ConsistencyCalendar.streak(
            endingAt: today,
            levels: levels([-2, -3, -4], from: today),
            calendar: cal
        )
        XCTAssertEqual(streak, 0)
    }

    func testGapStopsTheCount() {
        let today = cal.startOfDay(for: .now)
        // Active today and yesterday, gap at -2, more activity before it.
        let streak = ConsistencyCalendar.streak(
            endingAt: today,
            levels: levels([0, -1, -3, -4, -5], from: today),
            calendar: cal
        )
        XCTAssertEqual(streak, 2, "activity before a gap must not be counted")
    }

    func testNoActivityIsZero() {
        let today = cal.startOfDay(for: .now)
        XCTAssertEqual(
            ConsistencyCalendar.streak(endingAt: today, levels: [:], calendar: cal),
            0
        )
    }
}

final class ConsistencyCalendarBuildTests: XCTestCase {

    private let cal = Calendar.current

    /// Pinned to an explicit mid-year date: using `.now` made this fail every
    /// January 1st, when "yesterday" falls outside the counted year.
    func testCountsOnlyDaysWithActivity() {
        let today = cal.date(from: DateComponents(year: 2026, month: 6, day: 15))!
        let calendar = ConsistencyCalendar.forYear(
            containing: today,
            todoCompletions: [today, today, cal.date(byAdding: .day, value: -1, to: today)!],
            stepsByDay: [:],
            source: .todos,
            calendar: cal
        )
        XCTAssertEqual(calendar.activeDays, 2)
        XCTAssertEqual(calendar.level(on: today), ConsistencyLevel.level(todoCount: 2))
    }

    func testHealthOnlySourceIgnoresTodos() {
        let today = cal.startOfDay(for: .now)
        let calendar = ConsistencyCalendar.forYear(
            containing: today,
            todoCompletions: [today, today, today, today, today],
            stepsByDay: [today: 1_200],
            source: .health,
            calendar: cal
        )
        XCTAssertEqual(calendar.level(on: today), 1, "5 todos must not raise a health-only day")
    }

    func testCombinedTakesTheBrighterSource() {
        let today = cal.startOfDay(for: .now)
        let calendar = ConsistencyCalendar.forYear(
            containing: today,
            todoCompletions: [],
            stepsByDay: [today: 14_000],
            source: .combined,
            calendar: cal
        )
        XCTAssertEqual(calendar.level(on: today), 4, "a big walk alone should fill the cell")
    }

    func testWindowStartsOnJanuaryFirst() {
        let today = cal.startOfDay(for: .now)
        let calendar = ConsistencyCalendar.forYear(
            containing: today,
            todoCompletions: [],
            stepsByDay: [:],
            source: .todos,
            calendar: cal
        )
        let components = cal.dateComponents([.month, .day], from: calendar.start)
        XCTAssertEqual(components.month, 1)
        XCTAssertEqual(components.day, 1)
        XCTAssertEqual(calendar.end, today)
    }

    /// Regression: `forYear` used to score only from January 1st, so on Jan 2
    /// a long streak collapsed to "2 day streak".
    func testStreakSurvivesTheYearBoundary() {
        let jan2 = cal.date(from: DateComponents(year: 2027, month: 1, day: 2))!
        let fourDays = (0...3).compactMap { cal.date(byAdding: .day, value: -$0, to: jan2) }

        let calendar = ConsistencyCalendar.forYear(
            containing: jan2,
            todoCompletions: fourDays,
            stepsByDay: [:],
            source: .todos,
            calendar: cal
        )

        XCTAssertEqual(calendar.currentStreak, 4, "Dec 30-31 must still count toward the streak")
        XCTAssertEqual(calendar.activeDays, 2, "but only Jan 1-2 belong to the displayed year")
    }

    func testStepsBeforeTheYearAlsoExtendTheStreak() {
        let jan1 = cal.date(from: DateComponents(year: 2027, month: 1, day: 1))!
        var steps: [Date: Int] = [:]
        for offset in 0...5 {
            steps[cal.date(byAdding: .day, value: -offset, to: jan1)!] = 12_000
        }

        let calendar = ConsistencyCalendar.forYear(
            containing: jan1,
            todoCompletions: [],
            stepsByDay: steps,
            source: .health,
            calendar: cal
        )

        XCTAssertEqual(calendar.currentStreak, 6)
        XCTAssertEqual(calendar.activeDays, 1)
    }

    func testDaysOutsideTheYearAreNotCounted() {
        let today = cal.startOfDay(for: .now)
        let lastYear = cal.date(byAdding: .year, value: -1, to: today)!
        let calendar = ConsistencyCalendar.forYear(
            containing: today,
            todoCompletions: [lastYear],
            stepsByDay: [:],
            source: .todos,
            calendar: cal
        )
        XCTAssertEqual(calendar.activeDays, 0)
    }
}
