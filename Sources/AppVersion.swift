import Foundation

enum AppVersion {
    static let current = "2.2.0"
    static let build = "20260206"
    static let improvements = "✨ Paste Last (⌃⇧V), Mode Cycle (⌃⇧M), Better Shortcuts, Speech Detection Fix"

    static var full: String {
        "\(current) (\(build))"
    }
}
