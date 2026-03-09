import Foundation
import SwiftData

/// Configures one panel within a template.
/// Each panel has a type, ordering, visibility, and type-specific settings stored as JSON.
@Model
final class PanelConfiguration {
    var id: UUID
    var panelType: PanelType
    var sortOrder: Int
    var isVisible: Bool
    var title: String

    /// Type-specific configuration stored as JSON data.
    /// Decoded by each panel's renderer using its own Codable struct.
    var configData: Data?

    var template: WallpaperTemplate?

    init(
        panelType: PanelType,
        sortOrder: Int = 0,
        isVisible: Bool = true,
        title: String? = nil,
        configData: Data? = nil
    ) {
        self.id = UUID()
        self.panelType = panelType
        self.sortOrder = sortOrder
        self.isVisible = isVisible
        self.title = title ?? panelType.defaultTitle
        self.configData = configData
    }

    // MARK: - Config Encoding Helpers

    func decodeConfig<T: Decodable>(_ type: T.Type) -> T? {
        guard let data = configData else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    func encodeConfig<T: Encodable>(_ value: T) {
        configData = try? JSONEncoder().encode(value)
    }
}

// MARK: - Panel Types

enum PanelType: String, Codable, CaseIterable, Identifiable {
    case agenda = "agenda"
    case topThree = "top_three"
    case todo = "todo"
    case dateTime = "date_time"
    case habitsHeatmap = "habits_heatmap"
    case quote = "quote"
    case countdown = "countdown"
    case notes = "notes"
    case monthlyCalendar = "monthly_calendar"

    var id: String { rawValue }

    var defaultTitle: String {
        switch self {
        case .agenda: return "Agenda"
        case .topThree: return "Top 3"
        case .todo: return "To-Do"
        case .dateTime: return "Date & Time"
        case .habitsHeatmap: return "Habits"
        case .quote: return "Quote"
        case .countdown: return "Countdown"
        case .notes: return "Notes"
        case .monthlyCalendar: return "Calendar"
        }
    }

    var systemImage: String {
        switch self {
        case .agenda: return "calendar"
        case .topThree: return "star.fill"
        case .todo: return "checklist"
        case .dateTime: return "clock"
        case .habitsHeatmap: return "square.grid.3x3.fill"
        case .quote: return "quote.opening"
        case .countdown: return "hourglass"
        case .notes: return "note.text"
        case .monthlyCalendar: return "calendar.badge.clock"
        }
    }

    var isPro: Bool {
        switch self {
        case .agenda, .topThree, .todo, .dateTime, .countdown, .notes:
            return false
        case .habitsHeatmap, .quote, .monthlyCalendar:
            return true
        }
    }

    var skeletonLineCount: Int {
        switch self {
        case .dateTime: return 2
        case .agenda: return 3
        case .topThree: return 3
        case .todo: return 3
        case .quote: return 2
        case .habitsHeatmap: return 2
        case .countdown: return 2
        case .notes: return 3
        case .monthlyCalendar: return 4
        }
    }
}

// MARK: - Panel-Specific Config Structs

struct AgendaConfig: Codable {
    var dateRange: AgendaDateRange = .today
    var maxEvents: Int = 6
    var showTime: Bool = true
    var showLocation: Bool = false

    enum AgendaDateRange: String, Codable, CaseIterable {
        case today, tomorrow, week
    }
}

struct TopThreeConfig: Codable {
    var priority1: String = ""
    var priority2: String = ""
    var priority3: String = ""
}

struct TodoConfig: Codable {
    var showCompleted: Bool = false
    var maxItems: Int = 5
}

struct DateTimeConfig: Codable {
    var showDayOfWeek: Bool = true
    var showYear: Bool = false
    var dateFormat: DateFormatStyle = .long

    enum DateFormatStyle: String, Codable, CaseIterable {
        case short, medium, long
    }
}

struct HabitsHeatmapConfig: Codable {
    var habitName: String = "Habit"
    var weeksToShow: Int = 12
}

struct QuoteConfig: Codable {
    var text: String = ""
    var author: String = ""
}

struct CountdownConfig: Codable {
    var targetDate: Date = Calendar.current.date(byAdding: .day, value: 30, to: .now) ?? .now
    var eventName: String = "Event"
}

struct NotesConfig: Codable {
    var noteText: String = ""
    var maxLines: Int = 6
}

struct MonthlyCalendarConfig: Codable {
    var highlightToday: Bool = true
    var showEventDots: Bool = true
}
