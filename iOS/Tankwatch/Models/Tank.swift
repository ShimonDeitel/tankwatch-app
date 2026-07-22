import Foundation

/// A tracked propane/gas/oil tank.
struct Tank: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var capacityUnit: CapacityUnit
    var capacityAmount: Double
    var createdAt: Date

    init(id: UUID = UUID(), name: String, capacityUnit: CapacityUnit, capacityAmount: Double, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.capacityUnit = capacityUnit
        self.capacityAmount = capacityAmount
        self.createdAt = createdAt
    }
}
