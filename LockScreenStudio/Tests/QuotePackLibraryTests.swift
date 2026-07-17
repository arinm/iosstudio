import XCTest
@testable import LockScreenStudio

final class QuotePackLibraryTests: XCTestCase {

    func testAllPacksHaveContentAndUniqueIDs() {
        XCTAssertFalse(QuotePackLibrary.allPacks.isEmpty)
        let ids = QuotePackLibrary.allPacks.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count, "pack ids must be unique")
        for pack in QuotePackLibrary.allPacks {
            XCTAssertGreaterThanOrEqual(pack.quotes.count, 20, "\(pack.id) needs enough quotes for a monthly rotation")
            for quote in pack.quotes {
                XCTAssertFalse(quote.text.isEmpty)
                XCTAssertFalse(quote.author.isEmpty)
                XCTAssertLessThan(quote.text.count, 120, "quotes must stay wallpaper-length: \(quote.text)")
            }
        }
    }

    func testDailySelectionIsDeterministicWithinADay() {
        let noon = date(2026, 7, 16, hour: 12)
        let evening = date(2026, 7, 16, hour: 22)
        let a = QuotePackLibrary.todaysQuote(packID: "stoic", on: noon)
        let b = QuotePackLibrary.todaysQuote(packID: "stoic", on: evening)
        XCTAssertNotNil(a)
        XCTAssertEqual(a, b, "regenerating within the same day must yield the same quote")
    }

    func testConsecutiveDaysRotate() {
        let today = date(2026, 7, 16)
        let tomorrow = date(2026, 7, 17)
        let a = QuotePackLibrary.todaysQuote(packID: "focus", on: today)
        let b = QuotePackLibrary.todaysQuote(packID: "focus", on: tomorrow)
        XCTAssertNotEqual(a, b, "consecutive days must show different quotes")
    }

    func testUnknownPackReturnsNil() {
        XCTAssertNil(QuotePackLibrary.todaysQuote(packID: "does-not-exist"))
    }

    /// Pins the stable hash to a precomputed FNV-1a value. If someone swaps it
    /// back to `String.hashValue` (process-seeded), this fails on the next run
    /// with a different seed — the daily quote must survive relaunches because
    /// intents and background tasks run in fresh processes.
    func testStableHashIsProcessIndependent() {
        XCTAssertEqual(QuotePackLibrary.stableHash("stoic"), 0x45434ead76f8f35b)
    }

    func testLegacyQuoteConfigDecodesAsCustom() throws {
        let legacyJSON = Data(#"{"text":"My quote","author":"Me"}"#.utf8)
        let config = try JSONDecoder().decode(QuoteConfig.self, from: legacyJSON)
        XCTAssertEqual(config.source, .custom)
        XCTAssertNil(config.packID)
        XCTAssertEqual(config.text, "My quote")
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 9) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        return Calendar.current.date(from: components)!
    }
}
