import Foundation

/// Idiomas disponíveis na interface
enum AppLanguage: String, CaseIterable, Identifiable {
    case portuguese = "pt"
    case english = "en"
    case spanish = "es"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .portuguese: return "Português"
        case .english: return "English"
        case .spanish: return "Español"
        }
    }
    
    var flag: String {
        switch self {
        case .portuguese: return "🇧🇷"
        case .english: return "🇺🇸"
        case .spanish: return "🇪🇸"
        }
    }
}

/// Strings localizadas — EN / PT / ES
struct L10n {
    static var current: AppLanguage {
        if let saved = UserDefaults.standard.string(forKey: "appLanguage"),
           let lang = AppLanguage(rawValue: saved) {
            return lang
        }
        return .portuguese
    }
    
    static func t(_ en: String, _ pt: String, _ es: String) -> String {
        switch current {
        case .english: return en
        case .portuguese: return pt
        case .spanish: return es
        }
    }
    
    // MARK: - General
    static var ok: String { t("OK", "OK", "OK") }
    static var cancel: String { t("Cancel", "Cancelar", "Cancelar") }
    static var clear: String { t("Clear", "Limpar", "Limpiar") }
    static var about: String { t("About", "Sobre", "Acerca de") }
    static var save: String { t("Save", "Salvar", "Guardar") }
    static var saved: String { t("Saved!", "Salvo!", "¡Guardado!") }
    static var open: String { t("Open", "Abrir", "Abrir") }
    static var close: String { t("Close", "Fechar", "Cerrar") }
    static var back: String { t("Back", "Voltar", "Volver") }
    static var continueBtn: String { t("Continue", "Continuar", "Continuar") }
    static var delete: String { t("Delete", "Excluir", "Eliminar") }
    static var confirm: String { t("Confirm", "Confirmar", "Confirmar") }
    static var enabled: String { t("Enabled", "Ativado", "Activado") }
    static var disabled: String { t("Disabled", "Desativado", "Desactivado") }
    static var active: String { t("ACTIVE", "ATIVO", "ACTIVO") }
    static var tip: String { t("Tip", "Dica", "Consejo") }
    static var version: String { t("Version", "Versão", "Versión") }
    
    // MARK: - Main UI / Status
    static var ready: String { t("Ready", "Pronto", "Listo") }
    static var listening: String { t("Listening...", "Ouvindo...", "Escuchando...") }
    static var processing: String { t("Processing...", "Processando...", "Procesando...") }
    static var pasted: String { t("✓ Pasted!", "✓ Colado!", "✓ ¡Pegado!") }
    static var error: String { t("Error", "Erro", "Error") }
    static var configureAPIKey: String { t("Configure API Key", "Configure API Key", "Configurar API Key") }
    static var holdToRecord: String { t("Hold ⌥⌘ to record", "Segure ⌥⌘ para gravar", "Mantenga ⌥⌘ para grabar") }
    static var noText: String { t("No text", "Nenhum texto", "Sin texto") }
    static var recordingError: String { t("Recording error", "Erro na gravação", "Error de grabación") }
    
    // MARK: - Menu Bar
    static var showHide: String { t("Show/Hide (⌘⇧V)", "Mostrar/Ocultar (⌘⇧V)", "Mostrar/Ocultar (⌘⇧V)") }
    static var settings: String { t("Settings...", "Configurações...", "Configuración...") }
    static var quit: String { t("Quit", "Sair", "Salir") }
    static var defaultMode: String { t("Default Mode", "Modo Padrão", "Modo Predeterminado") }
    static var favoriteLanguages: String { t("Favorite Languages", "Idiomas Favoritos", "Idiomas Favoritos") }
    static var microphone: String { t("Microphone", "Microfone", "Micrófono") }
    static var noMicrophoneFound: String { t("No microphone found", "Nenhum microfone encontrado", "No se encontró micrófono") }
    static var openVoxAiGo: String { t("Open VoxAiGo", "Abrir VoxAiGo", "Abrir VoxAiGo") }
    static var configureSetup: String { t("Configure VoxAiGo", "Configurar VoxAiGo", "Configurar VoxAiGo") }
    static var nextMode: String { t("Next Mode (⌃⇧M)", "Próximo Modo (⌃⇧M)", "Siguiente Modo (⌃⇧M)") }
    static var cycleLanguage: String { t("Cycle Language (⌃⇧L)", "Alternar Idioma (⌃⇧L)", "Cambiar Idioma (⌃⇧L)") }
    static var pasteLastTranscription: String { t("Paste Last (⌃⇧V)", "Colar Último (⌃⇧V)", "Pegar Último (⌃⇧V)") }
    
    // MARK: - Setup Wizard
    static var wizardTitle: String { t("Set up VoxAiGo", "Configurar VoxAiGo", "Configurar VoxAiGo") }
    static var vibeFlowTagline: String { t("Transform your voice into code and text with artificial intelligence", "Transforme sua voz em codigo e texto com inteligencia artificial", "Transforma tu voz en código y texto con inteligencia artificial") }
    
    // Wizard - Features
    static var speakNaturally: String { t("Speak Naturally", "Fale Naturalmente", "Habla Naturalmente") }
    static var speakNaturallyDesc: String { t("Use your voice to write code, emails and texts", "Use sua voz para escrever codigo, emails e textos", "Usa tu voz para escribir código, correos y textos") }
    static var ultraFast: String { t("Ultra Fast", "Ultra Rapido", "Ultra Rápido") }
    static var ultraFastDesc: String { t("Instant transcription with Gemini 2.0 Flash", "Transcricao instantanea com Gemini 2.0 Flash", "Transcripción instantánea con Gemini 2.0 Flash") }
    static var simpleShortcut: String { t("Simple Shortcut", "Atalho Simples", "Atajo Simple") }
    static var simpleShortcutDesc: String { t("Hold ⌥⌘ to record, release to transcribe", "Segure ⌥⌘ para gravar, solte para transcrever", "Mantén ⌥⌘ para grabar, suelta para transcribir") }
    static var autoPaste: String { t("Auto Paste", "Cola Automatico", "Pegar Automático") }
    static var autoPasteDesc: String { t("Text is pasted directly into the active app", "O texto e colado direto no app ativo", "El texto se pega directamente en la app activa") }
    
