import XCTest
@testable import LockScreenStudio

final class DevicePresetTests: XCTestCase {

    func testAllPresetsHaveUniqueIDs() {
        let ids = DevicePreset.allPresets.map(\.id)
        let uniqueIDs = Set(ids)
        XCTAssertEqual(ids.count, uniqueIDs.count, "All device presets must have unique IDs")
    }

    func testAllPresetsHaveValidDimensions() {
        for preset in DevicePreset.allPresets {
            XCTAssertGreaterThan(preset.screenWidth, 0, "\(preset.name) width must be positive")
            XCTAssertGreaterThan(preset.screenHeight, 0, "\(preset.name) height must be positive")
            XCTAssertGreaterThan(preset.screenHeight, preset.screenWidth,
                                "\(preset.name) should be portrait orientation")
        }
    }

    func testAllPresetsHaveReasonableSafeAreas() {
        for preset in DevicePreset.allPresets {
            XCTAssertGreaterThanOrEqual(preset.safeArea.top, 0, "\(preset.name) top safe area")
            XCTAssertGreaterThanOrEqual(preset.safeArea.bottom, 0, "\(preset.name) bottom safe area")

            // Top safe area should be reasonable (clock area)
            let topRatio = preset.safeArea.top / CGFloat(preset.screenHeight)
            XCTAssertLessThan(topRatio, 0.2,
                              "\(preset.name) top safe area seems too large (\(topRatio))")

            // Content area should be at least 60% of screen
            let contentHeight = CGFloat(preset.screenHeight) - preset.safeArea.top - preset.safeArea.bottom
            let contentRatio = contentHeight / CGFloat(preset.screenHeight)
            XCTAssertGreaterThan(contentRatio, 0.6,
                                 "\(preset.name) content area too small (\(contentRatio))")
        }
    }

    func testDynamicIslandPresetsHaveLargerTopSafeArea() {
        let diPresets = DevicePreset.allPresets.filter(\.hasDynamicIsland)
        let nonDIPresets = DevicePreset.allPresets.filter { !$0.hasDynamicIsland }

        guard let minDI = diPresets.min(by: { $0.safeArea.top < $1.safeArea.top }),
              let maxNonDI = nonDIPresets.max(by: { $0.safeArea.top < $1.safeArea.top }) else {
            return // Skip if not enough data
        }

        XCTAssertGreaterThanOrEqual(minDI.safeArea.top, maxNonDI.safeArea.top,
                                     "Dynamic Island devices should have larger top safe areas")
    }

    func testResolutionCGSize() {
        let preset = DevicePreset.allPresets.first!
        let size = preset.resolution
        XCTAssertEqual(size.width, CGFloat(preset.screenWidth))
        XCTAssertEqual(size.height, CGFloat(preset.screenHeight))
    }

    func testKnownDeviceResolutions() {
        // Verify against Apple's published specs
        let iphone15Pro = DevicePreset.allPresets.first { $0.id == "iphone15pro" }
        XCTAssertNotNil(iphone15Pro)
        XCTAssertEqual(iphone15Pro?.screenWidth, 1179)
        XCTAssertEqual(iphone15Pro?.screenHeight, 2556)

        let iphone16ProMax = DevicePreset.allPresets.first { $0.id == "iphone16promax" }
        XCTAssertNotNil(iphone16ProMax)
        XCTAssertEqual(iphone16ProMax?.screenWidth, 1320)
        XCTAssertEqual(iphone16ProMax?.screenHeight, 2868)
    }
}

// MARK: - Device list drift

/// The device list lives in two places — `DevicePreset.allPresets` for the app
/// and `DeviceEnum` for Shortcuts — and nothing in the compiler ties them
/// together. `DeviceEnum.devicePreset` falls back to `.current` on an unknown
/// id, so a list that drifts fails silently instead of breaking the build.
final class DeviceListConsistencyTests: XCTestCase {

    private var presetIDs: Set<String> {
        Set(DevicePreset.allPresets.map(\.id))
    }

    private var enumIDs: Set<String> {
        Set(DeviceEnum.allCases.map(\.rawValue)).subtracting(["auto"])
    }

    func testEveryShortcutsDeviceResolvesToARealPreset() {
        let missing = enumIDs.subtracting(presetIDs)
        XCTAssertTrue(
            missing.isEmpty,
            "Shortcuts offers devices with no matching preset: \(missing.sorted())"
        )
    }

    /// The direction that catches "a new phone was added to the app but not to
    /// Shortcuts" — which is exactly how the iPhone 18 was missed.
    func testEveryPresetIsOfferedInShortcuts() {
        let missing = presetIDs.subtracting(enumIDs)
        XCTAssertTrue(
            missing.isEmpty,
            "Devices missing from the Shortcuts picker: \(missing.sorted())"
        )
    }

    func testEveryShortcutsDeviceHasADisplayName() {
        for device in DeviceEnum.allCases {
            XCTAssertNotNil(
                DeviceEnum.caseDisplayRepresentations[device],
                "\(device.rawValue) has no display name in Shortcuts"
            )
        }
    }

    func testIPhone18PresetsMatchTheRealPanels() {
        let pro = DevicePreset.allPresets.first { $0.id == "iphone18pro" }
        XCTAssertEqual(pro?.screenWidth, 1206)
        XCTAssertEqual(pro?.screenHeight, 2622)

        let proMax = DevicePreset.allPresets.first { $0.id == "iphone18promax" }
        XCTAssertEqual(proMax?.screenWidth, 1320)
        XCTAssertEqual(proMax?.screenHeight, 2868)
    }

    /// Regression: the fallback used to be `allPresets[2]`, which pointed at a
    /// different phone every time a new one was added to the top of the list.
    func testCurrentFallsBackToAKnownDevice() {
        XCTAssertNotNil(
            DevicePreset.allPresets.first { $0.id == "iphone17pro" },
            "the documented fallback device must exist in the list"
        )
    }
}
