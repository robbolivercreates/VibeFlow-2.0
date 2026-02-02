import Foundation

enum AppVersion {
    static let current = "1.1.0"
    static let build = "20260117"
    static let improvements = "✨ Melhorias: Temperature 0.7, Áudio 48kHz, Retry automático, Validação, Timeout, Logging"

    static var full: String {
        "\(current) (\(build))"
    }
}
