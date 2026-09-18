import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Entry

struct YearEntry: TimelineEntry {
    let date: Date
    let calendar: ConsistencyCalendar
    let source: HabitsHeatmapConfig.Source
}

// MARK: - Provider

/// Reads the same two sources the Consistency panel uses — todos ticked in the
/// app and step counts from Health — so the Home Screen and the wallpaper tell
/// the same story.
struct YearTimelineProvider: TimelineProvider {

    private let healthService: any HealthProviding = HealthService.shared

    func placeholder(in context: Context) -> YearEntry {
        YearEntry(date: .now, calendar: Self.sampleCalendar(), source: .combined)
    }

    func getSnapshot(in context: Context, completion: @escaping (YearEntry) -> Void) {
        Task { completion(await currentEntry()) }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<YearEntry>) -> Void) {
        Task {
            let entry = await currentEntry()
            let cal = Calendar.current
            let nextMidnight = cal.nextDate(
                after: .now,
                matching: DateComponents(hour: 0, minute: 0),
                matchingPolicy: .nextTime
            ) ?? Date(timeIntervalSinceNow: 3_600)
            completion(Timeline(entries: [entry], policy: .after(nextMidnight)))
        }
    }

    private func currentEntry() async -> YearEntry {
        let completions = await MainActor.run { todoCompletions() }
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let yearStart = cal.date(
            from: DateComponents(year: cal.component(.year, from: today), month: 1, day: 1)
        ) ?? today

        // The user's own choice, read from their Consistency panel — inferring
        // it from "did HealthKit return anything" would flip the grid's meaning
        // between refreshes, since HealthKit is unreadable while locked.
        let source = await MainActor.run { configuredSource() }

        // Reaches back beyond January 1st so a streak running into the new
        // year is counted in full; the grid itself still only shows this year.
        let streakWindow = cal.date(byAdding: .day, value: -366, to: yearStart) ?? yearStart
        let steps = source.needsHealthAccess
            ? await healthService.dailyStepCounts(from: streakWindow, to: today)
            : [:]

        return YearEntry(
            date: .now,
            calendar: ConsistencyCalendar.forYear(
                containing: .now,
                todoCompletions: completions,
                stepsByDay: steps,
                source: source
            ),
            source: source
        )
    }

    /// The source configured on the user's Consistency panel, or `.todos` when
    /// they have no such panel.
    @MainActor
    private func configuredSource() -> HabitsHeatmapConfig.Source {
        let context = ModelContext(SharedContainer.makeModelContainer())
        let panels = (try? context.fetch(FetchDescriptor<PanelConfiguration>())) ?? []
        guard let habits = panels.first(where: { $0.panelType == .habitsHeatmap }),
              let config = habits.decodeConfig(HabitsHeatmapConfig.self)
        else { return .todos }
        return config.source
    }

    @MainActor
    private func todoCompletions() -> [Date] {
        let context = ModelContext(SharedContainer.makeModelContainer())
        let todos = (try? context.fetch(FetchDescriptor<TodoItem>())) ?? []
        return todos.compactMap(\.completedAt)
    }

    /// Plausible-looking year so the widget gallery preview isn't an empty grid.
    static func sampleCalendar() -> ConsistencyCalendar {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let year = cal.component(.year, from: today)
        let start = cal.date(from: DateComponents(year: year, month: 1, day: 1)) ?? today

        var levels: [Date: Int] = [:]
        var cursor = start
        var seed = 7
        while cursor <= today {
            seed = (seed &* 1_103_515_245 &+ 12_345) & 0x7FFF_FFFF
            let roll = seed % 10
            if roll > 2 { levels[cursor] = min(4, roll - 2) }
            cursor = cal.startOfDay(for: cal.date(byAdding: .day, value: 1, to: cursor) ?? cursor)
        }
        return ConsistencyCalendar(
            levels: levels,
            currentStreak: ConsistencyCalendar.streak(endingAt: today, levels: levels, calendar: cal),
            activeDays: levels.count,
            start: start,
            end: today
        )
    }
}

