import Foundation

/// Derived status for a tank based purely on its most recent reading's percent-full.
enum TankStatus: String, Codable {
    case full         // > 60%
    case gettingLow   // 20...60%
    case refillSoon   // < 20%
    case noReadings   // no readings logged yet

    var displayName: String {
        switch self {
        case .full: return "Full"
        case .gettingLow: return "Getting Low"
        case .refillSoon: return "Refill Soon"
        case .noReadings: return "No Readings Yet"
        }
    }

    /// Pure function: derive status directly from the latest percent-full value.
    /// Boundaries (per spec):
    ///   > 60          -> full
    ///   20...60       -> gettingLow   (inclusive both ends)
    ///   < 20          -> refillSoon
    static func status(forLatestPercent percent: Double?) -> TankStatus {
        guard let percent = percent else { return .noReadings }
        if percent > 60 {
            return .full
        } else if percent >= 20 {
            return .gettingLow
        } else {
            return .refillSoon
        }
    }
}