    // Wizard - API Key
    static var configureGeminiKey: String { t("Configure your Google Gemini API Key", "Configure sua API Key do Google Gemini", "Configura tu API Key de Google Gemini") }
    static var pasteAPIKeyHere: String { t("Paste your API key here (Cmd+V)", "Cole sua API key aqui (Cmd+V)", "Pega tu API key aquí (Cmd+V)") }
    static var validating: String { t("Validating...", "Validando...", "Validando...") }
    static var validate: String { t("Validate", "Validar", "Validar") }
    static var howToGetAPIKey: String { t("How to get your free API Key:", "Como obter sua API Key gratuita:", "Cómo obtener tu API Key gratuita:") }
    static var openGoogleAIStudio: String { t("Open Google AI Studio", "Abrir Google AI Studio", "Abrir Google AI Studio") }
    static var apiKeyStoredLocally: String { t("Your API key is stored locally on your Mac and is never shared.", "Sua API key e armazenada localmente no seu Mac e nunca e compartilhada.", "Tu API key se almacena localmente en tu Mac y nunca se comparte.") }
    static var apiKeyLabel: String { t("Google Gemini API Key", "API Key do Google Gemini", "API Key de Google Gemini") }
    static var apiKeyPlaceholder: String { t("Paste your API Key here", "Cole sua API Key aqui", "Pega tu API Key aquí") }
    static var getAPIKey: String { t("Get free API Key →", "Obter API Key gratuita →", "Obtener API Key gratuita →") }
    
    // Wizard - Permissions
    static var requiredPermissions: String { t("Required Permissions", "Permissoes Necessarias", "Permisos Necesarios") }
    static var microphonePermDesc: String { t("To capture your voice and transcribe to text", "Para capturar sua voz e transcrever para texto", "Para capturar tu voz y transcribir a texto") }
    static var allowMicrophone: String { t("Allow Microphone", "Permitir Microfone", "Permitir Micrófono") }
    static var accessibilityTitle: String { t("♿ Accessibility", "♿ Acessibilidade", "♿ Accesibilidad") }
    static var accessibilityDesc: String { t("To paste text automatically (simulates Cmd+V)", "Para colar o texto automaticamente (simula Cmd+V)", "Para pegar texto automáticamente (simula Cmd+V)") }
    static var openPreferences: String { t("Open Preferences", "Abrir Preferencias", "Abrir Preferencias") }
    static var inputMonitoringTitle: String { t("⌨️ Input Monitoring", "⌨️ Input Monitoring", "⌨️ Input Monitoring") }
    static var inputMonitoringDesc: String { t("For global shortcuts to work in the background", "Para atalhos globais funcionarem em segundo plano", "Para que los atajos globales funcionen en segundo plano") }
    static var allPermissionsGranted: String { t("All permissions granted! All set.", "Todas as permissoes concedidas! Tudo pronto.", "¡Todos los permisos concedidos! Todo listo.") }
    static var permissionsSecurityNote: String { t("Your permissions are managed by macOS and can be revoked at any time in System Settings.", "Suas permissoes sao gerenciadas pelo macOS e podem ser revogadas a qualquer momento em Ajustes do Sistema.", "Tus permisos son gestionados por macOS y pueden ser revocados en cualquier momento en Ajustes del Sistema.") }
    static func permissionsGranted(_ count: Int, _ total: Int) -> String {
        t("\(count) of \(total) permissions granted", "\(count) de \(total) permissoes concedidas", "\(count) de \(total) permisos concedidos")
    }
    
    // Wizard - Permission Help Steps
    static var helpOpenPrefs: String { t("Click \"Open Preferences\" — it will open Preferences and Finder", "Clique em \"Abrir Preferencias\" — ira abrir as Preferencias e o Finder", "Haz clic en \"Abrir Preferencias\" — abrirá Preferencias y Finder") }
    static var helpDragVoxAiGo: String { t("Drag the VoxAiGo icon from Finder to the permissions list", "Arraste o icone do VoxAiGo do Finder para a lista de permissoes", "Arrastra el ícono de VoxAiGo del Finder a la lista de permisos") }
    static var helpEnableToggle: String { t("Enable the toggle next to \"VoxAiGo\"", "Ative o toggle (chave) ao lado de \"VoxAiGo\"", "Activa el interruptor junto a \"VoxAiGo\"") }
    
    // Wizard - Test
    static var testVoxAiGo: String { t("Test VoxAiGo", "Teste o VoxAiGo", "Prueba VoxAiGo") }
    static var testInstructions: String { t("Let's test if everything is working. Follow the instructions below:", "Vamos testar se tudo esta funcionando. Siga as instrucoes abaixo:", "Vamos a probar si todo funciona. Sigue las instrucciones:") }
    static var shortcutWorking: String { t("Shortcut working!", "Atalho funcionando!", "¡Atajo funcionando!") }
    static var shortcutTipsBody: String {
        t(
            "• Make sure no other app is using the same shortcuts\n• If the shortcut doesn't work, restart VoxAiGo\n• You can customize shortcuts in Settings > Shortcuts",
            "• Certifique-se de que nenhum outro app esta usando os mesmos atalhos\n• Se o atalho nao funcionar, reinicie o VoxAiGo\n• Voce pode customizar os atalhos em Configuracoes > Atalhos",
            "• Asegúrate de que ninguna otra app use los mismos atajos\n• Si el atajo no funciona, reinicia VoxAiGo\n• Puedes personalizar los atajos en Configuración > Atajos"
        )
    }
    static var testRecordingShortcut: String { t("Test the recording shortcut", "Teste o atalho de gravacao", "Prueba el atajo de grabación") }
    static var shortcutConfigured: String { t("The ⌥⌘ shortcut is configured correctly", "O atalho ⌥⌘ esta configurado corretamente", "El atajo ⌥⌘ está configurado correctamente") }
    static var holdOptionCommand: String { t("Hold ⌥⌘ (Option + Command) for 2 seconds", "Segure ⌥⌘ (Option + Command) por 2 segundos", "Mantén ⌥⌘ (Option + Command) por 2 segundos") }
    static var recordingSpeakSomething: String { t("Recording... Speak something!", "Gravando... Fale algo!", "Grabando... ¡Di algo!") }
    static var transcriptionResult: String { t("Transcription result:", "Resultado da transcricao:", "Resultado de la transcripción:") }
    static var transcriptionWorking: String { t("Transcription working perfectly!", "Transcricao funcionando perfeitamente!", "¡Transcripción funcionando perfectamente!") }
    static var simulateTest: String { t("Simulate test (if shortcut doesn't work)", "Simular teste (se o atalho nao funcionar)", "Simular prueba (si el atajo no funciona)") }
    static var tips: String { t("Tips:", "Dicas:", "Consejos:") }
    
