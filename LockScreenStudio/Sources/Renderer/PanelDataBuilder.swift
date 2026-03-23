import Foundation
import EventKit

/// Converts model data into PanelRenderData for the renderer.
/// This is the bridge between SwiftData models + EventKit and the renderer.
@MainActor
final class PanelDataBuilder {

    private let calendarService: CalendarService

    init(calendarService: CalendarService = CalendarService()) {
        self.calendarService = calendarService
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
                renderData.append(buildTodoPanel(panel, todos: todos))
            case .habitsHeatmap:
                renderData.append(buildHabitsPanel(panel))
            case .quote:
                renderData.append(buildQuotePanel(panel))
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
            if config.showTime, let startDate = event.startDate {
                return .event(time: timeFormatter.string(from: startDate), title: event.title ?? "No title")
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

        return PanelRenderData(title: panel.title, lines: lines)
    }

    private func buildTodoPanel(_ panel: PanelConfiguration, todos: [TodoItem]) -> PanelRenderData {
        let config = panel.decodeConfig(TodoConfig.self) ?? TodoConfig()

        let filteredTodos = todos
            .sorted { $0.sortOrder < $1.sortOrder }
            .filter { config.showCompleted || !$0.isCompleted }
            .prefix(config.maxItems)

        let lines: [PanelLine] = filteredTodos.map { item in
            .todoItem(text: item.text, completed: item.isCompleted)
        }

        let emptyLines: [PanelLine] = lines.isEmpty ? Self.sampleTodoLines : lines

        return PanelRenderData(title: panel.title, lines: emptyLines)
    }

    private func buildHabitsPanel(_ panel: PanelConfiguration) -> PanelRenderData {
        let config = panel.decodeConfig(HabitsHeatmapConfig.self) ?? HabitsHeatmapConfig()
        let weeks = config.weeksToShow

        // Generate deterministic sample data based on habit name seed
        var data: [Int] = []
        var seed: UInt64 = 42
        for char in config.habitName.unicodeScalars { seed = seed &+ UInt64(char.value) }
        for i in 0..<(weeks * 7) {
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            let val = Int((seed >> 33) % 6) // 0-5, biased toward lower
            data.append(min(val, 4))
        }

        return PanelRenderData(
            title: panel.title,
            lines: [.heatmapGrid(weeks: weeks, data: data)]
        )
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
            lines.append(.subtitle("days until \(config.eventName)"))
        } else if daysRemaining == 0 {
            lines.append(.heroText("TODAY"))
            lines.append(.subtitle(config.eventName))
        } else {
            lines.append(.heroText("\(abs(daysRemaining))"))
            lines.append(.subtitle("days since \(config.eventName)"))
        }

        return PanelRenderData(title: panel.title, lines: lines)
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

        return PanelRenderData(title: panel.title, lines: lines)
    }

    private func buildQuotePanel(_ panel: PanelConfiguration) -> PanelRenderData {
        let config = panel.decodeConfig(QuoteConfig.self) ?? QuoteConfig()
        var lines: [PanelLine] = []

        if !config.text.isEmpty {
            lines.append(.text("\"\(config.text)\""))
            if !config.author.isEmpty {
                lines.append(.text("— \(config.author)"))
            }
        } else {
            // Empty — user configures via panel settings
        }

        return PanelRenderData(title: panel.title, lines: lines)
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
