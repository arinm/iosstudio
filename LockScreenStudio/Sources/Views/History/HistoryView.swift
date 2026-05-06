import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query private var todos: [TodoItem]
    @Environment(\.dismiss) private var dismiss

    private let weeksToShow = 13 // ~3 months

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Todo completion streak")
                        .font(.subheadline.bold())
                    Text("How consistently you complete todos each day")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                statsSection
                heatmapSection
                if let day = selectedDay {
                    dayDetailSection(for: day)
                }
                if completionsByDay.isEmpty {
                    emptyState
                }
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
    }

    // MARK: - Stats

    @State private var selectedDay: Date?

    private var statsSection: some View {
        HStack(spacing: 12) {
            statCard(title: "Current", value: "\(currentStreak)", suffix: streakSuffix(currentStreak), color: .indigo)
            statCard(title: "Longest", value: "\(longestStreak)", suffix: streakSuffix(longestStreak), color: .orange)
            statCard(title: "Total", value: "\(totalCompleted)", suffix: totalCompleted == 1 ? "todo" : "todos", color: .green)
        }
    }

    private func streakSuffix(_ n: Int) -> String {
        n == 1 ? "day" : "days"
    }

    private func statCard(title: String, value: String, suffix: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                Text(suffix)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Heatmap

    private var heatmapSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Daily completions")
                        .font(.subheadline.bold())
                    Text("Last \(weeksToShow) weeks")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                heatmapLegend
            }

            HeatmapGrid(
                weeks: weeksToShow,
                completionsByDay: completionsByDay,
                selectedDay: $selectedDay
            )
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var heatmapLegend: some View {
        HStack(spacing: 4) {
            Text("Less")
                .font(.caption2)
                .foregroundStyle(.secondary)
            ForEach(0..<5) { level in
                RoundedRectangle(cornerRadius: 2)
                    .fill(HeatmapGrid.color(for: level))
                    .frame(width: 10, height: 10)
            }
            Text("More")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Day Detail

    private func dayDetailSection(for day: Date) -> some View {
        let dayTodos = todos.filter { todo in
            guard let completedAt = todo.completedAt else { return false }
            return Calendar.current.isDate(completedAt, inSameDayAs: day)
        }

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(day, format: .dateTime.weekday(.wide).month().day())
                        .font(.headline)
                    Text("\(dayTodos.count) completed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    selectedDay = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }

            if dayTodos.isEmpty {
                Text("No todos completed this day.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(dayTodos) { todo in
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.subheadline)
                            Text(todo.text)
                                .font(.subheadline)
                                .strikethrough()
                                .foregroundStyle(.primary)
                            Spacer()
                            if let completedAt = todo.completedAt {
                                Text(completedAt, format: .dateTime.hour().minute())
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.system(size: 36))
                .foregroundStyle(.indigo.opacity(0.6))
            Text("Your streak starts today")
                .font(.headline)
            Text("Complete your first todo and watch this fill up.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Derived stats

    private var completionsByDay: [Date: Int] {
        let cal = Calendar.current
        var map: [Date: Int] = [:]
        for todo in todos {
            guard let completedAt = todo.completedAt else { continue }
            let day = cal.startOfDay(for: completedAt)
            map[day, default: 0] += 1
        }
        return map
    }

    private var totalCompleted: Int {
        todos.lazy.filter { $0.completedAt != nil }.count
    }

    private var currentStreak: Int {
        let cal = Calendar.current
        var streak = 0
        var day = cal.startOfDay(for: .now)
        // If today has no completions, start checking from yesterday so the
        // streak doesn't drop to 0 mid-morning before any todo is done.
        if completionsByDay[day] == nil {
            guard let yesterday = cal.date(byAdding: .day, value: -1, to: day) else { return 0 }
            day = yesterday
        }
        while completionsByDay[day, default: 0] > 0 {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return streak
    }

    private var longestStreak: Int {
        let cal = Calendar.current
        let activeDays = completionsByDay.keys.sorted()
        guard !activeDays.isEmpty else { return 0 }
        var longest = 1
        var current = 1
        for i in 1..<activeDays.count {
            let prev = activeDays[i - 1]
            let day = activeDays[i]
            if let next = cal.date(byAdding: .day, value: 1, to: prev),
               cal.isDate(next, inSameDayAs: day) {
                current += 1
                longest = max(longest, current)
            } else {
                current = 1
            }
        }
        return longest
    }
}

// MARK: - Heatmap Grid

private struct HeatmapGrid: View {
    let weeks: Int
    let completionsByDay: [Date: Int]
    @Binding var selectedDay: Date?

    private let cellSize: CGFloat = 14
    private let cellSpacing: CGFloat = 3

    var body: some View {
        let columns = buildColumns()

        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: cellSpacing) {
                weekdayLabels
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing: cellSpacing) {
                            ForEach(Array(columns.enumerated()), id: \.offset) { index, week in
                                VStack(spacing: cellSpacing) {
                                    ForEach(0..<7, id: \.self) { row in
                                        cell(for: week[row])
                                    }
                                }
                                .id(index)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .onAppear {
                        proxy.scrollTo(columns.count - 1, anchor: .trailing)
                    }
                }
            }
        }
    }

    private var weekdayLabels: some View {
        VStack(spacing: cellSpacing) {
            ForEach(["M", "T", "W", "T", "F", "S", "S"], id: \.self) { label in
                Text(label)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                    .frame(width: 12, height: cellSize)
            }
        }
    }

    @ViewBuilder
    private func cell(for date: Date?) -> some View {
        if let date {
            let count = completionsByDay[date, default: 0]
            let level = Self.level(for: count)
            let isSelected = selectedDay.map { Calendar.current.isDate($0, inSameDayAs: date) } ?? false
            let isToday = Calendar.current.isDateInToday(date)

            RoundedRectangle(cornerRadius: 3)
                .fill(Self.color(for: level))
                .frame(width: cellSize, height: cellSize)
                .overlay {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(Color.indigo, lineWidth: 2)
                    } else if isToday {
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(Color.primary.opacity(0.4), lineWidth: 1)
                    }
                }
                .onTapGesture {
                    selectedDay = (selectedDay.map { Calendar.current.isDate($0, inSameDayAs: date) } ?? false) ? nil : date
                }
        } else {
            Color.clear.frame(width: cellSize, height: cellSize)
        }
    }

    /// Builds an array of weeks, each with 7 day-slots (Mon..Sun); slots before
    /// the first week's start or after today are nil.
    private func buildColumns() -> [[Date?]] {
        // Use Calendar.current so generated dates match completionsByDay keys (both use local midnight).
        // Anchor to the Monday of the *current* week so today is always in the last column.
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        let weekday = cal.component(.weekday, from: today) // Gregorian: 1=Sun, 2=Mon …
        let daysFromMonday = (weekday + 5) % 7            // Mon→0, Tue→1 … Sun→6
        guard let currentMonday = cal.date(byAdding: .day, value: -daysFromMonday, to: today),
              let firstMonday = cal.date(byAdding: .weekOfYear, value: -(weeks - 1), to: currentMonday) else {
            return []
        }

        var columns: [[Date?]] = []
        var cursor = firstMonday
        for _ in 0..<weeks {
            var week: [Date?] = []
            for _ in 0..<7 {
                if cursor > today {
                    week.append(nil)
                } else {
                    week.append(cursor)
                }
                cursor = cal.date(byAdding: .day, value: 1, to: cursor) ?? cursor
            }
            columns.append(week)
        }
        return columns
    }

    static func level(for count: Int) -> Int {
        switch count {
        case 0: return 0
        case 1: return 1
        case 2...3: return 2
        case 4...6: return 3
        default: return 4
        }
    }

    static func color(for level: Int) -> Color {
        switch level {
        case 0: return Color(.tertiarySystemBackground)
        case 1: return Color.indigo.opacity(0.25)
        case 2: return Color.indigo.opacity(0.5)
        case 3: return Color.indigo.opacity(0.75)
        default: return Color.indigo
        }
    }
}
