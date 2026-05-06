import Foundation
import SwiftData

/// User-created to-do items for the To-Do panel.
@Model
final class TodoItem {
    var id: UUID
    var text: String
    var isCompleted: Bool
    var sortOrder: Int
    var createdAt: Date
    /// Set when isCompleted transitions to true; cleared when toggled back.
    /// Drives daily history aggregation and streak features.
    var completedAt: Date?

    init(text: String, isCompleted: Bool = false, sortOrder: Int = 0) {
        self.id = UUID()
        self.text = text
        self.isCompleted = isCompleted
        self.sortOrder = sortOrder
        self.createdAt = Date()
        self.completedAt = isCompleted ? Date() : nil
    }
}

/// User-created priority items for the Top 3 panel.
@Model
final class PriorityItem {
    var id: UUID
    var text: String
    var rank: Int // 1, 2, or 3
    var date: Date // The day this priority applies to

    init(text: String, rank: Int, date: Date = .now) {
        self.id = UUID()
        self.text = text
        self.rank = min(max(rank, 1), 3)
        self.date = Calendar.current.startOfDay(for: date)
    }
}
