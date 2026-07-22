import SwiftUI

/// Bespoke industrial-but-warm palette for Tankwatch.
/// Charcoal base, burnt-orange/rust accent for low levels, warm cream for full/positive states.
enum Theme {
    // MARK: - Core palette

    /// Deep charcoal background — the "steel tank" base.
    static let charcoal = Color(red: 0.098, green: 0.106, blue: 0.114)      // #191B1D
    static let charcoalElevated = Color(red: 0.145, green: 0.153, blue: 0.165) // #25272A
    static let charcoalCard = Color(red: 0.180, green: 0.188, blue: 0.200)   // #2E3033

    /// Warm cream — the "full tank" color, used for text and full-level fills.
    static let cream = Color(red: 0.949, green: 0.910, blue: 0.831)          // #F2E8D4
    static let creamDim = Color(red: 0.780, green: 0.749, blue: 0.686)       // #C7BFAF

    /// Rust / burnt orange — the low-level warning accent.
    static let rust = Color(red: 0.784, green: 0.365, blue: 0.176)           // #C85D2D
    static let rustBright = Color(red: 0.902, green: 0.451, blue: 0.220)     // #E67338

    /// Amber — the "getting low" mid-state.
    static let amber = Color(red: 0.867, green: 0.635, blue: 0.243)         // #DDA23E

    /// Sage-green-adjacent "full" positive isn't used; full state uses cream/brass.
    static let brass = Color(red: 0.702, green: 0.596, blue: 0.318)         // #B39851

    static let divider = Color.white.opacity(0.08)

    // MARK: - Semantic status colors

    static func color(for status: TankStatus) -> Color {
        switch status {
        case .full: return brass
        case .gettingLow: return amber
        case .refillSoon: return rustBright
        case .noReadings: return creamDim.opacity(0.5)
        }
    }

    // MARK: - Typography

    static func titleFont() -> Font { .system(size: 28, weight: .bold, design: .rounded) }
    static func headlineFont() -> Font { .system(size: 20, weight: .semibold, design: .rounded) }
    static func bodyFont() -> Font { .system(size: 16, weight: .regular, design: .rounded) }
    static func captionFont() -> Font { .system(size: 13, weight: .medium, design: .rounded) }
    static func gaugeNumberFont() -> Font { .system(size: 34, weight: .heavy, design: .rounded) }

    // MARK: - Layout

    static let cornerRadius: CGFloat = 20
    static let smallCornerRadius: CGFloat = 12
}

extension View {
    /// Real tap-anywhere keyboard dismiss.
    func dismissKeyboardOnTap() -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded {
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil, from: nil, for: nil
                )
            }
        )
    }
}
