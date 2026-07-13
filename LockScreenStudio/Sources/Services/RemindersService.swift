@preconcurrency import EventKit
import Foundation

enum ReminderAuthorizationStatus: Equatable, Sendable {
    case notDetermined
    case authorized
    case denied
    case restricted
}

struct ReminderListOption: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
}

struct ReminderSnapshot: Equatable, Sendable {
    let id: String
    let title: String
    let isCompleted: Bool
    let dueDate: Date?
}

protocol RemindersProviding: Sendable {
    func currentAuthorizationStatus() async -> ReminderAuthorizationStatus
    func requestAccess() async -> Bool
    func availableLists() async -> [ReminderListOption]
    func isListAvailable(_ identifier: String?) async -> Bool
    func fetchReminders(
        filter: TodoConfig.ReminderFilter,
        listIdentifier: String?,
        referenceDate: Date
    ) async -> [ReminderSnapshot]
}

/// Read-only EventKit adapter used by the To-Do panel. The app requests access
/// only after the user explicitly selects an Apple Reminders-backed source.
actor RemindersService: RemindersProviding {
    static let shared = RemindersService()

    private let eventStore = EKEventStore()

    func currentAuthorizationStatus() -> ReminderAuthorizationStatus {
        switch EKEventStore.authorizationStatus(for: .reminder) {
        case .notDetermined: return .notDetermined
        case .fullAccess: return .authorized
        case .writeOnly: return .denied
        case .denied: return .denied
        case .restricted: return .restricted
        @unknown default: return .denied
        }
    }

    func requestAccess() async -> Bool {
        do {
            return try await eventStore.requestFullAccessToReminders()
        } catch {
            return false
        }
    }

    func availableLists() -> [ReminderListOption] {
        guard currentAuthorizationStatus() == .authorized else { return [] }

        return eventStore.calendars(for: .reminder)
            .map { ReminderListOption(id: $0.calendarIdentifier, title: $0.title) }
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    func isListAvailable(_ identifier: String?) -> Bool {
        guard let identifier else { return true }
        guard currentAuthorizationStatus() == .authorized else { return false }
        return eventStore.calendar(withIdentifier: identifier) != nil
    }

    func fetchReminders(
        filter: TodoConfig.ReminderFilter,
        listIdentifier: String?,
        referenceDate: Date
    ) async -> [ReminderSnapshot] {
        guard currentAuthorizationStatus() == .authorized else { return [] }

        let selectedCalendars: [EKCalendar]?
        if let listIdentifier {
            // Never broaden a deleted selection to All Lists during background
            // generation; that could place reminders from unrelated lists on
            // the wallpaper without an explicit choice.
            guard let selectedCalendar = eventStore.calendar(withIdentifier: listIdentifier) else {
                return []
            }
            selectedCalendars = [selectedCalendar]
        } else {
            selectedCalendars = nil
        }

        let calendar = Calendar.current
        let startDate: Date?
        let endDate: Date?

        switch filter {
        case .today:
            let startOfDay = calendar.startOfDay(for: referenceDate)
            startDate = startOfDay
            endDate = calendar.date(byAdding: .day, value: 1, to: startOfDay)
        case .upcoming:
            let startOfDay = calendar.startOfDay(for: referenceDate)
            startDate = startOfDay
            endDate = calendar.date(byAdding: .day, value: 7, to: startOfDay)
        case .allIncomplete:
            startDate = nil
            endDate = nil
        }

        let predicate = eventStore.predicateForIncompleteReminders(
            withDueDateStarting: startDate,
            ending: endDate,
            calendars: selectedCalendars
        )

        let reminders: [EKReminder] = await withCheckedContinuation { continuation in
            eventStore.fetchReminders(matching: predicate) { fetchedReminders in
                continuation.resume(returning: fetchedReminders ?? [])
            }
        }

        return reminders
            .map { reminder in
                let trimmedTitle = reminder.title?
                    .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                return ReminderSnapshot(
                    id: reminder.calendarItemIdentifier,
                    title: trimmedTitle.isEmpty ? "Untitled Reminder" : trimmedTitle,
                    isCompleted: reminder.isCompleted,
                    dueDate: reminder.dueDateComponents.flatMap { calendar.date(from: $0) }
                )
            }
            .sorted { lhs, rhs in
                switch (lhs.dueDate, rhs.dueDate) {
                case let (left?, right?):
                    if left != right { return left < right }
                    return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
                case (_?, nil):
                    return true
                case (nil, _?):
                    return false
                case (nil, nil):
                    return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
                }
            }
    }
}
