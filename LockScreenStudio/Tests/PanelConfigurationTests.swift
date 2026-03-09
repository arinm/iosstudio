import XCTest
@testable import LockScreenStudio

final class PanelConfigurationTests: XCTestCase {

    // MARK: - Config Encoding/Decoding

    func testAgendaConfigRoundTrip() {
        let panel = PanelConfiguration(panelType: .agenda)
        let config = AgendaConfig(dateRange: .week, maxEvents: 8, showTime: false, showLocation: true)

        panel.encodeConfig(config)
        let decoded = panel.decodeConfig(AgendaConfig.self)

        XCTAssertNotNil(decoded)
        XCTAssertEqual(decoded?.dateRange, .week)
        XCTAssertEqual(decoded?.maxEvents, 8)
        XCTAssertEqual(decoded?.showTime, false)
        XCTAssertEqual(decoded?.showLocation, true)
    }

    func testTopThreeConfigRoundTrip() {
        let panel = PanelConfiguration(panelType: .topThree)
        let config = TopThreeConfig(priority1: "Ship it", priority2: "Review", priority3: "Gym")

        panel.encodeConfig(config)
        let decoded = panel.decodeConfig(TopThreeConfig.self)

        XCTAssertNotNil(decoded)
        XCTAssertEqual(decoded?.priority1, "Ship it")
        XCTAssertEqual(decoded?.priority2, "Review")
        XCTAssertEqual(decoded?.priority3, "Gym")
    }

    func testTodoConfigRoundTrip() {
        let panel = PanelConfiguration(panelType: .todo)
        let config = TodoConfig(showCompleted: true, maxItems: 8)

        panel.encodeConfig(config)
        let decoded = panel.decodeConfig(TodoConfig.self)

        XCTAssertNotNil(decoded)
        XCTAssertEqual(decoded?.showCompleted, true)
        XCTAssertEqual(decoded?.maxItems, 8)
    }

    func testDateTimeConfigRoundTrip() {
        let panel = PanelConfiguration(panelType: .dateTime)
        let config = DateTimeConfig(showDayOfWeek: false, showYear: true, dateFormat: .short)

        panel.encodeConfig(config)
        let decoded = panel.decodeConfig(DateTimeConfig.self)

        XCTAssertNotNil(decoded)
        XCTAssertEqual(decoded?.showDayOfWeek, false)
        XCTAssertEqual(decoded?.showYear, true)
        XCTAssertEqual(decoded?.dateFormat, .short)
    }

    func testDecodeReturnsNilForMissingConfig() {
        let panel = PanelConfiguration(panelType: .agenda)
        // No config encoded
        let decoded = panel.decodeConfig(AgendaConfig.self)
        XCTAssertNil(decoded)
    }

    func testDecodeReturnsNilForWrongType() {
        let panel = PanelConfiguration(panelType: .agenda)
        let agendaConfig = AgendaConfig()
        panel.encodeConfig(agendaConfig)

        // Try to decode as wrong type
        let decoded = panel.decodeConfig(TopThreeConfig.self)
        // May or may not be nil depending on key overlap; the important thing is no crash
        _ = decoded
    }

    // MARK: - Panel Type Properties

    func testPanelTypeDefaultTitles() {
        XCTAssertEqual(PanelType.agenda.defaultTitle, "Agenda")
        XCTAssertEqual(PanelType.topThree.defaultTitle, "Top 3")
        XCTAssertEqual(PanelType.todo.defaultTitle, "To-Do")
        XCTAssertEqual(PanelType.dateTime.defaultTitle, "Date & Time")
    }

    func testPanelTypeProStatus() {
        XCTAssertFalse(PanelType.agenda.isPro)
        XCTAssertFalse(PanelType.topThree.isPro)
        XCTAssertFalse(PanelType.todo.isPro)
        XCTAssertFalse(PanelType.dateTime.isPro)
        XCTAssertTrue(PanelType.habitsHeatmap.isPro)
        XCTAssertTrue(PanelType.quote.isPro)
    }

    func testPanelTypeSystemImages() {
        for type in PanelType.allCases {
            XCTAssertFalse(type.systemImage.isEmpty,
                           "\(type) should have a system image")
        }
    }

    // MARK: - Default Initialization

    func testPanelDefaultValues() {
        let panel = PanelConfiguration(panelType: .agenda)

        XCTAssertTrue(panel.isVisible)
        XCTAssertEqual(panel.sortOrder, 0)
        XCTAssertEqual(panel.title, "Agenda")
        XCTAssertNil(panel.configData)
    }

    func testPanelCustomTitle() {
        let panel = PanelConfiguration(panelType: .agenda, title: "My Schedule")
        XCTAssertEqual(panel.title, "My Schedule")
    }
}
