import Foundation
import Combine
import ServiceManagement

/// Gerencia todas as configurações do app usando UserDefaults
class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    private let defaults = UserDefaults.standard
    
    // MARK: - Keys
    private enum Keys {
        static let apiKey = "gemini_api_key"
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
        static let enableStyleLearning = "enable_style_learning"
        static let clarifyText = "clarify_text"
    }
    
    // MARK: - Published Properties
    @Published var apiKey: String {
        didSet { defaults.set(apiKey, forKey: Keys.apiKey) }
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

    // MARK: - Computed
    var hasApiKey: Bool {
        !apiKey.isEmpty
    }
    
    // MARK: - Init
    private init() {
        self.apiKey = defaults.string(forKey: Keys.apiKey) ?? ""
        self.onboardingCompleted = defaults.bool(forKey: Keys.onboardingCompleted)
        
        let savedMode = defaults.string(forKey: Keys.selectedMode) ?? TranscriptionMode.code.rawValue
        self.selectedMode = TranscriptionMode(rawValue: savedMode) ?? .code
        
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

        self.shortcutRecordKey = defaults.string(forKey: Keys.shortcutRecord) ?? "⌥⌘"
        self.shortcutToggleKey = defaults.string(forKey: Keys.shortcutToggle) ?? "⌘⇧V"

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

        // Debug current state
        print("[SettingsManager] cycleToNextLanguage called")
        print("[SettingsManager] Current language: \(outputLanguage.displayName)")
        print("[SettingsManager] Favorites (\(favoriteLanguages.count)): \(favoriteLanguages.map { $0.displayName })")

        // Find current language in favorites, or start from beginning
        if let currentIndex = favoriteLanguages.firstIndex(of: outputLanguage) {
            currentFavoriteIndex = currentIndex
        }

        // Move to next index
        currentFavoriteIndex = (currentFavoriteIndex + 1) % favoriteLanguages.count
        let nextLanguage = favoriteLanguages[currentFavoriteIndex]

        print("[SettingsManager] Next index: \(currentFavoriteIndex), Next language: \(nextLanguage.displayName)")

        // Only update if different to avoid unnecessary notifications
        if outputLanguage != nextLanguage {
            outputLanguage = nextLanguage
        } else if favoriteLanguages.count > 1 {
            // If same (shouldn't happen), force move to next
            currentFavoriteIndex = (currentFavoriteIndex + 1) % favoriteLanguages.count
            outputLanguage = favoriteLanguages[currentFavoriteIndex]
            print("[SettingsManager] Forced next: \(outputLanguage.displayName)")
        }
    }

    /// Cycles to the next transcription mode
    func cycleToNextMode() {
        let allModes = TranscriptionMode.allCases
        guard let currentIndex = allModes.firstIndex(of: selectedMode) else { return }
        let nextIndex = (currentIndex + 1) % allModes.count
        let nextMode = allModes[nextIndex]
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
}