    // Wizard - Languages
    static var languagesAndQuickSwitch: String { t("Languages & Quick Switch", "Idiomas e Alternancia Rapida", "Idiomas y Cambio Rápido") }
    static var currentLanguage: String { t("Current language:", "Idioma atual:", "Idioma actual:") }
    static var switchLanguage: String { t("Switch Language", "Alternar Idioma", "Cambiar Idioma") }
    static var pressToSwitchLanguages: String { t("Press to cycle through your favorite languages", "Pressione para ciclar entre seus idiomas favoritos", "Presiona para ciclar entre tus idiomas favoritos") }
    static var favoriteLangsForQuickSwitch: String { t("Favorite Languages (for quick switch)", "Idiomas Favoritos (para alternancia rapida)", "Idiomas Favoritos (para cambio rápido)") }
    static var addRemoveFavoritesInSettings: String { t("You can add or remove favorite languages in Settings > Languages", "Voce pode adicionar ou remover idiomas favoritos em Configuracoes > Idiomas", "Puedes agregar o quitar idiomas favoritos en Configuración > Idiomas") }
    static var supportedLanguages: String { t("Supported languages (30+)", "Idiomas suportados (30+)", "Idiomas soportados (30+)") }
    static var manageLanguagesHint: String { t("To manage languages: Menu Bar > VoxAiGo > Open VoxAiGo > Languages", "Para gerenciar idiomas: Menu Bar > VoxAiGo > Abrir VoxAiGo > Idiomas", "Para gestionar idiomas: Barra de Menú > VoxAiGo > Abrir VoxAiGo > Idiomas") }
    
    // Wizard - Ready
    static var startUsing: String { t("Start Using", "Comecar a Usar", "Empezar a Usar") }
    
    // Wizard - Language Selection (new first step)
    static var chooseLanguage: String { t("Choose your language", "Escolha seu idioma", "Elige tu idioma") }
    static var interfaceLanguageDesc: String { t("Select the language for the VoxAiGo interface", "Selecione o idioma da interface do VoxAiGo", "Selecciona el idioma de la interfaz de VoxAiGo") }
    
    // MARK: - Home View
    static var recents: String { t("Recents", "Recentes", "Recientes") }
    static var noTranscriptionsYet: String { t("No transcriptions yet", "Nenhuma transcricao ainda", "Sin transcripciones aún") }
    static var holdOptionCmdToStart: String { t("Hold ⌥⌘ to start recording", "Segure ⌥⌘ para comecar a gravar", "Mantén ⌥⌘ para empezar a grabar") }
    
    // MARK: - History View
    static var history: String { t("History", "Histórico", "Historial") }
    static func itemsSaved(_ count: Int) -> String { t("\(count) items saved", "\(count) itens salvos", "\(count) elementos guardados") }
    static func deleteAllConfirmation(_ count: Int) -> String { t("This will permanently delete all \(count) items from history.", "Isso excluirá permanentemente todos os \(count) itens do histórico.", "Esto eliminará permanentemente los \(count) elementos del historial.") }
    static var noHistoryItems: String { t("No items in history", "Nenhum item no histórico", "Sin elementos en el historial") }
    static var transcriptionsAppearHere: String { t("Your transcriptions will appear here", "Suas transcrições aparecerão aqui", "Tus transcripciones aparecerán aquí") }
    static var noResultsFound: String { t("No results found", "Nenhum resultado encontrado", "Sin resultados encontrados") }
    static var preview: String { t("Preview", "Preview", "Vista previa") }
    
    // MARK: - Main Window
    static var transcriptions: String { t("transcriptions", "transcricoes", "transcripciones") }
    static var recorded: String { t("recorded", "gravado", "grabado") }
    
    // MARK: - Settings / Settings Detail
    static var settingsTitle: String { t("Settings", "Ajustes", "Ajustes") }
    static var customizeVoxAiGo: String { t("Customize your VoxAiGo", "Personalize seu VoxAiGo", "Personaliza tu VoxAiGo") }
    static var geminiModel: String { t("Gemini 2.0 Flash", "Gemini 2.0 Flash", "Gemini 2.0 Flash") }
    static var clickShortcutToEdit: String { t("Click a shortcut to edit. Press the desired keys.", "Clique em um atalho para editar. Pressione as teclas desejadas.", "Haz clic en un atajo para editar. Presiona las teclas deseadas.") }
    static var configureVoxAiGoPrefs: String { t("Configure VoxAiGo according to your preferences.", "Configure o VoxAiGo de acordo com suas preferencias.", "Configura VoxAiGo según tus preferencias.") }
    static var clearAllDataWarning: String { t("This will clear all transcription history and style samples. This action cannot be undone.", "Isso ira limpar todo o historico de transcricoes e amostras de estilo. Esta acao nao pode ser desfeita.", "Esto borrará todo el historial de transcripciones y muestras de estilo. Esta acción no se puede deshacer.") }
    
    // Settings - Tabs/Labels
    static var general: String { t("General", "Geral", "General") }
    static var api: String { t("API", "API", "API") }
    static var advanced: String { t("Advanced", "Avançado", "Avanzado") }
    static var behavior: String { t("Behavior", "Comportamento", "Comportamiento") }
    static var personalization: String { t("Personalization", "Personalizacao", "Personalización") }
    static var support: String { t("Support", "Suporte", "Soporte") }
    static var data: String { t("Data", "Dados", "Datos") }
    
    // Settings - Behavior toggles
    static var autoPasteToggle: String { t("Auto-paste automatically", "Colar automaticamente", "Pegar automáticamente") }
    static var autoClose: String { t("Close window after pasting", "Fechar janela após colar", "Cerrar ventana tras pegar") }
    static var saveHistory: String { t("Save history", "Salvar histórico", "Guardar historial") }
    static var soundEffects: String { t("Sound effects", "Efeitos sonoros", "Efectos de sonido") }
    static var clearHistory: String { t("Clear history", "Limpar histórico", "Limpiar historial") }
    
