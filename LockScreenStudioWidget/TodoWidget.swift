import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Entry

struct TodoEntry: TimelineEntry {
    let date: Date
    let todos: [TodoSnapshot]
    let totalIncomplete: Int
}

/// Lightweight value type so the widget doesn't carry SwiftData @Model objects
/// across timeline boundaries.
struct TodoSnapshot: Identifiable, Hashable {
    let id: UUID
    let text: String
    let isCompleted: Bool
}

// MARK: - Provider

struct TodoTimelineProvider: TimelineProvider {

    func placeholder(in context: Context) -> TodoEntry {
        TodoEntry(
            date: .now,
            todos: [
                TodoSnapshot(id: UUID(), text: "Tap to mark done", isCompleted: false),
                TodoSnapshot(id: UUID(), text: "Stays in sync with the app", isCompleted: false),
            ],
            totalIncomplete: 2
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (TodoEntry) -> Void) {
        Task { @MainActor in
            completion(currentEntry())
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodoEntry>) -> Void) {
        Task { @MainActor in
            let entry = currentEntry()
            // Refresh at midnight to flip "today" rollover; widget also reloads on
            // every interactive intent run via WidgetCenter.reloadAllTimelines().
            let nextMidnight = Calendar.current.nextDate(
                after: .now,
                matching: DateComponents(hour: 0, minute: 0),
                matchingPolicy: .nextTime
            ) ?? Date(timeIntervalSinceNow: 3600)
            completion(Timeline(entries: [entry], policy: .after(nextMidnight)))
        }
    }

    @MainActor
    private func currentEntry() -> TodoEntry {
        let context = ModelContext(SharedContainer.makeModelContainer())
        let descriptor = FetchDescriptor<TodoItem>(
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        let allTodos = (try? context.fetch(descriptor)) ?? []

        // Incomplete first (sorted by sortOrder), then completed sorted by
        // completedAt desc — recently ticked items stay visible with
        // strikethrough; ancient ones drop off naturally via prefix(6).
        let incomplete = allTodos
            .filter { !$0.isCompleted }
            .sorted { $0.sortOrder < $1.sortOrder }
        let completed = allTodos
            .filter { $0.isCompleted }
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
        let ordered = incomplete + completed

        let snapshots = ordered.prefix(6).map {
            TodoSnapshot(id: $0.id, text: $0.text, isCompleted: $0.isCompleted)
        }
        return TodoEntry(
            date: .now,
            todos: Array(snapshots),
            totalIncomplete: incomplete.count
        )
    }
}

// MARK: - View

struct TodoWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: TodoEntry

    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        default:
            mediumView
        }
    }

    private var rowLimit: Int {
        family == .systemSmall ? 3 : 6
    }

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 6) {
            header
            if entry.todos.isEmpty {
                emptyState
            } else {
                ForEach(entry.todos.prefix(rowLimit)) { todo in
                    todoRow(todo, compact: true)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private var mediumView: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            if entry.todos.isEmpty {
                emptyState
            } else {
                ForEach(entry.todos.prefix(rowLimit)) { todo in
                    todoRow(todo, compact: false)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 6) {
            Image(systemName: "checklist")
                .font(.caption.bold())
                .foregroundStyle(.indigo)
            Text("Today")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            Spacer()
            if entry.totalIncomplete > rowLimit {
                Text("+\(entry.totalIncomplete - rowLimit)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func todoRow(_ todo: TodoSnapshot, compact: Bool) -> some View {
        HStack(spacing: 8) {
            Button(intent: MarkTodoDoneIntent(todoID: todo.id.uuidString)) {
                Image(systemName: todo.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(compact ? .caption : .subheadline)
                    .foregroundStyle(todo.isCompleted ? .indigo : .secondary)
            }
            .buttonStyle(.plain)

            Text(todo.text)
                .font(compact ? .caption2 : .caption)
                .lineLimit(1)
                .strikethrough(todo.isCompleted)
                .foregroundStyle(todo.isCompleted ? .secondary : .primary)
            Spacer(minLength: 0)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 4) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(.green)
            Text("All done")
                .font(.caption.bold())
            Text("Add todos in the app")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Widget

struct TodoWidget: Widget {
    let kind: String = "TodoWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodoTimelineProvider()) { entry in
            TodoWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Today's Todos")
        .description("See and check off todos without opening the app.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
