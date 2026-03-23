import Foundation
import SwiftData
import UIKit

/// Defines export resolution and format for different iPhone models.
@Model
final class ExportPreset {
    var id: UUID
    var name: String
    var width: Int
    var height: Int
    var format: ImageFormat
    var jpegQuality: Double

    init(
        name: String,
        width: Int,
        height: Int,
        format: ImageFormat = .png,
        jpegQuality: Double = 0.9
    ) {
        self.id = UUID()
        self.name = name
        self.width = width
        self.height = height
        self.format = format
        self.jpegQuality = jpegQuality
    }

    var resolution: CGSize {
        CGSize(width: width, height: height)
    }
}

enum ImageFormat: String, Codable, CaseIterable {
    case png, jpeg

    var displayName: String {
        switch self {
        case .png: return "PNG"
        case .jpeg: return "JPEG"
        }
    }

    var fileExtension: String {
        switch self {
        case .png: return "png"
        case .jpeg: return "jpg"
        }
    }

    var mimeType: String {
        switch self {
        case .png: return "image/png"
        case .jpeg: return "image/jpeg"
        }
    }
}

// MARK: - Device Presets (Static Data)

struct DevicePreset: Identifiable, Hashable {
    let id: String
    let name: String
    let screenWidth: Int
    let screenHeight: Int
    let safeArea: SafeAreaInsets
    let hasDynamicIsland: Bool

    var resolution: CGSize {
        CGSize(width: screenWidth, height: screenHeight)
    }

    struct SafeAreaInsets: Hashable {
        let top: CGFloat      // Clock/Dynamic Island zone
        let bottom: CGFloat   // Home indicator zone
        let leading: CGFloat
        let trailing: CGFloat
    }
}

