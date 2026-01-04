import Foundation

/// Idiomas disponíveis na interface
enum AppLanguage: String, CaseIterable, Identifiable {
    case portuguese = "pt"
    case english = "en"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .portuguese: return "Português"
        case .english: return "English"
        }
    }
    
    var flag: String {
        switch self {
        case .portuguese: return "🇧🇷"
        case .english: return "🇺🇸"
        }
    }
}

/// Strings localizadas
struct L10n {
    static var current: AppLanguage {
        if let saved = UserDefaults.standard.string(forKey: "appLanguage"),
           let lang = AppLanguage(rawValue: saved) {
            return lang
        }
        return .portuguese
    }
    
    // MARK: - Main UI
    static var ready: String {
        current == .english ? "Ready" : "Pronto"
    }
    
    static var listening: String {
        current == .english ? "Listening..." : "Ouvindo..."
    }
    
    static var processing: String {
        current == .english ? "Processing..." : "Processando..."
    }
    
    static var pasted: String {
        current == .english ? "✓ Pasted!" : "✓ Colado!"
    }
    
    static var error: String {
        current == .english ? "Error" : "Erro"
    }
    
    static var configureAPIKey: String {
        current == .english ? "Configure API Key" : "Configure API Key"
    }
    
    static var holdToRecord: String {
        current == .english ? "Hold ⌥⌘ to record" : "Segure ⌥⌘ para gravar"
    }
    
    static var noText: String {
        current == .english ? "No text" : "Nenhum texto"
    }
    
    static var recordingError: String {
        current == .english ? "Recording error" : "Erro na gravação"
    }
    
    // MARK: - Menu
    static var showHide: String {
        current == .english ? "Show/Hide (⌘⇧V)" : "Mostrar/Ocultar (⌘⇧V)"
    }
    
    static var settings: String {
        current == .english ? "Settings..." : "Configurações..."
    }
    
    static var quit: String {
        current == .english ? "Quit" : "Sair"
    }
    
    // MARK: - Settings
    static var settingsTitle: String {
        current == .english ? "Settings" : "Configurações"
    }
    
    static var apiKeyLabel: String {
        current == .english ? "Google Gemini API Key" : "API Key do Google Gemini"
    }
    
    static var apiKeyPlaceholder: String {
        current == .english ? "Paste your API Key here" : "Cole sua API Key aqui"
    }
    
    static var getAPIKey: String {
        current == .english ? "Get free API Key →" : "Obter API Key gratuita →"
    }
    
    static var defaultMode: String {
        current == .english ? "Default Mode" : "Modo Padrão"
    }
    
    static var defaultModeDescription: String {
        current == .english ? "Choose the mode used when starting a recording" : "Escolha o modo que será usado ao iniciar uma gravação"
    }
    
    static var textClarity: String {
        current == .english ? "Text Clarity" : "Clareza do Texto"
    }
    
    static var clarifyAndOrganize: String {
        current == .english ? "Clarify and organize text" : "Clarear e organizar texto"
    }
    
    static var clarifyDescription: String {
        current == .english ? "Removes hesitations, organizes sentences and improves clarity" : "Remove hesitações, organiza frases e melhora a clareza"
    }
    
    static var translation: String {
        current == .english ? "Translation" : "Tradução"
    }
    
    static var translateToEnglish: String {
        current == .english ? "Translate to English" : "Traduzir para Inglês"
    }
    
    static var translateDescription: String {
        current == .english ? "Speak in Portuguese and get the result in English" : "Fale em português e receba o resultado em inglês"
    }
    
    static var interfaceLanguage: String {
        current == .english ? "Interface Language" : "Idioma da Interface"
    }
    
    static var languageDescription: String {
        current == .english ? "Language used in the app interface" : "Idioma usado na interface do app"
    }
    
    static var cancel: String {
        current == .english ? "Cancel" : "Cancelar"
    }
    
    static var save: String {
        current == .english ? "Save" : "Salvar"
    }
    
    static var saved: String {
        current == .english ? "Saved!" : "Salvo!"
    }
    
    // MARK: - Modes
    static var codeMode: String {
        current == .english ? "Code" : "Código"
    }
    
    static var textMode: String {
        current == .english ? "Text" : "Texto"
    }
    
    static var uxMode: String {
        current == .english ? "UX Design" : "UX Design"
    }
    
    static var emailMode: String {
        current == .english ? "Email" : "Email"
    }
    
    static var codeModeTitle: String {
        current == .english ? "Code Mode" : "Modo Código"
    }
    
    static var codeModeDescription: String {
        current == .english ? "Transforms dictation into code. Say \"sum function that takes two numbers\" and get ready code." : "Transforma ditado em código. Diga \"função soma que recebe dois números\" e receba código pronto."
    }
    
    static var textModeTitle: String {
        current == .english ? "Text Mode" : "Modo Texto"
    }
    
    static var textModeDescription: String {
        current == .english ? "Transcribes and formats text. Removes filler words and corrects grammar." : "Transcreve e formata texto. Remove palavras de preenchimento e corrige gramática."
    }
    
    static var uxModeTitle: String {
        current == .english ? "UX Design Mode" : "Modo UX Design"
    }
    
    static var uxModeDescription: String {
        current == .english ? "Formats interface descriptions, user flows and design specifications." : "Formata descrições de interfaces, fluxos de usuário e especificações de design."
    }
    
    static var emailModeTitle: String {
        current == .english ? "Email Mode" : "Modo Email"
    }
    
    static var emailModeDescription: String {
        current == .english ? "Writes clear and simple emails based on your dictation." : "Escreve emails claros e simples a partir do seu ditado."
    }
    
    // MARK: - Clarity features
    static var removesFillers: String {
        current == .english ? "Removes \"so\", \"like\", \"you know\", \"well\"..." : "Remove \"então\", \"tipo\", \"né\", \"assim\"..."
    }
    
    static var organizesSentences: String {
        current == .english ? "Organizes sentences logically" : "Organiza frases de forma lógica"
    }
    
    static var correctsGrammar: String {
        current == .english ? "Corrects grammar and punctuation" : "Corrige gramática e pontuação"
    }
}
