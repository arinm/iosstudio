import XCTest
@testable import LockScreenStudio

final class AutomationPreferencesTests: XCTestCase {

    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "AutomationPreferencesTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        UserDefaults.standard.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    private var savesToPhotos: Bool {
        defaults.bool(forKey: AutomationPreferences.savesToPhotosKey)
    }

    /// Fresh install: nobody has run an automation, so the new clutter-free
    /// default stands.
    func testFreshInstallLeavesPhotosArchiveOff() {
        AutomationPreferences.migrateSavesToPhotosIfNeeded(
            defaults: defaults,
            lastAutomationRun: nil
        )
        XCTAssertFalse(savesToPhotos)
    }

    /// Upgrading user whose shortcut predates the "Set Wallpaper" step: their
    /// wallpaper reaches them only via Photos, so the archive must stay on.
    func testExistingAutomationUserKeepsPhotosArchive() {
        AutomationPreferences.migrateSavesToPhotosIfNeeded(
            defaults: defaults,
            lastAutomationRun: Date(timeIntervalSinceNow: -3600)
        )
        XCTAssertTrue(savesToPhotos)
    }

    /// The migration must not fight the user: once they turn the archive off,
    /// a later launch must leave it off.
    func testMigrationDoesNotReEnableAfterUserTurnsItOff() {
        AutomationPreferences.migrateSavesToPhotosIfNeeded(
            defaults: defaults,
            lastAutomationRun: Date(timeIntervalSinceNow: -3600)
        )
        XCTAssertTrue(savesToPhotos, "precondition: migrated on")

        defaults.set(false, forKey: AutomationPreferences.savesToPhotosKey)

        AutomationPreferences.migrateSavesToPhotosIfNeeded(
            defaults: defaults,
            lastAutomationRun: Date(timeIntervalSinceNow: -60)
        )
        XCTAssertFalse(savesToPhotos, "migration re-enabled a setting the user turned off")
    }

    /// A fresh install that starts automating later must not retroactively get
    /// the archive switched on behind their back.
    func testMigrationIsOneShotForFreshInstalls() {
        AutomationPreferences.migrateSavesToPhotosIfNeeded(
            defaults: defaults,
            lastAutomationRun: nil
        )
        AutomationPreferences.migrateSavesToPhotosIfNeeded(
            defaults: defaults,
            lastAutomationRun: Date()
        )
        XCTAssertFalse(savesToPhotos)
    }
}
