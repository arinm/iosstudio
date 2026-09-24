import Foundation

/// User preferences that the Shortcuts-triggered AppIntents need to read.
///
/// Stored in the App Group suite, like `AutomationStatus`, so the value stays
/// readable whichever process an intent happens to run in.
enum AutomationPreferences {

    /// UserDefaults key, also used by the `@AppStorage` binding in Settings —
    /// keep the two in sync.
    static let savesToPhotosKey = "automationSavesToPhotos"
    private static let migratedKey = "automationSavesToPhotosMigrated"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: SharedContainer.appGroupID) ?? .standard
    }

    /// Whether a Shortcuts-triggered render also drops a copy into the photo
    /// library.
    ///
    /// Off by default: the recommended recipe pipes the intent's returned
    /// `IntentFile` straight into the system "Set Wallpaper Photo" action, so a
    /// Photos copy is pure clutter — a daily automation would otherwise bury
    /// roughly 365 images a year in the user's library.
    ///
    /// Only affects the Shortcuts path. The built-in BGTask refresh still
    /// always saves, because there the photo library *is* the deliverable.
    static var savesToPhotos: Bool {
        get { defaults.bool(forKey: savesToPhotosKey) }
        set { defaults.set(newValue, forKey: savesToPhotosKey) }
    }

    /// One-time migration for users upgrading from a version whose setup guide
    /// had no "Set Wallpaper Photo" step.
    ///
    /// Their existing shortcut ends at the generate action and relies on the
    /// Photos copy to apply the wallpaper by hand, so defaulting them to off
    /// would send their daily wallpaper nowhere. Anyone who has run an
    /// automation before keeps the old behaviour; fresh installs get the new
    /// clutter-free default and the new recipe to go with it.
    ///
    /// Parameters are injectable purely so this can be tested against a
    /// throwaway suite instead of the real App Group.
    static func migrateSavesToPhotosIfNeeded(
        defaults: UserDefaults = AutomationPreferences.defaults,
        lastAutomationRun: Date? = AutomationStatus.lastRunDate
    ) {
        // Runs exactly once. Anyone who later turns the toggle off must stay
        // off, so this must never re-evaluate on a later launch.
        guard !defaults.bool(forKey: migratedKey) else { return }
        defaults.set(true, forKey: migratedKey)
        if lastAutomationRun != nil {
            defaults.set(true, forKey: savesToPhotosKey)
        }
    }
}
