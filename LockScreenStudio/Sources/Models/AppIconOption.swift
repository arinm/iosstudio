import UIKit

enum AppIconOption: String, CaseIterable, Identifiable {
    case `default` = "AppIcon"
    case dark = "AppIconDark"
    case minimal = "AppIconMinimal"
    case neon = "AppIconNeon"
    case classic = "AppIconClassic"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .default: return "Default"
        case .dark: return "Dark"
        case .minimal: return "Minimal"
        case .neon: return "Neon"
        case .classic: return "Classic"
        }
    }

    /// nil means the primary (default) icon.
    var alternateIconName: String? {
        self == .default ? nil : rawValue
    }

    var isPro: Bool {
        self != .default
    }

    /// Preview color for the icon picker UI
    var previewColor: UIColor {
        switch self {
        case .default: return UIColor(red: 0.42, green: 0.35, blue: 0.94, alpha: 1) // indigo
        case .dark: return UIColor(red: 0.12, green: 0.12, blue: 0.16, alpha: 1)
        case .minimal: return UIColor(white: 0.95, alpha: 1)
        case .neon: return UIColor(red: 0.0, green: 0.95, blue: 0.65, alpha: 1)
        case .classic: return UIColor(red: 0.28, green: 0.25, blue: 0.65, alpha: 1)
        }
    }

    /// Whether to use dark icon overlay on this color
    var useDarkIcon: Bool {
        self == .minimal
    }
}
