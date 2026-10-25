import XCTest
import StoreKit
@testable import LockScreenStudio

/// The automation rendered the first free template every morning, whatever the
/// user had chosen — including for Pro subscribers who had chosen a Pro one.
final class AutomationTemplateTests: XCTestCase {

    private let free1 = AutomationTemplate.Candidate(id: UUID(), isPro: false)
    private let free2 = AutomationTemplate.Candidate(id: UUID(), isPro: false)
    private let pro = AutomationTemplate.Candidate(id: UUID(), isPro: true)

    private var all: [AutomationTemplate.Candidate] { [free1, free2, pro] }

    func testNothingChosenFallsBackToFirstFree() {
        XCTAssertEqual(AutomationTemplate.resolve(all, rememberedID: nil, isPro: false), free1.id)
    }

    /// The bug itself: a chosen free template that isn't first in the list.
    func testChosenFreeTemplateIsUsed() {
        XCTAssertEqual(AutomationTemplate.resolve(all, rememberedID: free2.id, isPro: false), free2.id)
    }

    /// The worst case of the bug: paying for a template and not getting it.
    func testChosenProTemplateIsUsedForSubscribers() {
        XCTAssertEqual(AutomationTemplate.resolve(all, rememberedID: pro.id, isPro: true), pro.id)
    }

    /// A lapsed subscription must not hand out Pro templates — and must not
    /// throw either, which would leave yesterday's wallpaper up silently.
    func testChosenProTemplateFallsBackWhenNotSubscribed() {
        XCTAssertEqual(AutomationTemplate.resolve(all, rememberedID: pro.id, isPro: false), free1.id)
    }

    func testDeletedTemplateFallsBack() {
        XCTAssertEqual(AutomationTemplate.resolve(all, rememberedID: UUID(), isPro: true), free1.id)
    }

    func testNoFreeTemplatesAndNothingChosenIsNil() {
        XCTAssertNil(AutomationTemplate.resolve([pro], rememberedID: nil, isPro: true))
    }

    func testRememberRoundTrips() {
        let suite = "AutomationTemplateTests"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        defer { defaults.removePersistentDomain(forName: suite) }

        XCTAssertNil(AutomationTemplate.rememberedID(defaults: defaults))
        AutomationTemplate.remember(free2.id, defaults: defaults)
        XCTAssertEqual(AutomationTemplate.rememberedID(defaults: defaults), free2.id)
    }
}

/// The rating prompt only fired after three manual exports, so the people the
/// automation works for — who never export by hand again — were never asked.
final class AutomationReviewPromptTests: XCTestCase {

    private var defaults: UserDefaults!
    private let suite = "AutomationReviewPromptTests"
    private let cal = Calendar(identifier: .gregorian)

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suite)
        defaults.removePersistentDomain(forName: suite)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suite)
        defaults = nil
        super.tearDown()
    }

    private func day(_ n: Int, hour: Int = 7) -> Date {
        cal.date(from: DateComponents(year: 2026, month: 10, day: n, hour: hour))!
    }

    func testNeverRunDoesNotPrompt() {
        XCTAssertFalse(ReviewRequestManager.shouldPromptAfterAutomation(
            firstRun: nil, lastRun: nil, calendar: cal, defaults: defaults, currentVersion: "1.0"))
    }

    /// One run could be the user tapping ▶ to test it.
    func testRunsOnOneDayDoNotPrompt() {
        XCTAssertFalse(ReviewRequestManager.shouldPromptAfterAutomation(
            firstRun: day(20, hour: 7), lastRun: day(20, hour: 22),
            calendar: cal, defaults: defaults, currentVersion: "1.0"))
    }

    func testRunsOnTwoDaysPromptOncePerVersion() {
        XCTAssertTrue(ReviewRequestManager.shouldPromptAfterAutomation(
            firstRun: day(20), lastRun: day(21), calendar: cal, defaults: defaults, currentVersion: "1.0"))
        XCTAssertFalse(ReviewRequestManager.shouldPromptAfterAutomation(
            firstRun: day(20), lastRun: day(22), calendar: cal, defaults: defaults, currentVersion: "1.0"),
            "a second prompt on the same version is nagging")
        XCTAssertTrue(ReviewRequestManager.shouldPromptAfterAutomation(
            firstRun: day(20), lastRun: day(23), calendar: cal, defaults: defaults, currentVersion: "1.1"))
    }

    /// Both triggers together still ask at most once per version.
    func testSharesTheOncePerVersionLimitWithTheExportTrigger() {
        for _ in 0..<ReviewRequestManager.promptThreshold {
            _ = ReviewRequestManager.registerPositiveMomentAndShouldPrompt(defaults: defaults, currentVersion: "1.0")
        }
        XCTAssertFalse(ReviewRequestManager.shouldPromptAfterAutomation(
            firstRun: day(20), lastRun: day(21), calendar: cal, defaults: defaults, currentVersion: "1.0"))
    }

    func testFirstRunIsKeptAcrossLaterRuns() {
        AutomationStatus.recordRun(at: day(20), defaults: defaults)
        AutomationStatus.recordRun(at: day(21), defaults: defaults)
        XCTAssertEqual(AutomationStatus.firstRunDate(defaults: defaults), day(20))
        XCTAssertEqual(AutomationStatus.lastRunDate(defaults: defaults), day(21))
    }

    /// People already relying on the automation before this update have a last
    /// run but no first run. They count from when they actually started.
    func testExistingInstallsSeedFirstRunFromTheirLastRun() {
        defaults.set(day(10), forKey: "lastAutomationRun")
        AutomationStatus.recordRun(at: day(20), defaults: defaults)
        XCTAssertEqual(AutomationStatus.firstRunDate(defaults: defaults), day(10))
    }
}

final class PaywallTrialLabelTests: XCTestCase {

    func testLabelsEachUnit() {
        XCTAssertEqual(PaywallView.trialLabel(value: 7, unit: .day), "7-day free trial")
        XCTAssertEqual(PaywallView.trialLabel(value: 1, unit: .week), "1-week free trial")
        // Previously every non-day unit was labelled "week".
        XCTAssertEqual(PaywallView.trialLabel(value: 1, unit: .month), "1-month free trial")
        XCTAssertEqual(PaywallView.trialLabel(value: 1, unit: .year), "1-year free trial")
    }
}
