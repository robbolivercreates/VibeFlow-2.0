import Foundation
import Combine

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
        self.shortcutRecordKey = defaults.string(forKey: Keys.shortcutRecord) ?? "⌥⌘"
        self.shortcutToggleKey = defaults.string(forKey: Keys.shortcutToggle) ?? "⌘⇧V"
    }
    
    // MARK: - Methods
    func resetOnboarding() {
        onboardingCompleted = false
    }
    
    func completeOnboarding() {
        onboardingCompleted = true
    }
}

// MARK: - Notifications
extension Notification.Name {
    static let modeChanged = Notification.Name("modeChanged")
    static let transcriptionComplete = Notification.Name("transcriptionComplete")
    static let recordingCancelled = Notification.Name("recordingCancelled")
    static let showWizardAfterActivation = Notification.Name("showWizardAfterActivation")
    static let shortcutChanged = Notification.Name("shortcutChanged")
}
