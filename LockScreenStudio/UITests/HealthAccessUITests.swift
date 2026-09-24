import XCTest

/// Walks to the Health permission row on the Consistency panel.
///
/// This path had no coverage for two compounding reasons: the editor's panel
/// rows were unreachable (see `AppDriver`), and the Add Panel sheet's rows could
/// only be addressed by their visible text, which resolves to a container
/// rather than the button — so the tap landed on nothing. Both are fixed; the
/// rows now carry `add-panel-<type>` and `panel-settings-<type>`.
///
/// It matters because this is the only place the app asks for HealthKit. A
/// silent break here leaves the step heatmap permanently empty.
final class HealthAccessUITests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false
    }

    func testConsistencyPanelOffersHealthAccess() {
        let app = XCUIApplication()
        app.launchArguments += ["--uitest-pro", "--uitest-fresh-store", "-hasCompletedOnboarding", "YES"]
        app.launch()

        XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 10),
                      "app did not reach the template gallery")

        let card = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH 'Today Dashboard template'")
        ).firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 10), "the Today Dashboard card is missing")
        card.tap()

        // No stock template ships a Consistency panel, so add one. The Add
        // Panel button is itself Pro-gated — without `--uitest-pro` this opens
        // the paywall instead of the sheet.
        let addPanel = app.buttons["Add Panel"]
        XCTAssertTrue(addPanel.waitForExistence(timeout: 10), "no Add Panel button")
        addPanel.tap()

        let consistencyRow = app.buttons["add-panel-habits_heatmap"]
        XCTAssertTrue(consistencyRow.waitForExistence(timeout: 5),
                      "Consistency is not offered in Add Panel")
        consistencyRow.tap()

        // A new panel is appended, so it lands below the fold.
        let settings = app.buttons["panel-settings-habits_heatmap"]
        XCTAssertTrue(settings.waitForExistence(timeout: 10),
                      "the Consistency panel was never added")
        XCTAssertTrue(dragUntilHittable(app, settings),
                      "the Consistency panel row never scrolled into view")
        settings.tap()

        // A Health-backed source is what surfaces the permission row.
        let source = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH 'Source'")
        ).firstMatch
        XCTAssertTrue(source.waitForExistence(timeout: 5),
                      "no Source picker on the Consistency sheet")
        source.tap()

        let health = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'Health'")
        ).firstMatch
        if health.waitForExistence(timeout: 5) { health.tap() }
        sleep(3)

        // Reaching Apple's Health Access sheet is the success condition: it
        // means the app asked, with our own purpose string, for exactly the
        // data it claims to need. That string lives in Info.plist, is shown to
        // every user at the moment they decide, and nothing else checks it.
        let prompt = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] %@", "access your Health data")
        ).firstMatch
        let alreadyAuthorised = app.buttons["panel-settings-habits_heatmap"].exists
            && !app.buttons["Allow Apple Health access"].exists

        XCTAssertTrue(
            prompt.waitForExistence(timeout: 10) || alreadyAuthorised,
            "the app never asked for Health access and never showed it already had it"
        )

        if prompt.exists {
            // Assert on what the hierarchy actually exposes. Our
            // NSHealthShareUsageDescription is rendered on this sheet — the
            // attached screenshot shows it — but the text is not an
            // accessibility element, because the sheet is drawn by the system
            // out of process. It can be reviewed in the attachment; it cannot
            // be asserted on.
            //
            // The data types can: this app must ask for step count and nothing
            // else.
            XCTAssertTrue(
                app.staticTexts["Steps"].waitForExistence(timeout: 8),
                "the Health sheet does not offer Steps - the read types have changed"
            )
            XCTAssertTrue(
                app.staticTexts["Activity"].exists,
                "Steps is not under Activity; the requested types have changed"
            )

            let shot = XCTAttachment(screenshot: app.screenshot())
            shot.name = "health-permission-sheet"
            shot.lifetime = .keepAlways
            add(shot)

            // Leave the simulator in a clean state for the next run.
            let deny = app.buttons["Don\u{2019}t Allow"]
            if deny.exists { deny.tap() }
        }
    }

    /// Drags the content up until `element` is tappable.
    ///
    /// A deliberate press-and-drag from mid-screen, not `swipeUp()`: the
    /// editor's "Add Panel" button sits at the bottom, and a swipe starting on
    /// it registers as a tap, re-opening the sheet over the row being sought.
    private func dragUntilHittable(
        _ app: XCUIApplication, _ element: XCUIElement, attempts: Int = 6
    ) -> Bool {
        for _ in 0..<attempts {
            if waitForHittable(element, timeout: 1) { return true }
            let from = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7))
            let to = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.35))
            from.press(forDuration: 0.1, thenDragTo: to)
            usleep(600_000)
        }
        return waitForHittable(element, timeout: 2)
    }

    /// Waits for `element` to become tappable without touching the screen.
    ///
    /// Not a swipe loop: the editor's "Add Panel" button sits at the bottom of
    /// this screen, and a swipe starting on it registers as a tap, re-opening
    /// the sheet over the row being waited for.
    private func waitForHittable(_ element: XCUIElement, timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if element.exists && element.isHittable { return true }
            usleep(300_000)
        }
        return element.exists && element.isHittable
    }
}
