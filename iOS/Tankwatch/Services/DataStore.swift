import Foundation
import Combine

/// Simple on-device JSON persistence for tanks and readings.
/// Tanks are unlimited; only logging (adding a Reading) is rate-limited elsewhere.
@MainActor
final class DataStore: ObservableObject {
    @Published private(set) var tanks: [Tank] = []
    @Published private(set) var readings: [Reading] = []

    static let shared = DataStore()

    private let tanksFileName = "tankwatch_tanks.json"
    private let readingsFileName = "tankwatch_readings.json"

    init(loadFromDisk: Bool = true) {
        if loadFromDisk {
            load()
        }
    }

    // MARK: - Tanks

    func addTank(name: String, capacityUnit: CapacityUnit, capacityAmount: Double) {
        let tank = Tank(name: name, capacityUnit: capacityUnit, capacityAmount: capacityAmount)
        tanks.append(tank)
        persist()
    }

    func deleteTank(_ tank: Tank) {
        tanks.removeAll { $0.id == tank.id }
        readings.removeAll { $0.tankID == tank.id }
        persist()
    }

    func updateTank(_ tank: Tank) {
        guard let index = tanks.firstIndex(where: { $0.id == tank.id }) else { return }
        tanks[index] = tank
        persist()
    }

    // MARK: - Readings

    @discardableResult
    func addReading(tankID: UUID, percentFull: Double, date: Date = Date(), note: String? = nil) -> Reading {
        let reading = Reading(tankID: tankID, date: date, percentFull: percentFull, note: note)
        readings.append(reading)
        persist()
        return reading
    }

    func readings(for tankID: UUID) -> [Reading] {
        readings.filter { $0.tankID == tankID }.sorted { $0.date > $1.date }
    }

    func latestReading(for tankID: UUID) -> Reading? {
        SuggestionEngine.latestReading(for: tankID, in: readings)
    }

    func status(for tankID: UUID) -> TankStatus {
        TankStatus.status(forLatestPercent: latestReading(for: tankID)?.percentFull)
    }

    func suggestedRefillTank() -> Tank? {
        SuggestionEngine.suggestedRefillTank(tanks: tanks, readings: readings)
    }

    /// All reading dates, used to feed RateLimiter.
    var allReadingDates: [Date] {
        readings.map(\.date)
    }

    // MARK: - Persistence

    private var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private func persist() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let tanksData = try? encoder.encode(tanks) {
            try? tanksData.write(to: documentsURL.appendingPathComponent(tanksFileName))
        }
        if let readingsData = try? encoder.encode(readings) {
            try? readingsData.write(to: documentsURL.appendingPathComponent(readingsFileName))
        }
    }

    private func load() {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let data = try? Data(contentsOf: documentsURL.appendingPathComponent(tanksFileName)),
           let decoded = try? decoder.decode([Tank].self, from: data) {
            tanks = decoded
        }
        if let data = try? Data(contentsOf: documentsURL.appendingPathComponent(readingsFileName)),
           let decoded = try? decoder.decode([Reading].self, from: data) {
            readings = decoded
        }
    }
}
