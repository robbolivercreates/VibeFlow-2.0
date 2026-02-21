import SwiftUI
import Combine

class VoxAiGoViewModel: ObservableObject {
    @Published var isRecording = false
    @Published var isProcessing = false
    @Published var statusText = L10n.ready
    @Published var error: String?
    @Published var selectedMode: TranscriptionMode = .code
    var clarifyText: Bool {
        get { settings.clarifyText }
        set { settings.clarifyText = newValue }
    }
    @Published var needsAuth = false
    @Published var showUpgradePrompt = false
    @Published var audioLevel: CGFloat = 0.0

    private let settings = SettingsManager.shared
    private let snippets = SnippetsManager.shared
    private let auth = AuthManager.shared
    private let subscription = SubscriptionManager.shared
    let audioRecorder = AudioRecorder()
    private var cancellables = Set<AnyCancellable>()

    // Conversation Reply mode: set by AppDelegate when ⌥⌘ is pressed during conversation HUD
    var isConversationReplyMode = false
    var conversationReplyTargetLanguage: String = ""

    init() {
        loadSettings()
        setupObservers()
        checkAuth()
    }

    private func loadSettings() {
        selectedMode = settings.selectedMode
    }

    private func setupObservers() {
        audioRecorder.$isRecording
            .assign(to: &$isRecording)

        audioRecorder.$recordingError
            .compactMap { $0 }
            .assign(to: &$error)

        audioRecorder.$audioLevel
            .assign(to: &$audioLevel)

        // Observe auth changes
        auth.$isAuthenticated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAuth in
                self?.needsAuth = !isAuth && !(self?.settings.hasByokKey ?? false)
            }
            .store(in: &cancellables)
    }

    /// Determines which transcription service to use
    private func getTranscriptionService() -> TranscriptionServiceType {
        // Priority 1: Supabase (authenticated user)
        if auth.isAuthenticated {
            return .supabase
        }

        // Priority 2: BYOK (easter egg)
        if settings.hasByokKey {
            return .byok(apiKey: settings.byokApiKey)
        }

        return .none
    }

    func checkAuth() {
        let service = getTranscriptionService()
        switch service {
        case .none:
            needsAuth = true
            error = L10n.loginRequired
        case .supabase, .byok:
            needsAuth = false
            error = nil
        }
    }

    func reloadSettings() {
        loadSettings()
        checkAuth()
    }

    func updateMode(_ mode: TranscriptionMode) {
        selectedMode = mode
        settings.selectedMode = mode
    }

    func toggleRecording() {
        let service = getTranscriptionService()

        // Check auth/key
        if case .none = service {
            error = L10n.loginRequired
            needsAuth = true
            return
        }

        // Feature gating: mode restriction (only for Supabase users, not BYOK)
        print("[ViewModel] toggleRecording: mode=\(selectedMode.rawValue) service=\(service) isPro=\(subscription.isPro) devMode=\(subscription.devModeActive)")
        if case .supabase = service, !subscription.canUseMode(selectedMode) {
            error = L10n.proModeRequired
            print("[ViewModel] BLOCKED: proModeRequired for \(selectedMode.rawValue)")
            NotificationCenter.default.post(name: .recordingCancelled, object: nil)
            return
        }

        // Feature gating: language restriction (only for Supabase users, not BYOK)
        if case .supabase = service, !subscription.canUseLanguage(settings.outputLanguage) {
            error = L10n.proLanguageRequired
            print("[ViewModel] BLOCKED: proLanguageRequired for \(settings.outputLanguage.rawValue)")
            NotificationCenter.default.post(name: .recordingCancelled, object: nil)
            return
        }

        // Feature gating: free limit (only for Supabase users, not BYOK)
        if case .supabase = service, subscription.hasReachedFreeLimit {
            error = L10n.freeLimitReached
            showUpgradePrompt = true
            NotificationCenter.default.post(name: .recordingCancelled, object: nil)
            // Show upgrade window after HUD closes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NotificationCenter.default.post(name: .showUpgradePrompt, object: nil)
            }
            return
        }

        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        error = nil
        statusText = L10n.listening

        audioRecorder.startRecording()
    }

    private func stopRecording() {
        // Verificar se detectou fala antes de parar
        let hasSpeech = audioRecorder.isRecordingValid()

        // Save recording duration BEFORE stopping (stopRecording clears the start time)
        let recordingDuration = audioRecorder.recordingDuration

        guard let _ = audioRecorder.stopRecording(),
              let audioData = audioRecorder.getRecordingData() else {
            error = L10n.recordingError
            statusText = L10n.error
            // Post after a delay so the error is visible before the HUD closes
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                NotificationCenter.default.post(name: .recordingCancelled, object: nil)
            }
            return
        }

        // Se não detectou fala suficiente, não processar e fechar janela
        if !hasSpeech {
            statusText = L10n.ready
            error = nil
            print("[VoxAiGo] Gravação ignorada - nenhuma fala detectada")

            // Notificar para fechar a janela
            NotificationCenter.default.post(
                name: .recordingCancelled,
                object: nil
            )
            return
        }

        // MARK: Conversation Reply path (translate speech → detected language)
        if isConversationReplyMode {
            isConversationReplyMode = false
            let targetLanguage = conversationReplyTargetLanguage
            conversationReplyTargetLanguage = ""
            statusText = L10n.processing

            let service = getTranscriptionService()

            Task {
                await MainActor.run { self.isProcessing = true }
                ConversationReplyManager.shared.beginProcessingReply()

                do {
                    let translatedReply: String

                    switch service {
                    case .byok(let apiKey):
                        let gemini = GeminiService(
                            apiKey: apiKey,
                            mode: .text,
                            outputLanguage: .english,
                            clarifyText: false
                        )
                        translatedReply = try await gemini.translateSpeechReply(
                            audioData: audioData,
                            toLanguage: targetLanguage
                        )

                    case .supabase:
                        // Routes through edge function with translation system prompt
                        let supabase = SupabaseService(mode: .text, outputLanguage: .english, clarifyText: false)
                        translatedReply = try await supabase.translateSpeechReply(
                            audioData: audioData,
                            toLanguage: targetLanguage
                        )

                    case .none:
                        throw NSError(
                            domain: "ConversationReply",
                            code: 2,
                            userInfo: [NSLocalizedDescriptionKey: L10n.loginRequired]
                        )
                    }

                    await MainActor.run {
                        self.isProcessing = false
                        ClipboardHelper.copyAndPaste(translatedReply)
                        self.statusText = L10n.pasted
                        ConversationReplyManager.shared.dismiss()
                        NotificationCenter.default.post(name: .conversationReplyTimedOut, object: nil)

                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                            self?.statusText = L10n.ready
                        }
                    }

                } catch {
                    await MainActor.run {
                        self.isProcessing = false
                        self.error = error.localizedDescription
                        self.statusText = L10n.error
                        ConversationReplyManager.shared.dismiss()
                        NotificationCenter.default.post(name: .conversationReplyTimedOut, object: nil)
                    }
                }
            }
            return
        }

        statusText = L10n.processing

        let service = getTranscriptionService()
        let currentMode = self.selectedMode
        let currentLanguage = self.settings.outputLanguage
        let currentClarify = self.clarifyText
        Task {
            await MainActor.run {
                self.isProcessing = true
            }

            do {
                let transcribedText: String

                switch service {
                case .supabase:
                    transcribedText = try await transcribeViaSupabase(
                        audioData: audioData,
                        mode: currentMode,
                        language: currentLanguage,
                        clarifyText: currentClarify
                    )

                case .byok(let apiKey):
                    transcribedText = try await transcribeViaBYOK(
                        audioData: audioData,
                        apiKey: apiKey,
                        mode: currentMode,
                        language: currentLanguage,
                        clarifyText: currentClarify
                    )

                case .none:
                    await MainActor.run {
                        self.error = L10n.loginRequired
                        self.statusText = L10n.error
                        self.needsAuth = true
                        self.isProcessing = false
                    }
                    return
                }

                await handleTranscriptionSuccess(
                    text: transcribedText,
                    mode: currentMode,
                    recordingDuration: recordingDuration
                )

            } catch {
                // Fallback: if Supabase fails and BYOK key exists, try direct Gemini
                if case .supabase = service, self.settings.hasByokKey {
                    print("[VoxAiGo] Supabase failed, falling back to BYOK: \(error.localizedDescription)")
                    do {
                        let fallbackText = try await transcribeViaBYOK(
                            audioData: audioData,
                            apiKey: self.settings.byokApiKey,
                            mode: currentMode,
                            language: currentLanguage,
                            clarifyText: currentClarify
                        )
                        await handleTranscriptionSuccess(
                            text: fallbackText,
                            mode: currentMode,
                            recordingDuration: recordingDuration
                        )
                        return
                    } catch let fallbackError {
                        print("[VoxAiGo] BYOK fallback also failed: \(fallbackError.localizedDescription)")
                    }
                }

                await MainActor.run {
                    self.isProcessing = false

                    // Special handling for free limit reached — show upgrade prompt
                    if case SupabaseTranscriptionError.freeLimitReached = error {
                        self.error = L10n.freeLimitReached
                        self.statusText = L10n.error
                        self.showUpgradePrompt = true
                        // Refresh profile to sync counter
                        Task { await SubscriptionManager.shared.fetchProfile() }
                        // Show upgrade window after HUD closes
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            NotificationCenter.default.post(name: .showUpgradePrompt, object: nil)
                        }
                    } else {
                        self.error = "\(L10n.error): \(error.localizedDescription)"
                        self.statusText = L10n.error
                    }
                    // Close the HUD window — without this, it stays stuck showing "Segure"
                    NotificationCenter.default.post(name: .recordingCancelled, object: nil)
                }
            }
        }
    }

    // MARK: - Transcription Methods

    private func transcribeViaSupabase(
        audioData: Data,
        mode: TranscriptionMode,
        language: SpeechLanguage,
        clarifyText: Bool
    ) async throws -> String {
        let service = SupabaseService(mode: mode, outputLanguage: language, clarifyText: clarifyText)
        return try await service.transcribeAudio(audioData: audioData)
    }

    private func transcribeViaBYOK(
        audioData: Data,
        apiKey: String,
        mode: TranscriptionMode,
        language: SpeechLanguage,
        clarifyText: Bool
    ) async throws -> String {
        let service = GeminiService(
            apiKey: apiKey,
            mode: mode,
            outputLanguage: language,
            clarifyText: clarifyText
        )
        return try await service.transcribeAudio(audioData: audioData)
    }

    private func handleTranscriptionSuccess(
        text: String,
        mode: TranscriptionMode,
        recordingDuration: TimeInterval
    ) async {
        await MainActor.run {
            self.isProcessing = false

            if text.isEmpty {
                self.error = L10n.noText
                self.statusText = L10n.error
            } else {
                // Expandir snippets
                let finalText = self.snippets.expand(text)

                // ── Wake word detection ─────────────────────────────────────────
                // Only activates if text STARTS with the configured wake word.
                // Tries mode match first, language match second.
                // Does NOT paste — fires a notification for the AppDelegate HUD.
                if self.settings.wakeWordEnabled {
                    let result = VoxAiGoViewModel.detectWakeWordCommand(
                        in: finalText,
                        wakeWord: self.settings.wakeWord
                    )

                    if let result = result {
                        switch result {
                        case .mode(let newMode):
                            self.updateMode(newMode)
                            print("[WakeWord] Mode → \(newMode.rawValue)")
                            NotificationCenter.default.post(
                                name: .wakeWordCommand,
                                object: nil,
                                userInfo: [
                                    "label": newMode.rawValue,
                                    "icon": newMode.icon,
                                    "type": "mode"
                                ]
                            )

                        case .language(let newLang):
                            self.settings.outputLanguage = newLang
                            print("[WakeWord] Language → \(newLang.displayName)")
                            NotificationCenter.default.post(
                                name: .wakeWordCommand,
                                object: nil,
                                userInfo: [
                                    "label": "\(newLang.flag) \(newLang.displayName)",
                                    "icon": "globe",
                                    "type": "language"
                                ]
                            )
                        }

                        // Close the recording HUD immediately — AppDelegate shows a dedicated toast
                        NotificationCenter.default.post(name: .recordingCancelled, object: nil)
                        return
                    }
                }
                // ───────────────────────────────────────────────────────────────

                // Copiar e colar
                ClipboardHelper.copyAndPaste(finalText)
                self.statusText = L10n.pasted

                // Registrar analytics (with mode and recording duration)
                AnalyticsManager.shared.recordTranscription(
                    characters: finalText.count,
                    mode: mode,
                    recordingDuration: recordingDuration
                )

                // Learn from successful transcription for style personalization
                WritingStyleManager.shared.learnFromTranscription(finalText, mode: mode)

                // Notificar AppDelegate sobre transcrição completa
                NotificationCenter.default.post(
                    name: .transcriptionComplete,
                    object: nil,
                    userInfo: ["text": finalText, "mode": mode]
                )

                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                    self?.statusText = L10n.ready
                }
            }
        }
    }

    // MARK: - Wake Word Detection

    /// Result of a wake word command — either a mode switch or a language switch
    enum WakeWordResult {
        case mode(TranscriptionMode)
        case language(SpeechLanguage)
    }

    /// Parses transcribed text for a wake word command at the BEGINNING of the string.
    /// Returns a `WakeWordResult` (mode or language) if matched, nil otherwise.
    /// Tries mode aliases first, language aliases second to avoid ambiguity.
    static func detectWakeWordCommand(in text: String, wakeWord: String = "Hey Vox") -> WakeWordResult? {
        let normalized = text
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: " ")
            .replacingOccurrences(of: ".", with: " ")
            .replacingOccurrences(of: "!", with: " ")
            .components(separatedBy: .whitespaces).filter { !$0.isEmpty }.joined(separator: " ")

        // Build wake word candidate list
        let base = wakeWord.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        var candidates: [String] = [base]
        if base == "hey vox" {
            candidates += ["ei vox", "hey fox", "hey box", "a vox", "hey vocs"]
        } else {
            let stripped = base.folding(options: .diacriticInsensitive, locale: .current)
            if stripped != base { candidates.append(stripped) }
        }

        // Must start with wake word (not appear in the middle of a sentence)
        guard let wake = candidates.first(where: { normalized.hasPrefix($0) }) else {
            return nil
        }

        let commandPart = normalized
            .dropFirst(wake.count)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !commandPart.isEmpty else { return nil }

        // ── Strip filler sounds between wake word and the actual command ──
        // e.g. "hey vox, ãh, email" → commandPart becomes "email"
        let fillers = ["ãh", "ah", "uh", "um", "hmm", "hm", "né", "tipo", "então", "er", "bem", "sabe"]
        var cleanedCommand = commandPart
        for filler in fillers {
            cleanedCommand = cleanedCommand
                .replacingOccurrences(of: filler + " ", with: "")
                .replacingOccurrences(of: " " + filler + " ", with: " ")
        }
        // Strip leading/trailing filler
        for filler in fillers where cleanedCommand == filler {
            cleanedCommand = ""
        }
        cleanedCommand = cleanedCommand.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedCommand.isEmpty else { return nil }

        // ── Special: "próximo idioma" / "next language" → cycle forward ──
        let nextAliases = ["próximo idioma", "proximo idioma", "next language", "próximo", "next"]
        let prevAliases = ["idioma anterior", "previous language", "anterior", "previous", "volta idioma", "back language"]
        if nextAliases.contains(where: { cleanedCommand.hasPrefix($0) }) {
            // Cycle to next language among all SpeechLanguage cases
            let all = SpeechLanguage.allCases
            let current = SettingsManager.shared.outputLanguage
            let idx = all.firstIndex(of: current) ?? 0
            let next = all[(idx + 1) % all.count]
            return .language(next)
        }
        if prevAliases.contains(where: { cleanedCommand.hasPrefix($0) }) {
            let all = SpeechLanguage.allCases
            let current = SettingsManager.shared.outputLanguage
            let idx = all.firstIndex(of: current) ?? 0
            let prev = all[(idx - 1 + all.count) % all.count]
            return .language(prev)
        }

        // ── 1. Try mode match first (sorted by alias length — most specific first) ──
        let sortedModes = TranscriptionMode.allCases.sorted { a, b in
            let maxA = a.voiceAliases.map(\.count).max() ?? 0
            let maxB = b.voiceAliases.map(\.count).max() ?? 0
            return maxA > maxB
        }
        for mode in sortedModes {
            for alias in mode.voiceAliases where !alias.isEmpty {
                if cleanedCommand.hasPrefix(alias) || cleanedCommand == alias {
                    return .mode(mode)
                }
            }
        }

        // ── 2. Try language match (sorted by alias length too) ──
        let sortedLanguages = SpeechLanguage.allCases.sorted { a, b in
            let maxA = a.voiceAliases.map(\.count).max() ?? 0
            let maxB = b.voiceAliases.map(\.count).max() ?? 0
            return maxA > maxB
        }
        for lang in sortedLanguages {
            for alias in lang.voiceAliases {
                if cleanedCommand.hasPrefix(alias) || cleanedCommand == alias {
                    return .language(lang)
                }
            }
        }

        return nil
    }
}

// MARK: - Localization

extension L10n {
    static var loginRequired: String { t("Login required to use VoxAiGo", "Faça login para usar o VoxAiGo", "Inicia sesión para usar VoxAiGo") }
    static var proModeRequired: String { t("This mode requires Pro plan", "Este modo requer plano Pro", "Este modo requiere plan Pro") }
    static var proLanguageRequired: String { t("This language requires Pro plan", "Este idioma requer plano Pro", "Este idioma requiere plan Pro") }
}


