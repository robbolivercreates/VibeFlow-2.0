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
    @Published var isTransformMode = false

    /// Text captured from user's selection when recording started (set by AppDelegate)
    var pendingSelectedText: String?

    private let settings = SettingsManager.shared
    private let snippets = SnippetsManager.shared
    private let auth = AuthManager.shared
    private let subscription = SubscriptionManager.shared
    let audioRecorder = AudioRecorder()
    private var cancellables = Set<AnyCancellable>()

    // Conversation Reply mode: set by AppDelegate when ⌥⌘ is pressed during conversation HUD
    var isConversationReplyMode = false
    var conversationReplyTargetLanguage: String = ""

    // Character limits for text transformation
    static let transformLimitFree = 500
    static let transformLimitPro = 3000

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

        // Keep selectedMode in sync with SettingsManager
        settings.$selectedMode
            .receive(on: DispatchQueue.main)
            .sink { [weak self] mode in
                if self?.selectedMode != mode {
                    self?.selectedMode = mode
                }
            }
            .store(in: &cancellables)
    }

    /// Determines which transcription service to use
    private func getTranscriptionService() -> TranscriptionServiceType {
        // Priority 1: BYOK (easter egg — always wins)
        if settings.hasByokKey {
            return .byok(apiKey: settings.byokApiKey)
        }

        // Must be authenticated
        guard auth.isAuthenticated else { return .none }

        // Priority 2: Manual offline toggle (Pro users can force Whisper local)
        if settings.offlineMode { return .whisper }

        // Priority 3: Pro subscriber → Gemini cloud
        if subscription.isPro { return .supabase }

        // Priority 4: Trial active → Gemini cloud
        if TrialManager.shared.isTrialActive() { return .supabase }

        // Priority 5: Free → Whisper local
        return .whisper
    }

    func checkAuth() {
        let service = getTranscriptionService()
        switch service {
        case .none:
            needsAuth = true
            error = L10n.loginRequired
        case .supabase, .byok, .whisper:
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

        // Feature gating applies to Supabase and Whisper users (not BYOK)
        let needsGating = { if case .byok = service { return false }; return true }()

        print("[ViewModel] toggleRecording: mode=\(selectedMode.rawValue) service=\(service) isPro=\(subscription.isPro) devMode=\(subscription.devModeActive)")

        // Online validation enforcement: block if >48h without server check
        if needsGating {
            subscription.checkOnlineValidationStatus()
            if subscription.needsOnlineValidation {
                // Try to validate now
                Task {
                    await subscription.fetchProfile()
                    await subscription.syncWhisperUsageToServer()
                    await MainActor.run {
                        if subscription.needsOnlineValidation {
                            // Still can't reach server — block
                            error = L10n.onlineValidationRequired
                            NotificationCenter.default.post(name: .recordingCancelled, object: nil)
                        }
                    }
                }
                if subscription.needsOnlineValidation {
                    error = L10n.onlineValidationRequired
                    NotificationCenter.default.post(name: .recordingCancelled, object: nil)
                    return
                }
            }
        }

        // Feature gating: mode restriction
        if needsGating, !subscription.canUseMode(selectedMode) {
            error = L10n.proModeRequired
            print("[ViewModel] BLOCKED: proModeRequired for \(selectedMode.rawValue)")
            NotificationCenter.default.post(name: .recordingCancelled, object: nil)
            return
        }

        // Feature gating: language restriction
        if needsGating, !subscription.canUseLanguage(settings.outputLanguage) {
            error = L10n.proLanguageRequired
            print("[ViewModel] BLOCKED: proLanguageRequired for \(settings.outputLanguage.rawValue)")
            NotificationCenter.default.post(name: .recordingCancelled, object: nil)
            return
        }

        // Feature gating: trial limit (50 transcriptions) — trial expired, goes to free
        if case .supabase = service, !subscription.isPro, TrialManager.shared.hasReachedTrialLimit {
            error = L10n.trialExpiredTitle
            NotificationCenter.default.post(name: .recordingCancelled, object: nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NotificationCenter.default.post(name: .showTrialExpired, object: nil)
            }
            return
        }

        // Note: Legacy Supabase 100 free limit removed — free users now use
        // Whisper local only (200/month). Supabase path is only for Pro/Trial.

        // Feature gating: whisper free limit (200/month — LOCKED)
        if case .whisper = service, subscription.hasReachedWhisperLimit {
            error = L10n.monthlyLimitTitle
            NotificationCenter.default.post(name: .recordingCancelled, object: nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NotificationCenter.default.post(name: .showMonthlyLimit, object: nil)
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

                    case .whisper:
                        // Whisper can't translate — transcribe in user's language
                        let langCode = self.settings.outputLanguage.rawValue
                        translatedReply = try await WhisperEngine.shared.transcribe(audioData: audioData, language: langCode)

                    case .none:
                        throw NSError(
                            domain: "ConversationReply",
                            code: 2,
                            userInfo: [NSLocalizedDescriptionKey: L10n.loginRequired]
                        )
                    }

                    // Count usage for Conversation Reply
                    await MainActor.run {
                        switch service {
                        case .supabase:
                            if TrialManager.shared.isTrialActive() {
                                TrialManager.shared.recordTrialTranscription()
                            }
                        case .whisper:
                            self.subscription.recordWhisperTranscription()
                        default: break
                        }
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
                print("[DEBUG] Starting transcription with service: \(service)")

                switch service {
                case .supabase:
                    transcribedText = try await transcribeViaSupabase(
                        audioData: audioData,
                        mode: currentMode,
                        language: currentLanguage,
                        clarifyText: currentClarify
                    )
                    // Track trial transcription if on trial
                    if TrialManager.shared.isTrialActive() {
                        TrialManager.shared.recordTrialTranscription()
                        // Show downgrade message if trial limit just reached
                        if TrialManager.shared.hasReachedTrialLimit {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                NotificationCenter.default.post(name: .showTrialExpired, object: nil)
                            }
                        }
                    }

                case .whisper:
                    // Pass raw text — formatting applied AFTER wake word detection
                    transcribedText = try await transcribeViaWhisper(audioData: audioData)
                    subscription.recordWhisperTranscription()

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

                print("[DEBUG] Transcription succeeded: '\(transcribedText.prefix(100))' (\(transcribedText.count) chars)")
                await handleTranscriptionSuccess(
                    text: transcribedText,
                    mode: currentMode,
                    recordingDuration: recordingDuration
                )

            } catch {
                print("[DEBUG] ❌ Transcription FAILED: \(error) — \(error.localizedDescription)")
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
                    self.error = "\(L10n.error): \(error.localizedDescription)"
                    self.statusText = L10n.error
                    // Close the HUD window — without this, it stays stuck showing "Segure"
                    NotificationCenter.default.post(name: .recordingCancelled, object: nil)
                }
            }
        }
    }

    // MARK: - Transcription Methods

    private func transcribeViaWhisper(audioData: Data) async throws -> String {
        // Pass current language so Whisper transcribes in the user's native language
        // instead of auto-detecting (which often translates to English)
        let langCode = settings.outputLanguage.rawValue
        return try await WhisperEngine.shared.transcribe(audioData: audioData, language: langCode)
    }

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
            print("[DEBUG] handleTranscriptionSuccess called with text: '\(text.prefix(80))' (\(text.count) chars)")

            if text.isEmpty {
                self.error = L10n.noText
                self.statusText = L10n.error
                print("[DEBUG] Text is empty → showing error")
            } else {
                // Expandir snippets
                let finalText = self.snippets.expand(text)
                print("[DEBUG] wakeWordEnabled=\(self.settings.wakeWordEnabled), wakeWord='\(self.settings.wakeWord)', finalText='\(finalText.prefix(80))'")

                // ── Wake word routing ────────────────────────────────────────
                // Mode command   → ALWAYS switch mode
                // Language command → ALWAYS switch language
                // Wake word alone → IGNORE (don't paste "Hey Vox")
                // ─────────────────────────────────────────────────────────────────
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

                        if AppDelegate.shared?.isWizardActive == true {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                AppDelegate.shared?.wizardWindow?.makeKeyAndOrderFront(nil)
                                NSApp.activate(ignoringOtherApps: true)
                            }
                        } else {
                            NotificationCenter.default.post(name: .recordingCancelled, object: nil)
                        }
                        return
                    }

                    // ── Wake word detected but no valid command → IGNORE ──
                    let wakeBase = self.settings.wakeWord.lowercased()
                    let textLower = finalText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                    let wakeVariants = wakeBase == "hey vox"
                        ? [wakeBase, "ei vox", "hey fox", "hey box", "a vox", "hey vocs"]
                        : [wakeBase]
                    if wakeVariants.contains(where: { textLower.hasPrefix($0) }) {
                        print("[DEBUG] Wake word prefix matched in '\(textLower)' → ignoring (NOT pasting)")
                        if AppDelegate.shared?.isWizardActive == true {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                AppDelegate.shared?.wizardWindow?.makeKeyAndOrderFront(nil)
                                NSApp.activate(ignoringOtherApps: true)
                            }
                        } else {
                            NotificationCenter.default.post(name: .recordingCancelled, object: nil)
                        }
                        return
                    }
                    print("[DEBUG] Not a wake word → proceeding to paste")
                }
                // ───────────────────────────────────────────────────────────────

                // Apply local mode formatting for Whisper offline (after wake word check)
                var outputText = finalText
                let currentService = self.getTranscriptionService()
                if case .whisper = currentService {
                    if self.subscription.isPro || TrialManager.shared.isTrialActive() {
                        outputText = LocalModeFormatter.format(finalText, mode: mode)
                        print("[DEBUG] Whisper Pro offline → applied mode formatting")
                    } else {
                        outputText = LocalModeFormatter.fixPunctuation(finalText)
                        print("[DEBUG] Whisper Free → applied punctuation fix")
                    }
                }

                let isWizardActive = AppDelegate.shared?.isWizardActive ?? false

                if isWizardActive {
                    // During wizard test: show result but DON'T paste or close
                    print("[DEBUG] Wizard active → skipping paste, posting transcriptionComplete only")
                    self.statusText = L10n.pasted

                    NotificationCenter.default.post(
                        name: .transcriptionComplete,
                        object: nil,
                        userInfo: ["text": outputText, "mode": mode]
                    )

                    // Re-activate wizard window
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        AppDelegate.shared?.wizardWindow?.makeKeyAndOrderFront(nil)
                        NSApp.activate(ignoringOtherApps: true)
                    }
                } else {
                    // Normal flow: paste text
                    print("[DEBUG] About to copyAndPaste: '\(outputText.prefix(80))'")
                    ClipboardHelper.copyAndPaste(outputText)
                    self.statusText = L10n.pasted
                    print("[DEBUG] ✅ Pasted successfully")
                }

                // Registrar analytics (with mode and recording duration)
                AnalyticsManager.shared.recordTranscription(
                    characters: outputText.count,
                    mode: mode,
                    recordingDuration: recordingDuration
                )

                // Learn from successful transcription for style personalization
                WritingStyleManager.shared.learnFromTranscription(outputText, mode: mode)

                // Notificar AppDelegate sobre transcrição completa (already done for wizard above)
                if !isWizardActive {
                    NotificationCenter.default.post(
                        name: .transcriptionComplete,
                        object: nil,
                        userInfo: ["text": outputText, "mode": mode]
                    )
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                    self?.statusText = L10n.ready
                }
            }
        }
    }

    // MARK: - Vox Transform

    /// Extracts the instruction portion after the wake word from transcribed text.
    static func extractInstruction(from text: String, wakeWord: String) -> String? {
        let normalized = text
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: " ")
            .replacingOccurrences(of: ".", with: " ")
            .replacingOccurrences(of: "!", with: " ")
            .components(separatedBy: .whitespaces).filter { !$0.isEmpty }.joined(separator: " ")

        let base = wakeWord.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        var candidates: [String] = [base]
        if base == "hey vox" {
            candidates += ["ei vox", "hey fox", "hey box", "a vox", "hey vocs"]
        }

        guard let wake = candidates.first(where: { normalized.hasPrefix($0) }) else {
            return nil
        }

        let instruction = normalized
            .dropFirst(wake.count)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Strip fillers
        let fillers = ["ãh", "ah", "uh", "um", "hmm", "hm", "né", "tipo", "então", "er", "bem", "sabe"]
        var cleaned = instruction
        for filler in fillers {
            cleaned = cleaned
                .replacingOccurrences(of: filler + " ", with: "")
                .replacingOccurrences(of: " " + filler + " ", with: " ")
        }
        for filler in fillers where cleaned == filler {
            cleaned = ""
        }
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)

        return cleaned.isEmpty ? nil : cleaned
    }

    /// Performs text transformation via Gemini (text-to-text, no audio needed).
    private func performTransform(
        selectedText: String,
        instruction: String,
        wakeWordResult: WakeWordResult,
        recordingDuration: TimeInterval
    ) async {
        let service = getTranscriptionService()

        do {
            let transformedText: String

            // Determine which mode to use for the transform prompt
            let transformMode: TranscriptionMode?
            switch wakeWordResult {
            case .mode(let mode): transformMode = mode
            default: transformMode = nil
            }

            switch service {
            case .byok(let apiKey):
                transformedText = try await GeminiService.transformText(
                    selectedText: selectedText,
                    instruction: instruction,
                    mode: transformMode,
                    outputLanguage: settings.outputLanguage,
                    apiKey: apiKey
                )

            case .supabase:
                transformedText = try await SupabaseService.transformText(
                    selectedText: selectedText,
                    instruction: instruction,
                    mode: transformMode,
                    outputLanguage: settings.outputLanguage
                )

            case .whisper:
                // Whisper is transcription-only — text transformation requires Gemini (Pro)
                await MainActor.run {
                    self.error = "Text transformation requires Pro plan"
                    self.statusText = L10n.error
                    self.isProcessing = false
                    NotificationCenter.default.post(name: .recordingCancelled, object: nil)
                }
                return

            case .none:
                await MainActor.run {
                    self.error = L10n.loginRequired
                    self.statusText = L10n.error
                    self.isProcessing = false
                    NotificationCenter.default.post(name: .recordingCancelled, object: nil)
                }
                return
            }

            // Safety: don't paste empty results
            guard !transformedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                await MainActor.run {
                    self.isProcessing = false
                    self.statusText = L10n.ready
                    print("[VoxTransform] Empty result from Gemini → ignoring")
                    NotificationCenter.default.post(name: .recordingCancelled, object: nil)
                }
                return
            }

            // Count usage for text transforms (consumes trial quota)
            await MainActor.run {
                if case .supabase = service, TrialManager.shared.isTrialActive() {
                    TrialManager.shared.recordTrialTranscription()
                }
            }

            await MainActor.run {
                self.isProcessing = false
                ClipboardHelper.copyAndPaste(transformedText)
                self.statusText = L10n.pasted

                // Analytics
                AnalyticsManager.shared.recordTranscription(
                    characters: transformedText.count,
                    mode: transformMode ?? .text,
                    recordingDuration: recordingDuration
                )

                NotificationCenter.default.post(
                    name: .transcriptionComplete,
                    object: nil,
                    userInfo: ["text": transformedText, "mode": transformMode ?? TranscriptionMode.text]
                )

                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                    self?.statusText = L10n.ready
                }
            }

        } catch {
            await MainActor.run {
                self.isProcessing = false
                self.error = "\(L10n.error): \(error.localizedDescription)"
                self.statusText = L10n.error
                print("[VoxTransform] Error: \(error.localizedDescription)")
                NotificationCenter.default.post(name: .recordingCancelled, object: nil)
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
    static var onlineValidationRequired: String { t("Internet connection required. Connect to continue using VoxAiGo.", "Conexão com a internet necessária. Conecte-se para continuar usando o VoxAiGo.", "Conexión a internet necesaria. Conéctese para continuar usando VoxAiGo.") }
}