extension DevicePreset {
    static let allPresets: [DevicePreset] = [

        // MARK: iPhone 17

        DevicePreset(
            id: "iphone17promax",
            name: "iPhone 17 Pro Max",
            screenWidth: 1320,
            screenHeight: 2868,
            safeArea: .init(top: 450, bottom: 102, leading: 0, trailing: 0),
            hasDynamicIsland: true
        ),
        DevicePreset(
            id: "iphone17pro",
            name: "iPhone 17 Pro",
            screenWidth: 1206,
            screenHeight: 2622,
            safeArea: .init(top: 430, bottom: 96, leading: 0, trailing: 0),
            hasDynamicIsland: true
        ),
        DevicePreset(
            id: "iphone17air",
            name: "iPhone 17 Air",
            screenWidth: 1260,
            screenHeight: 2736,
            safeArea: .init(top: 436, bottom: 99, leading: 0, trailing: 0),
            hasDynamicIsland: true
        ),
        DevicePreset(
            id: "iphone17",
            name: "iPhone 17",
            screenWidth: 1206,
            screenHeight: 2622,
            safeArea: .init(top: 430, bottom: 96, leading: 0, trailing: 0),
            hasDynamicIsland: true
        ),

        // MARK: iPhone 16

        DevicePreset(
            id: "iphone16promax",
            name: "iPhone 16 Pro Max",
            screenWidth: 1320,
            screenHeight: 2868,
            safeArea: .init(top: 450, bottom: 102, leading: 0, trailing: 0),
            hasDynamicIsland: true
        ),
        DevicePreset(
            id: "iphone16pro",
            name: "iPhone 16 Pro",
            screenWidth: 1206,
            screenHeight: 2622,
            safeArea: .init(top: 430, bottom: 96, leading: 0, trailing: 0),
            hasDynamicIsland: true
        ),
        DevicePreset(
            id: "iphone16plus",
            name: "iPhone 16 Plus",
            screenWidth: 1290,
            screenHeight: 2796,
            safeArea: .init(top: 440, bottom: 99, leading: 0, trailing: 0),
            hasDynamicIsland: true
        ),
        DevicePreset(
            id: "iphone16",
            name: "iPhone 16",
            screenWidth: 1179,
            screenHeight: 2556,
            safeArea: .init(top: 420, bottom: 93, leading: 0, trailing: 0),
            hasDynamicIsland: true
        ),
        DevicePreset(
            id: "iphone16e",
            name: "iPhone 16e",
            screenWidth: 1170,
            screenHeight: 2532,
            safeArea: .init(top: 382, bottom: 93, leading: 0, trailing: 0),
            hasDynamicIsland: false
        ),

        // MARK: iPhone 15

        DevicePreset(
            id: "iphone15promax",
            name: "iPhone 15 Pro Max",
            screenWidth: 1290,
            screenHeight: 2796,
            safeArea: .init(top: 440, bottom: 99, leading: 0, trailing: 0),
            hasDynamicIsland: true
        ),
        DevicePreset(
            id: "iphone15pro",
            name: "iPhone 15 Pro",
            screenWidth: 1179,
            screenHeight: 2556,
            safeArea: .init(top: 420, bottom: 93, leading: 0, trailing: 0),
            hasDynamicIsland: true
        ),
        DevicePreset(
            id: "iphone15plus",
            name: "iPhone 15 Plus",
            screenWidth: 1290,
            screenHeight: 2796,
            safeArea: .init(top: 440, bottom: 99, leading: 0, trailing: 0),
            hasDynamicIsland: true
        ),
        DevicePreset(
            id: "iphone15",
            name: "iPhone 15",
            screenWidth: 1179,
            screenHeight: 2556,
            safeArea: .init(top: 420, bottom: 93, leading: 0, trailing: 0),
            hasDynamicIsland: true
        ),

        // MARK: iPhone 14

        DevicePreset(
            id: "iphone14promax",
            name: "iPhone 14 Pro Max",
            screenWidth: 1290,
            screenHeight: 2796,
            safeArea: .init(top: 440, bottom: 99, leading: 0, trailing: 0),
            hasDynamicIsland: true
        ),
        DevicePreset(
            id: "iphone14pro",
            name: "iPhone 14 Pro",
            screenWidth: 1179,
            screenHeight: 2556,
            safeArea: .init(top: 420, bottom: 93, leading: 0, trailing: 0),
            hasDynamicIsland: true
        ),
        DevicePreset(
            id: "iphone14plus",
            name: "iPhone 14 Plus",
            screenWidth: 1284,
            screenHeight: 2778,
            safeArea: .init(top: 382, bottom: 93, leading: 0, trailing: 0),
            hasDynamicIsland: false
        ),
        DevicePreset(
            id: "iphone14",
            name: "iPhone 14",
            screenWidth: 1170,
            screenHeight: 2532,
            safeArea: .init(top: 382, bottom: 93, leading: 0, trailing: 0),
            hasDynamicIsland: false
        ),

        // MARK: iPhone 13

        DevicePreset(
            id: "iphone13promax",
            name: "iPhone 13 Pro Max",
            screenWidth: 1284,
            screenHeight: 2778,
            safeArea: .init(top: 382, bottom: 93, leading: 0, trailing: 0),
            hasDynamicIsland: false
        ),
        DevicePreset(
            id: "iphone13pro",
            name: "iPhone 13 Pro",
            screenWidth: 1170,
            screenHeight: 2532,
            safeArea: .init(top: 382, bottom: 93, leading: 0, trailing: 0),
            hasDynamicIsland: false
        ),
        DevicePreset(
            id: "iphone13",
            name: "iPhone 13",
            screenWidth: 1170,
            screenHeight: 2532,
            safeArea: .init(top: 382, bottom: 93, leading: 0, trailing: 0),
            hasDynamicIsland: false
        ),
        DevicePreset(
            id: "iphone13mini",
            name: "iPhone 13 mini",
            screenWidth: 1080,
            screenHeight: 2340,
            safeArea: .init(top: 262, bottom: 86, leading: 0, trailing: 0),
            hasDynamicIsland: false
        ),

        // MARK: iPhone 12

        DevicePreset(
            id: "iphone12promax",
            name: "iPhone 12 Pro Max",
            screenWidth: 1284,
            screenHeight: 2778,
            safeArea: .init(top: 382, bottom: 93, leading: 0, trailing: 0),
            hasDynamicIsland: false
        ),
        DevicePreset(
            id: "iphone12pro",
            name: "iPhone 12 Pro",
            screenWidth: 1170,
            screenHeight: 2532,
            safeArea: .init(top: 382, bottom: 93, leading: 0, trailing: 0),
            hasDynamicIsland: false
        ),
        DevicePreset(
            id: "iphone12",
            name: "iPhone 12",
            screenWidth: 1170,
            screenHeight: 2532,
            safeArea: .init(top: 382, bottom: 93, leading: 0, trailing: 0),
            hasDynamicIsland: false
        ),
        DevicePreset(
            id: "iphone12mini",
            name: "iPhone 12 mini",
            screenWidth: 1080,
            screenHeight: 2340,
            safeArea: .init(top: 262, bottom: 86, leading: 0, trailing: 0),
            hasDynamicIsland: false
        ),

        // MARK: iPhone SE

        DevicePreset(
            id: "iphonese3",
            name: "iPhone SE (3rd gen)",
            screenWidth: 750,
            screenHeight: 1334,
            safeArea: .init(top: 180, bottom: 0, leading: 0, trailing: 0),
            hasDynamicIsland: false
        ),
    ]

    /// Auto-detect the current device's closest matching preset.
    static var current: DevicePreset {
        let screenSize = UIScreen.main.nativeBounds.size
        let match = allPresets.min(by: { preset1, preset2 in
            let d1 = abs(CGFloat(preset1.screenWidth) - screenSize.width) +
                      abs(CGFloat(preset1.screenHeight) - screenSize.height)
            let d2 = abs(CGFloat(preset2.screenWidth) - screenSize.width) +
                      abs(CGFloat(preset2.screenHeight) - screenSize.height)
            return d1 < d2
        })
        return match ?? allPresets[2] // Default to iPhone 15 Pro
    }
}
