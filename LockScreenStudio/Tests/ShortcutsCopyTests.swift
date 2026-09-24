import XCTest
@testable import LockScreenStudio

/// Guards on the Shortcuts setup copy.
///
/// This screen is the app's only instruction manual, and it is long enough that
/// a formatting mistake reads as normal prose when you skim the source. One
/// did: `autoApplyVerify` was a `"""` block whose newlines got collapsed into
/// the leading indentation, so it shipped with nine-space gaps in the middle of
/// sentences. No test covered any of this text, so nothing caught it.
final class ShortcutsCopyTests: XCTestCase {

    /// Every user-visible string on the sheet, flattened.
    private var allCopy: [(label: String, text: String)] {
        var out: [(String, String)] = []
        for (idx, step) in ShortcutsSetupSheet.importSteps.enumerated() {
            out.append(("importSteps[\(idx)]", step))
        }
        // Both branches, not just the simulator's — see `openingSteps(inlineAutomations:)`.
        for inline in [true, false] {
            for (idx, step) in ShortcutsSetupSheet.openingSteps(inlineAutomations: inline).enumerated() {
                out.append(("openingSteps(inline: \(inline))[\(idx)]", step))
            }
            for (idx, step) in ShortcutsSetupSheet.finishingSteps(inlineAutomations: inline).enumerated() {
                out.append(("finishingSteps(inline: \(inline))[\(idx)]", step))
            }
        }
        for recipe in ShortcutsSetupSheet.recipes {
            out.append(("\(recipe.id).title", recipe.title))
            out.append(("\(recipe.id).summary", recipe.summary))
            out.append(("\(recipe.id).verify", recipe.verify))
            for inline in [true, false] {
                for (idx, step) in steps(for: recipe, inline: inline).enumerated() {
                    out.append(("\(recipe.id).steps(inline: \(inline))[\(idx)]", step))
                }
            }
        }
        return out
    }

    private func steps(for recipe: ShortcutsSetupSheet.AutomationRecipe, inline: Bool) -> [String] {
        ShortcutsSetupSheet.steps(
            trigger: recipe.trigger,
            inlineTrigger: recipe.inlineTrigger,
            actions: recipe.actions,
            inlineAutomations: inline
        )
    }

    /// The regression that prompted this file. Runs of spaces survive a code
    /// review because the source looks like indentation; on screen they are an
    /// obvious gap mid-sentence.
    func testNoRunsOfSpaces() {
        for (label, text) in allCopy {
            XCTAssertFalse(
                text.contains("  "),
                "\(label) contains a double space, which renders as a visible gap: \(text)"
            )
        }
    }

    /// Markdown is rendered via `Text(.init(_:))`, so an unpaired `**` shows up
    /// literally as asterisks instead of bolding anything.
    func testBoldMarkersArePaired() {
        for (label, text) in allCopy {
            let markers = text.components(separatedBy: "**").count - 1
            XCTAssertEqual(markers % 2, 0, "\(label) has an unpaired ** marker: \(text)")
        }
    }

    func testNoCopyIsEmptyOrPadded() {
        for (label, text) in allCopy {
            XCTAssertFalse(text.isEmpty, "\(label) is empty")
            XCTAssertEqual(text, text.trimmingCharacters(in: .whitespacesAndNewlines),
                           "\(label) has leading or trailing whitespace")
        }
    }

    // MARK: - Structure

    /// The steps are composed, not copy-pasted, so that an iOS redesign is one
    /// edit rather than five. Assert the composition actually holds.
    func testEveryRecipeComposesTheSharedSteps() {
        for recipe in ShortcutsSetupSheet.recipes {
            for inline in [true, false] {
                let opening = ShortcutsSetupSheet.openingSteps(inlineAutomations: inline)
                let finishing = ShortcutsSetupSheet.finishingSteps(inlineAutomations: inline)
                let composed = steps(for: recipe, inline: inline)
                XCTAssertEqual(
                    Array(composed.prefix(opening.count)), opening,
                    "\(recipe.id) (inline: \(inline)) does not start with the shared opening steps"
                )
                XCTAssertEqual(
                    Array(composed.suffix(finishing.count)), finishing,
                    "\(recipe.id) (inline: \(inline)) does not end with the shared finishing steps"
                )
            }
        }
    }

