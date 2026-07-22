import Foundation

/// Unit of measure for a tank's stated capacity.
enum CapacityUnit: String, Codable, CaseIterable, Identifiable {
    case lbs
    case gallons
    case kg
    case liters

    var id: String { rawValue }

    var shortLabel: String {
        switch self {
        case .lbs: return "lbs"
        case .gallons: return "gal"
        case .kg: return "kg"
        case .liters: return "L"
        }
    }

    var displayName: String {
        switch self {
        case .lbs: return "Pounds (lbs)"
        case .gallons: return "Gallons"
        case .kg: return "Kilograms (kg)"
        case .liters: return "Liters"
        }
    }
}
