import XCTest
@testable import LockScreenStudio

final class HabitsHeatmapConfigDecodingTests: XCTestCase {

    /// Panels saved before `source` existed must keep their settings. A
    /// synthesized Codable would throw on the missing key, and `decodeConfig`
    /// swallows that and hands back a fresh default — silently resetting the
    /// user's week count.
    func testDecodesConfigSavedBeforeSourceExisted() throws {
        let legacy = Data(#"{"habitName":"Running","weeksToShow":20}"#.utf8)

        let config = try JSONDecoder().decode(HabitsHeatmapConfig.self, from: legacy)

        XCTAssertEqual(config.habitName, "Running")
        XCTAssertEqual(config.weeksToShow, 20)
        XCTAssertEqual(config.source, .todos, "legacy panels must keep the old behaviour")
    }

    func testDecodesFullyPopulatedConfig() throws {
        let data = Data(#"{"habitName":"Steps","weeksToShow":8,"source":"combined"}"#.utf8)

        let config = try JSONDecoder().decode(HabitsHeatmapConfig.self, from: data)

        XCTAssertEqual(config.habitName, "Steps")
        XCTAssertEqual(config.weeksToShow, 8)
        XCTAssertEqual(config.source, .combined)
    }

    func testRoundTrips() throws {
        let original = HabitsHeatmapConfig(habitName: "Walk", weeksToShow: 6, source: .health)

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(HabitsHeatmapConfig.self, from: data)

        XCTAssertEqual(decoded.habitName, original.habitName)
        XCTAssertEqual(decoded.weeksToShow, original.weeksToShow)
        XCTAssertEqual(decoded.source, original.source)
    }

    func testOnlyHealthSourcesNeedAccess() {
        XCTAssertFalse(HabitsHeatmapConfig.Source.todos.needsHealthAccess)
        XCTAssertTrue(HabitsHeatmapConfig.Source.health.needsHealthAccess)
        XCTAssertTrue(HabitsHeatmapConfig.Source.combined.needsHealthAccess)
    }
}

final class HabitsHeatLevelTests: XCTestCase {

    func testStepThresholdsMapToFiveLevels() {
        XCTAssertEqual(ConsistencyLevel.level(steps: 0), 0)
        XCTAssertEqual(ConsistencyLevel.level(steps: 2_999), 1)
        XCTAssertEqual(ConsistencyLevel.level(steps: 3_000), 2)
        XCTAssertEqual(ConsistencyLevel.level(steps: 5_999), 2)
        XCTAssertEqual(ConsistencyLevel.level(steps: 6_000), 3)
        XCTAssertEqual(ConsistencyLevel.level(steps: 9_999), 3)
        XCTAssertEqual(ConsistencyLevel.level(steps: 10_000), 4)
        XCTAssertEqual(ConsistencyLevel.level(steps: 40_000), 4)
    }

    /// Without a floor, every day the phone was carried would score as active
    /// and the streak would never break — the panel would measure phone
    /// carriage rather than the habit.
    func testTrivialStepCountsAreNotAnActiveDay() {
        XCTAssertEqual(ConsistencyLevel.level(steps: 1), 0)
        XCTAssertEqual(ConsistencyLevel.level(steps: 50), 0)
        XCTAssertEqual(ConsistencyLevel.level(steps: 999), 0)
        XCTAssertEqual(ConsistencyLevel.level(steps: 1_000), 1, "1,000 steps is a real day")
    }

    func testTodosSourceIgnoresSteps() {
        let level = ConsistencyLevel.level(source: .todos, todoCount: 1, steps: 20_000)
        XCTAssertEqual(level, ConsistencyLevel.level(todoCount: 1))
    }

    func testHealthSourceIgnoresTodos() {
        let level = ConsistencyLevel.level(source: .health, todoCount: 9, steps: 3_500)
        XCTAssertEqual(level, 2)
    }

    /// The panel answers "did you show up?", so a long walk must not be diluted
    /// by an empty todo list, nor the reverse.
    func testCombinedTakesTheBrighterSource() {
        XCTAssertEqual(
            ConsistencyLevel.level(source: .combined, todoCount: 0, steps: 12_000), 4,
            "a big walk should fill the cell even with no todos"
        )
        XCTAssertEqual(
            ConsistencyLevel.level(source: .combined, todoCount: 8, steps: 0), 4,
            "a heavy todo day should fill the cell even with no steps"
        )
        XCTAssertEqual(
            ConsistencyLevel.level(source: .combined, todoCount: 0, steps: 0), 0,
            "a day with neither stays empty"
        )
    }

    func testCombinedNeverSumsSources() {
        // 1 todo -> level 1, 3,500 steps -> level 2. Summing would give 3.
        XCTAssertEqual(ConsistencyLevel.level(source: .combined, todoCount: 1, steps: 3_500), 2)
    }
}

// MARK: - Panel rendering

private struct StubHealthProvider: HealthProviding {
    var isAvailable: Bool = true
    var steps: [Date: Int] = [:]

    func currentlyAuthorized() async -> Bool { true }
    func requestAccess() async -> Bool { true }
    func dailyStepCounts(from: Date, to: Date) async -> [Date: Int] { steps }
}

@MainActor
final class HabitsPanelRenderTests: XCTestCase {

    private let cal = Calendar.current

    private func panel(_ config: HabitsHeatmapConfig) -> PanelConfiguration {
        let panel = PanelConfiguration(panelType: .habitsHeatmap)
        panel.encodeConfig(config)
        return panel
    }

    private func completedTodo(daysAgo: Int) -> TodoItem {
        let todo = TodoItem(text: "Done \(daysAgo)", isCompleted: true)
        todo.completedAt = cal.date(byAdding: .day, value: -daysAgo, to: .now)
        return todo
    }

    func testStreakHeadlinePrecedesTheGrid() async throws {
        let builder = PanelDataBuilder(healthService: StubHealthProvider())
        let result = await builder.buildPanelData(
            for: [panel(HabitsHeatmapConfig(source: .todos, showStreak: true))],
            priorities: [],
            todos: [completedTodo(daysAgo: 0), completedTodo(daysAgo: 1)]
        )

        let lines = try XCTUnwrap(result.first?.lines)
        XCTAssertEqual(lines.count, 3)
        guard case let .heroText(streak) = lines[0] else {
            return XCTFail("expected a hero streak line first")
        }
        XCTAssertEqual(streak, "2")
        guard case let .subtitle(label) = lines[1] else {
            return XCTFail("expected a subtitle under the streak")
        }
        XCTAssertEqual(label, "day streak")
        guard case .heatmapGrid = lines[2] else {
            return XCTFail("expected the grid last")
        }
    }

    func testStreakCanBeTurnedOff() async throws {
        let builder = PanelDataBuilder(healthService: StubHealthProvider())
        let result = await builder.buildPanelData(
            for: [panel(HabitsHeatmapConfig(source: .todos, showStreak: false))],
            priorities: [],
            todos: [completedTodo(daysAgo: 0)]
        )

        let lines = try XCTUnwrap(result.first?.lines)
        XCTAssertEqual(lines.count, 1)
        guard case .heatmapGrid = lines[0] else {
            return XCTFail("expected only the grid")
        }
    }

    /// The headline must count the same days the grid paints — a health-only
    /// panel showing a streak built from todos would be a lie.
    func testStreakUsesTheConfiguredSource() async throws {
        let today = cal.startOfDay(for: .now)
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!
        let stub = StubHealthProvider(steps: [today: 11_000, yesterday: 9_000])
        let builder = PanelDataBuilder(healthService: stub)

        let result = await builder.buildPanelData(
            for: [panel(HabitsHeatmapConfig(source: .health, showStreak: true))],
            priorities: [],
            todos: [completedTodo(daysAgo: 5)]
        )

        let lines = try XCTUnwrap(result.first?.lines)
        guard case let .heroText(streak) = lines[0] else {
            return XCTFail("expected a hero streak line")
        }
        XCTAssertEqual(streak, "2", "steps today and yesterday, todos must not extend it")
    }

    /// Regression: the streak was computed only from the grid's visible
    /// columns, so a narrow grid under-reported a long run.
    func testStreakIsNotTruncatedByGridWidth() async throws {
        let builder = PanelDataBuilder(healthService: StubHealthProvider())
        let fortyDays = (0..<40).map { completedTodo(daysAgo: $0) }

        let result = await builder.buildPanelData(
            for: [panel(HabitsHeatmapConfig(weeksToShow: 4, source: .todos, showStreak: true))],
            priorities: [],
            todos: fortyDays
        )

        guard case let .heroText(streak) = try XCTUnwrap(result.first?.lines.first) else {
            return XCTFail("expected a hero streak line")
        }
        XCTAssertEqual(streak, "40", "a 4-week grid must not cap a 40-day streak")
    }

    /// Regression: the Health fetch window was clamped to 20 weeks while the
    /// grid allowed 53, leaving the oldest columns permanently blank.
    func testFullYearGridStillGetsStepDataForItsOldestColumns() async throws {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        var steps: [Date: Int] = [:]
        for offset in 0..<(HabitsHeatmapConfig.maxWeeks * 7) {
            steps[cal.date(byAdding: .day, value: -offset, to: today)!] = 12_000
        }
        let builder = PanelDataBuilder(healthService: StubHealthProvider(steps: steps))

        let result = await builder.buildPanelData(
            for: [panel(HabitsHeatmapConfig(
                weeksToShow: HabitsHeatmapConfig.maxWeeks, source: .health, showStreak: false
            ))],
            priorities: [],
            todos: []
        )

        guard case let .heatmapGrid(_, data) = try XCTUnwrap(result.first?.lines.first) else {
            return XCTFail("expected a grid")
        }
        // The first column is the oldest week; with steps every day it must be lit.
        XCTAssertTrue(data.prefix(7).allSatisfy { $0 == 4 }, "oldest columns lost their step data")
    }

    func testWeeksAreClampedToAFullYear() async throws {
        let builder = PanelDataBuilder(healthService: StubHealthProvider())
        let result = await builder.buildPanelData(
            for: [panel(HabitsHeatmapConfig(weeksToShow: 999, showStreak: false))],
            priorities: [],
            todos: []
        )

        guard case let .heatmapGrid(weeks, data) = try XCTUnwrap(result.first?.lines.first) else {
            return XCTFail("expected a grid")
        }
        XCTAssertEqual(weeks, HabitsHeatmapConfig.maxWeeks)
        XCTAssertEqual(data.count, HabitsHeatmapConfig.maxWeeks * 7)
    }
}
