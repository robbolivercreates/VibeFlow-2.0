import Foundation

/// Localization strings for VibeFlow iOS
enum L10n {

    // MARK: - Language Detection

    static var currentLanguage: String {
        Locale.current.language.languageCode?.identifier ?? "en"
    }

    static var isPortuguese: Bool {
        currentLanguage == "pt"
    }

    // MARK: - Onboarding

    static var onboardingTitle1: String {
        isPortuguese ? "Voz para Texto" : "Voice to Text"
    }

    static var onboardingDesc1: String {
        isPortuguese
            ? "Transforme sua voz em texto perfeitamente formatado, código ou emails usando IA."
            : "Transform your voice into perfectly formatted text, code, or emails using AI."
    }

    static var onboardingTitle2: String {
        isPortuguese ? "Teclado Personalizado" : "Custom Keyboard"
    }

    static var onboardingDesc2: String {
        isPortuguese
            ? "Use o VibeFlow como teclado em qualquer app. Toque e fale!"
            : "Use VibeFlow as a keyboard in any app. Just tap and speak!"
    }

    static var onboardingTitle3: String {
        isPortuguese ? "Powered by IA" : "AI-Powered"
    }

    static var onboardingDesc3: String {
        isPortuguese
            ? "Desenvolvido com Google Gemini para transcrição precisa e inteligente."
            : "Powered by Google Gemini for accurate, intelligent transcription."
    }

    static var addApiKey: String {
        isPortuguese ? "Adicione sua API Key" : "Add Your API Key"
    }

    static var apiKeyDesc: String {
        isPortuguese
            ? "Obtenha uma API key gratuita do Google AI Studio para suas transcrições."
            : "Get a free API key from Google AI Studio to power your transcriptions."
    }

    static var apiKeyPlaceholder: String {
        isPortuguese ? "Cole sua API Key do Gemini" : "Paste your Gemini API Key"
    }

    static var getApiKey: String {
        isPortuguese ? "Obter API Key" : "Get API Key"
    }

    static var validating: String {
        isPortuguese ? "Validando..." : "Validating..."
    }

    static var invalidApiKey: String {
        isPortuguese ? "API key inválida. Verifique e tente novamente." : "Invalid API key. Please check and try again."
    }

    static var allSet: String {
        isPortuguese ? "Tudo Pronto!" : "You're All Set!"
    }

    static var getStarted: String {
        isPortuguese ? "Começar" : "Get Started"
    }

    static var next: String {
        isPortuguese ? "Próximo" : "Next"
    }

    static var back: String {
        isPortuguese ? "Voltar" : "Back"
    }

    static var validateContinue: String {
        isPortuguese ? "Validar e Continuar" : "Validate & Continue"
    }

    // MARK: - Setup Steps

    static var setupStep1: String {
        isPortuguese ? "Vá em Ajustes > Geral > Teclado" : "Go to Settings > General > Keyboard"
    }

    static var setupStep2: String {
        isPortuguese ? "Toque em Teclados > Adicionar Novo Teclado" : "Tap Keyboards > Add New Keyboard"
    }

    static var setupStep3: String {
        isPortuguese ? "Selecione VibeFlow" : "Select VibeFlow"
    }

    static var setupStep4: String {
        isPortuguese ? "Ative \"Permitir Acesso Total\"" : "Enable \"Allow Full Access\""
    }

    static var setupComplete: String {
        isPortuguese
            ? "Depois troque para o teclado VibeFlow em qualquer app!"
            : "Then switch to VibeFlow keyboard in any app!"
    }

    // MARK: - Home

    static var ready: String {
        isPortuguese ? "Pronto para Usar" : "Ready to Use"
    }

    static var setupRequired: String {
        isPortuguese ? "Configuração Necessária" : "Setup Required"
    }

    static var readyDesc: String {
        isPortuguese
            ? "Troque para o teclado VibeFlow em qualquer app e toque no mic para transcrever."
            : "Switch to VibeFlow keyboard in any app and tap the mic to transcribe."
    }