    // Settings - Mode
    static var modeDescription: String { t("The mode determines how Gemini processes your audio.", "O modo determina como o Gemini processa seu áudio.", "El modo determina cómo Gemini procesa tu audio.") }
    static var outputLanguage: String { t("The transcribed text will be generated in this language, regardless of the language spoken.", "O texto transcrito sera gerado neste idioma, independente do idioma falado.", "El texto transcrito se generará en este idioma, independientemente del idioma hablado.") }
    static var shortcutToChangeLanguage: String { t("Shortcut to change language", "Atalho para mudar idioma", "Atajo para cambiar idioma") }
    static var pressCtrlShiftL: String { t("Press ⌃⇧L (Control+Shift+L) to switch between favorite languages", "Pressione ⌃⇧L (Control+Shift+L) para alternar entre idiomas favoritos", "Presiona ⌃⇧L (Control+Shift+L) para alternar entre idiomas favoritos") }
    static var selectFrequentLanguages: String { t("Select the languages you use frequently to switch quickly with ⌃⇧L", "Selecione os idiomas que você usa com frequência para alternar rapidamente com ⌃⇧L", "Selecciona los idiomas que usas frecuentemente para cambiar rápidamente con ⌃⇧L") }
    
    // Settings - Style
    static var writingStyleDescription: String { t("VoxAiGo learns your style from previous transcriptions to personalize results.", "VoxAiGo aprende seu estilo com base nas transcricoes anteriores para personalizar os resultados.", "VoxAiGo aprende tu estilo de transcripciones anteriores para personalizar los resultados.") }
    static func samplesSaved(_ count: Int) -> String { t("\(count) samples saved", "\(count) amostras salvas", "\(count) muestras guardadas") }
    
    // Settings - API
    static var geminiAPI: String { t("Gemini API", "API Gemini", "API Gemini") }
    static var outputLanguageDescription: String { t("Output Language", "Idioma de Saída", "Idioma de Salida") }
    static var permissions: String { t("Permissions", "Permissões", "Permisos") }
    static var shortcuts: String { t("Shortcuts", "Atalhos", "Atajos") }
    static var apiKeyStoredInKeychain: String { t("Your API key is stored locally in the macOS Keychain.", "Sua API key é armazenada localmente no Keychain do macOS.", "Tu API key se almacena localmente en el Keychain de macOS.") }
    static var getAPIKeyGoogleAI: String { t("Get API key at Google AI Studio", "Obter API key no Google AI Studio", "Obtener API key en Google AI Studio") }
    static var model: String { t("Model", "Modelo", "Modelo") }
    
    // Settings - Wizard
    static var setupWizard: String { t("Setup Wizard", "Wizard de Configuração", "Asistente de Configuración") }
    static var rerunWizard: String { t("Run the wizard again to reconfigure VoxAiGo", "Execute o wizard novamente para reconfigurar o VoxAiGo", "Ejecuta el asistente nuevamente para reconfigurar VoxAiGo") }
    
    // Settings - Permissions
    static var accessibility: String { t("Accessibility", "Acessibilidade", "Accesibilidad") }
    static var inputMonitoring: String { t("Input Monitoring", "Input Monitoring", "Input Monitoring") }
    static var permissionsHint: String { t("VoxAiGo needs Accessibility to auto-paste (⌘V) and Input Monitoring to detect global keyboard shortcuts.", "O VoxAiGo precisa de Acessibilidade para colar automaticamente (⌘V) e Input Monitoring para detectar atalhos globais de teclado.", "VoxAiGo necesita Accesibilidad para pegar automáticamente (⌘V) e Input Monitoring para detectar atajos globales de teclado.") }
    static var request: String { t("Request", "Solicitar", "Solicitar") }
    static var allow: String { t("Allow", "Permitir", "Permitir") }
    static var allowed: String { t("Allowed", "Permitido", "Permitido") }
    static var requiredForAutoPaste: String { t("Required for auto-paste", "Necessário para colar automaticamente", "Necesario para pegar automáticamente") }
    static var requiredForShortcuts: String { t("Required for global shortcuts", "Necessário para atalhos globais", "Necesario para atajos globales") }
    
    // Permission status
    static var statusNotDetermined: String { t("Not Determined", "Não solicitado", "No determinado") }
    static var statusRestricted: String { t("Restricted", "Restrito", "Restringido") }
    static var statusDenied: String { t("Denied", "Negado", "Denegado") }
    static var statusAuthorized: String { t("Authorized", "Permitido", "Autorizado") }
    static var statusUnknown: String { t("Unknown", "Desconhecido", "Desconocido") }
    
    // Settings - Shortcuts
    static var record: String { t("Record", "Gravar", "Grabar") }
    static var recordShortcut: String { t("⌥⌘ (hold)", "⌥⌘ (segure)", "⌥⌘ (mantener)") }
    static var showHideShort: String { t("Show/Hide", "Mostrar/Esconder", "Mostrar/Ocultar") }
    static var settingsShort: String { t("Settings", "Configurações", "Configuración") }
    static var helpAndDocs: String { t("Help and documentation", "Ajuda e documentação", "Ayuda y documentación") }
    static var checkAll: String { t("Check All", "Verificar Tudo", "Verificar Todo") }
    
    // Settings - Tips
    static var shortcutsTipTitle: String { t("Tip: If shortcuts stop working", "Dica: Se os atalhos pararem de funcionar", "Consejo: Si los atajos dejan de funcionar") }
    static var shortcutsTipBody: String { t("When VoxAiGo is updated, macOS may revoke permissions. In that case, go to System Settings → Privacy and remove/re-add VoxAiGo in the Accessibility and Input Monitoring sections.", "Quando o VoxAiGo é atualizado, o macOS pode revogar as permissões. Nesse caso, vá em Ajustes do Sistema → Privacidade e remova/re-adicione o VoxAiGo nas seções de Acessibilidade e Monitoramento de Teclado.", "Cuando VoxAiGo se actualiza, macOS puede revocar los permisos. En ese caso, ve a Ajustes del Sistema → Privacidad y quita/reagrega VoxAiGo en las secciones de Accesibilidad y Monitoreo de Teclado.") }
    
    // MARK: - Modern Settings
    static var touchToChange: String { t("Touch to change", "Toque para mudar", "Toca para cambiar") }
    static var selectFavoriteLangs: String { t("Select languages to cycle quickly", "Selecione os idiomas para ciclar rapidamente", "Selecciona los idiomas para ciclar rápidamente") }
    static var editFavorites: String { t("Edit favorites", "Editar favoritos", "Editar favoritos") }
    static var selectLanguage: String { t("Select Language", "Selecionar Idioma", "Seleccionar Idioma") }
    static var chooseOutputLanguage: String { t("Choose your output language", "Escolha seu idioma de saída", "Elige tu idioma de salida") }
    static var favorites: String { t("FAVORITES", "FAVORITOS", "FAVORITOS") }
    static func favoritesCount(_ count: Int) -> String { t("\(count) favorites", "\(count) favoritos", "\(count) favoritos") }
    static var clickStarToToggle: String { t("Click the star to add/remove favorites", "Clique na estrela para adicionar/remover favoritos", "Haz clic en la estrella para agregar/quitar favoritos") }
    
