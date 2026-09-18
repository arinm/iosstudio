import Foundation

/// iCloud share links for ready-made versions of the automation recipes.
///
/// iOS has no API to install a Shortcut on the user's behalf, and unsigned
/// `.shortcut` files are refused unless the user has enabled untrusted
/// shortcuts. The only route that works for everyone is an iCloud share link,
/// which opens the Shortcuts app on an "Add Shortcut" prompt.
///
/// Producing one is a manual, one-time job per recipe:
///
/// 1. Build the shortcut in the Shortcuts app on a device. On iOS 27 or later,
///    add the automation trigger as the shortcut's first action so the trigger
///    travels with the file; earlier iOS can only share the actions, and the
///    user still has to attach a trigger themselves.
/// 2. Share it, then **Copy iCloud Link**.
/// 3. Paste the link below, keyed by the recipe's `id`.
///
/// Recipes with no entry here fall back to the step-by-step walkthrough, so
/// leaving one out — or shipping with the table empty — is safe.
enum ShortcutLibrary {

    /// Keyed by `ShortcutsSetupSheet.AutomationRecipe.id` — the ids in use are
    /// `morning`, `alarm`, `focus`, `location` and `sunset`. Fill entries in as
    /// links are published, for example:
    ///
    ///     static let shareLinks: [String: URL] = [
    ///         "morning": URL(string: "https://www.icloud.com/shortcuts/abc123")!,
    ///     ]
    static let shareLinks: [String: URL] = [:]

    static func shareLink(for recipeID: String) -> URL? {
        shareLinks[recipeID]
    }

    /// True once at least one ready-made shortcut has been published, so the
    /// guide can promise a one-tap setup instead of a walkthrough.
    static var hasAnyShareLink: Bool { !shareLinks.isEmpty }
}
