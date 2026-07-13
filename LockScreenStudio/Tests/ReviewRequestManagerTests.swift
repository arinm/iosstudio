import XCTest
@testable import LockScreenStudio

final class ReviewRequestManagerTests: XCTestCase {
    private var defaults: UserDefaults!
    private let suiteName = "ReviewRequestManagerTests"

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    func testDoesNotPromptBeforeThreshold() {
        XCTAssertFalse(ReviewRequestManager.registerPositiveMomentAndShouldPrompt(defaults: defaults, currentVersion: "1.0"))
        XCTAssertFalse(ReviewRequestManager.registerPositiveMomentAndShouldPrompt(defaults: defaults, currentVersion: "1.0"))
    }

    func testPromptsExactlyOnceAtThreshold() {
        XCTAssertFalse(ReviewRequestManager.registerPositiveMomentAndShouldPrompt(defaults: defaults, currentVersion: "1.0"))
        XCTAssertFalse(ReviewRequestManager.registerPositiveMomentAndShouldPrompt(defaults: defaults, currentVersion: "1.0"))
        // 3rd success crosses the threshold → prompt.
        XCTAssertTrue(ReviewRequestManager.registerPositiveMomentAndShouldPrompt(defaults: defaults, currentVersion: "1.0"))
        // Further successes on the same version do not prompt again.
        XCTAssertFalse(ReviewRequestManager.registerPositiveMomentAndShouldPrompt(defaults: defaults, currentVersion: "1.0"))
    }

    func testPromptsAgainOnNewVersion() {
        for _ in 0..<3 {
            _ = ReviewRequestManager.registerPositiveMomentAndShouldPrompt(defaults: defaults, currentVersion: "1.0")
        }
        // Already past threshold; a new version allows one more prompt.
        XCTAssertTrue(ReviewRequestManager.registerPositiveMomentAndShouldPrompt(defaults: defaults, currentVersion: "1.1"))
        XCTAssertFalse(ReviewRequestManager.registerPositiveMomentAndShouldPrompt(defaults: defaults, currentVersion: "1.1"))
    }
}
