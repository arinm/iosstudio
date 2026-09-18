import XCTest

/// Covers the automation settings that changed behaviour for existing users.
final class AutomationSettingsUITests: XCTestCase {

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    /// The Photos archive defaults off now that shortcuts apply the wallpaper
    /// directly. This is the control users need when their shortcut has no
    /// "Set Wallpaper" step, so it must be reachable and off.
    func testPhotosArchiveIsOffByDefault() {
        let driver = AppDriver.launchPro()
        driver.openSettings()

        // Label carries the current value ("Mode, Off" / "Mode, Built-in"), and
        // the mode persists between runs, so match on the prefix.
        let modeButton = driver.app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Mode")
        ).firstMatch
        XCTAssertTrue(modeButton.waitForExistence(timeout: 5), "Mode picker missing")
        modeButton.tap()
        let shortcuts = driver.app.buttons["Shortcuts (recommended)"]
        XCTAssertTrue(shortcuts.waitForExistence(timeout: 3), "mode menu did not open")
        shortcuts.tap()

        let toggle = driver.app.switches["Also save to Photos"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5), "Photos toggle missing in Shortcuts mode")
        XCTAssertEqual(toggle.value as? String, "0", "the Photos archive must default to off")
    }

    /// The onboarding promise changed when the Set Wallpaper action turned out
    /// to exist; this pins the new hands-free claim so it cannot silently
    /// revert to the old "one tap to apply" copy.
    func testOnboardingPromisesHandsFreeApply() {
        let app = XCUIApplication()
        app.launchArguments += ["-hasCompletedOnboarding", "NO"]
        app.launch()

        var sawClaim = false
        for _ in 1...10 {
            if app.staticTexts["Applied to your Lock Screen"].exists { sawClaim = true; break }
            let forward = ["Get Started", "Sounds good", "Continue", "Next"]
            var acted = false
            for label in forward {
                let button = app.buttons[label]
                if button.exists && button.isHittable { button.tap(); acted = true; break }
            }
            if !acted { app.swipeLeft() }
        }
        XCTAssertTrue(sawClaim, "onboarding no longer states the wallpaper is applied automatically")
    }
}