// MARK: - Shared cell styling

private enum PixelPalette {
    /// Index 0 is the "nothing happened" square; 1...4 ramp up. Indigo matches
    /// the app's accent and the heatmap already on the wallpaper.
    static func color(for level: Int, scheme: ColorScheme) -> Color {
        guard level > 0 else {
            return scheme == .dark ? Color.white.opacity(0.07) : Color.black.opacity(0.06)
        }
        return Color.indigo.opacity([0.3, 0.5, 0.72, 1.0][min(level, 4) - 1])
    }
}

// MARK: - Year grid

/// The whole year, one row per month. Deliberately small squares — this half of
/// the widget is about the shape of the year, not about reading a single day.
struct YearGrid: View {
    @Environment(\.colorScheme) private var scheme
    let calendar: ConsistencyCalendar
    let cell: CGFloat
    let spacing: CGFloat

    private let cal = Calendar.current

    var body: some View {
        let year = cal.component(.year, from: calendar.end)
        VStack(alignment: .leading, spacing: spacing) {
            ForEach(1...12, id: \.self) { month in
                HStack(spacing: spacing) {
                    Text(Self.monthInitials[month - 1])
                        .font(.system(size: cell * 0.85, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(width: cell * 1.6, alignment: .leading)

                    ForEach(1...31, id: \.self) { day in
                        cellView(year: year, month: month, day: day)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func cellView(year: Int, month: Int, day: Int) -> some View {
        if let date = cal.date(from: DateComponents(year: year, month: month, day: day)),
           cal.component(.day, from: date) == day {
            // Future days draw the empty-cell colour rather than vanishing, so
            // the year reads as one complete rectangle instead of trailing off
            // into orphaned month letters. Empty means "not yet", not "failed".
            RoundedRectangle(cornerRadius: cell * 0.25)
                .fill(PixelPalette.color(
                    for: date > calendar.end ? 0 : calendar.level(on: date),
                    scheme: scheme
                ))
                .frame(width: cell, height: cell)
        } else {
            // Short months: keep the grid rectangular without drawing a square.
            Color.clear.frame(width: cell, height: cell)
        }
    }

    private static let monthInitials = ["J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"]
}

// MARK: - Current month detail

/// The same data zoomed in: big enough to read a date and find today.
struct MonthDetail: View {
    @Environment(\.colorScheme) private var scheme
    let calendar: ConsistencyCalendar
    let cell: CGFloat
    let spacing: CGFloat

    private let cal = Calendar.current

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            HStack(spacing: spacing) {
                // Indexed, not `id: \.self` — "T" and "S" each appear twice,
                // and duplicate ForEach ids collapse the header to five cells.
                ForEach(Array(Self.weekdayInitials.enumerated()), id: \.offset) { _, day in
                    Text(day)
                        .font(.system(size: cell * 0.34, weight: .semibold))
                        .foregroundStyle(.tertiary)
                        .frame(width: cell)
                }
            }

            ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                HStack(spacing: spacing) {
                    ForEach(Array(week.enumerated()), id: \.offset) { _, date in
                        dayCell(date)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func dayCell(_ date: Date?) -> some View {
        if let date {
            let isToday = cal.isDate(date, inSameDayAs: calendar.end)
            // Future days draw the empty cell, matching the year grid above —
            // a half-drawn month reads as broken rather than as "not yet".
            let level = date > calendar.end ? 0 : calendar.level(on: date)
            RoundedRectangle(cornerRadius: cell * 0.26)
                .fill(PixelPalette.color(for: level, scheme: scheme))
                .frame(width: cell, height: cell)
                .overlay(
                    Text("\(cal.component(.day, from: date))")
                        .font(.system(size: cell * 0.38, weight: isToday ? .bold : .regular))
                        .foregroundStyle(level >= 3 ? Color.white : Color.primary.opacity(0.65))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cell * 0.26)
                        .strokeBorder(Color.primary.opacity(isToday ? 0.85 : 0), lineWidth: 1.5)
                )
        } else {
            Color.clear.frame(width: cell, height: cell)
        }
    }

    /// Month laid out Monday-first, padded with nils so every row has 7 slots.
    private var weeks: [[Date?]] {
        let end = calendar.end
        guard let interval = cal.dateInterval(of: .month, for: end) else { return [] }
        let first = interval.start
        let dayCount = cal.range(of: .day, in: .month, for: end)?.count ?? 30

        let weekday = cal.component(.weekday, from: first) // 1 = Sunday
        let leading = (weekday + 5) % 7                    // Monday = 0

        var slots: [Date?] = Array(repeating: nil, count: leading)
        for offset in 0..<dayCount {
            slots.append(cal.date(byAdding: .day, value: offset, to: first))
        }
        while slots.count % 7 != 0 { slots.append(nil) }

        return stride(from: 0, to: slots.count, by: 7).map { Array(slots[$0..<$0 + 7]) }
    }

    private static let weekdayInitials = ["M", "T", "W", "T", "F", "S", "S"]
}

// MARK: - Full page view

struct YearInPixelsEntryView: View {
    @Environment(\.colorScheme) private var scheme
    let entry: YearEntry

    private var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: entry.calendar.end)
    }

    var body: some View {
        GeometryReader { geo in
            // Derived from the container so the layout holds on every device
            // width instead of being tuned to one screen.
            //
            // The year row is one 1.6-wide month label plus 31 cells, with a
            // 0.28-cell gap between all 32 items:
            //   1.6c + 31c + 31(0.28c) = 41.28c
            let yearCell = (geo.size.width - 2) / 41.3
            // Month row is 7 cells with 6 gaps of 0.13c: 7c + 0.78c = 7.78c
            let monthCell = (geo.size.width - 2) / 7.78

            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.bottom, 14)

                YearGrid(calendar: entry.calendar, cell: yearCell, spacing: yearCell * 0.28)

                Text(monthName.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.secondary)
                    .tracking(1.1)
                    .padding(.top, 20)
                    .padding(.bottom, 8)

                MonthDetail(calendar: entry.calendar, cell: monthCell, spacing: monthCell * 0.13)

                // Only flexible gap in the stack, so leftover height collects
                // here instead of opening a hole mid-layout.
                Spacer(minLength: 8)

                footer
            }
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("\(entry.calendar.currentStreak)")
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(Color.indigo)
            VStack(alignment: .leading, spacing: 1) {
                Text("day streak")
                    .font(.system(size: 13, weight: .semibold))
                Text("\(entry.calendar.activeDays) active days this year")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
    }

    private var footer: some View {
        HStack(spacing: 5) {
            Text(entry.source == .todos ? "Todos" : "Todos + Health")
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.tertiary)
            Spacer(minLength: 0)
            Text("Less")
                .font(.system(size: 9))
                .foregroundStyle(.tertiary)
            ForEach(0...4, id: \.self) { level in
                RoundedRectangle(cornerRadius: 2)
                    .fill(PixelPalette.color(for: level, scheme: scheme))
                    .frame(width: 8, height: 8)
            }
            Text("More")
                .font(.system(size: 9))
                .foregroundStyle(.tertiary)
        }
    }
}

// MARK: - Widget

/// iOS 27's full-page portrait family. The year grid only becomes legible at
/// this size — at `systemLarge` the squares collapse into mush — so the widget
/// deliberately offers no smaller variant.
@available(iOS 27.0, *)
struct YearInPixelsWidget: Widget {
    let kind: String = "YearInPixelsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: YearTimelineProvider()) { entry in
            YearInPixelsEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Your Year")
        .description("Every day you showed up, on one page.")
        .supportedFamilies([.systemExtraLargePortrait])
    }
}
