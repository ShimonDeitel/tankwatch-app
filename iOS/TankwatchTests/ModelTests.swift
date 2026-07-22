import XCTest
@testable import Tankwatch

final class ModelTests: XCTestCase {

    func test_reading_clampsPercentAbove100() {
        let tankID = UUID()
        let reading = Reading(tankID: tankID, percentFull: 150)
        XCTAssertEqual(reading.percentFull, 100)
    }

    func test_reading_clampsPercentBelow0() {
        let tankID = UUID()
        let reading = Reading(tankID: tankID, percentFull: -10)
        XCTAssertEqual(reading.percentFull, 0)
    }

    func test_reading_withinRange_isUnchanged() {
        let tankID = UUID()
        let reading = Reading(tankID: tankID, percentFull: 42.5)
        XCTAssertEqual(reading.percentFull, 42.5)
    }

    func test_tank_codableRoundTrip() throws {
        let tank = Tank(name: "Grill Propane", capacityUnit: .lbs, capacityAmount: 20)
        let data = try JSONEncoder().encode(tank)
        let decoded = try JSONDecoder().decode(Tank.self, from: data)
        XCTAssertEqual(decoded, tank)
    }

    func test_reading_codableRoundTrip() throws {
        let reading = Reading(tankID: UUID(), percentFull: 33, note: "eyeballed it")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(reading)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(Reading.self, from: data)
        XCTAssertEqual(decoded.percentFull, reading.percentFull)
        XCTAssertEqual(decoded.note, reading.note)
        XCTAssertEqual(decoded.tankID, reading.tankID)
    }

    func test_capacityUnit_shortLabels() {
        XCTAssertEqual(CapacityUnit.lbs.shortLabel, "lbs")
        XCTAssertEqual(CapacityUnit.gallons.shortLabel, "gal")
        XCTAssertEqual(CapacityUnit.kg.shortLabel, "kg")
        XCTAssertEqual(CapacityUnit.liters.shortLabel, "L")
    }
}
