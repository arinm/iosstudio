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
    /// Optional for lightweight migration from stores created before this
    /// preference existed. A missing value preserves the original behavior.
    var showTitle: Bool?

    var isTitleShown: Bool {
        get { showTitle ?? true }
        set { showTitle = newValue }
    }

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
        self.showTitle = true
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
        case .habitsHeatmap: return "Consistency"
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

    /// Whether this panel type is available to users (shown in Add Panel sheet)
    var isAvailable: Bool {
        // habitsHeatmap was hidden in v1.0 because it rendered sample data;
        // since v1.13 it shows the user's real todo-completion history.
        true
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
    var showCompleted: Bool
    var maxItems: Int
    var source: TodoSource
    var reminderListIdentifier: String?
    var reminderFilter: ReminderFilter

    init(
        showCompleted: Bool = false,
        maxItems: Int = 5,
        source: TodoSource = .local,
        reminderListIdentifier: String? = nil,
        reminderFilter: ReminderFilter = .allIncomplete
    ) {
        self.showCompleted = showCompleted
        self.maxItems = maxItems
        self.source = source
        self.reminderListIdentifier = reminderListIdentifier
        self.reminderFilter = reminderFilter
    }

    private enum CodingKeys: String, CodingKey {
        case showCompleted
        case maxItems
        case source
        case reminderListIdentifier
        case reminderFilter
    }

    /// Configurations saved before Apple Reminders support only contain
    /// `showCompleted` and `maxItems`. Decode every new field defensively so
    /// existing To-Do panels keep their original local-only behavior.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        showCompleted = try container.decodeIfPresent(Bool.self, forKey: .showCompleted) ?? false
        maxItems = try container.decodeIfPresent(Int.self, forKey: .maxItems) ?? 5
        source = try container.decodeIfPresent(TodoSource.self, forKey: .source) ?? .local
        reminderListIdentifier = try container.decodeIfPresent(
            String.self,
            forKey: .reminderListIdentifier
        )
        reminderFilter = try container.decodeIfPresent(
            ReminderFilter.self,
            forKey: .reminderFilter
        ) ?? .allIncomplete
    }

    enum TodoSource: String, Codable, CaseIterable, Identifiable {
        case local
        case appleReminders = "apple_reminders"
        case combined

        var id: String { rawValue }

        var title: String {
            switch self {
            case .local: return "Lock Screen Studio"
            case .appleReminders: return "Apple Reminders"
            case .combined: return "Combined"
            }
        }

        var usesLocalTodos: Bool {
            self != .appleReminders
        }

        var usesAppleReminders: Bool {
            self != .local
        }
    }

    enum ReminderFilter: String, Codable, CaseIterable, Identifiable {
        case today
        case upcoming
        case allIncomplete = "all_incomplete"

        var id: String { rawValue }

        var title: String {
            switch self {
            case .today: return "Today"
            case .upcoming: return "Next 7 Days"
            case .allIncomplete: return "All Incomplete"
            }
        }
    }
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
    enum Source: String, Codable, CaseIterable, Identifiable {
        case custom
        case pack

        var id: String { rawValue }
    }

    var text: String
    var author: String
    var source: Source
    /// One of `QuotePackLibrary.allPacks` ids when `source == .pack`.
    var packID: String?

    init(
        text: String = "",
        author: String = "",
        source: Source = .custom,
        packID: String? = nil
    ) {
        self.text = text
        self.author = author
        self.source = source
        self.packID = packID
    }

    private enum CodingKeys: String, CodingKey {
        case text, author, source, packID
    }

    /// Configs saved before quote packs existed only carry text/author.
    /// Decode the new fields defensively so old panels keep their custom quote.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        text = try container.decodeIfPresent(String.self, forKey: .text) ?? ""
        author = try container.decodeIfPresent(String.self, forKey: .author) ?? ""
        source = try container.decodeIfPresent(Source.self, forKey: .source) ?? .custom
        packID = try container.decodeIfPresent(String.self, forKey: .packID)
    }
}

struct CountdownConfig: Codable {
    var targetDate: Date = Calendar.current.date(byAdding: .day, value: 30, to: .now) ?? .now
    var eventName: String = "Event"
    var beforeText: String = "days until"
    var afterText: String = "days since"
    var todayText: String = "TODAY"
}

struct NotesConfig: Codable {
    var noteText: String = ""
    var maxLines: Int = 6
}

struct MonthlyCalendarConfig: Codable {
    var highlightToday: Bool = true
    var showEventDots: Bool = true
}