    /// iOS 27 renamed the two controls that finish an automation. Shipping the
    /// old names there sends people looking for a "Run Immediately" row that no
    /// longer exists — and both spellings are still in Apple's string table, so
    /// nothing else would catch it.
    func testFinishingStepsUseTheRightNamesPerVersion() {
        let inline = ShortcutsSetupSheet.finishingSteps(inlineAutomations: true).joined()
        XCTAssertTrue(inline.contains("**Automation**"), "iOS 27 finishing steps must name the Automation toggle")
        XCTAssertTrue(inline.contains("**Notify**"), "iOS 27 finishing steps must name the Notify toggle")
        XCTAssertFalse(inline.contains("Run Immediately"), "Run Immediately is the pre-27 name")

        let legacy = ShortcutsSetupSheet.finishingSteps(inlineAutomations: false).joined()
        XCTAssertTrue(legacy.contains("**Run Immediately**"), "pre-27 finishing steps must name Run Immediately")
    }

    /// Sunset stopped being a trigger of its own in iOS 27 and became an
    /// **Event** option inside Time of Day. Verified by driving the Shortcuts
    /// app in the simulator: the Automation list, scrolled to its end, has no
    /// Sunset row.
    func testSunsetRecipeDoesNotPromiseASunsetTriggerOnIOS27() {
        guard let sunset = ShortcutsSetupSheet.recipes.first(where: { $0.id == "sunset" }) else {
            return XCTFail("the sunset recipe is gone")
        }
        let inline = steps(for: sunset, inline: true).joined()
        XCTAssertTrue(inline.contains("**Event**"), "iOS 27 must route Sunset through the Event picker")
        XCTAssertFalse(
            inline.contains("Pick **Sunset**"),
            "there is no Sunset trigger to pick on iOS 27"
        )
    }

    /// `Show Preview` inside `Set Wallpaper Photo` is the step that fails
    /// silently — left on, the user is asked to approve the change every single
    /// morning, which defeats the entire feature. It must appear in every
    /// recipe, not just the recommended one.
    func testEveryRecipeTellsYouToTurnOffShowPreview() {
        for recipe in ShortcutsSetupSheet.recipes {
            let mentionsIt = recipe.steps.contains { $0.contains("**Show Preview**") }
            XCTAssertTrue(mentionsIt, "\(recipe.id) never tells the user to turn Show Preview off")
        }
    }

    /// Apple's action is `Set Wallpaper Photo`. The guide said `Set Wallpaper`
    /// for a long time, which is not the name of anything — verified against
    /// `ActionKit.framework/en.lproj/Localizable.strings` on iOS 26.1, 26.2 and
    /// 27, where the key is `Set Wallpaper Photo (Action Name)` and no key for a
    /// bare "Set Wallpaper" action exists. Naming a control that isn't on screen
    /// is how a walkthrough loses people, so it is worth a test.
    func testActionIsNamedAsAppleNamesIt() {
        for (label, text) in allCopy {
            guard let range = text.range(of: "Set Wallpaper") else { continue }
            XCTAssertTrue(
                text[range.upperBound...].hasPrefix(" Photo"),
                "\(label) says \"Set Wallpaper\" where Apple's action is \"Set Wallpaper Photo\": \(text)"
            )
        }
    }

    /// Importing a shared shortcut installs it disabled, by design. The second
    /// step is the whole reason this list is numbered instead of being a
    /// sentence under the button.
    func testImportStepsEndOnEnablingTheAutomation() {
        let steps = ShortcutsSetupSheet.importSteps
        XCTAssertEqual(steps.count, 2, "a third step makes the second one skimmable again")
        XCTAssertTrue(
            steps.last?.contains("**Automation**") == true,
            "the last import step must point at the Automation toggle"
        )
        // Whether iOS *always* installs a shared automation switched off is not
        // something we have observed, so the copy says "can arrive" and tells
        // the user to check. Asserting the stronger claim here would re-enshrine
        // a fact we only read in an article.
        XCTAssertFalse(
            steps.joined().contains("arrive turned off"),
            "don't state the disabled-on-import default as certain"
        )
    }

    /// `ShortcutLibrary` is keyed by recipe id, and a typo there fails silently:
    /// the lookup misses and the user quietly gets the walkthrough instead of
    /// the link we published.
    func testShareLinkKeysMatchRecipeIDs() {
        let ids = Set(ShortcutsSetupSheet.recipes.map(\.id))
        for key in ShortcutLibrary.shareLinks.keys {
            XCTAssertTrue(ids.contains(key), "shareLinks has key \"\(key)\" with no matching recipe")
        }
    }

    func testRecipeIDsAreUnique() {
        let ids = ShortcutsSetupSheet.recipes.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count, "recipe ids collide, so share links would be ambiguous")
    }
}
