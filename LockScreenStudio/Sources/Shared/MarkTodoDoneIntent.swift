import AppIntents
import SwiftData
import WidgetKit
import Foundation

/// Toggles a todo's completion state directly from the widget.
/// Runs in the widget extension's process (no app launch) and writes to the
/// shared App Group SwiftData store so the main app sees the change too.
struct MarkTodoDoneIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Todo"
    static var description = IntentDescription("Mark a todo as done or undone from the widget.")

    /// Open the app after running? No — we want a stay-in-widget experience.
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Todo ID")
    var todoID: String

    init() {}

    init(todoID: String) {
        self.todoID = todoID
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        let container = SharedContainer.makeModelContainer()
        let context = ModelContext(container)

        guard let uuid = UUID(uuidString: todoID) else { return .result() }

        let descriptor = FetchDescriptor<TodoItem>(
            predicate: #Predicate<TodoItem> { $0.id == uuid }
        )
        guard let todo = try? context.fetch(descriptor).first else {
            return .result()
        }

        todo.isCompleted.toggle()
        todo.completedAt = todo.isCompleted ? Date() : nil
        try? context.save()

        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
