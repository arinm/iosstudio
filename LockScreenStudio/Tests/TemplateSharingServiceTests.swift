import XCTest
@testable import LockScreenStudio

@MainActor
final class TemplateSharingServiceTests: XCTestCase {
    func testRoundTripCreatesCustomTemplateAndPreservesStructure() throws {
        let datePanel = PanelConfiguration(
            panelType: .dateTime,
            sortOrder: 1,
            isVisible: false,
            title: "Clock"
        )
        datePanel.showTitle = false
        datePanel.encodeConfig(
            DateTimeConfig(showDayOfWeek: false, showYear: true, dateFormat: .short)
        )
        let agendaPanel = PanelConfiguration(
            panelType: .agenda,
            sortOrder: 0,
            title: "Schedule"
        )
        agendaPanel.encodeConfig(
            AgendaConfig(dateRange: .week, maxEvents: 8, showTime: false, showLocation: true)
        )
        let source = WallpaperTemplate(
            builtInKey: BuiltInTemplateKey.todayDashboard.rawValue,
            name: "Shared Layout",
            description: "A useful layout",
            layoutType: .headerDetail,
            isBuiltIn: true,
            sortOrder: 1,
            panels: [datePanel, agendaPanel]
        )

        let data = try TemplateSharingService.exportData(for: source)
        let imported = try TemplateSharingService.importTemplate(from: data, sortOrder: 42)

        XCTAssertNil(imported.builtInKey)
        XCTAssertFalse(imported.isBuiltIn)
        XCTAssertEqual(imported.name, "Shared Layout")
        XCTAssertEqual(imported.templateDescription, "A useful layout")
        XCTAssertEqual(imported.layoutType, .headerDetail)
        XCTAssertEqual(imported.sortOrder, 42)
        XCTAssertEqual(imported.panels.map(\.panelType), [.agenda, .dateTime])
        XCTAssertEqual(imported.panels.map(\.sortOrder), [0, 1])
        XCTAssertFalse(imported.panels[1].isVisible)
        XCTAssertFalse(imported.panels[1].isTitleShown)

        let agenda = try XCTUnwrap(imported.panels[0].decodeConfig(AgendaConfig.self))
        XCTAssertEqual(agenda.dateRange, .week)
        XCTAssertEqual(agenda.maxEvents, 8)
        XCTAssertFalse(agenda.showTime)
        XCTAssertTrue(agenda.showLocation)
    }

    func testExportAndImportScrubPersonalPanelContent() throws {
        let priorities = PanelConfiguration(panelType: .topThree, sortOrder: 0)
        priorities.encodeConfig(
            TopThreeConfig(
                priority1: "Private priority",
                priority2: "Private appointment",
                priority3: "Private task"
            )
        )

        let todos = PanelConfiguration(panelType: .todo, sortOrder: 1)
        todos.encodeConfig(
            TodoConfig(
                showCompleted: true,
                maxItems: 8,
                source: .combined,
                reminderListIdentifier: "private-reminder-list-id",
                reminderFilter: .today
            )
        )

        let notes = PanelConfiguration(panelType: .notes, sortOrder: 2)
        notes.encodeConfig(NotesConfig(noteText: "Private notes", maxLines: 9))

        let source = WallpaperTemplate(
            name: "Privacy Test",
            isBuiltIn: false,
            panels: [priorities, todos, notes]
        )

        let data = try TemplateSharingService.exportData(for: source)
        let exportedText = try XCTUnwrap(String(data: data, encoding: .utf8))
        let imported = try TemplateSharingService.importTemplate(from: data, sortOrder: 0)

        XCTAssertFalse(exportedText.contains("Private priority"))
        XCTAssertFalse(exportedText.contains("Private appointment"))
        XCTAssertFalse(exportedText.contains("Private task"))
        XCTAssertFalse(exportedText.contains("private-reminder-list-id"))
        XCTAssertFalse(exportedText.contains("Private notes"))

        let decodedPriorities = try XCTUnwrap(
            imported.panels[0].decodeConfig(TopThreeConfig.self)
        )
        XCTAssertEqual(decodedPriorities.priority1, "")
        XCTAssertEqual(decodedPriorities.priority2, "")
        XCTAssertEqual(decodedPriorities.priority3, "")

        let decodedTodos = try XCTUnwrap(imported.panels[1].decodeConfig(TodoConfig.self))
        XCTAssertEqual(decodedTodos.source, .local)
        XCTAssertNil(decodedTodos.reminderListIdentifier)
        XCTAssertEqual(decodedTodos.maxItems, 8)

        let decodedNotes = try XCTUnwrap(imported.panels[2].decodeConfig(NotesConfig.self))
        XCTAssertEqual(decodedNotes.noteText, "")
        XCTAssertEqual(decodedNotes.maxLines, 9)
    }

