import XCTest
import SwiftData
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
        // Pixels, not points: the image used to be drawn at the screen's
        // scale, so a 1320x2868 export came out 3960x8604.
        XCTAssertEqual(result.image.cgImage?.width, 1320)
        XCTAssertEqual(result.image.cgImage?.height, 2868)
        XCTAssertEqual(UIImage(data: result.imageData)?.cgImage?.width, 1320)
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

    /// The preview used to be typeset at a third of the size, where the system
    /// font is set wider, so a line could wrap in the preview and not in the
    /// export. It is now the same drawing.
    func testPreviewIsDrawnExactlyLikeTheExport() throws {
        let preset = DevicePreset.allPresets.first { $0.id == "iphone15pro" }!
        let panels = [PanelRenderData(title: "Agenda", lines: [
            .event(time: "09:30", title: "Quarterly planning review with the design and product teams"),
        ])]

        let preview = try renderer.renderPreview(panels: panels, theme: .defaultDark, devicePreset: preset)
        let export = try renderer.render(.init(panels: panels, theme: .defaultDark, devicePreset: preset))

        XCTAssertEqual(preview.cgImage?.width, 1179)
        XCTAssertEqual(preview.pngData(), export.image.pngData())
    }

    // MARK: - Layout

    /// The layout used to give each line one font size of height, while every
    /// line is drawn at the font's full line height, about a fifth taller. On a
    /// long panel the difference added up: the separator cut through the last
    /// line, and lines past the panel's slot were not drawn at all.
    func testPanelHeightCoversEveryLineAtTheLargestTextSize() {
        let theme = RenderTheme.defaultDark.withFontScale(1.4)
        let lines = (1...8).map { PanelLine.todoItem(text: "Task \($0)", completed: false) }
        let panel = PanelRenderData(title: "To-Do", lines: lines)

        let height = panel.estimatedHeight(forWidth: 1000, theme: theme)

        let lineHeight = UIFont.systemFont(ofSize: theme.bodyFontSize).lineHeight
        XCTAssertGreaterThanOrEqual(height, 8 * (lineHeight + theme.lineSpacing))
    }

    /// A panel that runs past the bottom of the wallpaper is cut short. With
    /// exact heights the layout used to leave it out whole: on a small screen
    /// at a large text size, a To-Do panel vanished over one line too many.
    func testPanelThatRunsPastTheBottomIsCutShortNotLeftOut() throws {
        let preset = DevicePreset.allPresets.first { $0.id == "iphone15pro" }!
        let theme = RenderTheme.defaultDark
        let panels = [
            PanelRenderData(title: "Today", lines: [.text("Design review"), .text("Lunch")]),
            PanelRenderData(title: "To-Do", lines: (1...60).map {
                .todoItem(text: "Task \($0)", completed: false)
            }),
        ]

        let result = try renderer.render(.init(panels: panels, theme: theme, devicePreset: preset))

        let ink = inkedRows(in: result.image)
        let contentBottom = Int(preset.resolution.height - preset.safeArea.bottom - theme.margins.bottom)
        XCTAssertTrue(ink[(contentBottom - 300)..<contentBottom].contains(true),
                      "the panel that didn't fit was left out instead of cut short")
        XCTAssertFalse(ink[(contentBottom + 22)...].contains(true),
                       "lines were drawn past the bottom of the content area")
    }

    /// For each row of pixels, whether anything differs from the row's left
    /// edge, which is always background.
    private func inkedRows(in image: UIImage) -> [Bool] {
        guard let cg = image.cgImage else { return [] }
        let (w, h) = (cg.width, cg.height)
        var px = [UInt8](repeating: 0, count: w * h * 4)
        let ctx = CGContext(data: &px, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                            space: CGColorSpaceCreateDeviceRGB(),
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
        return (0..<h).map { y in
            let row = y * w * 4
            return stride(from: 0, to: w, by: 2).contains { x in
                let i = row + x * 4
                return (0..<3).reduce(0) { $0 + abs(Int(px[i + $1]) - Int(px[row + $1])) } > 60
            }
        }
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

    // MARK: - Built-in Template Migration

    func testTemplateSeedMigrationPreservesRenameAndDemotesDuplicate() throws {
        let configuration = ModelConfiguration(
            schema: SharedContainer.schema,
            isStoredInMemoryOnly: true
        )
        let container = try ModelContainer(
            for: SharedContainer.schema,
            configurations: [configuration]
        )
        let context = ModelContext(container)
        let suiteName = "TemplateSeederTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(4, forKey: "templateSeedVersion")

        let renamed = WallpaperTemplate(
            name: "My Morning Command Center",
            isBuiltIn: true,
            sortOrder: BuiltInTemplateKey.todayDashboard.sortOrder
        )
        let oldSeederDuplicate = WallpaperTemplate(
            name: "Today Dashboard",
            isBuiltIn: true,
            sortOrder: BuiltInTemplateKey.todayDashboard.sortOrder
        )
        context.insert(renamed)
        context.insert(oldSeederDuplicate)
        try context.save()

        XCTAssertTrue(TemplateSeeder.seedIfNeeded(context: context, defaults: defaults))

        let templates = try context.fetch(FetchDescriptor<WallpaperTemplate>())
        let migratedBuiltIns = templates.filter {
            $0.builtInKey == BuiltInTemplateKey.todayDashboard.rawValue && $0.isBuiltIn
        }
        XCTAssertEqual(migratedBuiltIns.count, 1)
        XCTAssertEqual(migratedBuiltIns.first?.name, "My Morning Command Center")
        XCTAssertFalse(oldSeederDuplicate.isBuiltIn)
        XCTAssertNil(oldSeederDuplicate.builtInKey)
        XCTAssertEqual(defaults.integer(forKey: "templateSeedVersion"), 5)

        for key in BuiltInTemplateKey.allCases {
            XCTAssertEqual(
                templates.filter { $0.isBuiltIn && $0.builtInKey == key.rawValue }.count,
                1,
                "Expected exactly one built-in template for \(key.rawValue)"
            )
        }
    }

    /// Regression: the stored seed version and the actual store can desync (App
    /// Group migration racing the widget, a reset store, iCloud restoring
    /// defaults but not the DB). When the version says "already seeded" but no
    /// built-ins exist, the seeder must re-seed so the gallery isn't empty.
    func testSeedSelfHealsWhenBuiltInsMissingDespiteCurrentVersion() throws {
        let configuration = ModelConfiguration(
            schema: SharedContainer.schema,
            isStoredInMemoryOnly: true
        )
        let container = try ModelContainer(
            for: SharedContainer.schema,
            configurations: [configuration]
        )
        let context = ModelContext(container)
        let suiteName = "TemplateSeederTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        // Version already current, but the store holds only a user's custom
        // template — no built-ins.
        defaults.set(5, forKey: "templateSeedVersion")
        let custom = WallpaperTemplate(name: "My Template", isBuiltIn: false, sortOrder: 1)
        context.insert(custom)
        try context.save()

        XCTAssertTrue(TemplateSeeder.seedIfNeeded(context: context, defaults: defaults))

        let templates = try context.fetch(FetchDescriptor<WallpaperTemplate>())
        let builtIns = templates.filter(\.isBuiltIn)
        XCTAssertEqual(builtIns.count, BuiltInTemplateKey.allCases.count, "all built-ins should be re-seeded")
        XCTAssertTrue(templates.contains { $0.name == "My Template" && !$0.isBuiltIn }, "custom template must survive")
    }
}
