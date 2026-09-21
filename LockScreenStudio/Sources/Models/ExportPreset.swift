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
    /// Hardware identifiers (the `uname` machine string) this preset describes.
    ///
    /// Only needed where resolution alone is ambiguous: the iPhone 17 and 18 Pro
    /// panels are byte-identical, so nearest-resolution matching cannot tell
    /// them apart and silently picks whichever is listed first. Empty elsewhere.
    ///
    /// `var` rather than `let` only so it gets a default in the synthesized
    /// memberwise init — a `let` with an initial value is excluded from it
    /// entirely. Every instance still lives in a `static let` table.
    var modelIdentifiers: [String] = []

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

        // MARK: iPhone 18
        //
        // Same panels as the 17 Pro line, so renders are pixel-identical and
        // `current` already resolved correctly on these devices. Listed so the
        // picker names the phone the user actually holds.

        DevicePreset(
            id: "iphone18promax",
            name: "iPhone 18 Pro Max",
            screenWidth: 1320,
            screenHeight: 2868,
            safeArea: .init(top: 450, bottom: 102, leading: 0, trailing: 0),
            hasDynamicIsland: true,
            modelIdentifiers: ["iPhone19,3"]
        ),
        DevicePreset(
            id: "iphone18pro",
            name: "iPhone 18 Pro",
            screenWidth: 1206,
            screenHeight: 2622,
            safeArea: .init(top: 430, bottom: 96, leading: 0, trailing: 0),
            hasDynamicIsland: true,
            modelIdentifiers: ["iPhone19,2"]
        ),

        // MARK: iPhone 17

        DevicePreset(
            id: "iphone17promax",
            name: "iPhone 17 Pro Max",
            screenWidth: 1320,
            screenHeight: 2868,
            safeArea: .init(top: 450, bottom: 102, leading: 0, trailing: 0),
            hasDynamicIsland: true,
            modelIdentifiers: ["iPhone18,2"]
        ),
        DevicePreset(
            id: "iphone17pro",
            name: "iPhone 17 Pro",
            screenWidth: 1206,
            screenHeight: 2622,
            safeArea: .init(top: 430, bottom: 96, leading: 0, trailing: 0),
            hasDynamicIsland: true,
            modelIdentifiers: ["iPhone18,1"]
        ),
        DevicePreset(
            // Apple ships this as "iPhone Air" — there is no "iPhone 17 Air".
            // The id stays `iphone17air`: it is the raw value of a Shortcuts
            // AppEnum case, so changing it would break saved user shortcuts.
            id: "iphone17air",
            name: "iPhone Air",
            screenWidth: 1260,
            screenHeight: 2736,
            safeArea: .init(top: 436, bottom: 99, leading: 0, trailing: 0),
            hasDynamicIsland: true,
            modelIdentifiers: ["iPhone18,4"]
        ),
        DevicePreset(
            id: "iphone17",
            name: "iPhone 17",
            screenWidth: 1206,
            screenHeight: 2622,
            safeArea: .init(top: 430, bottom: 96, leading: 0, trailing: 0),
            hasDynamicIsland: true,
            modelIdentifiers: ["iPhone18,3"]
        ),

        // MARK: iPhone 16

        DevicePreset(
            id: "iphone16promax",
            name: "iPhone 16 Pro Max",
            screenWidth: 1320,
            screenHeight: 2868,
            safeArea: .init(top: 450, bottom: 102, leading: 0, trailing: 0),
            hasDynamicIsland: true,
            modelIdentifiers: ["iPhone17,2"]
        ),
        DevicePreset(
            id: "iphone16pro",
            name: "iPhone 16 Pro",
            screenWidth: 1206,
            screenHeight: 2622,
            safeArea: .init(top: 430, bottom: 96, leading: 0, trailing: 0),
            hasDynamicIsland: true,
            modelIdentifiers: ["iPhone17,1"]
        ),
        DevicePreset(
            id: "iphone16plus",
            name: "iPhone 16 Plus",
            screenWidth: 1290,
            screenHeight: 2796,
            safeArea: .init(top: 440, bottom: 99, leading: 0, trailing: 0),
            hasDynamicIsland: true,
            modelIdentifiers: ["iPhone17,4"]
        ),
        DevicePreset(
            id: "iphone16",
            name: "iPhone 16",
            screenWidth: 1179,
            screenHeight: 2556,
            safeArea: .init(top: 420, bottom: 93, leading: 0, trailing: 0),
            hasDynamicIsland: true,
            modelIdentifiers: ["iPhone17,3"]
        ),
        DevicePreset(
            id: "iphone16e",
            name: "iPhone 16e",
            screenWidth: 1170,
            screenHeight: 2532,
            safeArea: .init(top: 382, bottom: 93, leading: 0, trailing: 0),
            hasDynamicIsland: false,
            modelIdentifiers: ["iPhone17,5"]
        ),

        // MARK: iPhone 15

        DevicePreset(
            id: "iphone15promax",
            name: "iPhone 15 Pro Max",
            screenWidth: 1290,
            screenHeight: 2796,
            safeArea: .init(top: 440, bottom: 99, leading: 0, trailing: 0),
            hasDynamicIsland: true,
            modelIdentifiers: ["iPhone16,2"]
        ),
        DevicePreset(
            id: "iphone15pro",
            name: "iPhone 15 Pro",
            screenWidth: 1179,
            screenHeight: 2556,
            safeArea: .init(top: 420, bottom: 93, leading: 0, trailing: 0),
            hasDynamicIsland: true,
            modelIdentifiers: ["iPhone16,1"]
        ),
        DevicePreset(
            id: "iphone15plus",
            name: "iPhone 15 Plus",
            screenWidth: 1290,
            screenHeight: 2796,
            safeArea: .init(top: 440, bottom: 99, leading: 0, trailing: 0),
            hasDynamicIsland: true,
            modelIdentifiers: ["iPhone15,5"]
        ),
        DevicePreset(
            id: "iphone15",
            name: "iPhone 15",
            screenWidth: 1179,
            screenHeight: 2556,
            safeArea: .init(top: 420, bottom: 93, leading: 0, trailing: 0),
            hasDynamicIsland: true,
            modelIdentifiers: ["iPhone15,4"]
        ),

        // MARK: iPhone 14

        DevicePreset(
            id: "iphone14promax",
            name: "iPhone 14 Pro Max",
            screenWidth: 1290,
            screenHeight: 2796,
            safeArea: .init(top: 440, bottom: 99, leading: 0, trailing: 0),
            hasDynamicIsland: true,
            modelIdentifiers: ["iPhone15,3"]
        ),
        DevicePreset(
            id: "iphone14pro",
            name: "iPhone 14 Pro",
            screenWidth: 1179,
            screenHeight: 2556,
            safeArea: .init(top: 420, bottom: 93, leading: 0, trailing: 0),
            hasDynamicIsland: true,
            modelIdentifiers: ["iPhone15,2"]
        ),
        DevicePreset(
            id: "iphone14plus",
            name: "iPhone 14 Plus",
            screenWidth: 1284,
            screenHeight: 2778,
            safeArea: .init(top: 382, bottom: 93, leading: 0, trailing: 0),
            hasDynamicIsland: false,
            modelIdentifiers: ["iPhone14,8"]
        ),
        DevicePreset(
            id: "iphone14",
            name: "iPhone 14",
            screenWidth: 1170,
            screenHeight: 2532,
            safeArea: .init(top: 382, bottom: 93, leading: 0, trailing: 0),
            hasDynamicIsland: false,
            modelIdentifiers: ["iPhone14,7"]
        ),

        // MARK: iPhone 13

        DevicePreset(
            id: "iphone13promax",
            name: "iPhone 13 Pro Max",
            screenWidth: 1284,
            screenHeight: 2778,
            safeArea: .init(top: 382, bottom: 93, leading: 0, trailing: 0),
            hasDynamicIsland: false,
            modelIdentifiers: ["iPhone14,3"]
        ),
        DevicePreset(
            id: "iphone13pro",
            name: "iPhone 13 Pro",
            screenWidth: 1170,
            screenHeight: 2532,
            safeArea: .init(top: 382, bottom: 93, leading: 0, trailing: 0),
            hasDynamicIsland: false,
            modelIdentifiers: ["iPhone14,2"]
        ),
        DevicePreset(
            id: "iphone13",
            name: "iPhone 13",
            screenWidth: 1170,
            screenHeight: 2532,
            safeArea: .init(top: 382, bottom: 93, leading: 0, trailing: 0),
            hasDynamicIsland: false,
            modelIdentifiers: ["iPhone14,5"]
        ),
        DevicePreset(
            id: "iphone13mini",
            name: "iPhone 13 mini",
            screenWidth: 1080,
            screenHeight: 2340,
            safeArea: .init(top: 262, bottom: 86, leading: 0, trailing: 0),
            hasDynamicIsland: false,
            modelIdentifiers: ["iPhone14,4"]
        ),

        // MARK: iPhone 12

        DevicePreset(
            id: "iphone12promax",
            name: "iPhone 12 Pro Max",
            screenWidth: 1284,
            screenHeight: 2778,
            safeArea: .init(top: 382, bottom: 93, leading: 0, trailing: 0),
            hasDynamicIsland: false,
            modelIdentifiers: ["iPhone13,4"]
        ),
        DevicePreset(
            id: "iphone12pro",
            name: "iPhone 12 Pro",
            screenWidth: 1170,
            screenHeight: 2532,
            safeArea: .init(top: 382, bottom: 93, leading: 0, trailing: 0),
            hasDynamicIsland: false,
            modelIdentifiers: ["iPhone13,3"]
        ),
        DevicePreset(
            id: "iphone12",
            name: "iPhone 12",
            screenWidth: 1170,
            screenHeight: 2532,
            safeArea: .init(top: 382, bottom: 93, leading: 0, trailing: 0),
            hasDynamicIsland: false,
            modelIdentifiers: ["iPhone13,2"]
        ),
        DevicePreset(
            id: "iphone12mini",
            name: "iPhone 12 mini",
            screenWidth: 1080,
            screenHeight: 2340,
            safeArea: .init(top: 262, bottom: 86, leading: 0, trailing: 0),
            hasDynamicIsland: false,
            modelIdentifiers: ["iPhone13,1"]
        ),

        // MARK: iPhone SE

        DevicePreset(
            id: "iphonese3",
            name: "iPhone SE (3rd gen)",
            screenWidth: 750,
            screenHeight: 1334,
            safeArea: .init(top: 180, bottom: 0, leading: 0, trailing: 0),
            hasDynamicIsland: false,
            modelIdentifiers: ["iPhone14,6"]
        ),
    ]

    /// The device's `uname` machine string, e.g. "iPhone19,2".
    ///
    /// On the simulator `uname` reports the host architecture, so the simulated
    /// device is read from the environment instead — otherwise every simulator
    /// run falls through to resolution matching.
    static var hardwareModel: String {
        #if targetEnvironment(simulator)
        if let simulated = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] {
            return simulated
        }
        #endif
        var info = utsname()
        uname(&info)
        // Mirror rather than rebinding a pointer into `info.machine`: taking
        // that pointer while `info` is still mutable trips Swift's exclusivity
        // checker, and the tuple-of-CChar has no nicer accessor.
        return Mirror(reflecting: info.machine).children.reduce(into: "") { result, element in
            guard let scalar = element.value as? CChar, scalar != 0 else { return }
            result.append(Character(UnicodeScalar(UInt8(scalar))))
        }
    }

    /// Auto-detect the current device's closest matching preset.
    ///
    /// Hardware identifier first: an iPhone 17 Pro and an iPhone 18 Pro have the
    /// same panel, so resolution alone would label one as the other depending
    /// purely on which is listed first. Resolution matching remains the fallback,
    /// and is what a phone released after this build lands on.
    static var current: DevicePreset {
        if let exact = allPresets.first(where: { $0.modelIdentifiers.contains(hardwareModel) }) {
            return exact
        }

        let screenSize = UIScreen.main.nativeBounds.size
        let match = allPresets.min(by: { preset1, preset2 in
            let d1 = abs(CGFloat(preset1.screenWidth) - screenSize.width) +
                      abs(CGFloat(preset1.screenHeight) - screenSize.height)
            let d2 = abs(CGFloat(preset2.screenWidth) - screenSize.width) +
                      abs(CGFloat(preset2.screenHeight) - screenSize.height)
            return d1 < d2
        })
        // Looked up by id, not index: the list grows at the top with each new
        // phone, and the old `allPresets[2]` silently pointed at a different
        // device every time it did.
        return match
            ?? allPresets.first { $0.id == "iphone17pro" }
            ?? allPresets[0]
    }
}
