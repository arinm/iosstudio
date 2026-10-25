import XCTest

/// Captures the app screens used in the App Store screenshots.
///
/// Skipped unless `APPSTORE_SHOTS_DIR` is set, so it never runs in the suite:
///
///     TEST_RUNNER_APPSTORE_SHOTS_DIR=<dir> xcodebuild test \
///       -only-testing:LockScreenStudioUITests/AppStoreScreensUITests ...
///
/// Pin the status bar first: `xcrun simctl status_bar <udid> override --time ...`.
final class AppStoreScreensUITests: XCTestCase {

    private var outputDir: URL!

    override func setUpWithError() throws {
        guard let path = ProcessInfo.processInfo.environment["APPSTORE_SHOTS_DIR"] else {
            throw XCTSkip("Set APPSTORE_SHOTS_DIR to capture the App Store screens")
        }
        outputDir = URL(fileURLWithPath: path)
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
        continueAfterFailure = false
    }

    func testGallery() throws {
        _ = launch()
        try save("app_gallery")
    }

    func testAutomationGuide() throws {
        let app = launch()
        app.buttons["Settings"].tap()
        let entry = app.buttons["Open Automation Gallery"]
        XCTAssertTrue(entry.waitForExistence(timeout: 5), "automation gallery row not found")
        entry.tap()
        XCTAssertTrue(app.staticTexts["Wake up to a fresh wallpaper"].waitForExistence(timeout: 5),
                      "the automation guide did not open")
        try save("app_automation")
    }

    func testTheme() throws {
        let app = launch()
        let card = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH 'Today Dashboard template'")
        ).firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 10), "the Today Dashboard card is missing")
        card.tap()
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Theme'")).firstMatch.tap()

        let purple = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Purple'")).firstMatch
        XCTAssertTrue(purple.waitForExistence(timeout: 5), "the theme sheet did not open")
        purple.tap()
        try save("app_theme")
    }

    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += [
            "--uitest-pro",
            "--uitest-fresh-store",
            "-hasCompletedOnboarding", "YES",
            "-automationMode", "shortcuts",
        ]
        app.launch()
        XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 10),
                      "app did not reach the template gallery")
        return app
    }

    private func save(_ name: String) throws {
        sleep(1) // let sheet and navigation animations finish
        try XCUIScreen.main.screenshot().pngRepresentation
            .write(to: outputDir.appendingPathComponent("\(name).png"))
    }
}
