import SwiftUI
import AppKit

/// VoxAiGo Design System — "Matte Black & Gold"
/// Centralized color tokens inspired by Marshall speakers aesthetic.
/// All views reference these tokens instead of hardcoded colors.
enum VoxTheme {
    // MARK: - Backgrounds
    static let background       = Color(red: 0.039, green: 0.039, blue: 0.039)     // #0A0A0A
    static let surface          = Color(red: 0.078, green: 0.078, blue: 0.078)     // #141414
    static let surfaceBorder    = Color(red: 0.122, green: 0.122, blue: 0.122)     // #1F1F1F

    // NSColor equivalents (for AppKit windows)
    static let nsBackground     = NSColor(red: 0.039, green: 0.039, blue: 0.039, alpha: 1.0)
    static let nsSurface        = NSColor(red: 0.078, green: 0.078, blue: 0.078, alpha: 1.0)
    static let nsSurfaceBorder  = NSColor(red: 0.122, green: 0.122, blue: 0.122, alpha: 1.0)

    // MARK: - Accent (Gold)
    static let accent           = Color(red: 0.831, green: 0.686, blue: 0.216)     // #D4AF37
    static let accentLight      = Color(red: 0.910, green: 0.831, blue: 0.545)     // #E8D48B
    static let accentMuted      = Color(red: 0.831, green: 0.686, blue: 0.216).opacity(0.15)

    static let nsAccent         = NSColor(red: 0.831, green: 0.686, blue: 0.216, alpha: 1.0)
    static let nsAccentLight    = NSColor(red: 0.910, green: 0.831, blue: 0.545, alpha: 1.0)

    // MARK: - Text
    static let textPrimary      = Color(red: 0.961, green: 0.961, blue: 0.961)     // #F5F5F5
    static let textSecondary    = Color(red: 0.541, green: 0.541, blue: 0.541)     // #8A8A8A
    static let textDisabled     = Color(red: 0.333, green: 0.333, blue: 0.333)     // #555555

    // MARK: - Semantic
    static let danger           = Color(red: 1.0, green: 0.267, blue: 0.267)       // #FF4444
    static let success          = Color(red: 0.290, green: 0.871, blue: 0.502)     // #4ADE80

    // MARK: - Gold Gradient (for brand elements: logo, PRO badges, upgrade buttons)
    static let goldGradient     = LinearGradient(
        colors: [accent, accentLight],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // NSColor gradient endpoints (for AppIcon NSImage drawing)
    static let nsGoldStart      = NSColor(red: 0.831, green: 0.686, blue: 0.216, alpha: 1.0)
    static let nsGoldEnd        = NSColor(red: 0.910, green: 0.831, blue: 0.545, alpha: 1.0)
    static let nsGoldDark       = NSColor(red: 0.722, green: 0.596, blue: 0.176, alpha: 1.0)
}
