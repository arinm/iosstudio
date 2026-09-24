import XCTest

/// Covers the editor's panel rows and the Consistency panel's configuration
/// sheet — both unreachable until `EditorView.panelRow` stopped nesting its
/// visibility `Toggle` inside a `Button`.
///
/// That nesting merged the two into one accessibility element of type Switch.
/// A VoiceOver user heard a switch and had no way to open a panel's settings;
/// a test tapping the row hid the panel instead. Splitting them fixed the app
/// for those users and made this file possible, which is the order those two
/// things belong in.
final class PanelSettingsUITests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false
    }

    private func openEditor() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += [
            "--uitest-pro",
            "--uitest-fresh-store",
            "-hasCompletedOnboarding", "YES",
        ]
        app.launch()
        XCTAssertTrue(
            app.buttons["Settings"].waitForExistence(timeout: 10),
            "app did not reach the template gallery"
        )
        return app
    }

    /// The row and its toggle are now two elements, each with its own
    /// identifier. If they ever merge again this fails rather than silently
    /// costing VoiceOver users the settings screen.
    func testPanelRowAndVisibilityToggleAreSeparateElements() {
        let app = openEditor()
        openFirstTemplate(app)

        let settings = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'panel-settings-'")
        ).firstMatch
        XCTAssertTrue(
            settings.waitForExistence(timeout: 10),
            "no panel settings button — the row has merged with its toggle again"
        )

        let toggle = app.switches.matching(
            NSPredicate(format: "identifier BEGINSWITH 'panel-visible-'")
        ).firstMatch
        XCTAssertTrue(toggle.exists, "no panel visibility switch")

        XCTAssertNotEqual(
            settings.identifier, toggle.identifier,
            "the settings button and the visibility toggle must be distinct elements"
        )
    }

    /// Tapping the row opens configuration — it must not toggle visibility,
    /// which is exactly what the merged element used to do.
    func testTappingThePanelRowOpensItsSettings() {
        let app = openEditor()
        openFirstTemplate(app)

        let settings = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'panel-settings-'")
        ).firstMatch
        XCTAssertTrue(settings.waitForExistence(timeout: 10), "no panel settings button")

        let toggle = app.switches.matching(
            NSPredicate(format: "identifier BEGINSWITH 'panel-visible-'")
        ).firstMatch
        let before = toggle.value as? String

        settings.tap()

        // A configuration sheet appeared, and visibility did not change.
        let sheetAppeared = app.navigationBars.firstMatch.waitForExistence(timeout: 5)
        XCTAssertTrue(sheetAppeared, "tapping the row did not open anything")
        if toggle.exists {
            XCTAssertEqual(toggle.value as? String, before,
                           "tapping the row flipped visibility instead of opening settings")
        }
    }

    /// Opens a template in the editor.
    ///
    /// By label, not by index: `buttons.element(boundBy: 0)` is "Import
    /// Template", whose sheet leaves you still on the gallery — which is how
    /// this file first "failed" against a fix that was actually fine.
    private func openFirstTemplate(_ app: XCUIApplication) {
        let card = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH 'Today Dashboard template'")
        ).firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 10), "the Today Dashboard card is missing")
        card.tap()

        XCTAssertTrue(
            app.buttons.matching(
                NSPredicate(format: "identifier BEGINSWITH 'panel-settings-'")
            ).firstMatch.waitForExistence(timeout: 10),
            "the editor's panel list never appeared"
        )
    }
}
