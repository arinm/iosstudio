import Foundation
import EventKit

/// Converts model data into PanelRenderData for the renderer.
/// This is the bridge between SwiftData models + EventKit and the renderer.
@MainActor
final class PanelDataBuilder {

    private let calendarService: CalendarService
    private let remindersService: any RemindersProviding

    init(
        calendarService: CalendarService = CalendarService(),
        remindersService: any RemindersProviding = RemindersService.shared
    ) {
        self.calendarService = calendarService
        self.remindersService = remindersService
    }

    /// Builds render data for all visible panels in a template.
    func buildPanelData(
        for panels: [PanelConfiguration],
        priorities: [PriorityItem],
        todos: [TodoItem],
        date: Date = .now
    ) async -> [PanelRenderData] {
        let visiblePanels = panels
            .filter(\.isVisible)
            .sorted { $0.sortOrder < $1.sortOrder }

        var renderData: [PanelRenderData] = []

        for panel in visiblePanels {
            switch panel.panelType {
            case .dateTime:
                renderData.append(buildDateTimePanel(panel, date: date))
            case .agenda:
                let agendaData = await buildAgendaPanel(panel, date: date)
                renderData.append(agendaData)
            case .topThree:
                renderData.append(buildTopThreePanel(panel, priorities: priorities, date: date))
            case .todo:
                renderData.append(await buildTodoPanel(panel, todos: todos, date: date))
            case .habitsHeatmap:
                renderData.append(buildHabitsPanel(panel, todos: todos, date: date))
            case .quote:
                renderData.append(buildQuotePanel(panel, date: date))
            case .countdown:
                renderData.append(buildCountdownPanel(panel, date: date))
            case .notes:
                renderData.append(buildNotesPanel(panel))
            case .monthlyCalendar:
                let calData = await buildMonthlyCalendarPanel(panel, date: date)
                renderData.append(calData)
            }
        }

        return renderData
    }

    // MARK: - Individual Panel Builders

    private func buildDateTimePanel(_ panel: PanelConfiguration, date: Date) -> PanelRenderData {
        let config = panel.decodeConfig(DateTimeConfig.self) ?? DateTimeConfig()
        let formatter = DateFormatter()

        var lines: [PanelLine] = []

        if config.showDayOfWeek {
            formatter.dateFormat = "EEEE"
            lines.append(.text(formatter.string(from: date).uppercased()))
        }

        switch config.dateFormat {
        case .short:
            formatter.dateStyle = .short
        case .medium:
            formatter.dateStyle = .medium
        case .long:
            formatter.dateStyle = .long
        }
        formatter.timeStyle = .none
        lines.append(.text(formatter.string(from: date)))

        return PanelRenderData(title: nil, lines: lines)
    }

