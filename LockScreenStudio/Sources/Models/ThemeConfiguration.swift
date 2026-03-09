import Foundation
import SwiftUI
import SwiftData

/// Defines the visual theme applied to the wallpaper.
@Model
final class ThemeConfiguration {
    var id: UUID
    var colorScheme: ThemeColorScheme
    var accentColor: AccentColorOption
    var fontStyle: FontStyleOption
    var backgroundOpacity: Double

    init(
        colorScheme: ThemeColorScheme = .dark,
        accentColor: AccentColorOption = .indigo,
        fontStyle: FontStyleOption = .system,
        backgroundOpacity: Double = 1.0
    ) {
        self.id = UUID()
        self.colorScheme = colorScheme
        self.accentColor = accentColor
        self.fontStyle = fontStyle
        self.backgroundOpacity = backgroundOpacity
    }
}

enum ThemeColorScheme: String, Codable, CaseIterable, Identifiable {
    case light, dark, auto

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .auto: return "Auto"
        }
    }
}

enum AccentColorOption: String, Codable, CaseIterable, Identifiable {
    case indigo, teal, orange, rose, blue, mint

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .indigo: return .indigo
        case .teal: return .teal
        case .orange: return .orange
        case .rose: return .pink
        case .blue: return .blue
        case .mint: return .mint
        }
    }

    var isPro: Bool {
        switch self {
        case .indigo, .blue: return false
        case .teal, .orange, .rose, .mint: return true
        }
    }
}

enum FontStyleOption: String, Codable, CaseIterable, Identifiable {
    case system, rounded, serif, mono

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "Default"
        case .rounded: return "Rounded"
        case .serif: return "Serif"
        case .mono: return "Mono"
        }
    }

    var fontDesign: Font.Design {
        switch self {
        case .system: return .default
        case .rounded: return .rounded
        case .serif: return .serif
        case .mono: return .monospaced
        }
    }

    var isPro: Bool {
        switch self {
        case .system: return false
        case .rounded, .serif, .mono: return true
        }
    }
}

enum FontColorOption: String, CaseIterable, Identifiable {
    case auto       // White on dark, dark on light (default)
    case white
    case cream
    case silver
    case warmGray
    case coolGray

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .auto: return "Auto"
        case .white: return "White"
        case .cream: return "Cream"
        case .silver: return "Silver"
        case .warmGray: return "Warm"
        case .coolGray: return "Cool"
        }
    }

    var previewColor: Color {
        switch self {
        case .auto: return .white
        case .white: return .white
        case .cream: return Color(red: 1.0, green: 0.96, blue: 0.88)
        case .silver: return Color(red: 0.82, green: 0.84, blue: 0.86)
        case .warmGray: return Color(red: 0.85, green: 0.80, blue: 0.75)
        case .coolGray: return Color(red: 0.75, green: 0.78, blue: 0.85)
        }
    }

    var uiColor: UIColor? {
        switch self {
        case .auto: return nil // Use theme default
        case .white: return UIColor(white: 0.97, alpha: 1)
        case .cream: return UIColor(red: 1.0, green: 0.96, blue: 0.88, alpha: 1)
        case .silver: return UIColor(red: 0.82, green: 0.84, blue: 0.86, alpha: 1)
        case .warmGray: return UIColor(red: 0.85, green: 0.80, blue: 0.75, alpha: 1)
        case .coolGray: return UIColor(red: 0.75, green: 0.78, blue: 0.85, alpha: 1)
        }
    }
}
