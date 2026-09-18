import XCTest

/// Navigation helpers shared by the UI tests.
///
/// Kept separate from the assertions so a change to onboarding or the gallery
/// breaks one file rather than every test.
struct AppDriver {

    let app: XCUIApplication

    /// Launches straight into the template gallery with Pro forced on.
    ///
    /// Onboarding is skipped rather than driven: every test below is about a
    /// screen behind it, and walking a multi-page pager on each run makes them
    /// slow and fragile for no coverage. `OnboardingUITests` launches without
    /// the skip to cover onboarding itself.
    ///
    /// Pro comes from a launch argument, not the Settings "Force Pro" toggle —
    /// see `SubscriptionManager.uiTestProArgument` for why.
    @discardableResult
    static func launchPro() -> AppDriver {
        let app = XCUIApplication()
        app.launchArguments += [
            "--uitest-pro",
            "-hasCompletedOnboarding", "YES",
        ]
        app.launch()

        let driver = AppDriver(app: app)
        XCTAssertTrue(
            app.buttons["Settings"].waitForExistence(timeout: 10),
            "app did not reach the template gallery"
        )
        return driver
    }

    /// Button whose OWN label contains `text`.
    ///
    /// Not `.containing(...)`: that matches any ancestor whose subtree contains
    /// the text, and `.firstMatch` then returns the outermost container — which
    /// is not the control, so tapping it does nothing.
    func button(containing text: String) -> XCUIElement {
        app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] %@", text)
        ).firstMatch
    }

    /// Scrolls until `element` exists, up to `attempts` swipes.
    @discardableResult
    func scrollTo(_ element: XCUIElement, attempts: Int = 8) -> Bool {
        for _ in 0..<attempts {
            if element.exists { return true }
            app.swipeUp()
        }
        return element.exists
    }

    func openSettings() {
        app.buttons["Settings"].tap()
        XCTAssertTrue(
            app.staticTexts["Automation"].waitForExistence(timeout: 5),
            "Settings did not open"
        )
    }

    /// Prints the current hierarchy. Call from a failing test to see what the
    /// runner actually sees.
    func dump(_ label: String) {
        print("=== \(label) ===")
        print(app.debugDescription)
    }
}

// MARK: - Not yet reachable
//
// The Consistency panel's configuration sheet (Source picker, Show streak,
// weeks stepper, Health permission row) has no UI coverage because the editor's
// panel rows cannot be driven reliably.
//
// `EditorView.panelRow` is a `Button` wrapping a visibility `Toggle`, and
// accessibility merges the two into a single `Switch` labelled
// "<title> panel, visible, title shown". There is no `Button` to tap, tapping
// the merged element hits the toggle and hides the panel instead of opening its
// config, and a freshly added panel could not be located in the list at all.
//
// That merge is also an accessibility defect in its own right: a VoiceOver user
// hears one switch per row and has no way to reach a panel's settings. Giving
// the row and its toggle separate accessibility elements — an
// `.accessibilityIdentifier` on the row plus an explicit label on the toggle —
// fixes the app for those users and makes this screen testable at the same
// time. Worth doing before writing these tests, not after.
