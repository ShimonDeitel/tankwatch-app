import Foundation

/// Computes the "refill this one first" suggestion across a tank collection.
enum SuggestionEngine {

    struct Candidate {
        let tank: Tank
        let latestPercent: Double
    }

    /// Returns the tank with the lowest most-recent percent-full.
    /// Ties broken alphabetically (case-insensitive, then case-sensitive fallback) by tank name.
    /// Tanks with no readings are excluded — there's nothing to base a suggestion on.
    static func suggestedRefillTank(tanks: [Tank], readings: [Reading]) -> Tank? {
        let candidates: [Candidate] = tanks.compactMap { tank in
            guard let latest = latestReading(for: tank.id, in: readings) else { return nil }
            return Candidate(tank: tank, latestPercent: latest.percentFull)
        }

        guard !candidates.isEmpty else { return nil }

        let sorted = candidates.sorted { lhs, rhs in
            if lhs.latestPercent != rhs.latestPercent {
                return lhs.latestPercent < rhs.latestPercent
            }
            let lhsName = lhs.tank.name.lowercased()
            let rhsName = rhs.tank.name.lowercased()
            if lhsName != rhsName {
                return lhsName < rhsName
            }
            // Final deterministic fallback if names are identical case-insensitively.
            return lhs.tank.name < rhs.tank.name
        }

        return sorted.first?.tank
    }

    /// The most recent reading (by date) for a given tank. If multiple readings share
    /// the exact same latest date, the one with the lowest percent is treated as "latest"
    /// to be conservative (deterministic tie-break), matching insertion-order-agnostic behavior.
    static func latestReading(for tankID: UUID, in readings: [Reading]) -> Reading? {
        let tankReadings = readings.filter { $0.tankID == tankID }
        guard !tankReadings.isEmpty else { return nil }
        let maxDate = tankReadings.map(\.date).max()!
        let readingsAtMaxDate = tankReadings.filter { $0.date == maxDate }
        if readingsAtMaxDate.count == 1 {
            return readingsAtMaxDate.first
        }
        return readingsAtMaxDate.min { $0.percentFull < $1.percentFull }
    }
}