    func testImportDerivesProRequirementFromPanelType() throws {
        let quote = PanelConfiguration(panelType: .quote)
        quote.encodeConfig(QuoteConfig(text: "Reusable quote", author: "Author"))
        let source = WallpaperTemplate(
            name: "Pro Layout",
            isPro: false,
            isBuiltIn: false,
            panels: [quote]
        )

        let data = try TemplateSharingService.exportData(for: source)
        let imported = try TemplateSharingService.importTemplate(from: data, sortOrder: 0)

        XCTAssertTrue(imported.isPro)
    }

    func testImportRejectsUnsupportedVersion() throws {
        let source = WallpaperTemplate(name: "Version Test", isBuiltIn: false)
        let data = try TemplateSharingService.exportData(for: source)
        var json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: data) as? [String: Any]
        )
        json["version"] = 999
        let unsupportedData = try JSONSerialization.data(withJSONObject: json)

        XCTAssertThrowsError(
            try TemplateSharingService.importTemplate(from: unsupportedData, sortOrder: 0)
        ) { error in
            XCTAssertEqual(error as? TemplateSharingError, .unsupportedVersion)
        }
    }

    /// habitsHeatmap became shareable in v1.13 (real-data Consistency panel).
    /// Export must sanitize the config: legacy habitName reset so no personal
    /// text travels, and weeksToShow clamped to the UI range.
    func testExportSanitizesHabitsHeatmapConfig() throws {
        let panel = PanelConfiguration(panelType: .habitsHeatmap)
        panel.encodeConfig(HabitsHeatmapConfig(habitName: "My private habit", weeksToShow: 99))
        let source = WallpaperTemplate(
            name: "Consistency Panel",
            isBuiltIn: false,
            panels: [panel]
        )

        let data = try TemplateSharingService.exportData(for: source)
        let imported = try TemplateSharingService.importTemplate(from: data, sortOrder: 0)
        let importedPanel = try XCTUnwrap(imported.panels.first { $0.panelType == .habitsHeatmap })
        let config = try XCTUnwrap(importedPanel.decodeConfig(HabitsHeatmapConfig.self))

        XCTAssertEqual(config.habitName, "Habit", "personal habit name must not travel in shared files")
        XCTAssertEqual(config.weeksToShow, 20, "weeks must be clamped to the UI maximum")
    }

    func testExportRejectsMoreThanMaximumPanels() {
        let panels = (0...TemplateSharingService.maxPanelCount).map {
            PanelConfiguration(panelType: .dateTime, sortOrder: $0)
        }
        let source = WallpaperTemplate(
            name: "Too Many Panels",
            isBuiltIn: false,
            panels: panels
        )

        XCTAssertThrowsError(try TemplateSharingService.exportData(for: source)) { error in
            XCTAssertEqual(error as? TemplateSharingError, .tooManyPanels)
        }
    }

    func testURLImportRejectsOversizedFile() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("lockscreenstudio")
        defer { try? FileManager.default.removeItem(at: url) }
        try Data(
            repeating: 0,
            count: TemplateSharingService.maxFileSize + 1
        ).write(to: url)

        XCTAssertThrowsError(
            try TemplateSharingService.importTemplate(from: url, sortOrder: 0)
        ) { error in
            XCTAssertEqual(error as? TemplateSharingError, .fileTooLarge)
        }
    }

    func testAnalyticsPropertiesContainNoEditableContent() {
        let source = WallpaperTemplate(
            name: "Private Template Name",
            isPro: true,
            isBuiltIn: false,
            panels: [PanelConfiguration(panelType: .dateTime)]
        )

        let properties = TemplateSharingService.analyticsProperties(for: source)

        XCTAssertEqual(properties["template_type"], "custom")
        XCTAssertEqual(properties["requires_pro"], "true")
        XCTAssertEqual(properties["panel_count"], "1_3")
        XCTAssertFalse(properties.values.contains(source.name))
    }
}
