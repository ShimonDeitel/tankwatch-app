import XCTest
@testable import Tankwatch

final class SuggestionEngineTests: XCTestCase {

    private func tank(_ name: String) -> Tank {
        Tank(name: name, capacityUnit: .lbs, capacityAmount: 20)
    }

    private func reading(_ tank: Tank, _ percent: Double, _ date: Date) -> Reading {
        Reading(tankID: tank.id, date: date, percentFull: percent)
    }

    func test_noTanks_returnsNil() {
        XCTAssertNil(SuggestionEngine.suggestedRefillTank(tanks: [], readings: []))
    }

    func test_tanksWithNoReadings_areExcluded_returnsNil() {
        let a = tank("Grill")
        let b = tank("Generator")
        XCTAssertNil(SuggestionEngine.suggestedRefillTank(tanks: [a, b], readings: []))
    }

    func test_singleTankWithReading_isSuggested() {
        let a = tank("Grill")
        let readings = [reading(a, 15, Date())]
        let result = SuggestionEngine.suggestedRefillTank(tanks: [a], readings: readings)
        XCTAssertEqual(result?.id, a.id)
    }

    func test_lowestPercent_isSuggested() {
        let a = tank("Grill")
        let b = tank("Generator")
        let c = tank("Heater")
        let now = Date()
        let readings = [
            reading(a, 70, now),
            reading(b, 10, now),
            reading(c, 45, now),
        ]
        let result = SuggestionEngine.suggestedRefillTank(tanks: [a, b, c], readings: readings)
        XCTAssertEqual(result?.id, b.id)
    }

    func test_tieBrokenAlphabeticallyByName() {
        let zebra = tank("Zebra Tank")
        let apple = tank("Apple Tank")
        let now = Date()
        let readings = [
            reading(zebra, 10, now),
            reading(apple, 10, now),
        ]
        let result = SuggestionEngine.suggestedRefillTank(tanks: [zebra, apple], readings: readings)
        XCTAssertEqual(result?.name, "Apple Tank")
    }

    func test_tieBreak_isCaseInsensitive() {
        let upper = tank("BBQ")
        let lower = tank("aardvark")
        let now = Date()
        let readings = [
            reading(upper, 30, now),
            reading(lower, 30, now),
        ]
        let result = SuggestionEngine.suggestedRefillTank(tanks: [upper, lower], readings: readings)
        // "aardvark" < "bbq" alphabetically, case-insensitive.
        XCTAssertEqual(result?.name, "aardvark")
    }

    func test_excludesTanksWithNoReadings_evenWhenOthersHaveReadings() {
        let hasReading = tank("Camping Propane")
        let noReading = tank("Spare Tank")
        let readings = [reading(hasReading, 5, Date())]
        let result = SuggestionEngine.suggestedRefillTank(tanks: [hasReading, noReading], readings: readings)
        XCTAssertEqual(result?.id, hasReading.id)
    }

    func test_usesOnlyMostRecentReadingPerTank_notLowestEverReading() {
        let a = tank("Grill")
        let old = Date(timeIntervalSince1970: 1_000_000)
        let recent = Date(timeIntervalSince1970: 2_000_000)
        let readings = [
            reading(a, 5, old),     // old, very low
            reading(a, 80, recent), // most recent: full
        ]
        let b = tank("Generator")
        let readingsB = [reading(b, 50, recent)]
        let result = SuggestionEngine.suggestedRefillTank(tanks: [a, b], readings: readings + readingsB)
        // Grill's most recent reading (80) is higher than Generator's (50), so Generator should be suggested.
        XCTAssertEqual(result?.id, b.id)
    }

    func test_latestReading_pureFunction_returnsMostRecentByDate() {
        let a = tank("Grill")
        let old = Date(timeIntervalSince1970: 1_000_000)
        let recent = Date(timeIntervalSince1970: 2_000_000)
        let readings = [reading(a, 5, old), reading(a, 80, recent)]
        let latest = SuggestionEngine.latestReading(for: a.id, in: readings)
        XCTAssertEqual(latest?.percentFull, 80)
    }

    func test_latestReading_noReadings_returnsNil() {
        let a = tank("Grill")
        XCTAssertNil(SuggestionEngine.latestReading(for: a.id, in: []))
    }

    func test_allTanksFull_stillSuggestsLowestOfTheFull() {
        let a = tank("Grill")
        let b = tank("Generator")
        let now = Date()
        let readings = [reading(a, 95, now), reading(b, 65, now)]
        let result = SuggestionEngine.suggestedRefillTank(tanks: [a, b], readings: readings)
        XCTAssertEqual(result?.id, b.id)
    }
}
