import Foundation

/// Languages supported for transcription output
enum SpeechLanguage: String, CaseIterable, Identifiable, Codable {
    // Most common
    case english = "en"
    case portuguese = "pt"
    case spanish = "es"
    case french = "fr"
    case german = "de"
    case italian = "it"
    case dutch = "nl"
    case russian = "ru"
    case japanese = "ja"
    case korean = "ko"
    case chinese = "zh"
    case arabic = "ar"
    case hindi = "hi"
    case turkish = "tr"
    case polish = "pl"
    case swedish = "sv"
    case norwegian = "no"
    case danish = "da"
    case finnish = "fi"
    case czech = "cs"
    case greek = "el"
    case hebrew = "he"
    case thai = "th"
    case vietnamese = "vi"
    case indonesian = "id"
    case malay = "ms"
    case ukrainian = "uk"
    case romanian = "ro"
    case hungarian = "hu"
    case catalan = "ca"

    var id: String { rawValue }

    /// Display name in native language + English
    var displayName: String {
        switch self {
        case .english: return "English"
        case .portuguese: return "Portugues"
        case .spanish: return "Espanol"
        case .french: return "Francais"
        case .german: return "Deutsch"
        case .italian: return "Italiano"
        case .dutch: return "Nederlands"
        case .russian: return "Russkiy"
        case .japanese: return "Nihongo"
        case .korean: return "Hangugeo"
        case .chinese: return "Zhongwen"
        case .arabic: return "Al-Arabiyyah"
        case .hindi: return "Hindi"
        case .turkish: return "Turkce"
        case .polish: return "Polski"
        case .swedish: return "Svenska"
        case .norwegian: return "Norsk"
        case .danish: return "Dansk"
        case .finnish: return "Suomi"
        case .czech: return "Cestina"
        case .greek: return "Ellinika"
        case .hebrew: return "Ivrit"
        case .thai: return "Phasa Thai"
        case .vietnamese: return "Tieng Viet"
        case .indonesian: return "Bahasa Indonesia"
        case .malay: return "Bahasa Melayu"
        case .ukrainian: return "Ukrayinska"
        case .romanian: return "Romana"
        case .hungarian: return "Magyar"
        case .catalan: return "Catala"
        }
    }

    /// Flag emoji for the language
    var flag: String {
        switch self {
        case .english: return "🇬🇧"
        case .portuguese: return "🇧🇷"
        case .spanish: return "🇪🇸"
        case .french: return "🇫🇷"
        case .german: return "🇩🇪"
        case .italian: return "🇮🇹"
        case .dutch: return "🇳🇱"
        case .russian: return "🇷🇺"
        case .japanese: return "🇯🇵"
        case .korean: return "🇰🇷"
        case .chinese: return "🇨🇳"
        case .arabic: return "🇸🇦"
        case .hindi: return "🇮🇳"
        case .turkish: return "🇹🇷"
        case .polish: return "🇵🇱"
        case .swedish: return "🇸🇪"
        case .norwegian: return "🇳🇴"
        case .danish: return "🇩🇰"
        case .finnish: return "🇫🇮"
        case .czech: return "🇨🇿"
        case .greek: return "🇬🇷"
        case .hebrew: return "🇮🇱"
        case .thai: return "🇹🇭"
        case .vietnamese: return "🇻🇳"
        case .indonesian: return "🇮🇩"
        case .malay: return "🇲🇾"
        case .ukrainian: return "🇺🇦"
        case .romanian: return "🇷🇴"
        case .hungarian: return "🇭🇺"
        case .catalan: return "🏴"
        }
    }

    /// Full name for prompts (English name)
    var fullName: String {
        switch self {
        case .english: return "English"
        case .portuguese: return "Portuguese"
        case .spanish: return "Spanish"
        case .french: return "French"
        case .german: return "German"
        case .italian: return "Italian"
        case .dutch: return "Dutch"
        case .russian: return "Russian"
        case .japanese: return "Japanese"
        case .korean: return "Korean"
        case .chinese: return "Chinese"
        case .arabic: return "Arabic"
        case .hindi: return "Hindi"
        case .turkish: return "Turkish"
        case .polish: return "Polish"
        case .swedish: return "Swedish"
        case .norwegian: return "Norwegian"
        case .danish: return "Danish"
        case .finnish: return "Finnish"
        case .czech: return "Czech"
        case .greek: return "Greek"
        case .hebrew: return "Hebrew"
        case .thai: return "Thai"
        case .vietnamese: return "Vietnamese"
        case .indonesian: return "Indonesian"
        case .malay: return "Malay"
        case .ukrainian: return "Ukrainian"
        case .romanian: return "Romanian"
        case .hungarian: return "Hungarian"
        case .catalan: return "Catalan"
        }
    }

    /// Display string with flag
    var displayWithFlag: String {
        "\(flag) \(displayName)"
    }

    /// Voice keywords that trigger this language via wake word ("Vox, <keyword>")
    /// Supports Portuguese, English and native names
    var voiceAliases: [String] {
        switch self {
        case .english:    return ["inglês", "ingles", "english", "inglesa"]
        case .portuguese: return ["português", "portugues", "portuguese", "pt", "ptbr"]
        case .spanish:    return ["espanhol", "español", "spanish", "espanol"]
        case .french:     return ["francês", "frances", "french", "français", "francais"]
        case .german:     return ["alemão", "alemao", "german", "deutsch"]
        case .italian:    return ["italiano", "italian"]
        case .dutch:      return ["holandês", "holandes", "dutch", "nederlands"]
        case .russian:    return ["russo", "russian", "russkiy"]
        case .japanese:   return ["japonês", "japones", "japanese", "nihongo"]
        case .korean:     return ["coreano", "korean", "hangugeo"]
        case .chinese:    return ["chinês", "chines", "chinese", "mandarin", "zhongwen"]
        case .arabic:     return ["árabe", "arabe", "arabic"]
        case .hindi:      return ["hindi", "hindu"]
        case .turkish:    return ["turco", "turkish", "türkçe", "turkce"]
        case .polish:     return ["polonês", "polones", "polish", "polski"]
        case .swedish:    return ["sueco", "swedish", "svenska"]
        case .norwegian:  return ["norueguês", "noruegues", "norwegian", "norsk"]
        case .danish:     return ["dinamarquês", "dinamarques", "danish", "dansk"]
        case .finnish:    return ["finlandês", "finlandes", "finnish", "suomi"]
        case .czech:      return ["tcheco", "czech", "čeština", "cestina"]
        case .greek:      return ["grego", "greek", "ellinika"]
        case .hebrew:     return ["hebraico", "hebrew", "ivrit"]
        case .thai:       return ["tailandês", "tailandes", "thai"]
        case .vietnamese: return ["vietnamita", "vietnamese", "tieng viet"]
        case .indonesian: return ["indonésio", "indonesio", "indonesian", "bahasa indonesia"]
        case .malay:      return ["malaio", "malay", "bahasa melayu"]
        case .ukrainian:  return ["ucraniano", "ukrainian", "ukrayinska"]
        case .romanian:   return ["romeno", "romanian", "română", "romana"]
        case .hungarian:  return ["húngaro", "hungaro", "hungarian", "magyar"]
        case .catalan:    return ["catalão", "catalan", "català", "catala"]
        }
    }
}
