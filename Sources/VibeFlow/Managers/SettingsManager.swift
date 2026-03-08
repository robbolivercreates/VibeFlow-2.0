import Foundation
import Combine
import ServiceManagement

/// Gerencia todas as configurações do app usando UserDefaults
class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    private let defaults = UserDefaults.standard
    
    // MARK: - Keys
    private enum Keys {
        static let byokEnabled = "byok_enabled"
        static let byokApiKey = "byok_api_key"
        static let onboardingCompleted = "onboarding_completed"
        static let selectedMode = "selected_mode"
        static let enableSounds = "enable_sounds"
        static let enableHistory = "enable_history"
        static let enableAutoPaste = "enable_auto_paste"
        static let enableAutoClose = "enable_auto_close"
        static let shortcutRecord = "shortcut_record"
        static let shortcutToggle = "shortcut_toggle"
        static let licenseKey = "license_key"
        static let isLicensed = "is_licensed"
        static let hasSeenLicensePrompt = "has_seen_license_prompt"
        static let outputLanguage = "output_language"
        static let favoriteLanguages = "favorite_languages"
        static let cycleLanguageShortcut = "cycle_language_shortcut"
        static let cycleModeShortcut = "cycle_mode_shortcut"
        static let pasteLastShortcut = "paste_last_shortcut"
        static let conversationReplyShortcut = "conversation_reply_shortcut"
        static let enableConversationReply = "enable_conversation_reply"
        static let enableStyleLearning = "enable_style_learning"
        static let clarifyText = "clarify_text"
        static let customModePrompt = "custom_mode_prompt"
        static let customModes = "custom_modes_v2"
        static let activeCustomModeId = "active_custom_mode_id"
        static let textFormalTone = "text_formal_tone"
        static let summaryBulletFormat = "summary_bullet_format"
        static let socialTweetMode = "social_tweet_mode"
        static let wakeWord = "wake_word"
        static let wakeWordEnabled = "wake_word_enabled"
        static let commandLanguage = "command_language"
        static let offlineMode = "offline_mode"
        static let favoriteModes = "favorite_modes"
    }
    
    // MARK: - Published Properties
    @Published var byokEnabled: Bool {
        didSet { defaults.set(byokEnabled, forKey: Keys.byokEnabled) }
    }

    @Published var byokApiKey: String {
        didSet { defaults.set(byokApiKey, forKey: Keys.byokApiKey) }
    }

    @Published var onboardingCompleted: Bool {
        didSet { defaults.set(onboardingCompleted, forKey: Keys.onboardingCompleted) }
    }
    
    @Published var selectedMode: TranscriptionMode {
        didSet { 
            defaults.set(selectedMode.rawValue, forKey: Keys.selectedMode)
            NotificationCenter.default.post(name: .modeChanged, object: selectedMode)
        }
    }
    
    @Published var enableSounds: Bool {
        didSet { defaults.set(enableSounds, forKey: Keys.enableSounds) }
    }
    
    @Published var enableHistory: Bool {
        didSet { defaults.set(enableHistory, forKey: Keys.enableHistory) }
    }
    
    @Published var enableAutoPaste: Bool {
        didSet { defaults.set(enableAutoPaste, forKey: Keys.enableAutoPaste) }
    }
    
    @Published var enableAutoClose: Bool {
        didSet { defaults.set(enableAutoClose, forKey: Keys.enableAutoClose) }
    }
    
    @Published var licenseKey: String {
        didSet { defaults.set(licenseKey, forKey: Keys.licenseKey) }
    }
    
    @Published var isLicensed: Bool {
        didSet { defaults.set(isLicensed, forKey: Keys.isLicensed) }
    }
    
    @Published var hasSeenLicensePrompt: Bool {
        didSet { defaults.set(hasSeenLicensePrompt, forKey: Keys.hasSeenLicensePrompt) }
    }

    @Published var outputLanguage: SpeechLanguage {
        didSet { 
            defaults.set(outputLanguage.rawValue, forKey: Keys.outputLanguage)
            NotificationCenter.default.post(name: .languageChanged, object: outputLanguage)
        }
    }

    @Published var enableStyleLearning: Bool {
        didSet { defaults.set(enableStyleLearning, forKey: Keys.enableStyleLearning) }
    }

    @Published var clarifyText: Bool {
        didSet { defaults.set(clarifyText, forKey: Keys.clarifyText) }
    }

    /// Custom mode user-defined prompt (legacy — kept for migration)
    @Published var customModePrompt: String {
        didSet { defaults.set(customModePrompt, forKey: Keys.customModePrompt) }
    }

    /// Multiple custom mode definitions (new system)
    @Published var customModes: [CustomModeDefinition] {
        didSet {
            if let data = try? JSONEncoder().encode(customModes) {
                defaults.set(data, forKey: Keys.customModes)
            }
        }
    }

    /// ID of the currently active custom mode
    @Published var activeCustomModeId: UUID? {
        didSet {
            if let id = activeCustomModeId {
                defaults.set(id.uuidString, forKey: Keys.activeCustomModeId)
            } else {
                defaults.removeObject(forKey: Keys.activeCustomModeId)
            }
        }
    }

    /// Toggle: formal tone for Texto mode
    @Published var textFormalTone: Bool {
        didSet { defaults.set(textFormalTone, forKey: Keys.textFormalTone) }
    }

    /// Toggle: bullet format for Resumo mode
    @Published var summaryBulletFormat: Bool {
        didSet { defaults.set(summaryBulletFormat, forKey: Keys.summaryBulletFormat) }
    }

    /// Toggle: tweet mode (280 chars) for Social Media
    @Published var socialTweetMode: Bool {
        didSet { defaults.set(socialTweetMode, forKey: Keys.socialTweetMode) }
    }

    /// Favorite modes (max 4) — shown as quick-switch pills in HUD
    @Published var favoriteModes: [TranscriptionMode] {
        didSet {
            defaults.set(favoriteModes.map { $0.rawValue }, forKey: Keys.favoriteModes)
        }
    }

    /// Toggle a mode as favorite (max 4)
    func toggleFavorite(_ mode: TranscriptionMode) {
        if let index = favoriteModes.firstIndex(of: mode) {
            favoriteModes.remove(at: index)
        } else if favoriteModes.count < 4 {
            favoriteModes.append(mode)
        }
    }

    /// Check if a mode is favorited
    func isFavorite(_ mode: TranscriptionMode) -> Bool {
        favoriteModes.contains(mode)
    }

    /// Returns the prompt of the currently active custom mode
    var activeCustomModePrompt: String {
        if let id = activeCustomModeId,
           let mode = customModes.first(where: { $0.id == id }) {
            return mode.prompt
        }
        // Fallback to first custom mode or legacy prompt
        return customModes.first?.prompt ?? customModePrompt
    }

    /// Wake word used to trigger voice commands (default: "Vox")
    @Published var wakeWord: String {
        didSet { defaults.set(wakeWord, forKey: Keys.wakeWord) }
    }

    /// Whether wake word mode switching is enabled
    @Published var wakeWordEnabled: Bool {
        didSet { defaults.set(wakeWordEnabled, forKey: Keys.wakeWordEnabled) }
    }

    /// Language the user speaks for wake word commands (default: Portuguese).
    /// Independent from outputLanguage — so a PT speaker can always say "Vox, inglês"
    /// even when output language is Turkish.
    @Published var commandLanguage: SpeechLanguage {
        didSet { defaults.set(commandLanguage.rawValue, forKey: Keys.commandLanguage) }
    }

    @Published var launchAtLogin: Bool {
        didSet {
            if launchAtLogin {
                try? SMAppService.mainApp.register()
            } else {
                try? SMAppService.mainApp.unregister()
            }
        }
    }
    
    /// Lista de idiomas favoritos para ciclagem rápida
    @Published var favoriteLanguages: [SpeechLanguage] {
        didSet {
            let rawValues = favoriteLanguages.map { $0.rawValue }
            defaults.set(rawValues, forKey: Keys.favoriteLanguages)
            // Reset cycle index when favorites change
            resetFavoriteIndex()
        }
    }
    
    /// Atalho para ciclar entre idiomas favoritos
    @Published var cycleLanguageShortcut: String {
        didSet {
            defaults.set(cycleLanguageShortcut, forKey: Keys.cycleLanguageShortcut)
            NotificationCenter.default.post(name: .shortcutChanged, object: nil)
        }
    }

    /// Atalho para ciclar entre modos de transcrição
    @Published var cycleModeShortcut: String {
        didSet {
            defaults.set(cycleModeShortcut, forKey: Keys.cycleModeShortcut)
            NotificationCenter.default.post(name: .shortcutChanged, object: nil)
        }
    }

    /// Atalho para colar última transcrição do histórico
    @Published var pasteLastShortcut: String {
        didSet {
            defaults.set(pasteLastShortcut, forKey: Keys.pasteLastShortcut)
            NotificationCenter.default.post(name: .shortcutChanged, object: nil)
        }
    }

    /// Atalho para Conversation Reply (selecionar texto + traduzir + responder)
    @Published var conversationReplyShortcut: String {
        didSet {
            defaults.set(conversationReplyShortcut, forKey: Keys.conversationReplyShortcut)
            NotificationCenter.default.post(name: .shortcutChanged, object: nil)
        }
    }

    /// Habilita/desabilita o recurso Conversation Reply
    @Published var enableConversationReply: Bool {
        didSet { defaults.set(enableConversationReply, forKey: Keys.enableConversationReply) }
    }

    @Published var shortcutRecordKey: String {
        didSet { 
            defaults.set(shortcutRecordKey, forKey: Keys.shortcutRecord)
            NotificationCenter.default.post(name: .shortcutChanged, object: nil)
        }
    }
    
    @Published var shortcutToggleKey: String {
        didSet {
            defaults.set(shortcutToggleKey, forKey: Keys.shortcutToggle)
            NotificationCenter.default.post(name: .shortcutChanged, object: nil)
        }
    }

    /// Current index for cycling through favorites
    private var currentFavoriteIndex: Int = 0

    /// Offline mode: force Whisper local even for Pro users
    @Published var offlineMode: Bool {
        didSet { defaults.set(offlineMode, forKey: Keys.offlineMode) }
    }

    // MARK: - Computed
    var hasByokKey: Bool {
        byokEnabled && !byokApiKey.isEmpty
    }

    /// Whether the Vox intelligent agent is active (Gemini cloud)
    var isVoxActive: Bool {
        !offlineMode && (SubscriptionManager.shared.isPro || TrialManager.shared.isTrialActive())
    }

    // MARK: - Init
    private init() {
        // BYOK easter egg (hidden by default)
        self.byokEnabled = defaults.bool(forKey: Keys.byokEnabled)
        self.byokApiKey = defaults.string(forKey: Keys.byokApiKey) ?? ""

        // Migration: move old gemini_api_key to byokApiKey if present
        if let oldKey = defaults.string(forKey: "gemini_api_key"), !oldKey.isEmpty,
           oldKey != "YOUR_API_KEY_HERE", oldKey != "SUA_API_KEY_AQUI" {
            self.byokApiKey = oldKey
            self.byokEnabled = true
            defaults.set(oldKey, forKey: Keys.byokApiKey)
            defaults.set(true, forKey: Keys.byokEnabled)
            defaults.removeObject(forKey: "gemini_api_key")
            print("[SettingsManager] Migrated old API key to BYOK")
        }

        self.onboardingCompleted = defaults.bool(forKey: Keys.onboardingCompleted)
        
        let savedMode = defaults.string(forKey: Keys.selectedMode) ?? TranscriptionMode.text.rawValue
        self.selectedMode = TranscriptionMode(rawValue: savedMode) ?? .text
        
        self.enableSounds = defaults.object(forKey: Keys.enableSounds) as? Bool ?? true
        self.enableHistory = defaults.object(forKey: Keys.enableHistory) as? Bool ?? true
        self.enableAutoPaste = defaults.object(forKey: Keys.enableAutoPaste) as? Bool ?? true
        self.enableAutoClose = defaults.object(forKey: Keys.enableAutoClose) as? Bool ?? true
        self.licenseKey = defaults.string(forKey: Keys.licenseKey) ?? ""
        self.isLicensed = defaults.bool(forKey: Keys.isLicensed)
        self.hasSeenLicensePrompt = defaults.bool(forKey: Keys.hasSeenLicensePrompt)

        let savedLanguage = defaults.string(forKey: Keys.outputLanguage) ?? SpeechLanguage.english.rawValue
        self.outputLanguage = SpeechLanguage(rawValue: savedLanguage) ?? .english

        self.enableStyleLearning = defaults.object(forKey: Keys.enableStyleLearning) as? Bool ?? true

        // Launch at login: enable by default on first run
        let launchStatus = SMAppService.mainApp.status
        if launchStatus == .notRegistered {
            try? SMAppService.mainApp.register()
            self.launchAtLogin = true
        } else {
            self.launchAtLogin = launchStatus == .enabled
        }

        self.customModePrompt = defaults.string(forKey: Keys.customModePrompt) ?? ""

        // Load custom modes
        if let data = defaults.data(forKey: Keys.customModes),
           let decoded = try? JSONDecoder().decode([CustomModeDefinition].self, from: data) {
            self.customModes = decoded
        } else {
            self.customModes = []
        }

        // Load active custom mode ID
        if let idString = defaults.string(forKey: Keys.activeCustomModeId),
           let uuid = UUID(uuidString: idString) {
            self.activeCustomModeId = uuid
        } else {
            self.activeCustomModeId = nil
        }

        // Mode toggles
        self.textFormalTone = defaults.bool(forKey: Keys.textFormalTone)
        self.summaryBulletFormat = defaults.bool(forKey: Keys.summaryBulletFormat)
        self.socialTweetMode = defaults.bool(forKey: Keys.socialTweetMode)

        // Load favorite modes (default: [.text])
        if let savedFavModes = defaults.stringArray(forKey: Keys.favoriteModes) {
            self.favoriteModes = savedFavModes.compactMap { TranscriptionMode(rawValue: $0) }
        } else {
            self.favoriteModes = [.text]
        }

        // Migrate clarifyText from old ViewModel key if needed, default: true
        if defaults.object(forKey: Keys.clarifyText) != nil {
            self.clarifyText = defaults.bool(forKey: Keys.clarifyText)
        } else if defaults.object(forKey: "clarifyText") != nil {
            let migrated = defaults.bool(forKey: "clarifyText")
            self.clarifyText = migrated
            defaults.set(migrated, forKey: Keys.clarifyText)
        } else {
            self.clarifyText = true
        }
        
        // Load favorite languages (default: English, Portuguese, Spanish)
        if let savedFavorites = defaults.stringArray(forKey: Keys.favoriteLanguages) {
            self.favoriteLanguages = savedFavorites.compactMap { SpeechLanguage(rawValue: $0) }
        } else {
            self.favoriteLanguages = [.english, .portuguese, .spanish]
        }
        
        self.cycleLanguageShortcut = defaults.string(forKey: Keys.cycleLanguageShortcut) ?? "⌃⇧L"
        self.cycleModeShortcut = defaults.string(forKey: Keys.cycleModeShortcut) ?? "⌃⇧M"
        self.pasteLastShortcut = defaults.string(forKey: Keys.pasteLastShortcut) ?? "⌃⇧V"
        self.conversationReplyShortcut = defaults.string(forKey: Keys.conversationReplyShortcut) ?? "⌃⇧R"
        self.enableConversationReply = defaults.object(forKey: Keys.enableConversationReply) as? Bool ?? true

        self.shortcutRecordKey = defaults.string(forKey: Keys.shortcutRecord) ?? "⌥⌘"
        self.shortcutToggleKey = defaults.string(forKey: Keys.shortcutToggle) ?? "⌘⇧V"

        self.wakeWord = defaults.string(forKey: Keys.wakeWord) ?? "Vox"
        self.wakeWordEnabled = defaults.object(forKey: Keys.wakeWordEnabled) as? Bool ?? true
        let cmdLangRaw = defaults.string(forKey: Keys.commandLanguage) ?? SpeechLanguage.portuguese.rawValue
        self.commandLanguage = SpeechLanguage(rawValue: cmdLangRaw) ?? .portuguese

        self.offlineMode = defaults.bool(forKey: Keys.offlineMode)

        // ── Migration: removed modes → new equivalents ──
        let savedModeRaw = defaults.string(forKey: Keys.selectedMode) ?? ""
        if savedModeRaw == "Formal" {
            self.selectedMode = .text
            self.textFormalTone = true
            defaults.set(TranscriptionMode.text.rawValue, forKey: Keys.selectedMode)
            defaults.set(true, forKey: Keys.textFormalTone)
            print("[SettingsManager] Migrated mode Formal → Texto + formalTone")
        } else if savedModeRaw == "X" {
            self.selectedMode = .social
            self.socialTweetMode = true
            defaults.set(TranscriptionMode.social.rawValue, forKey: Keys.selectedMode)
            defaults.set(true, forKey: Keys.socialTweetMode)
            print("[SettingsManager] Migrated mode X → Social Media + tweetMode")
        } else if savedModeRaw == "Tópicos" {
            self.selectedMode = .summary
            self.summaryBulletFormat = true
            defaults.set(TranscriptionMode.summary.rawValue, forKey: Keys.selectedMode)
            defaults.set(true, forKey: Keys.summaryBulletFormat)
            print("[SettingsManager] Migrated mode Tópicos → Resumo + bulletFormat")
        } else if savedModeRaw == "Social" {
            // rawValue changed from "Social" → "Social Media"
            self.selectedMode = .social
            defaults.set(TranscriptionMode.social.rawValue, forKey: Keys.selectedMode)
            print("[SettingsManager] Migrated rawValue Social → Social Media")
        }

        // ── Migration: old single customModePrompt → first custom mode ──
        if customModes.isEmpty && !customModePrompt.isEmpty {
            let migrated = CustomModeDefinition(
                name: "Meu Modo",
                prompt: customModePrompt,
                icon: "slider.horizontal.3",
                colorHex: "#999999"
            )
            self.customModes = [migrated]
            self.activeCustomModeId = migrated.id
            if let data = try? JSONEncoder().encode(self.customModes) {
                defaults.set(data, forKey: Keys.customModes)
            }
            defaults.set(migrated.id.uuidString, forKey: Keys.activeCustomModeId)
            print("[SettingsManager] Migrated legacy customModePrompt → first custom mode")
        }

        // Initialize favorite index based on current language
        if let index = self.favoriteLanguages.firstIndex(of: self.outputLanguage) {
            self.currentFavoriteIndex = index
        }
    }
    
    // MARK: - Methods
    func resetOnboarding() {
        onboardingCompleted = false
    }
    
    func completeOnboarding() {
        onboardingCompleted = true
    }
    
    /// Cicla para o próximo idioma favorito
    func cycleToNextLanguage() {
        guard !favoriteLanguages.isEmpty else {
            print("[SettingsManager] cycleToNextLanguage: No favorite languages configured")
            return
        }

        let isFreeTier = !SubscriptionManager.shared.isPro && !TrialManager.shared.isTrialActive()
        let freeLanguages = SubscriptionManager.freeLanguages

        // Filter available languages for the current tier
        let availableLanguages = isFreeTier
            ? favoriteLanguages.filter { freeLanguages.contains($0) }
            : favoriteLanguages

        guard !availableLanguages.isEmpty else { return }

        print("[SettingsManager] cycleToNextLanguage called")
        print("[SettingsManager] Current language: \(outputLanguage.displayName)")
        print("[SettingsManager] Available (\(availableLanguages.count)): \(availableLanguages.map { $0.displayName })")

        // Find current language in available set
        if let currentIndex = availableLanguages.firstIndex(of: outputLanguage) {
            currentFavoriteIndex = currentIndex
        } else {
            currentFavoriteIndex = -1
        }

        // Move to next index within available set
        let nextIndex = (currentFavoriteIndex + 1) % availableLanguages.count
        let nextLanguage = availableLanguages[nextIndex]

        // Update global index to match favorites array
        if let globalIndex = favoriteLanguages.firstIndex(of: nextLanguage) {
            currentFavoriteIndex = globalIndex
        }

        print("[SettingsManager] Next language: \(nextLanguage.displayName)")

        if outputLanguage != nextLanguage {
            outputLanguage = nextLanguage
        }
    }

    /// Cycles to the next transcription mode (skips Pro modes for Free users)
    func cycleToNextMode() {
        let allModes = TranscriptionMode.allCases
        let isFreeTier = !SubscriptionManager.shared.isPro && !TrialManager.shared.isTrialActive()

        // Filter to available modes for current tier
        let availableModes = isFreeTier
            ? allModes.filter { SubscriptionManager.freeModes.contains($0) }
            : allModes

        guard !availableModes.isEmpty else { return }
        guard let currentIndex = availableModes.firstIndex(of: selectedMode) else {
            // Current mode is Pro-only for a Free user — jump to first free mode
            selectedMode = availableModes[0]
            return
        }
        let nextIndex = (currentIndex + 1) % availableModes.count
        let nextMode = availableModes[nextIndex]
        print("[SettingsManager] Mode changed: \(selectedMode.localizedName) → \(nextMode.localizedName)")
        selectedMode = nextMode
    }

    /// Reset favorite index when favorites change
    func resetFavoriteIndex() {
        if let index = favoriteLanguages.firstIndex(of: outputLanguage) {
            currentFavoriteIndex = index
        } else {
            currentFavoriteIndex = 0
        }
    }
}