    // MARK: - Analytics View
    static var words: String { t("Words", "Palavras", "Palabras") }
    static var statistics: String { t("Statistics", "Estatísticas", "Estadísticas") }
    static var summary: String { t("Summary", "Resumo", "Resumen") }
    static var achievements: String { t("Achievements", "Conquistas", "Logros") }
    static var timeSavedHeader: String { t("Time Saved", "Tempo Economizado", "Tiempo Ahorrado") }
    static var recordedTimeHeader: String { t("Recorded Time", "Tempo Gravado", "Tiempo Grabado") }
    static var timeSavedPerMonth: String { t("Time Saved per Month", "Tempo Economizado por Mês", "Tiempo Ahorrado por Mes") }
    
    static func levelN(_ n: Int) -> String { t("Level \(n)", "Nível \(n)", "Nivel \(n)") }
    static var nextLevel: String { t("Next level", "Próximo nível", "Siguiente nivel") }
    static func transcriptionsToNext(_ n: Int) -> String { t("\(n) transcriptions", "\(n) transcrições", "\(n) transcripciones") }
    static var maxLevel: String { t("Max Level!", "Nível Máximo!", "¡Nivel Máximo!") }
    static var currentStreak: String { t("Current streak", "Streak atual", "Racha actual") }
    static var longestStreak: String { t("Longest streak", "Maior streak", "Mayor racha") }
    static var today: String { t("Today", "Hoje", "Hoy") }
    static var speed: String { t("Speed", "Velocidade", "Velocidad") }
    static var wpmSpeaking: String { t("WPM speaking", "WPM falando", "PPM hablando") }
    static var wpmTyping: String { t("WPM typing", "WPM digitando", "PPM tecleando") }
    static var faster: String { t("faster", "mais rápido", "más rápido") }
    static func timeSavedHours(_ hours: Int) -> String {
        let h = hours > 1
        return t(
            "You saved **\(hours) hour\(h ? "s" : "")** that would have been spent typing!",
            "Você economizou **\(hours) hora\(h ? "s" : "")** que seriam gastas digitando!",
            "¡Ahorraste **\(hours) hora\(h ? "s" : "")** que habrías gastado tecleando!"
        )
    }
    static func timeSavedWords(_ words: String) -> String {
        t("You saved time equivalent to typing **\(words) words**!", "Você economizou tempo equivalente a digitar **\(words) palavras**!", "¡Ahorraste tiempo equivalente a teclear **\(words) palabras**!")
    }
    static var startUsingToSeeTime: String { t("Start using VoxAiGo to see how much time you save!", "Comece a usar o VoxAiGo para ver quanto tempo você economiza!", "¡Empieza a usar VoxAiGo para ver cuánto tiempo ahorras!") }
    static func achievementsCount(_ unlocked: Int, _ total: Int) -> String { t("\(unlocked) of \(total) achievements", "\(unlocked) de \(total) conquistas", "\(unlocked) de \(total) logros") }
    
    // MARK: - Modes View
    static var modes: String { t("Modes", "Modos", "Modos") }
    static var modesDescription: String { t("Each mode optimizes transcription for a specific type of content. Choose the ideal mode for your task.", "Cada modo otimiza a transcricao para um tipo especifico de conteudo. Escolha o modo ideal para sua tarefa.", "Cada modo optimiza la transcripción para un tipo específico de contenido. Elige el modo ideal para tu tarea.") }
    static var currentMode: String { t("Current Mode", "Modo Atual", "Modo Actual") }
    static var creativity: String { t("Creativity", "Criatividade", "Creatividad") }
    static var allModes: String { t("All Modes", "Todos os Modos", "Todos los Modos") }
    static var modeTip: String { t("The mode is automatically saved. You can switch modes at any time, even during a recording session.", "O modo e automaticamente salvo. Voce pode trocar de modo a qualquer momento, mesmo durante uma sessao de gravacao.", "El modo se guarda automáticamente. Puedes cambiar de modo en cualquier momento, incluso durante una sesión de grabación.") }
    static var uses: String { t("uses", "usos", "usos") }
    static var systemPrompt: String { t("System Prompt", "Prompt do Sistema", "Prompt del Sistema") }
    static var temperature: String { t("Temperature:", "Temperatura:", "Temperatura:") }
    static var commandMode: String { t("Command Mode", "Modo Comando", "Modo Comando") }
    
    // MARK: - Modes
    static var codeMode: String { t("Code", "Código", "Código") }
    static var textMode: String { t("Text", "Texto", "Texto") }
    static var uxMode: String { t("UX Design", "UX Design", "UX Design") }
    static var codeModeTitle: String { t("Code Mode", "Modo Código", "Modo Código") }
    static var codeModeDescription: String { t("Transforms dictation into code. Say \"sum function that takes two numbers\" and get ready code.", "Transforma ditado em código. Diga \"função soma que recebe dois números\" e receba código pronto.", "Transforma el dictado en código. Di \"función suma que recibe dos números\" y obtén código listo.") }
    static var textModeTitle: String { t("Text Mode", "Modo Texto", "Modo Texto") }
    static var textModeDescription: String { t("Transcribes and formats text. Removes filler words and corrects grammar.", "Transcreve e formata texto. Remove palavras de preenchimento e corrige gramática.", "Transcribe y formatea texto. Elimina muletillas y corrige gramática.") }
    static var uxModeTitle: String { t("UX Design Mode", "Modo UX Design", "Modo UX Design") }
    static var uxModeDescription: String { t("Formats interface descriptions, user flows and design specifications.", "Formata descrições de interfaces, fluxos de usuário e especificações de design.", "Formatea descripciones de interfaces, flujos de usuario y especificaciones de diseño.") }
    
