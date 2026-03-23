import EventKit
import Foundation

/// Manages EventKit calendar access and event fetching.
/// Handles permissions gracefully — the app works without calendar access.
actor CalendarService {

    private let eventStore = EKEventStore()

    enum AuthorizationStatus {
        case notDetermined
        case authorized
        case denied
        case restricted
    }

    // MARK: - Authorization

    var authorizationStatus: AuthorizationStatus {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .notDetermined: return .notDetermined
        case .fullAccess: return .authorized
        case .writeOnly: return .denied // writeOnly cannot read events
        case .denied: return .denied
        case .restricted: return .restricted
        @unknown default: return .denied
        }
    }

    /// Requests calendar access. Returns true if granted.
    /// On iOS 17+, uses requestFullAccessToEvents().
    func requestAccess() async -> Bool {
        do {
            return try await eventStore.requestFullAccessToEvents()
        } catch {
            return false
        }
    }

    // MARK: - Event Fetching

    /// Fetches calendar events in the given date range.
    /// Returns empty array if access is denied (graceful degradation).
    func fetchEvents(from startDate: Date, to endDate: Date) -> [EKEvent] {
        guard authorizationStatus == .authorized else {
            return []
        }

        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: nil // All calendars
        )

        let events = eventStore.events(matching: predicate)
            .sorted { ($0.startDate ?? .distantPast) < ($1.startDate ?? .distantPast) }

        return events
    }

    /// Fetches today's events. Convenience method.
    func fetchTodayEvents() -> [EKEvent] {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return [] }
        return fetchEvents(from: start, to: end)
    }

    /// Returns the calendars the user has access to.
    func availableCalendars() -> [EKCalendar] {
        guard authorizationStatus == .authorized else { return [] }
        return eventStore.calendars(for: .event)
    }
}
