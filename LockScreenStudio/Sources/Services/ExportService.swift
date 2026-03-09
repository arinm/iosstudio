import UIKit
import Photos
import SwiftData
import UniformTypeIdentifiers

/// Handles wallpaper export: saving to Photos, sharing, and file creation for Shortcuts.
@MainActor
final class ExportService {

    private let renderer = WallpaperRenderer()
    private let panelDataBuilder = PanelDataBuilder()

    // MARK: - Full Generation Pipeline

    /// Generates a wallpaper from a project configuration.
    /// This is the primary API used by both the UI and App Intents.
    func generateWallpaper(
        panels: [PanelConfiguration],
        theme: ThemeConfiguration?,
        devicePreset: DevicePreset = .current,
        priorities: [PriorityItem] = [],
        todos: [TodoItem] = [],
        format: ImageFormat = .png,
        jpegQuality: CGFloat = 0.9,
        date: Date = .now
    ) async throws -> WallpaperRenderer.RenderResult {
        let renderTheme = Self.buildRenderTheme(from: theme)
        let (position, clockPadding) = Self.readLayoutSettings()
        let bgImage = Self.loadBackgroundImage()

        let panelData = await panelDataBuilder.buildPanelData(
            for: panels,
            priorities: priorities,
            todos: todos,
            date: date
        )

        let (photoX, photoY) = Self.readPhotoOffset()
        let (blur, dim) = Self.readPhotoEffects()
        let request = WallpaperRenderer.RenderRequest(
            panels: panelData,
            theme: renderTheme,
            devicePreset: devicePreset,
            format: format,
            jpegQuality: jpegQuality,
            contentPosition: position,
            clockTopPadding: clockPadding,
            backgroundImage: bgImage,
            photoOffsetX: photoX,
            photoOffsetY: photoY,
            photoBlur: blur,
            photoDim: dim
        )

        return try renderer.render(request)
    }

    /// Generates a preview image (lower resolution for fast display).
    func generatePreview(
        panels: [PanelConfiguration],
        theme: ThemeConfiguration?,
        devicePreset: DevicePreset = .current,
        priorities: [PriorityItem] = [],
        todos: [TodoItem] = [],
        date: Date = .now
    ) async throws -> UIImage {
        let renderTheme = Self.buildRenderTheme(from: theme)
        let (position, clockPadding) = Self.readLayoutSettings()
        let bgImage = Self.loadBackgroundImage()
        let (photoX, photoY) = Self.readPhotoOffset()
        let (blur, dim) = Self.readPhotoEffects()

        let panelData = await panelDataBuilder.buildPanelData(
            for: panels,
            priorities: priorities,
            todos: todos,
            date: date
        )

        return try renderer.renderPreview(
            panels: panelData,
            theme: renderTheme,
            devicePreset: devicePreset,
            contentPosition: position,
            clockTopPadding: clockPadding,
            backgroundImage: bgImage,
            photoOffsetX: photoX,
            photoOffsetY: photoY,
            photoBlur: blur,
            photoDim: dim
        )
    }

    // MARK: - Save to Photos

    func saveToPhotos(_ image: UIImage) async throws {
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }
    }

    // MARK: - Save to Temporary File (for Shortcuts)

    /// Writes the wallpaper to a temporary file and returns its URL.
    /// Used by App Intents to return a file result.
    nonisolated func saveToTemporaryFile(_ result: WallpaperRenderer.RenderResult) throws -> URL {
        let fileName = "LockScreenStudio_\(Self.timestamp).\(result.format.fileExtension)"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try result.imageData.write(to: tempURL)
        return tempURL
    }

    // MARK: - Theme Conversion

    static func buildRenderTheme(from config: ThemeConfiguration?, fontScale: CGFloat? = nil) -> RenderTheme {
        let baseTheme: RenderTheme
        if let config {
            switch config.colorScheme {
            case .dark, .auto: // Auto defaults to dark for wallpapers
                baseTheme = .defaultDark
            case .light:
                baseTheme = .defaultLight
            }
        } else {
            // Check for gradient background mode
            let bgMode = UserDefaults.standard.string(forKey: "backgroundMode") ?? "dark"
            if let gradient = GradientPreset.from(backgroundMode: bgMode) {
                baseTheme = RenderTheme.defaultDark.withGradient(gradient)
            } else {
                let scheme = UserDefaults.standard.string(forKey: "selectedColorScheme") ?? "dark"
                baseTheme = scheme == "light" ? .defaultLight : .defaultDark
            }
        }

        // Apply accent color if config provided
        let accentedTheme: RenderTheme
        if let config {
            accentedTheme = baseTheme.withAccent(UIColor(config.accentColor.color))
        } else {
            // Read accent from AppStorage fallback
            let accentKey = UserDefaults.standard.string(forKey: "selectedAccent") ?? "indigo"
            let accent = AccentColorOption(rawValue: accentKey) ?? .indigo
            accentedTheme = baseTheme.withAccent(UIColor(accent.color))
        }

        // Apply font scale: use explicit parameter, or read from UserDefaults
        let scale = fontScale ?? {
            let stored = UserDefaults.standard.double(forKey: "fontScale")
            return stored > 0 ? stored : 1.0
        }()

        let scaledTheme = accentedTheme.withFontScale(scale)

        // Apply custom font color
        let fontColorKey = UserDefaults.standard.string(forKey: "fontColor") ?? "auto"
        if let fontColor = FontColorOption(rawValue: fontColorKey),
           let uiColor = fontColor.uiColor {
            return scaledTheme.withTextColor(uiColor)
        }

        return scaledTheme
    }

    // MARK: - Background Image

    private static let bgFileName = "custom_background.jpg"

    static var backgroundImageURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(bgFileName)
    }

    static func saveBackgroundImage(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.85) else { return }
        try? data.write(to: backgroundImageURL)
    }

    static func loadBackgroundImage() -> UIImage? {
        guard UserDefaults.standard.string(forKey: "backgroundMode") == "photo" else { return nil }
        guard FileManager.default.fileExists(atPath: backgroundImageURL.path) else { return nil }
        return UIImage(contentsOfFile: backgroundImageURL.path)
    }

    static func deleteBackgroundImage() {
        try? FileManager.default.removeItem(at: backgroundImageURL)
    }

    // MARK: - Layout Settings

    static func readLayoutSettings() -> (WallpaperRenderer.ContentPosition, CGFloat) {
        let posRaw = UserDefaults.standard.string(forKey: "contentPosition") ?? "center"
        let position = WallpaperRenderer.ContentPosition(rawValue: posRaw) ?? .center
        let topPadding = UserDefaults.standard.double(forKey: "topPadding")
        return (position, topPadding)
    }

    // MARK: - Photo Offset

    static func readPhotoOffset() -> (CGFloat, CGFloat) {
        let x = UserDefaults.standard.double(forKey: "photoOffsetX")
        let y = UserDefaults.standard.double(forKey: "photoOffsetY")
        return (x, y)
    }

    // MARK: - Photo Effects

    static func readPhotoEffects() -> (CGFloat, CGFloat) {
        let blur = UserDefaults.standard.double(forKey: "photoBlur")
        let dim = UserDefaults.standard.object(forKey: "photoDim") != nil
            ? UserDefaults.standard.double(forKey: "photoDim")
            : 0.45
        return (blur, dim)
    }

    // MARK: - Private

    private nonisolated static var timestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter.string(from: Date())
    }
}