    static var setupRequiredDesc: String {
        isPortuguese
            ? "Adicione sua API key do Gemini nas Configurações para começar."
            : "Add your Gemini API key in Settings to get started."
    }

    static var transcriptionMode: String {
        isPortuguese ? "Modo de Transcrição" : "Transcription Mode"
    }

    static var statistics: String {
        isPortuguese ? "Estatísticas" : "Statistics"
    }

    static var transcriptions: String {
        isPortuguese ? "Transcrições" : "Transcriptions"
    }

    static var currentMode: String {
        isPortuguese ? "Modo Atual" : "Current Mode"
    }

    static var howToUse: String {
        isPortuguese ? "Como Usar" : "How to Use"
    }

    // MARK: - Settings

    static var settings: String {
        isPortuguese ? "Configurações" : "Settings"
    }

    static var apiConfiguration: String {
        isPortuguese ? "Configuração da API" : "API Configuration"
    }

    static var geminiApiKey: String {
        isPortuguese ? "API Key do Gemini" : "Gemini API Key"
    }

    static var saveApiKey: String {
        isPortuguese ? "Salvar API Key" : "Save API Key"
    }

    static var apiKeyConfigured: String {
        isPortuguese ? "API key configurada" : "API key configured"
    }

    static var getApiKeyAt: String {
        isPortuguese ? "Obtenha sua API key gratuita em aistudio.google.com" : "Get your free API key at aistudio.google.com"
    }

    static var transcription: String {
        isPortuguese ? "Transcrição" : "Transcription"
    }

    static var defaultMode: String {
        isPortuguese ? "Modo Padrão" : "Default Mode"
    }

    static var speechLanguage: String {
        isPortuguese ? "Idioma da Fala" : "Speech Language"
    }

    static var translateToEnglish: String {
        isPortuguese ? "Traduzir para Inglês" : "Translate to English"
    }

    static var keyboard: String {
        isPortuguese ? "Teclado" : "Keyboard"
    }

    static var hapticFeedback: String {
        isPortuguese ? "Feedback Tátil" : "Haptic Feedback"
    }

    static var showWaveform: String {
        isPortuguese ? "Mostrar Animação de Onda" : "Show Waveform Animation"
    }

    static var openKeyboardSettings: String {
        isPortuguese ? "Abrir Configurações do Teclado" : "Open Keyboard Settings"
    }

    static var about: String {
        isPortuguese ? "Sobre" : "About"
    }

    static var version: String {
        isPortuguese ? "Versão" : "Version"
    }

    static var totalTranscriptions: String {
        isPortuguese ? "Total de Transcrições" : "Total Transcriptions"
    }

    static var resetAllSettings: String {
        isPortuguese ? "Resetar Configurações" : "Reset All Settings"
    }

    // MARK: - Keyboard

    static var holdToRecord: String {
        isPortuguese ? "Segure para gravar" : "Hold to record"
    }

    static var recording: String {
        isPortuguese ? "Gravando..." : "Recording..."
    }

    static var processing: String {
        isPortuguese ? "Processando..." : "Processing..."
    }

    static var done: String {
        isPortuguese ? "Pronto!" : "Done!"
    }

    static var addApiKeyInApp: String {
        isPortuguese ? "Adicione API key no app" : "Add API key in app"
    }

    static var micError: String {
        isPortuguese ? "Erro no microfone" : "Mic error"
    }

    static var enableFullAccess: String {
        isPortuguese ? "Ative 'Acesso Total' em Ajustes" : "Enable 'Full Access' in Settings"
    }

    static var space: String {
        isPortuguese ? "espaço" : "space"
    }

    // MARK: - Modes

    static var modeCode: String {
        isPortuguese ? "Código" : "Code"
    }

    static var modeText: String {
        isPortuguese ? "Texto" : "Text"
    }

    static var modeEmail: String {
        "Email"
    }

    static var modeUXDesign: String {
        "UX Design"
    }

    // MARK: - Tabs

    static var home: String {
        isPortuguese ? "Início" : "Home"
    }
}
