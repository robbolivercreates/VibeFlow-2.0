import Foundation

enum AppVersion {
    static let current = "2.1.0"
    static let build = "20260202"
    static let improvements = "✨ Setup Wizard, History (50 itens), Snippets, Sound Effects, Improved Menu"

    static var full: String {
        "\(current) (\(build))"
    }
}
