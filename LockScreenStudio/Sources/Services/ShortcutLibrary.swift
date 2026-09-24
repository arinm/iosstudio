import Foundation

/// iCloud share links for ready-made versions of the automation recipes.
///
/// iOS has no API to install a Shortcut on the user's behalf, and unsigned
/// `.shortcut` files are refused unless the user has enabled untrusted
/// shortcuts. The only route that works for everyone is an iCloud share link,
/// which opens the Shortcuts app on an "Add Shortcut" prompt.
///
/// Producing one is a manual, one-time job per recipe, done on an iOS 26+
/// device:
///
/// 1. Build the shortcut in the Shortcuts app, with the automation trigger as
///    its first action so the trigger travels with the file. This is what makes
///    the link worth shipping at all — before iOS 27 a shared shortcut carried
///    only the actions, which left the user doing the hard half by hand.
/// 2. **Turn off the `Show Preview` option inside `Set Wallpaper Photo` before
///    sharing.** Action options travel with the shortcut, so getting this right
///    once removes the single most common setup failure for everyone who
///    imports it — instead of every one of them having to find the toggle.
/// 3. Share it, then **Copy iCloud Link**.
/// 4. Paste the link below, keyed by the recipe's `id`.
///
/// Recipes with no entry here fall back to the step-by-step walkthrough, so
/// leaving one out — or shipping with the table empty — is safe.
///
/// The guide only offers these links on iOS 27+, even though a link built there
/// might partly work on iOS 26. See `ShortcutsSetupSheet.readyMadeLink(for:)`.
enum ShortcutLibrary {

    /// Keyed by `ShortcutsSetupSheet.AutomationRecipe.id` — the ids in use are
    /// `morning`, `alarm`, `focus`, `location` and `sunset`. Fill entries in as
    /// links are published, for example:
    ///
    ///     static let shareLinks: [String: URL] = [
    ///         "morning": URL(string: "https://www.icloud.com/shortcuts/abc123")!,
    ///     ]
    static let shareLinks: [String: URL] = [:]

    /// Launch argument that fills the table with a placeholder link for every
    /// recipe, in DEBUG only.
    ///
    /// Without it the import card is unreachable until a real link is
    /// published, which means the copy, the layout and the numbered steps
    /// cannot be looked at — or screenshotted for the App Store — before the
    /// shortcut exists. The placeholder points at Apple's Shortcuts gallery so
    /// tapping it still lands somewhere harmless.
    static let previewLinksArgument = "--preview-share-links"

    static func shareLink(for recipeID: String) -> URL? {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains(previewLinksArgument) {
            return URL(string: "https://www.icloud.com/shortcuts/")
        }
        #endif
        return shareLinks[recipeID]
    }

    /// True once at least one ready-made shortcut has been published, so the
    /// guide can offer an import instead of opening on a walkthrough.
    static var hasAnyShareLink: Bool {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains(previewLinksArgument) { return true }
        #endif
        return !shareLinks.isEmpty
    }
}
