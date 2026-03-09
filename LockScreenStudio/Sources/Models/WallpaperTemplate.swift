import Foundation
import SwiftData

/// Defines the layout structure: which panels in what order.
/// Built-in templates are seeded on first launch; Pro templates require subscription.
@Model
final class WallpaperTemplate {
    var id: UUID
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
        name: String,
        description: String = "",
        layoutType: LayoutType = .singleColumn,
        isPro: Bool = false,
        isBuiltIn: Bool = true,
        sortOrder: Int = 0,
        panels: [PanelConfiguration] = []
    ) {
        self.id = UUID()
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
