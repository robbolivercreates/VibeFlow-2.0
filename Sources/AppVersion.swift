import Foundation

enum AppVersion {
    static let current = "1.1.0"
    static let build = "20260104"
    
    static var full: String {
        "\(current) (\(build))"
    }
}
