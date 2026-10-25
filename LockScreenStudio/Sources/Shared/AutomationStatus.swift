import Foundation

/// Cross-process tracker for "last time a Shortcuts-triggered AppIntent ran".
/// Stored in the App Group UserDefaults so the main app can read what the
/// Shortcuts/widget process wrote.
enum AutomationStatus {
    private static let lastRunKey = "lastAutomationRun"
    private static let firstRunKey = "firstAutomationRun"

    static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: SharedContainer.appGroupID) ?? .standard
    }

    private static var defaults: UserDefaults { sharedDefaults }

    /// Call from inside an AppIntent's perform() when the run completes
    /// successfully. Records the current date so the editor can surface a
    /// "Last auto-run: …" status.
    ///
    /// The first run is kept too, so "it has worked on two different days" can
    /// be told apart from a single test tap. Installs that predate this key
    /// seed it from their existing last run, so people already relying on the
    /// automation count from when they actually started, not from this update.
    static func recordRun(at now: Date = .now, defaults: UserDefaults = sharedDefaults) {
        if defaults.object(forKey: firstRunKey) == nil {
            let existing = defaults.object(forKey: lastRunKey) as? Date
            defaults.set(existing ?? now, forKey: firstRunKey)
        }
        defaults.set(now, forKey: lastRunKey)
    }

    /// Most recent successful automation run, or nil if it has never run.
    static var lastRunDate: Date? {
        defaults.object(forKey: lastRunKey) as? Date
    }

    /// Earliest recorded successful run, or nil if it has never run.
    static func firstRunDate(defaults: UserDefaults = sharedDefaults) -> Date? {
        defaults.object(forKey: firstRunKey) as? Date
    }

    static func lastRunDate(defaults: UserDefaults) -> Date? {
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
