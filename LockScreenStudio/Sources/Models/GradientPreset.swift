import UIKit

enum GradientPreset: String, CaseIterable, Identifiable {
    case deepPurple = "gradient_deepPurple"
    case oceanBlue = "gradient_oceanBlue"
    case sunset = "gradient_sunset"
    case forest = "gradient_forest"
    case midnight = "gradient_midnight"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .deepPurple: return "Purple"
        case .oceanBlue: return "Ocean"
        case .sunset: return "Sunset"
        case .forest: return "Forest"
        case .midnight: return "Midnight"
        }
    }

    var topColor: UIColor {
        switch self {
        case .deepPurple: return UIColor(red: 0.25, green: 0.10, blue: 0.55, alpha: 1)
        case .oceanBlue: return UIColor(red: 0.05, green: 0.15, blue: 0.40, alpha: 1)
        case .sunset: return UIColor(red: 0.55, green: 0.15, blue: 0.25, alpha: 1)
        case .forest: return UIColor(red: 0.05, green: 0.20, blue: 0.15, alpha: 1)
        case .midnight: return UIColor(red: 0.06, green: 0.06, blue: 0.15, alpha: 1)
        }
    }

    var bottomColor: UIColor {
        switch self {
        case .deepPurple: return UIColor(red: 0.08, green: 0.04, blue: 0.20, alpha: 1)
        case .oceanBlue: return UIColor(red: 0.02, green: 0.06, blue: 0.18, alpha: 1)
        case .sunset: return UIColor(red: 0.18, green: 0.06, blue: 0.12, alpha: 1)
        case .forest: return UIColor(red: 0.02, green: 0.08, blue: 0.06, alpha: 1)
        case .midnight: return UIColor(red: 0.02, green: 0.02, blue: 0.06, alpha: 1)
        }
    }

    var gradientColors: [UIColor] { [topColor, bottomColor] }

    /// All gradient presets use light text (they're all dark gradients)
    var usesLightText: Bool { true }

    var backgroundModeValue: String { rawValue }

    static func from(backgroundMode: String) -> GradientPreset? {
        GradientPreset(rawValue: backgroundMode)
    }
}
