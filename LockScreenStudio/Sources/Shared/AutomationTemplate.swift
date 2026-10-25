import Foundation

/// Which template the "Generate Today's Wallpaper" automation renders.
///
/// The intent used to take the first free template by sort order, every time.
/// Whatever the user picked, edited or paid for, the automation produced Today
/// Dashboard — and a Pro subscriber who chose a Pro template got a free one
/// every morning, with nothing on screen to say why.
///
/// It now renders the template the user last worked on: the one they generated
/// a preview from, or opened the automation guide from. Stored in the App Group
/// because the intent does not necessarily run in the app's own process.
enum AutomationTemplate {

    /// Just enough of a `WallpaperTemplate` to choose between them, so the rule
    /// can be tested without a SwiftData store.
    struct Candidate: Equatable {
        let id: UUID
        let isPro: Bool
    }

    static let rememberedIDKey = "automationTemplateID"

    static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: SharedContainer.appGroupID) ?? .standard
    }

    static func remember(_ id: UUID, defaults: UserDefaults = sharedDefaults) {
        defaults.set(id.uuidString, forKey: rememberedIDKey)
    }

    static func rememberedID(defaults: UserDefaults = sharedDefaults) -> UUID? {
        defaults.string(forKey: rememberedIDKey).flatMap(UUID.init(uuidString:))
    }

    /// The template to render, chosen from `candidates` in display order.
    ///
    /// Falls back to the first free template when nothing was chosen, when the
    /// chosen one was deleted, or when it is Pro and the subscription has lapsed.
    /// Never to an error: a morning automation that throws leaves yesterday's
    /// wallpaper up and gives the user nothing to act on.
    static func resolve(_ candidates: [Candidate], rememberedID: UUID?, isPro: Bool) -> UUID? {
        if let rememberedID,
           let chosen = candidates.first(where: { $0.id == rememberedID }),
           !chosen.isPro || isPro {
            return chosen.id
        }
        return candidates.first(where: { !$0.isPro })?.id
    }
}
