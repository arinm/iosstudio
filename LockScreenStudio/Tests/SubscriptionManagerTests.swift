import XCTest
@testable import LockScreenStudio

@MainActor
final class SubscriptionManagerTests: XCTestCase {

    // MARK: - Feature Gating

    func testFreeFeatureAccessWithoutPro() {
        let manager = SubscriptionManager()
        // Without any purchases, isPro should be false
        XCTAssertFalse(manager.isPro)

        // Free features should be accessible
        XCTAssertTrue(manager.hasAccess(to: .template(isPro: false)))
        XCTAssertTrue(manager.hasAccess(to: .panelType(.agenda)))
        XCTAssertTrue(manager.hasAccess(to: .panelType(.topThree)))
        XCTAssertTrue(manager.hasAccess(to: .panelType(.todo)))
        XCTAssertTrue(manager.hasAccess(to: .panelType(.dateTime)))

        // Pro features should be blocked
        XCTAssertFalse(manager.hasAccess(to: .template(isPro: true)))
        XCTAssertFalse(manager.hasAccess(to: .unlimitedExports))
        XCTAssertFalse(manager.hasAccess(to: .premiumTheme))
        XCTAssertFalse(manager.hasAccess(to: .premiumFont))
        XCTAssertFalse(manager.hasAccess(to: .fullShortcutsIntents))
        XCTAssertFalse(manager.hasAccess(to: .panelType(.habitsHeatmap)))
    }

    // MARK: - Export Limits

    func testFreeExportLimit() {
        let manager = SubscriptionManager()
        XCTAssertEqual(SubscriptionManager.freeExportLimit, 3)
    }

    func testCanExportWhenNotExhausted() {
        let manager = SubscriptionManager()
        // Fresh state (no exports today) should allow export
        // Note: This depends on UserDefaults state
        XCTAssertTrue(manager.canExport)
    }

    // MARK: - Product IDs

    func testProductIDs() {
        XCTAssertEqual(SubscriptionManager.monthlyProductID, "com.lockscreenstudio.pro.monthly")
        XCTAssertEqual(SubscriptionManager.yearlyProductID, "com.lockscreenstudio.pro.yearly")
        XCTAssertEqual(SubscriptionManager.allProductIDs.count, 2)
    }

    // MARK: - Pro Feature Model

    func testProFeatureFreeStatus() {
        // Free panel types
        XCTAssertTrue(ProFeature.panelType(.agenda).isFree)
        XCTAssertTrue(ProFeature.panelType(.topThree).isFree)
        XCTAssertTrue(ProFeature.panelType(.todo).isFree)
        XCTAssertTrue(ProFeature.panelType(.dateTime).isFree)

        // Pro panel types
        XCTAssertFalse(ProFeature.panelType(.habitsHeatmap).isFree)
        XCTAssertFalse(ProFeature.panelType(.quote).isFree)

        // Template gating
        XCTAssertTrue(ProFeature.template(isPro: false).isFree)
        XCTAssertFalse(ProFeature.template(isPro: true).isFree)

        // Pro-only features
        XCTAssertFalse(ProFeature.unlimitedExports.isFree)
        XCTAssertFalse(ProFeature.premiumTheme.isFree)
        XCTAssertFalse(ProFeature.premiumFont.isFree)
        XCTAssertFalse(ProFeature.fullShortcutsIntents.isFree)
        XCTAssertFalse(ProFeature.advancedExportPresets.isFree)
    }
}
