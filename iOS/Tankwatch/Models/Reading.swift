import Foundation

/// A single level-check reading logged for a tank.
struct Reading: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var tankID: UUID
    var date: Date
    /// Estimated percent-full, 0...100.
    var percentFull: Double
    /// Optional free-text note, e.g. "weighed with bathroom scale rule of thumb".
    var note: String?

    init(id: UUID = UUID(), tankID: UUID, date: Date = Date(), percentFull: Double, note: String? = nil) {
        self.id = id
        self.tankID = tankID
        self.date = date
        self.percentFull = min(max(percentFull, 0), 100)
        self.note = note
    }
}
