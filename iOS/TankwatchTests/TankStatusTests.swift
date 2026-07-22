import XCTest
@testable import Tankwatch

final class TankStatusTests: XCTestCase {

    func test_noReadings_returnsNoReadings() {
        XCTAssertEqual(TankStatus.status(forLatestPercent: nil), .noReadings)
    }

    func test_zeroPercent_isRefillSoon() {
        XCTAssertEqual(TankStatus.status(forLatestPercent: 0), .refillSoon)
    }

    func test_justBelow20_isRefillSoon() {
        XCTAssertEqual(TankStatus.status(forLatestPercent: 19.999), .refillSoon)
    }

    func test_exactly20_isGettingLow() {
        // Spec: 20-60% inclusive is Getting Low.
        XCTAssertEqual(TankStatus.status(forLatestPercent: 20), .gettingLow)
    }

    func test_midRange_isGettingLow() {
        XCTAssertEqual(TankStatus.status(forLatestPercent: 40), .gettingLow)
    }

    func test_exactly60_isGettingLow() {
        // Spec: >60% is Full, so 60 itself must remain Getting Low.
        XCTAssertEqual(TankStatus.status(forLatestPercent: 60), .gettingLow)
    }

    func test_justAbove60_isFull() {
        XCTAssertEqual(TankStatus.status(forLatestPercent: 60.001), .full)
    }

    func test_100Percent_isFull() {
        XCTAssertEqual(TankStatus.status(forLatestPercent: 100), .full)
    }
}
