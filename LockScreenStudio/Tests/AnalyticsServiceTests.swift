import XCTest
@testable import LockScreenStudio

@MainActor
final class AnalyticsServiceTests: XCTestCase {
    func testTracksEventAndPropertiesThroughInjectedSink() {
        let sink = RecordingAnalyticsSink()
        let analytics = AnalyticsService(sink: sink)

        analytics.track(.exportCompleted, properties: ["format": "png"])

        XCTAssertEqual(
            sink.events,
            [AnalyticsEvent(name: .exportCompleted, properties: ["format": "png"])]
        )
    }

    func testTemplatePropertiesNeverContainEditableName() {
        let template = WallpaperTemplate(
            builtInKey: BuiltInTemplateKey.todayDashboard.rawValue,
            name: "Private user-defined name",
            isBuiltIn: true
        )

        let properties = AnalyticsService.templateProperties(template)

        XCTAssertEqual(properties["template_key"], "today_dashboard")
        XCTAssertEqual(properties["template_type"], "built_in")
        XCTAssertFalse(properties.values.contains(template.name))
    }

    func testLegacyCustomTemplateIsClassifiedAsCustomWithoutStableKey() {
        let template = WallpaperTemplate(
            name: "Legacy Custom",
            isBuiltIn: true,
            sortOrder: 99
        )

        let properties = AnalyticsService.templateProperties(template)

        XCTAssertEqual(properties["template_key"], "custom")
        XCTAssertEqual(properties["template_type"], "custom")
    }

    func testReminderPropertiesContainNoListOrReminderContent() {
        let panel = PanelConfiguration(panelType: .todo)
        panel.encodeConfig(
            TodoConfig(
                source: .appleReminders,
                reminderListIdentifier: "private-list-identifier",
                reminderFilter: .today
            )
        )

        let properties = AnalyticsService.remindersProperties(for: [panel])

        XCTAssertEqual(properties, ["uses_apple_reminders": "true"])
        XCTAssertFalse(properties.values.contains("private-list-identifier"))
    }

}

private final class RecordingAnalyticsSink: AnalyticsSink {
    private(set) var events: [AnalyticsEvent] = []

    func send(_ event: AnalyticsEvent) {
        events.append(event)
    }
}