    private func buildAgendaPanel(_ panel: PanelConfiguration, date: Date) async -> PanelRenderData {
        let config = panel.decodeConfig(AgendaConfig.self) ?? AgendaConfig()

        let startDate: Date
        let endDate: Date
        let calendar = Calendar.current

        switch config.dateRange {
        case .today:
            startDate = calendar.startOfDay(for: date)
            endDate = calendar.date(byAdding: .day, value: 1, to: startDate)!
        case .tomorrow:
            startDate = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: date))!
            endDate = calendar.date(byAdding: .day, value: 1, to: startDate)!
        case .week:
            startDate = calendar.startOfDay(for: date)
            endDate = calendar.date(byAdding: .day, value: 7, to: startDate)!
        }

        let events = await calendarService.fetchEvents(from: startDate, to: endDate)
        let limitedEvents = Array(events.prefix(config.maxEvents))

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"

        let lines: [PanelLine] = limitedEvents.map { event in
            if config.showTime {
                let timeLabel: String
                if event.isAllDay {
                    timeLabel = "All Day"
                } else if let startDate = event.startDate {
                    timeLabel = timeFormatter.string(from: startDate)
                } else {
                    timeLabel = ""
                }
                return .event(time: timeLabel, title: event.title ?? "No title")
            } else {
                return .text(event.title ?? "No title")
            }
        }

        // Show appropriate message when calendar is empty
        let emptyLines: [PanelLine]
        if lines.isEmpty {
            let calStatus = await calendarService.authorizationStatus
            if calStatus == .authorized {
                emptyLines = [.text("No events today")]
            } else {
                emptyLines = []
            }
        } else {
            emptyLines = lines
        }

        return PanelRenderData(
            title: panel.title,
            lines: emptyLines
        )
    }

    private func buildTopThreePanel(
        _ panel: PanelConfiguration,
        priorities: [PriorityItem],
        date: Date
    ) -> PanelRenderData {
        let config = panel.decodeConfig(TopThreeConfig.self) ?? TopThreeConfig()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: date)

        // Prefer SwiftData priorities for today; fall back to config
        let todayPriorities = priorities
            .filter { calendar.isDate($0.date, inSameDayAs: today) }
            .sorted { $0.rank < $1.rank }

        var lines: [PanelLine] = []

        if !todayPriorities.isEmpty {
            for p in todayPriorities.prefix(3) {
                lines.append(.priority(rank: p.rank, text: p.text))
            }
        } else {
            // Fall back to panel config
            let configPriorities = [config.priority1, config.priority2, config.priority3]
            for (index, text) in configPriorities.enumerated() where !text.isEmpty {
                lines.append(.priority(rank: index + 1, text: text))
            }
        }

        if lines.isEmpty {
            // Demo data for first launch
            lines = Self.samplePriorityLines
        }

        return PanelRenderData(title: panel.isTitleShown ? panel.title : nil, lines: lines)
    }

    private func buildTodoPanel(
        _ panel: PanelConfiguration,
        todos: [TodoItem],
        date: Date
    ) async -> PanelRenderData {
        let config = panel.decodeConfig(TodoConfig.self) ?? TodoConfig()

        var lines: [PanelLine] = []
        let reminderAuthorizationStatus = config.source.usesAppleReminders
            ? await remindersService.currentAuthorizationStatus()
            : nil
        let isReminderListAvailable = config.source.usesAppleReminders
            ? await remindersService.isListAvailable(config.reminderListIdentifier)
            : true
        let shouldRenderLocalTodos = config.source.usesLocalTodos
            || (
                config.source == .appleReminders
                    && (reminderAuthorizationStatus != .authorized || !isReminderListAvailable)
            )

        if shouldRenderLocalTodos {
            let localLines = todos
                .sorted { $0.sortOrder < $1.sortOrder }
                .filter { config.showCompleted || !$0.isCompleted }
                .map { item in
                    PanelLine.todoItem(text: item.text, completed: item.isCompleted)
                }
            lines.append(contentsOf: localLines)
        }

        if config.source.usesAppleReminders,
           reminderAuthorizationStatus == .authorized,
           isReminderListAvailable {
            let reminders = await remindersService.fetchReminders(
                filter: config.reminderFilter,
                listIdentifier: config.reminderListIdentifier,
                referenceDate: date
            )
            lines.append(contentsOf: reminders.map { reminder in
                .todoItem(text: reminder.title, completed: reminder.isCompleted)
            })
        }

        let limitedLines = Array(lines.prefix(max(1, config.maxItems)))

        let displayLines: [PanelLine]
        if limitedLines.isEmpty,
           config.source == .appleReminders,
           reminderAuthorizationStatus == .authorized,
           isReminderListAvailable {
            displayLines = [.text("No reminders")]
        } else {
            displayLines = limitedLines.isEmpty ? Self.sampleTodoLines : limitedLines
        }

        return PanelRenderData(title: panel.isTitleShown ? panel.title : nil, lines: displayLines)
    }

    /// Renders the user's real todo-completion history as a contribution-style
    /// heatmap. Data comes from `TodoItem.completedAt` — the same source as the
    /// in-app History view — so the wallpaper shows a genuine streak, not
    /// sample data (which is why this panel was disabled in v1.0).
    private func buildHabitsPanel(
        _ panel: PanelConfiguration,
        todos: [TodoItem],
        date: Date
    ) -> PanelRenderData {
        let config = panel.decodeConfig(HabitsHeatmapConfig.self) ?? HabitsHeatmapConfig()
        let weeks = max(4, min(config.weeksToShow, 20))
        let cal = Calendar.current
        let today = cal.startOfDay(for: date)

        // Count completions per day.
        var countsByDay: [Date: Int] = [:]
        for todo in todos {
            guard let completedAt = todo.completedAt else { continue }
            countsByDay[cal.startOfDay(for: completedAt), default: 0] += 1
        }

        // Grid is column-major (index = week * 7 + day, day 0 = top row).
        // Anchor the last column to the Monday of the current week so today is
        // always in the rightmost column, matching the in-app History heatmap.
        let weekday = cal.component(.weekday, from: today) // Gregorian: 1=Sun, 2=Mon …
        let daysFromMonday = (weekday + 5) % 7             // Mon→0 … Sun→6
        guard let currentMonday = cal.date(byAdding: .day, value: -daysFromMonday, to: today),
              let firstMonday = cal.date(byAdding: .weekOfYear, value: -(weeks - 1), to: currentMonday)
        else {
            return PanelRenderData(title: panel.isTitleShown ? panel.title : nil, lines: [.heatmapGrid(weeks: weeks, data: [])])
        }

        var data: [Int] = []
        data.reserveCapacity(weeks * 7)
        var cursor = firstMonday
        for _ in 0..<(weeks * 7) {
            if cursor > today {
                data.append(0) // future days in the current week stay empty
            } else {
                data.append(Self.heatLevel(for: countsByDay[cursor, default: 0]))
            }
            cursor = cal.date(byAdding: .day, value: 1, to: cursor) ?? cursor
        }

        return PanelRenderData(
            title: panel.isTitleShown ? panel.title : nil,
            lines: [.heatmapGrid(weeks: weeks, data: data)]
        )
    }

    /// Same thresholds as the in-app History heatmap so both surfaces agree.
    static func heatLevel(for count: Int) -> Int {
        switch count {
        case 0: return 0
        case 1: return 1
        case 2...3: return 2
        case 4...6: return 3
        default: return 4
        }
    }

    // MARK: - Sample Data (shown before user adds their own)

    private static let sampleAgendaLines: [PanelLine] = []

    private static let samplePriorityLines: [PanelLine] = []

    private static let sampleTodoLines: [PanelLine] = []

    private func buildCountdownPanel(_ panel: PanelConfiguration, date: Date) -> PanelRenderData {
        let config = panel.decodeConfig(CountdownConfig.self) ?? CountdownConfig()
        let calendar = Calendar.current

        let startOfToday = calendar.startOfDay(for: date)
        let startOfTarget = calendar.startOfDay(for: config.targetDate)
        let components = calendar.dateComponents([.day], from: startOfToday, to: startOfTarget)
        let daysRemaining = components.day ?? 0

        var lines: [PanelLine] = []

        if daysRemaining > 0 {
            lines.append(.heroText("\(daysRemaining)"))
            lines.append(.subtitle("\(config.beforeText) \(config.eventName)"))
        } else if daysRemaining == 0 {
            lines.append(.heroText(config.todayText))
            lines.append(.subtitle(config.eventName))
        } else {
            lines.append(.heroText("\(abs(daysRemaining))"))
            lines.append(.subtitle("\(config.afterText) \(config.eventName)"))
        }

        return PanelRenderData(title: panel.isTitleShown ? panel.title : nil, lines: lines)
    }

    private func buildNotesPanel(_ panel: PanelConfiguration) -> PanelRenderData {
        let config = panel.decodeConfig(NotesConfig.self) ?? NotesConfig()

        var lines: [PanelLine] = []
        if !config.noteText.isEmpty {
            let noteLines = config.noteText
                .components(separatedBy: .newlines)
                .prefix(config.maxLines)
            for line in noteLines {
                lines.append(.text(line))
            }
        } else {
            // Empty — user configures via panel settings
        }

        return PanelRenderData(title: panel.isTitleShown ? panel.title : nil, lines: lines)
    }

    private func buildQuotePanel(_ panel: PanelConfiguration, date: Date) -> PanelRenderData {
        let config = panel.decodeConfig(QuoteConfig.self) ?? QuoteConfig()

        // Resolve the quote: a curated pack rotates deterministically per day
        // (regenerating within the same day yields the same quote); custom
        // shows the user's own text.
        let text: String
        let author: String
        if config.source == .pack,
           let packID = config.packID,
           let daily = QuotePackLibrary.todaysQuote(packID: packID, on: date) {
            text = daily.text
            author = daily.author
        } else {
            text = config.text
            author = config.author
        }

        var lines: [PanelLine] = []
        if !text.isEmpty {
            lines.append(.text("\"\(text)\""))
            if !author.isEmpty {
                lines.append(.text("— \(author)"))
            }
        }

        return PanelRenderData(title: panel.isTitleShown ? panel.title : nil, lines: lines)
    }

    private func buildMonthlyCalendarPanel(_ panel: PanelConfiguration, date: Date) async -> PanelRenderData {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let today = calendar.component(.day, from: date)

        // Fetch events for this month to mark days with dots
        var eventDays = Set<Int>()
        let config = panel.decodeConfig(MonthlyCalendarConfig.self) ?? MonthlyCalendarConfig()

        if config.showEventDots {
            var startComponents = DateComponents()
            startComponents.year = year
            startComponents.month = month
            startComponents.day = 1
            if let monthStart = calendar.date(from: startComponents),
               let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) {
                let events = await calendarService.fetchEvents(from: monthStart, to: monthEnd)
                for event in events {
                    let day = calendar.component(.day, from: event.startDate)
                    eventDays.insert(day)
                }
            }
        }

        let lines: [PanelLine] = [
            .calendarGrid(year: year, month: month, today: config.highlightToday ? today : 0, eventDays: eventDays)
        ]

        // Use month name as title if no custom title
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        let title = panel.title.isEmpty ? formatter.string(from: date) : panel.title

        return PanelRenderData(title: title, lines: lines)
    }
}
