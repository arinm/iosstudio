import Foundation
import SwiftData

/// Root project model — each project holds one template configuration
/// and tracks its own theme, panels, and export history.
@Model
final class DashboardProject {
    var id: UUID
    var name: String
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade)
    var template: WallpaperTemplate?

    @Relationship(deleteRule: .cascade)
    var theme: ThemeConfiguration?

    init(
        name: String = "My Wallpaper",
        template: WallpaperTemplate? = nil,
        theme: ThemeConfiguration? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.updatedAt = Date()
        self.template = template
        self.theme = theme
    }
}
