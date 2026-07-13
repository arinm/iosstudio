import Foundation
import SwiftData

/// Defines the layout structure: which panels in what order.
/// Built-in templates are seeded on first launch; Pro templates require subscription.
@Model
final class WallpaperTemplate {
    var id: UUID
    /// Stable identifier for built-in templates. Unlike `name`, this never
    /// changes when the user renames a template and is safe for App Intents
    /// and incremental seeding.
    var builtInKey: String?
    var name: String
    var templateDescription: String
    var layoutType: LayoutType
    var isPro: Bool
    var isBuiltIn: Bool
    var sortOrder: Int
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \PanelConfiguration.template)
    var panels: [PanelConfiguration]

    init(
        builtInKey: String? = nil,
        name: String,
        description: String = "",
        layoutType: LayoutType = .singleColumn,
        isPro: Bool = false,
        isBuiltIn: Bool = true,
        sortOrder: Int = 0,
        panels: [PanelConfiguration] = []
    ) {
        self.id = UUID()
        self.builtInKey = builtInKey
        self.name = name
        self.templateDescription = description
        self.layoutType = layoutType
        self.isPro = isPro
        self.isBuiltIn = isBuiltIn
        self.sortOrder = sortOrder
        self.createdAt = Date()
        self.panels = panels
    }
}

/// Stable identities shared by the template seeder and App Intents.
/// The order mirrors the original built-in sort order so existing installs
/// can be backfilled even when a user has renamed a template.
enum BuiltInTemplateKey: String, CaseIterable {
    case todayDashboard = "today_dashboard"
    case minimalAgenda = "minimal_agenda"
    case priorityFocus = "priority_focus"
    case weeklyOverview = "weekly_overview"
    case darkFocus = "dark_focus"
    case splitLayout = "split_layout"
    case countdown
    case morningBriefing = "morning_briefing"
    case studentPlanner = "student_planner"
    case fitness
    case meetingDay = "meeting_day"
    case minimalNotes = "minimal_notes"
    case fullDashboard = "full_dashboard"
    case justTodo = "just_todo"

    var sortOrder: Int {
        Self.allCases.firstIndex(of: self) ?? 0
    }

    /// Maps a built-in template's `sortOrder` back to its stable key. This is a
    /// positional mapping used ONLY to backfill `builtInKey` for users who
    /// installed before the key existed (see TemplateSeeder migration).
    ///
    /// ⚠️ CORRECTNESS DEPENDS ON built-in `sortOrder` being IMMUTABLE and equal
    /// to the case order above. There is intentionally no drag-to-reorder UI for
    /// built-in templates. If you ever add reordering, this positional backfill
    /// will mis-assign identities — replace it with an explicit name→key map or
    /// gate it so it only runs for never-reordered installs.
    init?(sortOrder: Int) {
        guard Self.allCases.indices.contains(sortOrder) else { return nil }
        self = Self.allCases[sortOrder]
    }
}

/// Layout variants for how panels are arranged on the wallpaper.
enum LayoutType: String, Codable, CaseIterable {
    case singleColumn = "single_column"
    case splitHorizontal = "split_horizontal"
    case headerDetail = "header_detail"
    case grid = "grid"
    case minimal = "minimal"

    var displayName: String {
        switch self {
        case .singleColumn: return "Single Column"
        case .splitHorizontal: return "Split"
        case .headerDetail: return "Header + Detail"
        case .grid: return "Grid"
        case .minimal: return "Minimal"
        }
    }
}
