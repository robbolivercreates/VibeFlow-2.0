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
    
    private static func t(_ en: String, _ pt: String, _ es: String) -> String {
        switch current {
        case .english: return en
        case .portuguese: return pt
        case .spanish: return es
        }
    }
    
    // MARK: - General
    static var ok: String { t("OK", "OK", "OK") }
    static var cancel: String { t("Cancel", "Cancelar", "Cancelar") }
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
    static var openVibeFlow: String { t("Open VibeFlow", "Abrir VibeFlow", "Abrir VibeFlow") }
    static var configureSetup: String { t("Configure VibeFlow", "Configurar VibeFlow", "Configurar VibeFlow") }
    static var nextMode: String { t("Next Mode (⌃⇧M)", "Próximo Modo (⌃⇧M)", "Siguiente Modo (⌃⇧M)") }
    static var cycleLanguage: String { t("Cycle Language (⌃⇧L)", "Alternar Idioma (⌃⇧L)", "Cambiar Idioma (⌃⇧L)") }
    static var pasteLastTranscription: String { t("Paste Last (⌃⇧V)", "Colar Último (⌃⇧V)", "Pegar Último (⌃⇧V)") }
    
    // MARK: - Setup Wizard
    static var wizardTitle: String { t("Set up VibeFlow", "Configurar VibeFlow", "Configurar VibeFlow") }
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
    
    // Wizard - Permission Help Steps
    static var helpOpenPrefs: String { t("Click \"Open Preferences\" — it will open Preferences and Finder", "Clique em \"Abrir Preferencias\" — ira abrir as Preferencias e o Finder", "Haz clic en \"Abrir Preferencias\" — abrirá Preferencias y Finder") }
    static var helpDragVibeFlow: String { t("Drag the VibeFlow icon from Finder to the permissions list", "Arraste o icone do VibeFlow do Finder para a lista de permissoes", "Arrastra el ícono de VibeFlow del Finder a la lista de permisos") }
    static var helpEnableToggle: String { t("Enable the toggle next to \"VibeFlow\"", "Ative o toggle (chave) ao lado de \"VibeFlow\"", "Activa el interruptor junto a \"VibeFlow\"") }
    
    // Wizard - Test
    static var testVibeFlow: String { t("Test VibeFlow", "Teste o VibeFlow", "Prueba VibeFlow") }
    static var testInstructions: String { t("Let's test if everything is working. Follow the instructions below:", "Vamos testar se tudo esta funcionando. Siga as instrucoes abaixo:", "Vamos a probar si todo funciona. Sigue las instrucciones:") }
    static var shortcutWorking: String { t("Shortcut working!", "Atalho funcionando!", "¡Atajo funcionando!") }
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
    static var manageLanguagesHint: String { t("To manage languages: Menu Bar > VibeFlow > Open VibeFlow > Languages", "Para gerenciar idiomas: Menu Bar > VibeFlow > Abrir VibeFlow > Idiomas", "Para gestionar idiomas: Barra de Menú > VibeFlow > Abrir VibeFlow > Idiomas") }
    
    // Wizard - Ready
    static var startUsing: String { t("Start Using", "Comecar a Usar", "Empezar a Usar") }
    
    // Wizard - Language Selection (new first step)
    static var chooseLanguage: String { t("Choose your language", "Escolha seu idioma", "Elige tu idioma") }
    static var interfaceLanguageDesc: String { t("Select the language for the VibeFlow interface", "Selecione o idioma da interface do VibeFlow", "Selecciona el idioma de la interfaz de VibeFlow") }
    
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
    static var customizeVibeFlow: String { t("Customize your VibeFlow", "Personalize seu VibeFlow", "Personaliza tu VibeFlow") }
    static var geminiModel: String { t("Gemini 2.0 Flash", "Gemini 2.0 Flash", "Gemini 2.0 Flash") }
    static var clickShortcutToEdit: String { t("Click a shortcut to edit. Press the desired keys.", "Clique em um atalho para editar. Pressione as teclas desejadas.", "Haz clic en un atajo para editar. Presiona las teclas deseadas.") }
    static var configureVibeFlowPrefs: String { t("Configure VibeFlow according to your preferences.", "Configure o VibeFlow de acordo com suas preferencias.", "Configura VibeFlow según tus preferencias.") }
    static var clearAllDataWarning: String { t("This will clear all transcription history and style samples. This action cannot be undone.", "Isso ira limpar todo o historico de transcricoes e amostras de estilo. Esta acao nao pode ser desfeita.", "Esto borrará todo el historial de transcripciones y muestras de estilo. Esta acción no se puede deshacer.") }
    
    // Settings - Mode
    static var modeDescription: String { t("The mode determines how Gemini processes your audio.", "O modo determina como o Gemini processa seu áudio.", "El modo determina cómo Gemini procesa tu audio.") }
    static var outputLanguage: String { t("The transcribed text will be generated in this language, regardless of the language spoken.", "O texto transcrito sera gerado neste idioma, independente do idioma falado.", "El texto transcrito se generará en este idioma, independientemente del idioma hablado.") }
    static var shortcutToChangeLanguage: String { t("Shortcut to change language", "Atalho para mudar idioma", "Atajo para cambiar idioma") }
    static var pressCtrlShiftL: String { t("Press ⌃⇧L (Control+Shift+L) to switch between favorite languages", "Pressione ⌃⇧L (Control+Shift+L) para alternar entre idiomas favoritos", "Presiona ⌃⇧L (Control+Shift+L) para alternar entre idiomas favoritos") }
    static var selectFrequentLanguages: String { t("Select the languages you use frequently to switch quickly with ⌃⇧L", "Selecione os idiomas que você usa com frequência para alternar rapidamente com ⌃⇧L", "Selecciona los idiomas que usas frecuentemente para cambiar rápidamente con ⌃⇧L") }
    
    // Settings - Style
    static var writingStyleDescription: String { t("VibeFlow learns your style from previous transcriptions to personalize results.", "VibeFlow aprende seu estilo com base nas transcricoes anteriores para personalizar os resultados.", "VibeFlow aprende tu estilo de transcripciones anteriores para personalizar los resultados.") }
    static func samplesSaved(_ count: Int) -> String { t("\(count) samples saved", "\(count) amostras salvas", "\(count) muestras guardadas") }
    
    // Settings - API
    static var apiKeyStoredInKeychain: String { t("Your API key is stored locally in the macOS Keychain.", "Sua API key é armazenada localmente no Keychain do macOS.", "Tu API key se almacena localmente en el Keychain de macOS.") }
    static var getAPIKeyGoogleAI: String { t("Get API key at Google AI Studio", "Obter API key no Google AI Studio", "Obtener API key en Google AI Studio") }
    static var model: String { t("Model", "Modelo", "Modelo") }
    
    // Settings - Wizard
    static var setupWizard: String { t("Setup Wizard", "Wizard de Configuração", "Asistente de Configuración") }
    static var rerunWizard: String { t("Run the wizard again to reconfigure VibeFlow", "Execute o wizard novamente para reconfigurar o VibeFlow", "Ejecuta el asistente nuevamente para reconfigurar VibeFlow") }
    
    // Settings - Permissions
    static var accessibility: String { t("Accessibility", "Acessibilidade", "Accesibilidad") }
    static var inputMonitoring: String { t("Input Monitoring", "Input Monitoring", "Input Monitoring") }
    static var permissionsHint: String { t("VibeFlow needs Accessibility to auto-paste (⌘V) and Input Monitoring to detect global keyboard shortcuts.", "O VibeFlow precisa de Acessibilidade para colar automaticamente (⌘V) e Input Monitoring para detectar atalhos globais de teclado.", "VibeFlow necesita Accesibilidad para pegar automáticamente (⌘V) e Input Monitoring para detectar atajos globales de teclado.") }
    
    // Settings - Shortcuts
    static var record: String { t("Record", "Gravar", "Grabar") }
    static var recordShortcut: String { t("⌥⌘ (hold)", "⌥⌘ (segure)", "⌥⌘ (mantener)") }
    static var showHideShort: String { t("Show/Hide", "Mostrar/Esconder", "Mostrar/Ocultar") }
    static var settingsShort: String { t("Settings", "Configurações", "Configuración") }
    static var helpAndDocs: String { t("Help and documentation", "Ajuda e documentação", "Ayuda y documentación") }
    static var checkAll: String { t("Check All", "Verificar Tudo", "Verificar Todo") }
    
    // Settings - Tips
    static var shortcutsTipTitle: String { t("Tip: If shortcuts stop working", "Dica: Se os atalhos pararem de funcionar", "Consejo: Si los atajos dejan de funcionar") }
    static var shortcutsTipBody: String { t("When VibeFlow is updated, macOS may revoke permissions. In that case, go to System Settings → Privacy and remove/re-add VibeFlow in the Accessibility and Input Monitoring sections.", "Quando o VibeFlow é atualizado, o macOS pode revogar as permissões. Nesse caso, vá em Ajustes do Sistema → Privacidade e remova/re-adicione o VibeFlow nas seções de Acessibilidade e Monitoramento de Teclado.", "Cuando VibeFlow se actualiza, macOS puede revocar los permisos. En ese caso, ve a Ajustes del Sistema → Privacidad y quita/reagrega VibeFlow en las secciones de Accesibilidad y Monitoreo de Teclado.") }
    
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
    static var startUsingToSeeTime: String { t("Start using VibeFlow to see how much time you save!", "Comece a usar o VibeFlow para ver quanto tempo você economiza!", "¡Empieza a usar VibeFlow para ver cuánto tiempo ahorras!") }
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
    static var writingStyleFullDesc: String { t("VibeFlow learns your writing style to personalize transcriptions, imitating your vocabulary, tone and formatting.", "O VibeFlow aprende seu estilo de escrita para personalizar as transcricoes, imitando seu vocabulario, tom e formatacao.", "VibeFlow aprende tu estilo de escritura para personalizar las transcripciones, imitando tu vocabulario, tono y formato.") }
    static var styleLearning: String { t("Style Learning", "Aprendizado de Estilo", "Aprendizaje de Estilo") }
    static var styleLearningDesc: String { t("When enabled, VibeFlow analyzes your transcriptions to learn your unique style.", "Quando ativado, o VibeFlow analisa suas transcricoes para aprender seu estilo unico.", "Cuando está activado, VibeFlow analiza tus transcripciones para aprender tu estilo único.") }
    static var howItWorks: String { t("How It Works", "Como Funciona", "Cómo Funciona") }
    static var learnedSamples: String { t("Learned Samples", "Amostras Aprendidas", "Muestras Aprendidas") }
    static var clearAll: String { t("Clear All", "Limpar Tudo", "Limpiar Todo") }
    static var noSamplesYet: String { t("No samples yet", "Nenhuma amostra ainda", "Sin muestras aún") }
    static var doTranscriptionsToLearn: String { t("Do some transcriptions for VibeFlow to learn your style", "Faca algumas transcricoes para o VibeFlow aprender seu estilo", "Haz algunas transcripciones para que VibeFlow aprenda tu estilo") }
    static func sampleCount(_ n: Int) -> String { t("\(n) sample\(n == 1 ? "" : "s")", "\(n) amostra\(n == 1 ? "" : "s")", "\(n) muestra\(n == 1 ? "" : "s")") }
    static var clearSamplesForThisMode: String { t("Clear samples for this mode", "Limpar amostras deste modo", "Limpiar muestras de este modo") }
    static func clearConfirmMode(_ mode: String) -> String { t("Do you want to clear all samples from mode \(mode)?", "Deseja limpar todas as amostras do modo \(mode)?", "¿Deseas limpiar todas las muestras del modo \(mode)?") }
    static var clearConfirmAll: String { t("Do you want to clear all style samples?", "Deseja limpar todas as amostras de estilo?", "¿Deseas limpiar todas las muestras de estilo?") }
    
    // MARK: - Languages View
    static var languages: String { t("Languages", "Idiomas", "Idiomas") }
    static var languagesDesc: String { t("Configure the output language for your transcriptions. You can speak in any language - VibeFlow translates automatically.", "Configure o idioma de saida das suas transcricoes. Voce pode falar em qualquer idioma - o VibeFlow traduz automaticamente.", "Configura el idioma de salida de tus transcripciones. Puedes hablar en cualquier idioma - VibeFlow traduce automáticamente.") }
    static var shortcutToSwitch: String { t("Shortcut to switch", "Atalho para alternar", "Atajo para alternar") }
    static var useCtrlShiftL: String { t("Use ⌃⇧L to quickly switch between your favorite languages.", "Use ⌃⇧L para alternar rapidamente entre seus idiomas favoritos.", "Usa ⌃⇧L para alternar rápidamente entre tus idiomas favoritos.") }
    static var allLanguages: String { t("All Languages", "Todos os Idiomas", "Todos los Idiomas") }
    
    // MARK: - Snippets View
    static var snippets: String { t("Snippets", "Snippets", "Snippets") }
    static var snippetsDesc: String { t("Use :abbreviation: in transcribed text to expand automatically.", "Use :abbreviation: no texto transcrito para expandir automaticamente.", "Usa :abreviación: en el texto transcrito para expandir automáticamente.") }
    static var snippetUsageHint: String { t("Use :your-abbreviation: in text to expand", "Use :sua-abreviacao: no texto para expandir", "Usa :tu-abreviación: en el texto para expandir") }
    
    // MARK: - Floating Preview
    static func characters(_ n: Int) -> String { t("\(n) characters", "\(n) caracteres", "\(n) caracteres") }
    
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
}
