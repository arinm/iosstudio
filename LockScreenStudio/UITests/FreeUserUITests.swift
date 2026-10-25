import XCTest

/// What someone without Pro meets in the editor. Launched without
/// `--uitest-pro`, so every gate is live.
///
/// The two rules: a free feature must not lead to the paywall, and a locked
/// one must lead somewhere. Both were broken — Add Panel opened the paywall
/// for everyone, and locked theme controls did nothing at all.
final class FreeUserUITests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false
    }

    private func openEditor() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += [
            "--uitest-fresh-store",
            "-hasCompletedOnboarding", "YES",
            // Overrides a "Force Pro" left on from a manual session.
            "-debug_force_pro", "NO",
        ]
        app.launch()

        let card = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH 'Today Dashboard template'")
        ).firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 10), "the Today Dashboard card is missing")
        card.tap()
        XCTAssertTrue(app.buttons["Add Panel"].waitForExistence(timeout: 10),
                      "the editor never appeared")
        return app
    }

    /// Six of the nine panel types are free, but the button in front of them
    /// was Pro-gated, so a free user never saw the list.
    func testAddPanelOpensThePanelList() {
        let app = openEditor()
        app.buttons["Add Panel"].tap()

        XCTAssertTrue(app.buttons["add-panel-countdown"].waitForExistence(timeout: 5),
                      "Add Panel did not open the panel list")
        XCTAssertFalse(app.staticTexts["Unlimited exports"].exists,
                       "Add Panel opened the paywall")
    }

    /// The Pro rows in the sheet hand off to the paywall only after the sheet
    /// has gone. No free user reached that hand-off while the button in front
    /// of the sheet was gated, so it had never run in practice.
    func testProPanelOpensThePaywallAndAddsNothing() {
        let app = openEditor()
        app.buttons["Add Panel"].tap()

        let quote = app.buttons["add-panel-quote"]
        XCTAssertTrue(quote.waitForExistence(timeout: 5), "Quote is not offered in Add Panel")
        quote.tap()

        XCTAssertTrue(app.staticTexts["Unlimited exports"].waitForExistence(timeout: 5),
                      "tapping a Pro panel did not open the paywall")
        XCTAssertFalse(app.buttons["panel-settings-quote"].exists,
                       "a free user got a Pro panel added")
    }

    func testLockedGradientOpensThePaywall() {
        let app = openEditor()
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Theme'")).firstMatch.tap()

        let ocean = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Ocean'")).firstMatch
        XCTAssertTrue(ocean.waitForExistence(timeout: 5), "no Ocean gradient in the theme sheet")
        ocean.tap()

        XCTAssertTrue(app.staticTexts["Unlimited exports"].waitForExistence(timeout: 5),
                      "tapping a locked gradient did not open the paywall")
    }
}
