import XCTest

/// Covers the ready-made-shortcut import path on the automation guide.
///
/// That path is normally invisible: it only appears once `ShortcutLibrary`
/// carries a published iCloud link, and the table ships empty. So without the
/// `--preview-share-links` argument this screen could be written, reviewed and
/// shipped without anyone — including us — ever seeing it rendered.
final class ShortcutsGuideUITests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false
    }

    private func openGuide(previewLinks: Bool) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += [
            "--uitest-pro",
            "--uitest-fresh-store",
            "-hasCompletedOnboarding", "YES",
            // The guide's entry row only exists in Shortcuts mode, and the
            // default is "off".
            "-automationMode", "shortcuts",
        ]
        if previewLinks {
            app.launchArguments.append("--preview-share-links")
        }
        app.launch()

        XCTAssertTrue(
            app.buttons["Settings"].waitForExistence(timeout: 10),
            "app did not reach the template gallery"
        )
        app.buttons["Settings"].tap()

        let entry = app.buttons["Open Automation Gallery"]
        XCTAssertTrue(entry.waitForExistence(timeout: 5), "automation gallery row not found in Settings")
        entry.tap()

        XCTAssertTrue(
            app.staticTexts["Wake up to a fresh wallpaper"].waitForExistence(timeout: 5),
            "the automation guide did not open"
        )
        return app
    }

    /// With a link published, the recommended recipe leads with the import and
    /// spells out the step that iOS deliberately leaves undone.
    func testImportPathShowsBothStepsIncludingEnabling() {
        let app = openGuide(previewLinks: true)

        XCTAssertTrue(
            app.buttons["Add to Shortcuts"].waitForExistence(timeout: 5),
            "the import button is missing even though a link is published"
        )

        // The failure this screen exists to prevent: a shortcut that installs
        // fine and then silently never runs.
        let enableStep = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS[c] %@", "check it is on")
        ).firstMatch
        XCTAssertTrue(enableStep.exists, "the step that checks the Automation toggle is not on screen")

        let addStep = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS[c] %@", "Add Shortcut")
        ).firstMatch
        XCTAssertTrue(addStep.exists, "the 'Add Shortcut' step is not on screen")

        attachScreenshot(app, named: "guide-with-share-link-top")
        app.swipeUp()
        attachScreenshot(app, named: "guide-with-share-link")
    }

    /// The walkthrough is still the whole experience when nothing is published,
    /// which is what ships today — so it has to stand on its own.
    func testWalkthroughStillLeadsWhenNoLinkIsPublished() {
        let app = openGuide(previewLinks: false)

        XCTAssertFalse(
            app.buttons["Add to Shortcuts"].exists,
            "the import button must not appear without a published link"
        )
        XCTAssertTrue(
            app.staticTexts["Step by step"].exists,
            "the walkthrough heading is missing"
        )

        attachScreenshot(app, named: "guide-walkthrough")
    }

    /// Saved to the runner's temp directory as well as attached, so a screenshot
    /// can be pulled off the simulator without unpacking the .xcresult.
    private func attachScreenshot(_ app: XCUIApplication, named name: String) {
        let shot = app.screenshot()

        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)

        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("\(name).png")
        try? shot.pngRepresentation.write(to: url)
    }
}
