import Foundation

/// Cross-process tracker for "last time a Shortcuts-triggered AppIntent ran".
/// Stored in the App Group UserDefaults so the main app can read what the
/// Shortcuts/widget process wrote.
enum AutomationStatus {
    private static let lastRunKey = "lastAutomationRun"

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: SharedContainer.appGroupID) ?? .standard
    }

    /// Call from inside an AppIntent's perform() when the run completes
    /// successfully. Records the current date so the editor can surface a
    /// "Last auto-run: …" status.
    static func recordRun() {
        defaults.set(Date(), forKey: lastRunKey)
    }

    /// Most recent successful automation run, or nil if it has never run.
    static var lastRunDate: Date? {
        defaults.object(forKey: lastRunKey) as? Date
    }

    /// Human-friendly relative description ("3h ago", "yesterday at 7:02").
    /// Returns nil if there's no recorded run.
    static func lastRunDescription() -> String? {
        guard let date = lastRunDate else { return nil }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: .now)
    }
}
