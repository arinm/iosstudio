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
            "--uitest-fresh-store",
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

// MARK: - Panel rows
//
// `EditorView.panelRow` used to be a `Button` wrapping its visibility `Toggle`.
// Accessibility merged the two into one `Switch`, so a VoiceOver user heard a
// switch per row and had no way to reach a panel's settings at all, and a test
// tapping the row hid the panel instead of configuring it.
//
// The two are siblings now, each with its own identifier —
// `panel-settings-<type>` and `panel-visible-<type>`. `PanelSettingsUITests`
// asserts they stay distinct, because the failure mode is silent: the screen
// still looks right, it just stops being operable.
//
// MARK: - AddPanelSheet
//
// Its rows looked untappable from a test: taps as `Cell`, as `Button`, as
// `StaticText` and by coordinate all left the sheet sitting there. A tap by
// hand worked, which ruled out a dead control and pointed at the row's shape.
//
// The `HStack` had no `.contentShape(Rectangle())`, so only the glyph and the
// title were tappable and the middle of the row was dead space. People hit it
// because they aim at the words; a tap at the row's centre hit nothing. Adding
// the content shape fixed the row for everyone and made `HealthAccessUITests`
// possible. Each row also carries `add-panel-<type>` now, because the visible
// text alone resolves to a container rather than the button.
//
// Three traps cost real time here and are worth knowing:
//   * SwiftData survives app relaunch, so a panel added by one run was still
//     there for the next: `panel-settings-<type>` stopped being unique and the
//     suite passed or failed depending on what had run before it. Every UI test
//     now launches with `--uitest-fresh-store`
//     (`SharedContainer.uiTestFreshStoreArgument`), which swaps in a throwaway
//     in-memory store. Add it to any new UI test.
//   * "Add Panel" is both the editor's button and the sheet's title, so
//     "is the sheet gone?" written against that label can never be true.
//   * The system Health sheet renders our NSHealthShareUsageDescription, but
//     the text is not an accessibility element — it is drawn out of process.
//     It can be reviewed in a screenshot attachment; it cannot be asserted on.
//     The data types (`Steps` under `Activity`) are exposed, so those are what
//     the test checks.
