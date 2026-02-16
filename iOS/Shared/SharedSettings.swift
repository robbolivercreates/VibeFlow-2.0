import Foundation

/// Shared settings between the main app and keyboard extension
/// Uses App Groups for data sharing
final class SharedSettings {
    static let shared = SharedSettings()

    // App Group identifier - must match Xcode configuration
    private let appGroupID = "group.robboliver.vibeflow"

    private var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    private init() {}

    // MARK: - Keys

    private enum Keys {
        static let apiKey = "gemini_api_key"
        static let selectedMode = "selected_mode"
        static let selectedLanguage = "selected_language"
        static let translateToEnglish = "translate_to_english"
        static let onboardingCompleted = "onboarding_completed"
        static let totalTranscriptions = "total_transcriptions"
        static let hapticFeedback = "haptic_feedback"
        static let showWaveform = "show_waveform"
    }

    // MARK: - API Key

    var apiKey: String {
        get { defaults?.string(forKey: Keys.apiKey) ?? "" }
        set { defaults?.set(newValue, forKey: Keys.apiKey) }
    }

    var hasApiKey: Bool {
        !apiKey.isEmpty
    }

    // MARK: - Transcription Mode

    var selectedMode: TranscriptionMode {
        get {
            guard let rawValue = defaults?.string(forKey: Keys.selectedMode),
                  let mode = TranscriptionMode(rawValue: rawValue) else {
                return .text
            }
            return mode
        }
        set {
            defaults?.set(newValue.rawValue, forKey: Keys.selectedMode)
        }
    }

    // MARK: - Language

    var selectedLanguage: SpeechLanguage {
        get {
            guard let rawValue = defaults?.string(forKey: Keys.selectedLanguage),
                  let language = SpeechLanguage(rawValue: rawValue) else {
                return .english
            }
            return language
        }
        set {
            defaults?.set(newValue.rawValue, forKey: Keys.selectedLanguage)
        }
    }

    var translateToEnglish: Bool {
        get { defaults?.bool(forKey: Keys.translateToEnglish) ?? false }
        set { defaults?.set(newValue, forKey: Keys.translateToEnglish) }
    }

    // MARK: - Onboarding

    var onboardingCompleted: Bool {
        get { defaults?.bool(forKey: Keys.onboardingCompleted) ?? false }
        set { defaults?.set(newValue, forKey: Keys.onboardingCompleted) }
    }

    // MARK: - Statistics

    var totalTranscriptions: Int {
        get { defaults?.integer(forKey: Keys.totalTranscriptions) ?? 0 }
        set { defaults?.set(newValue, forKey: Keys.totalTranscriptions) }
    }

    func incrementTranscriptions() {
        totalTranscriptions += 1
    }

    // MARK: - Preferences

    var hapticFeedback: Bool {
        get { defaults?.object(forKey: Keys.hapticFeedback) == nil ? true : defaults!.bool(forKey: Keys.hapticFeedback) }
        set { defaults?.set(newValue, forKey: Keys.hapticFeedback) }
    }

    var showWaveform: Bool {
        get { defaults?.object(forKey: Keys.showWaveform) == nil ? true : defaults!.bool(forKey: Keys.showWaveform) }
        set { defaults?.set(newValue, forKey: Keys.showWaveform) }
    }

    // MARK: - Reset

    func resetAll() {
        let keys = [
            Keys.apiKey,
            Keys.selectedMode,
            Keys.selectedLanguage,
            Keys.translateToEnglish,
            Keys.onboardingCompleted,
            Keys.totalTranscriptions,
            Keys.hapticFeedback,
            Keys.showWaveform
        ]

        keys.forEach { defaults?.removeObject(forKey: $0) }
    }
}