// MARK: - Notifications
extension Notification.Name {
    static let modeChanged = Notification.Name("modeChanged")
    static let transcriptionComplete = Notification.Name("transcriptionComplete")
    static let recordingCancelled = Notification.Name("recordingCancelled")
    static let showWizardAfterActivation = Notification.Name("showWizardAfterActivation")
    static let shortcutChanged = Notification.Name("shortcutChanged")
    static let languageChanged = Notification.Name("languageChanged")
    static let openSetupWizard = Notification.Name("openSetupWizard")
    static let authStateChanged = Notification.Name("authStateChanged")
    static let showUpgradePrompt = Notification.Name("showUpgradePrompt")
    static let wakeWordCommand = Notification.Name("wakeWordCommand")
    static let offlineModeChanged = Notification.Name("offlineModeChanged")
    static let showWelcomeTrial = Notification.Name("showWelcomeTrial")
    static let showTrialExpired = Notification.Name("showTrialExpired")
    static let showMonthlyLimit = Notification.Name("showMonthlyLimit")
    static let showUpgradeReminder = Notification.Name("showUpgradeReminder")
    static let subscriptionChanged = Notification.Name("subscriptionChanged")
    static let wakeWordProLocked = Notification.Name("wakeWordProLocked")
    // Dev HUD preview triggers
    static let devPreviewLanguageHUD = Notification.Name("devPreviewLanguageHUD")
    static let devPreviewModeHUD = Notification.Name("devPreviewModeHUD")
    static let devPreviewWakeWordHUD = Notification.Name("devPreviewWakeWordHUD")
    static let devPreviewPasteHUD = Notification.Name("devPreviewPasteHUD")
    static let devPreviewNoHistoryHUD = Notification.Name("devPreviewNoHistoryHUD")
    static let devPreviewRecordingHUD = Notification.Name("devPreviewRecordingHUD")
}
