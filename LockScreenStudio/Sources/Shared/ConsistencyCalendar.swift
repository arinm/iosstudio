import Foundation

/// Single source of truth for "how active was this day", shared by the
/// wallpaper renderer and the widgets so a day can never look one brightness on
/// the Lock Screen and another on the Home Screen.
enum ConsistencyLevel {

    /// Todo completions on a day, mapped to 0...4.
    static func level(todoCount: Int) -> Int {
        switch todoCount {
        case 0: return 0
        case 1: return 1
        case 2...3: return 2
        case 4...6: return 3
        default: return 4
        }
    }

    /// Step thresholds sit around the familiar 10k-a-day goal, so a full cell
    /// means "hit the goal" rather than an arbitrary number.
    ///
    /// The floor matters as much as the ceiling: counting a single step as an
    /// active day would mean the streak never breaks for anyone who carries
    /// their phone, and the panel would measure phone carriage rather than the
    /// habit. 1,000 steps is "you actually moved today".
    static func level(steps: Int) -> Int {
        switch steps {
        case ..<1_000: return 0
        case ..<3_000: return 1
        case ..<6_000: return 2
        case ..<10_000: return 3
        default: return 4
        }
    }

    /// Combines the configured sources into a single 0...4 level.
    ///
    /// `.combined` takes the max rather than the sum on purpose: the question
    /// is "did you show up today?", so a long walk shouldn't be diluted by an
    /// empty todo list, or the reverse.
    static func level(source: HabitsHeatmapConfig.Source, todoCount: Int, steps: Int) -> Int {
        switch source {
        case .todos: return level(todoCount: todoCount)
        case .health: return level(steps: steps)
        case .combined: return max(level(todoCount: todoCount), level(steps: steps))
        }
    }
}

/// A year's worth of daily activity, plus the headline numbers the widgets put
/// above it.
struct ConsistencyCalendar {

    /// Level 0...4 per `Calendar.startOfDay`. Days with no activity are absent.
    let levels: [Date: Int]
    /// Consecutive active days ending today (or yesterday, if today is still
    /// empty — the day isn't over yet).
    let currentStreak: Int
    /// Active days within the covered window.
    let activeDays: Int
    /// First day of the covered window.
    let start: Date
    /// Last day of the covered window, normally today.
    let end: Date

    func level(on day: Date, calendar: Calendar = .current) -> Int {
        levels[calendar.startOfDay(for: day)] ?? 0
    }

    /// Builds the calendar for the year containing `date`.
    static func forYear(
        containing date: Date,
        todoCompletions: [Date],
        stepsByDay: [Date: Int],
        source: HabitsHeatmapConfig.Source,
        calendar: Calendar = .current
    ) -> ConsistencyCalendar {
        let today = calendar.startOfDay(for: date)
        let year = calendar.component(.year, from: today)
        let start = calendar.date(from: DateComponents(year: year, month: 1, day: 1)) ?? today

        var todoCounts: [Date: Int] = [:]
        for completion in todoCompletions {
            todoCounts[calendar.startOfDay(for: completion), default: 0] += 1
        }
        var stepCounts: [Date: Int] = [:]
        for (day, count) in stepsByDay {
            stepCounts[calendar.startOfDay(for: day), default: 0] += count
        }

        // Scored across every day either source has data for, not just the
        // displayed year: a streak running through New Year's Eve must not
        // collapse to "1 day" on January 1st. The grid still only draws
        // start...end; `activeDays` still counts only the displayed year.
        var candidates = Set(todoCounts.keys)
        candidates.formUnion(stepCounts.keys)

        var levels: [Date: Int] = [:]
        for day in candidates where day <= today {
            let value = ConsistencyLevel.level(
                source: source,
                todoCount: todoCounts[day, default: 0],
                steps: stepCounts[day, default: 0]
            )
            if value > 0 { levels[day] = value }
        }

        return ConsistencyCalendar(
            levels: levels,
            currentStreak: streak(endingAt: today, levels: levels, calendar: calendar),
            activeDays: levels.keys.count { $0 >= start && $0 <= today },
            start: start,
            end: today
        )
    }

    /// Counts back from today. Today being empty does not break the streak —
    /// the day isn't over — but an empty yesterday does.
    /// Every step is re-normalised through `startOfDay`. In time zones whose
    /// DST transition happens at midnight (Santiago, Havana, Asunción, Beirut)
    /// `date(byAdding: .day, value: -1)` lands on 01:00, and from then on every
    /// lookup into a `startOfDay`-keyed dictionary misses — silently halving
    /// the streak for the rest of the DST period.
    static func streak(endingAt today: Date, levels: [Date: Int], calendar: Calendar) -> Int {
        var cursor = calendar.startOfDay(for: today)
        if levels[cursor] == nil {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor) else { return 0 }
            cursor = calendar.startOfDay(for: yesterday)
        }

        var count = 0
        while levels[cursor] != nil {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = calendar.startOfDay(for: previous)
        }
        return count
    }
}
