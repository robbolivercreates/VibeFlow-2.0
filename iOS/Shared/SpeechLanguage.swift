import Foundation

/// Speech languages supported for transcription
enum SpeechLanguage: String, CaseIterable, Codable {
    case portuguese = "pt-BR"
    case english = "en-US"
    case spanish = "es-ES"
    case french = "fr-FR"
    case german = "de-DE"
    case italian = "it-IT"
    case japanese = "ja-JP"
    case chinese = "zh-CN"

    var displayName: String {
        switch self {
        case .portuguese: return "Portugues (BR)"
        case .english: return "English (US)"
        case .spanish: return "Espanol"
        case .french: return "Francais"
        case .german: return "Deutsch"
        case .italian: return "Italiano"
        case .japanese: return "Japanese"
        case .chinese: return "Chinese"
        }
    }

    var flag: String {
        switch self {
        case .portuguese: return "🇧🇷"
        case .english: return "🇺🇸"
        case .spanish: return "🇪🇸"
        case .french: return "🇫🇷"
        case .german: return "🇩🇪"
        case .italian: return "🇮🇹"
        case .japanese: return "🇯🇵"
        case .chinese: return "🇨🇳"
        }
    }
}
