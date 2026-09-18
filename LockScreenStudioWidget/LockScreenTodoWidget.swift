import WidgetKit
import SwiftUI

// MARK: - Lock Screen (accessory) widgets
//
// Shares `TodoTimelineProvider` and `TodoEntry` with the home screen widget —
// the only difference is the rendering. Accessory widgets are drawn in a
// vibrant monochrome mode on the Lock Screen, so these views deliberately lean
// on shape, weight and layout rather than colour, and mark the one element
// that should pick up the user's tint with `.widgetAccentable()`.
//
// These are display-only on purpose. The home screen widget keeps the
// interactive check-off buttons; on the Lock Screen the targets are far below
// the 44pt HIG minimum, so a tap here just opens the app.

// MARK: - Circular

/// Progress ring: how much of today is already ticked off.
struct LockScreenTodoCircularView: View {
    let entry: TodoEntry

    var body: some View {
        Gauge(value: entry.progress) {
            Image(systemName: "checklist")
        } currentValueLabel: {
            if entry.outstandingTotal == 0 {
                // A bare "0" reads as "zero done" when the real story is
                // "nothing to do" — show the glyph instead.
                Image(systemName: "checklist")
                    .font(.caption)
            } else {
                Text("\(entry.completedToday)")
                    .font(.system(.title3, design: .rounded).bold())
            }
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .widgetAccentable()
    }
}

// MARK: - Rectangular

/// Headline count plus the next thing to do — the most useful of the three,
/// because it answers "what's left?" without unlocking.
struct LockScreenTodoRectangularView: View {
    let entry: TodoEntry

    // Three fits the ~76pt accessory height at .caption without crowding, and
    // uses the space two lines left empty.
    private var nextUp: [TodoSnapshot] {
        Array(entry.todos.filter { !$0.isCompleted }.prefix(3))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "checklist")
                    .font(.caption2.bold())
                Text(headline)
                    .font(.caption.bold())
                Spacer(minLength: 0)
            }
            .widgetAccentable()

            if nextUp.isEmpty {
                Text(entry.outstandingTotal == 0 ? "No todos yet" : "All done")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(nextUp) { todo in
                    Text(todo.text)
                        .font(.caption)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
        }
    }

    private var headline: String {
        guard entry.outstandingTotal > 0 else { return "Today" }
        guard entry.completedToday > 0 else { return "\(entry.totalIncomplete) to do" }
        return "\(entry.completedToday) done · \(entry.totalIncomplete) left"
    }
}

// MARK: - Inline

/// One line above the clock. Inline accessories get a single Text plus an
/// optional glyph, so this is deliberately just the score.
struct LockScreenTodoInlineView: View {
    let entry: TodoEntry

    var body: some View {
        if entry.outstandingTotal == 0 {
            Label("No todos", systemImage: "checklist")
        } else if entry.totalIncomplete == 0 {
            Label("All done", systemImage: "checkmark.seal.fill")
        } else {
            Label("\(entry.totalIncomplete) to do", systemImage: "checklist")
        }
    }
}

// MARK: - Family switch

struct LockScreenTodoEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: TodoEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            LockScreenTodoCircularView(entry: entry)
        case .accessoryInline:
            LockScreenTodoInlineView(entry: entry)
        default:
            LockScreenTodoRectangularView(entry: entry)
        }
    }
}

// MARK: - Widget

/// Registered separately from `TodoWidget` so each gets its own name and
/// description in the gallery it actually shows up in — WidgetKit filters the
/// Lock Screen gallery to widgets that declare accessory families.
struct LockScreenTodoWidget: Widget {
    let kind: String = "LockScreenTodoWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodoTimelineProvider()) { entry in
            LockScreenTodoEntryView(entry: entry)
                .containerBackground(.clear, for: .widget)
        }
        .configurationDisplayName("Today's Progress")
        .description("Your todo progress on the Lock Screen.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline,
        ])
    }
}