    // MARK: - Style View
    static var writingStyle: String { t("Writing Style", "Estilo de Escrita", "Estilo de Escritura") }
    static var writingStyleFullDesc: String { t("VoxAiGo learns your writing style to personalize transcriptions, imitating your vocabulary, tone and formatting.", "O VoxAiGo aprende seu estilo de escrita para personalizar as transcricoes, imitando seu vocabulario, tom e formatacao.", "VoxAiGo aprende tu estilo de escritura para personalizar las transcripciones, imitando tu vocabulario, tono y formato.") }
    static var styleLearning: String { t("Style Learning", "Aprendizado de Estilo", "Aprendizaje de Estilo") }
    static var styleLearningDesc: String { t("When enabled, VoxAiGo analyzes your transcriptions to learn your unique style.", "Quando ativado, o VoxAiGo analisa suas transcricoes para aprender seu estilo unico.", "Cuando está activado, VoxAiGo analiza tus transcripciones para aprender tu estilo único.") }
    static var howItWorks: String { t("How It Works", "Como Funciona", "Cómo Funciona") }
    static var learnedSamples: String { t("Learned Samples", "Amostras Aprendidas", "Muestras Aprendidas") }
    static var clearAll: String { t("Clear All", "Limpar Tudo", "Limpiar Todo") }
    static var noSamplesYet: String { t("No samples yet", "Nenhuma amostra ainda", "Sin muestras aún") }
    static var doTranscriptionsToLearn: String { t("Do some transcriptions for VoxAiGo to learn your style", "Faca algumas transcricoes para o VoxAiGo aprender seu estilo", "Haz algunas transcripciones para que VoxAiGo aprenda tu estilo") }
    static func sampleCount(_ n: Int) -> String { t("\(n) sample\(n == 1 ? "" : "s")", "\(n) amostra\(n == 1 ? "" : "s")", "\(n) muestra\(n == 1 ? "" : "s")") }
    static var clearSamplesForThisMode: String { t("Clear samples for this mode", "Limpar amostras deste modo", "Limpiar muestras de este modo") }
    static func clearConfirmMode(_ mode: String) -> String { t("Do you want to clear all samples from mode \(mode)?", "Deseja limpar todas as amostras do modo \(mode)?", "¿Deseas limpiar todas las muestras del modo \(mode)?") }
    static var clearConfirmAll: String { t("Do you want to clear all style samples?", "Deseja limpar todas as amostras de estilo?", "¿Deseas limpiar todas las muestras de estilo?") }
    
    // MARK: - Languages View
    static var languages: String { t("Languages", "Idiomas", "Idiomas") }
    static var languagesDesc: String { t("Configure the output language for your transcriptions. You can speak in any language - VoxAiGo translates automatically.", "Configure o idioma de saida das suas transcricoes. Voce pode falar em qualquer idioma - o VoxAiGo traduz automaticamente.", "Configura el idioma de salida de tus transcripciones. Puedes hablar en cualquier idioma - VoxAiGo traduce automáticamente.") }
    static var shortcutToSwitch: String { t("Shortcut to switch", "Atalho para alternar", "Atajo para alternar") }
    static var useCtrlShiftL: String { t("Use ⌃⇧L to quickly switch between your favorite languages.", "Use ⌃⇧L para alternar rapidamente entre seus idiomas favoritos.", "Usa ⌃⇧L para alternar rápidamente entre tus idiomas favoritos.") }
    static var allLanguages: String { t("All Languages", "Todos os Idiomas", "Todos los Idiomas") }
    
    // MARK: - Snippets View
    static var snippets: String { t("Snippets", "Snippets", "Snippets") }
    static var snippetsDesc: String { t("Use :abbreviation: in transcribed text to expand automatically.", "Use :abbreviation: no texto transcrito para expandir automaticamente.", "Usa :abreviación: en el texto transcrito para expandir automáticamente.") }
    static var snippetUsageHint: String { t("Use :your-abbreviation: in text to expand", "Use :sua-abreviacao: no texto para expandir", "Usa :tu-abreviación: en el texto para expandir") }
    
    // MARK: - Floating Preview
    static func characters(_ n: Int) -> String { t("\(n) characters", "\(n) caracteres", "\(n) caracteres") }
    
    // MARK: - Launch at Login
    static var launchAtLogin: String { t("Launch at login", "Abrir ao iniciar", "Abrir al iniciar") }
    static var launchAtLoginDescription: String { t("Automatically start VoxAiGo when you log in", "Inicia o VoxAiGo automaticamente ao ligar o Mac", "Inicia VoxAiGo automáticamente al encender el Mac") }

    // MARK: - Clarity features
    static var textClarity: String { t("Text Clarity", "Clareza do Texto", "Claridad del Texto") }
    static var clarifyAndOrganize: String { t("Clarify and organize text", "Clarear e organizar texto", "Aclarar y organizar texto") }
    static var clarifyDescription: String { t("Removes hesitations, organizes sentences and improves clarity", "Remove hesitações, organiza frases e melhora a clareza", "Elimina vacilaciones, organiza oraciones y mejora la claridad") }
    static var translation: String { t("Translation", "Tradução", "Traducción") }
    static var translateToEnglish: String { t("Translate to English", "Traduzir para Inglês", "Traducir al Inglés") }
    static var translateDescription: String { t("Speak in Portuguese and get the result in English", "Fale em português e receba o resultado em inglês", "Habla en portugués y obtén el resultado en inglés") }
    static var interfaceLanguage: String { t("Interface Language", "Idioma da Interface", "Idioma de la Interfaz") }
    static var languageDescription: String { t("Language used in the app interface", "Idioma usado na interface do app", "Idioma usado en la interfaz de la app") }
    static var removesFillers: String { t("Removes \"so\", \"like\", \"you know\", \"well\"...", "Remove \"então\", \"tipo\", \"né\", \"assim\"...", "Elimina \"pues\", \"o sea\", \"bueno\", \"este\"...") }
    static var organizesSentences: String { t("Organizes sentences logically", "Organiza frases de forma lógica", "Organiza oraciones lógicamente") }
    static var correctsGrammar: String { t("Corrects grammar and punctuation", "Corrige gramática e pontuação", "Corrige gramática y puntuación") }
    
    static var defaultModeDescription: String { t("Choose the mode used when starting a recording", "Escolha o modo que será usado ao iniciar uma gravação", "Elige el modo usado al iniciar una grabación") }

    // MARK: - Mode Detailed Descriptions
    static var codeModeDetail: String { t(
        "Ideal for dictating code by voice. Say what you want to create — like \"a function that sorts an array\" — and get clean, ready-to-use code.\n\nWhen to use:\n• Writing functions, classes, or variables\n• Describing logic you want turned into code\n• Quick prototyping without typing\n\nTip: Mention the programming language for better results, e.g. \"in Python, a function that...\"",
        "Ideal para ditar código por voz. Diga o que deseja criar — como \"uma função que ordena um array\" — e receba código limpo, pronto para usar.\n\nQuando usar:\n• Escrever funções, classes ou variáveis\n• Descrever lógica que você quer transformar em código\n• Prototipar rapidamente sem digitar\n\nDica: Mencione a linguagem para melhores resultados, ex: \"em Python, uma função que...\"",
        "Ideal para dictar código por voz. Di lo que deseas crear — como \"una función que ordena un array\" — y obtén código limpio, listo para usar.\n\nCuándo usar:\n• Escribir funciones, clases o variables\n• Describir lógica que quieres convertir en código\n• Prototipar rápidamente sin teclear\n\nConsejo: Menciona el lenguaje para mejores resultados, ej: \"en Python, una función que...\""
    ) }

