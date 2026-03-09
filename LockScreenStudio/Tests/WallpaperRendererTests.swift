import XCTest
@testable import LockScreenStudio

@MainActor
final class WallpaperRendererTests: XCTestCase {

    private var renderer: WallpaperRenderer!

    override func setUp() {
        super.setUp()
        renderer = WallpaperRenderer()
    }

    // MARK: - Output Dimensions

    func testRenderProducesCorrectDimensions() throws {
        let preset = DevicePreset.allPresets.first { $0.id == "iphone15pro" }!
        let panels = [
            PanelRenderData(title: "Test", lines: [.text("Hello")])
        ]
        let request = WallpaperRenderer.RenderRequest(
            panels: panels,
            theme: .defaultDark,
            devicePreset: preset
        )

        let result = try renderer.render(request)

        XCTAssertEqual(result.resolution.width, 1179)
        XCTAssertEqual(result.resolution.height, 2556)
        XCTAssertEqual(result.image.size.width, 1179)
        XCTAssertEqual(result.image.size.height, 2556)
    }

    func testRenderProducesCorrectDimensionsForProMax() throws {
        let preset = DevicePreset.allPresets.first { $0.id == "iphone16promax" }!
        let panels = [
            PanelRenderData(title: nil, lines: [.text("Test")])
        ]
        let request = WallpaperRenderer.RenderRequest(
            panels: panels,
            theme: .defaultDark,
            devicePreset: preset
        )

        let result = try renderer.render(request)

        XCTAssertEqual(result.resolution.width, 1320)
        XCTAssertEqual(result.resolution.height, 2868)
    }

    // MARK: - Deterministic Output

    func testSameInputsProduceSameOutput() throws {
        let preset = DevicePreset.allPresets[2]
        let panels = [
            PanelRenderData(title: "Agenda", lines: [
                .event(time: "09:00", title: "Standup"),
                .event(time: "14:00", title: "Review"),
            ]),
            PanelRenderData(title: "Top 3", lines: [
                .priority(rank: 1, text: "Ship v1"),
                .priority(rank: 2, text: "Review PRs"),
            ]),
        ]
        let request = WallpaperRenderer.RenderRequest(
            panels: panels,
            theme: .defaultDark,
            devicePreset: preset
        )

        let result1 = try renderer.render(request)
        let result2 = try renderer.render(request)

        XCTAssertEqual(result1.imageData, result2.imageData,
                       "Same inputs must produce identical output")
    }

    // MARK: - Format

    func testPNGFormat() throws {
        let request = WallpaperRenderer.RenderRequest(
            panels: [PanelRenderData(title: nil, lines: [.text("Test")])],
            theme: .defaultDark,
            devicePreset: DevicePreset.allPresets[2],
            format: .png
        )

        let result = try renderer.render(request)

        XCTAssertEqual(result.format, .png)
        // PNG magic bytes
        let header = [UInt8](result.imageData.prefix(8))
        XCTAssertEqual(header[0], 0x89)
        XCTAssertEqual(header[1], 0x50) // P
        XCTAssertEqual(header[2], 0x4E) // N
        XCTAssertEqual(header[3], 0x47) // G
    }

    func testJPEGFormat() throws {
        let request = WallpaperRenderer.RenderRequest(
            panels: [PanelRenderData(title: nil, lines: [.text("Test")])],
            theme: .defaultDark,
            devicePreset: DevicePreset.allPresets[2],
            format: .jpeg,
            jpegQuality: 0.8
        )

        let result = try renderer.render(request)

        XCTAssertEqual(result.format, .jpeg)
        // JPEG magic bytes
        let header = [UInt8](result.imageData.prefix(2))
        XCTAssertEqual(header[0], 0xFF)
        XCTAssertEqual(header[1], 0xD8)
    }

    // MARK: - Empty Panels

    func testRenderWithNoPanels() throws {
        let request = WallpaperRenderer.RenderRequest(
            panels: [],
            theme: .defaultDark,
            devicePreset: DevicePreset.allPresets[2]
        )

        let result = try renderer.render(request)

        // Should still produce a valid image (just background)
        XCTAssertNotNil(result.image)
        XCTAssertFalse(result.imageData.isEmpty)
    }

    // MARK: - Theme Variants

    func testLightTheme() throws {
        let request = WallpaperRenderer.RenderRequest(
            panels: [PanelRenderData(title: "Test", lines: [.text("Hello")])],
            theme: .defaultLight,
            devicePreset: DevicePreset.allPresets[2]
        )

        let result = try renderer.render(request)
        XCTAssertNotNil(result.image)
    }

    func testCustomAccentColor() throws {
        let theme = RenderTheme.defaultDark.withAccent(.systemTeal)
        let request = WallpaperRenderer.RenderRequest(
            panels: [PanelRenderData(title: "Test", lines: [.priority(rank: 1, text: "Task")])],
            theme: theme,
            devicePreset: DevicePreset.allPresets[2]
        )

        let result = try renderer.render(request)
        XCTAssertNotNil(result.image)
    }

    // MARK: - Preview Render

    func testPreviewRenderProducesReducedSize() throws {
        let preset = DevicePreset.allPresets.first { $0.id == "iphone15pro" }!
        let panels = [PanelRenderData(title: "Test", lines: [.text("Preview")])]

        let image = try renderer.renderPreview(
            panels: panels,
            theme: .defaultDark,
            devicePreset: preset
        )

        // Preview should be 1/3 resolution
        XCTAssertEqual(image.size.width, 393, accuracy: 1)
        XCTAssertEqual(image.size.height, 852, accuracy: 1)
    }

    // MARK: - Panel Line Types

    func testAllLineTypesRender() throws {
        let panels = [
            PanelRenderData(title: "All Types", lines: [
                .text("Simple text"),
                .event(time: "10:00", title: "Meeting"),
                .priority(rank: 1, text: "First priority"),
                .todoItem(text: "Buy groceries", completed: false),
                .todoItem(text: "Done task", completed: true),
            ])
        ]

        let request = WallpaperRenderer.RenderRequest(
            panels: panels,
            theme: .defaultDark,
            devicePreset: DevicePreset.allPresets[2]
        )

        let result = try renderer.render(request)
        XCTAssertNotNil(result.image)
        XCTAssertFalse(result.imageData.isEmpty)
    }
}
