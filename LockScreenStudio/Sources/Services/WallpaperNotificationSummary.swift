import Foundation

/// Builds the one-line day summary used in the "Wallpaper Updated"
/// notification, so the notification is useful before the user even taps it:
/// "3 events today, first at 09:00 · 5 todos open. Tap to open Photos and apply."
///
/// Lives in the app target (not Shared) because it depends on CalendarService;
/// the widget never sends this notification.
@MainActor
enum WallpaperNotificationSummary {

    static func build(
        todos: [TodoItem],
        calendarService: CalendarService = CalendarService(),
        now: Date = .now
    ) async -> String? {
        var parts: [String] = []

        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: now)
        if let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart),
           await calendarService.authorizationStatus == .authorized {
            let events = await calendarService.fetchEvents(from: dayStart, to: dayEnd)
            if events.isEmpty {
                parts.append("No events today")
            } else {
                let noun = events.count == 1 ? "event" : "events"
                // Only mention a time for an event that hasn't started yet —
                // "first at 09:00" at 10 PM would be misleading. Locale-aware
                // time format (12h/24h follows the user's setting).
                if let next = events.first(where: { !$0.isAllDay && ($0.startDate ?? .distantPast) >= now }),
                   let start = next.startDate {
                    let time = start.formatted(date: .omitted, time: .shortened)
                    parts.append("\(events.count) \(noun) today, next at \(time)")
                } else {
                    parts.append("\(events.count) \(noun) today")
                }
            }
        }

        let openTodos = todos.filter { !$0.isCompleted }.count
        if openTodos > 0 {
            parts.append("\(openTodos) \(openTodos == 1 ? "todo" : "todos") open")
        }

        guard !parts.isEmpty else { return nil }
        return parts.joined(separator: " · ") + ". Tap to open Photos and apply."
    }
}