    static var textModeDetail: String { t(
        "For everyday use. Speak naturally and get clean, well-formatted text — without the \"ums\", \"ahs\", and filler words.\n\nWhen to use:\n• Writing messages, notes, or documents\n• Capturing ideas quickly by voice\n• Any situation where you'd normally type text\n\nTip: Speak naturally — VoxAiGo automatically removes hesitations and corrects grammar.",
        "Para o dia a dia. Fale naturalmente e receba texto limpo e bem formatado — sem os \"éé\", \"tipo\", \"né\" e palavras de preenchimento.\n\nQuando usar:\n• Escrever mensagens, notas ou documentos\n• Capturar ideias rapidamente por voz\n• Qualquer situação em que você normalmente digitaria\n\nDica: Fale naturalmente — o VoxAiGo remove hesitações e corrige a gramática automaticamente.",
        "Para el día a día. Habla naturalmente y obtén texto limpio y bien formateado — sin los \"este\", \"o sea\", \"bueno\" y muletillas.\n\nCuándo usar:\n• Escribir mensajes, notas o documentos\n• Capturar ideas rápidamente por voz\n• Cualquier situación donde normalmente teclearías\n\nConsejo: Habla naturalmente — VoxAiGo elimina vacilaciones y corrige la gramática automáticamente."
    ) }

    static var emailModeDetail: String { t(
        "Transforms your speech into a well-structured, professional email. Just describe what you want to say and get a ready-to-send email.\n\nWhen to use:\n• Composing professional or formal emails\n• Quick replies that need good formatting\n• Writing messages with proper greeting and sign-off\n\nTip: Start by saying who the email is for and the subject, e.g. \"email to João about the meeting tomorrow\".",
        "Transforma sua fala em um email profissional e bem estruturado. Basta descrever o que quer dizer e receba um email pronto para enviar.\n\nQuando usar:\n• Compor emails profissionais ou formais\n• Respostas rápidas que precisam de boa formatação\n• Escrever mensagens com saudação e despedida adequadas\n\nDica: Comece dizendo para quem é o email e o assunto, ex: \"email para o João sobre a reunião de amanhã\".",
        "Transforma tu habla en un email profesional y bien estructurado. Solo describe lo que quieres decir y obtén un email listo para enviar.\n\nCuándo usar:\n• Componer emails profesionales o formales\n• Respuestas rápidas que necesitan buena estructura\n• Escribir mensajes con saludo y despedida adecuados\n\nConsejo: Empieza diciendo a quién va el email y el tema, ej: \"email para João sobre la reunión de mañana\"."
    ) }

    static var uxModeDetail: String { t(
        "Designed for UX designers and product teams. Describe interfaces, user flows, or design specs and get well-organized documentation.\n\nWhen to use:\n• Describing screens, components, or interactions\n• Documenting user flows step by step\n• Writing design specs and requirements\n\nTip: Be specific about UI elements — say \"button\", \"modal\", \"card\", \"dropdown\" — for better structured output.",
        "Feito para designers UX e equipes de produto. Descreva interfaces, fluxos de usuário ou especificações de design e receba documentação bem organizada.\n\nQuando usar:\n• Descrever telas, componentes ou interações\n• Documentar fluxos de usuário passo a passo\n• Escrever specs de design e requisitos\n\nDica: Seja específico com elementos de UI — diga \"botão\", \"modal\", \"card\", \"dropdown\" — para uma saída mais estruturada.",
        "Diseñado para diseñadores UX y equipos de producto. Describe interfaces, flujos de usuario o specs de diseño y obtén documentación bien organizada.\n\nCuándo usar:\n• Describir pantallas, componentes o interacciones\n• Documentar flujos de usuario paso a paso\n• Escribir specs de diseño y requisitos\n\nConsejo: Sé específico con elementos de UI — di \"botón\", \"modal\", \"card\", \"dropdown\" — para una salida más estructurada."
    ) }

    static var commandModeDetail: String { t(
        "A powerful mode that transforms selected text based on voice commands. Select text in any app, then use a voice command to modify it.\n\nWhen to use:\n• \"Make it professional\" — rewrites in formal tone\n• \"Summarize\" — creates a concise summary\n• \"Translate to English\" — translates the text\n• \"Fix grammar\" — corrects errors only\n• \"Add bullet points\" — formats as a list\n\nTip: First select text in any app, then activate VoxAiGo and say the command.",
        "Um modo poderoso que transforma texto selecionado com comandos de voz. Selecione texto em qualquer app e use um comando de voz para modificá-lo.\n\nQuando usar:\n• \"Mais profissional\" — reescreve em tom formal\n• \"Resumir\" — cria um resumo conciso\n• \"Traduzir para inglês\" — traduz o texto\n• \"Corrigir gramática\" — corrige apenas erros\n• \"Adicionar tópicos\" — formata como lista\n\nDica: Primeiro selecione o texto em qualquer app, depois ative o VoxAiGo e diga o comando.",
        "Un modo poderoso que transforma texto seleccionado con comandos de voz. Selecciona texto en cualquier app y usa un comando de voz para modificarlo.\n\nCuándo usar:\n• \"Más profesional\" — reescribe en tono formal\n• \"Resumir\" — crea un resumen conciso\n• \"Traducir al inglés\" — traduce el texto\n• \"Corregir gramática\" — corrige solo errores\n• \"Agregar viñetas\" — formatea como lista\n\nConsejo: Primero selecciona texto en cualquier app, luego activa VoxAiGo y di el comando."
    ) }
    
    // MARK: - ModernSettingsView
    static var openWizardShort: String { t("Open Wizard", "Abrir Wizard", "Abrir Asistente") }
    static var transcriptionMode: String { t("Transcription Mode", "Modo de Transcrição", "Modo de Transcripción") }
    static var outputLanguageTitle: String { t("Output Language", "Idioma de Saída", "Idioma de Salida") }
    static var favoriteLangsTitle: String { t("Favorite Languages", "Idiomas Favoritos", "Idiomas Favoritos") }
    static var keyboardShortcuts: String { t("Keyboard Shortcuts", "Atalhos de Teclado", "Atajos de Teclado") }
    static var systemPermissions: String { t("System Permissions", "Permissões do Sistema", "Permisos del Sistema") }
    static var diagnostics: String { t("Diagnostics", "Diagnóstico", "Diagnóstico") }
    
