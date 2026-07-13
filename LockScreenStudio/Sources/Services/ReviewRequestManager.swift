import Foundation

/// Decides when to ask for an App Store review. Counts genuinely positive
/// moments (successful wallpaper exports) and signals a prompt after a
/// threshold — at most once per app version so the app never nags. Apple's
/// system prompt is additionally throttled to ~3 times per year regardless of
/// how often `requestReview` is called, so this only gates *our* intent.
enum ReviewRequestManager {
    static let successCountKey = "reviewSuccessfulExportCount"
    static let lastPromptedVersionKey = "reviewLastPromptedVersion"
    static let promptThreshold = 3

    /// Records a positive moment and returns whether the caller should show the
    /// review prompt now. Returns true at most once per `currentVersion`, the
    /// first time the success count reaches the threshold.
    static func registerPositiveMomentAndShouldPrompt(
        defaults: UserDefaults = .standard,
        currentVersion: String = Self.currentShortVersion
    ) -> Bool {
        let newCount = defaults.integer(forKey: successCountKey) + 1
        defaults.set(newCount, forKey: successCountKey)

        guard newCount >= promptThreshold else { return false }

        // Only prompt once per app version — a user who already saw the prompt
        // on this version shouldn't see it again until they update.
        if defaults.string(forKey: lastPromptedVersionKey) == currentVersion {
            return false
        }
        defaults.set(currentVersion, forKey: lastPromptedVersionKey)
        return true
    }

    static var currentShortVersion: String {
        (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "0"
    }
}