    // ModernSettings - Behavior subtitles
    static var autoPasteSub: String { t("Pastes text in the active app", "Cola o texto no app ativo", "Pega el texto en la app activa") }
    static var autoCloseSub: String { t("Hides window automatically", "Esconde a janela automaticamente", "Oculta la ventana automáticamente") }
    static var soundEffectsSub: String { t("Plays sounds when recording and processing", "Toca sons ao gravar e processar", "Reproduce sonidos al grabar y procesar") }
    static var saveHistorySub: String { t("Keeps the last 50 transcriptions", "Mantém as últimas 50 transcrições", "Mantiene las últimas 50 transcripciones") }
    
    // ModernSettings - Shortcut descriptions
    static var recordHold: String { t("Record (hold)", "Gravar (segure)", "Grabar (mantener)") }
    static var holdToRecordRelease: String { t("Hold to record, release to process", "Segure para gravar, solte para processar", "Mantén para grabar, suelta para procesar") }
    static var toggleVoxAiGoWindow: String { t("Toggles the VoxAiGo window", "Alterna a janela do VoxAiGo", "Alterna la ventana de VoxAiGo") }
    static var changeLanguage: String { t("Change Language", "Mudar Idioma", "Cambiar Idioma") }
    static var cyclesFavoriteLangs: String { t("Cycles between favorite languages", "Cicla entre os idiomas favoritos", "Cicla entre los idiomas favoritos") }
    static var opensSettingsWindow: String { t("Opens this window", "Abre esta janela", "Abre esta ventana") }
    static var showsTranscriptionHistory: String { t("Shows the transcription history", "Mostra o histórico de transcrições", "Muestra el historial de transcripciones") }
    static var conversationReplyShortcutDesc: String { t("Translate selected text and reply in their language", "Traduz texto selecionado e responde no idioma deles", "Traduce texto seleccionado y responde en su idioma") }

    // Conversation Reply Settings
    static var conversationReplyTitle: String { t("Conversation Reply", "Resposta de Conversa", "Respuesta de Conversación") }
    static var enableConversationReply: String { t("Enable Conversation Reply", "Habilitar Resposta de Conversa", "Habilitar Respuesta de Conversación") }
    static var enableConversationReplySub: String { t("Translate messages and reply in the sender's language", "Traduz mensagens e responde no idioma do remetente", "Traduce mensajes y responde en el idioma del remitente") }
    static var conversationReplyActivate: String { t("Activate with", "Ativar com", "Activar con") }
    static var crStep1: String { t("Select a message in any app (WhatsApp, Slack, email…)", "Selecione uma mensagem em qualquer app (WhatsApp, Slack, email…)", "Selecciona un mensaje en cualquier app (WhatsApp, Slack, email…)") }
    static var crStep2: String { t("Press ⌃⇧R — a panel appears with the translation", "Pressione ⌃⇧R — um painel aparece com a tradução", "Presiona ⌃⇧R — aparece un panel con la traducción") }
    static var crStep3: String { t("Read the translation in your language (\(SettingsManager.shared.outputLanguage.displayName))", "Leia a tradução no seu idioma (\(SettingsManager.shared.outputLanguage.displayName))", "Lee la traducción en tu idioma (\(SettingsManager.shared.outputLanguage.displayName))") }
    static var crStep4: String { t("Hold ⌥⌘ and speak your reply in your language", "Segure ⌥⌘ e fale sua resposta no seu idioma", "Mantén ⌥⌘ y habla tu respuesta en tu idioma") }
    static var crStep5: String { t("Your reply is auto-translated and pasted in their language", "Sua resposta é traduzida automaticamente e colada no idioma deles", "Tu respuesta se traduce automáticamente y se pega en su idioma") }

    // ModernSettings - Permissions
    static var toRecordVoice: String { t("To record your voice", "Para gravar sua voz", "Para grabar tu voz") }
    static var toAutoPasteText: String { t("To auto-paste text", "Para colar texto automaticamente", "Para pegar texto automáticamente") }
    static var keyboardMonitoring: String { t("Keyboard Monitoring", "Monitoramento de Teclado", "Monitoreo de Teclado") }
    static var forGlobalShortcuts: String { t("For global shortcuts (⌃⇧L, ⌃⇧M, ⌃⇧V)", "Para atalhos globais (⌃⇧L, ⌃⇧M, ⌃⇧V)", "Para atajos globales (⌃⇧L, ⌃⇧M, ⌃⇧V)") }
    static var configure: String { t("Configure", "Configurar", "Configurar") }
    static var required: String { t("Required", "Necessário", "Necesario") }
    
    // ModernSettings - Diagnostics
    static var working: String { t("Working", "Funcionando", "Funcionando") }
    static var noPermission: String { t("No permission", "Sem permissão", "Sin permiso") }
    static var cgEventTapTitle: String { t("CGEvent Tap (Global Shortcuts)", "CGEvent Tap (Atalhos Globais)", "CGEvent Tap (Atajos Globales)") }
    static var activeCapturing: String { t("Active and capturing keys", "Ativo e capturando teclas", "Activo y capturando teclas") }
    static var inactiveShortcuts: String { t("Inactive — shortcuts won't work in background", "Inativo — atalhos não funcionarão em segundo plano", "Inactivo — atajos no funcionarán en segundo plano") }
    
    // ModernSettings - Mode descriptions
    static var codeModeShort: String { t("Converts natural language to code", "Converte linguagem natural em código", "Convierte lenguaje natural en código") }
    static var textModeShort: String { t("Clean text transcription", "Transcrição limpa de texto", "Transcripción limpia de texto") }
    static var emailModeShort: String { t("Formats as professional email", "Formata como email profissional", "Formatea como email profesional") }
    static var uxModeShort: String { t("For design documentation", "Para documentação de design", "Para documentación de diseño") }
    static var commandModeShort: String { t("Transforms selected text", "Transforma texto selecionado", "Transforma texto seleccionado") }
    
    // ModernSettings - Search
    static var searchLanguage: String { t("Search language...", "Buscar idioma...", "Buscar idioma...") }
    
    // Tabs
    static var languageTab: String { t("Language", "Idioma", "Idioma") }
    static var shortcutsTab: String { t("Shortcuts", "Atalhos", "Atajos") }
    static var permissionsTab: String { t("Permissions", "Permissões", "Permisos") }
}

