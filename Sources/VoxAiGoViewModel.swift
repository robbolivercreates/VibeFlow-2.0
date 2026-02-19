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
    @Published var audioLevel: CGFloat = 0.0

    private let settings = SettingsManager.shared
    private let snippets = SnippetsManager.shared
    private let auth = AuthManager.shared
    private let subscription = SubscriptionManager.shared
    let audioRecorder = AudioRecorder()
    private var cancellables = Set<AnyCancellable>()

    // Command mode: stores selected text before recording
    // Internal access so AppDelegate can pre-capture text before window activation
    var commandModeSelectedText: String?

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
        if case .supabase = service, !subscription.canUseMode(selectedMode) {
            error = L10n.proModeRequired
            NotificationCenter.default.post(name: .recordingCancelled, object: nil)
            return
        }

        // Feature gating: language restriction (only for Supabase users, not BYOK)
        if case .supabase = service, !subscription.canUseLanguage(settings.outputLanguage) {
            error = L10n.proLanguageRequired
            NotificationCenter.default.post(name: .recordingCancelled, object: nil)
            return
        }

        // Feature gating: free limit (only for Supabase users, not BYOK)
        if case .supabase = service, subscription.hasReachedFreeLimit {
            error = L10n.freeLimitReached
            NotificationCenter.default.post(name: .recordingCancelled, object: nil)
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

        // In command mode, check if text was already pre-captured by AppDelegate
        // (text is captured BEFORE window activation for correct focus)
        if selectedMode == .command {
            // Only try to capture if not already set by AppDelegate
            if commandModeSelectedText == nil {
                commandModeSelectedText = ClipboardHelper.getSelectedText()
            }

            if commandModeSelectedText != nil {
                print("[VoxAiGo] Command mode: using selected text (\(commandModeSelectedText!.count) chars)")
            } else {
                print("[VoxAiGo] Command mode: no text selected, will transcribe as normal")
            }
        } else {
            commandModeSelectedText = nil
        }

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
        let selectedText = self.commandModeSelectedText

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
                        clarifyText: currentClarify,
                        selectedText: selectedText
                    )

                case .byok(let apiKey):
                    transcribedText = try await transcribeViaBYOK(
                        audioData: audioData,
                        apiKey: apiKey,
                        mode: currentMode,
                        language: currentLanguage,
                        clarifyText: currentClarify,
                        selectedText: selectedText
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
                            clarifyText: currentClarify,
                            selectedText: selectedText
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
                    self.commandModeSelectedText = nil
                    self.isProcessing = false
                    self.error = "\(L10n.error): \(error.localizedDescription)"
                    self.statusText = L10n.error
                }
            }
        }
    }

    // MARK: - Transcription Methods

    private func transcribeViaSupabase(
        audioData: Data,
        mode: TranscriptionMode,
        language: SpeechLanguage,
        clarifyText: Bool,
        selectedText: String?
    ) async throws -> String {
        let service = SupabaseService(mode: mode, outputLanguage: language, clarifyText: clarifyText)

        if mode == .command, let selectedText = selectedText {
            return try await service.transcribeWithSelectedText(audioData: audioData, selectedText: selectedText)
        } else {
            return try await service.transcribeAudio(audioData: audioData)
        }
    }

    private func transcribeViaBYOK(
        audioData: Data,
        apiKey: String,
        mode: TranscriptionMode,
        language: SpeechLanguage,
        clarifyText: Bool,
        selectedText: String?
    ) async throws -> String {
        let service = GeminiService(
            apiKey: apiKey,
            mode: mode,
            outputLanguage: language,
            clarifyText: clarifyText
        )

        if mode == .command, let selectedText = selectedText {
            return try await service.transcribeWithSelectedText(audioData: audioData, selectedText: selectedText)
        } else {
            return try await service.transcribeAudio(audioData: audioData)
        }
    }

    private func handleTranscriptionSuccess(
        text: String,
        mode: TranscriptionMode,
        recordingDuration: TimeInterval
    ) async {
        await MainActor.run {
            self.commandModeSelectedText = nil
            self.isProcessing = false

            if text.isEmpty {
                self.error = L10n.noText
                self.statusText = L10n.error
            } else {
                // Expandir snippets
                let finalText = self.snippets.expand(text)

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
}

// MARK: - Localization

extension L10n {
    static var loginRequired: String { t("Login required to use VoxAiGo", "Faça login para usar o VoxAiGo", "Inicia sesión para usar VoxAiGo") }
    static var proModeRequired: String { t("This mode requires Pro plan", "Este modo requer plano Pro", "Este modo requiere plan Pro") }
    static var proLanguageRequired: String { t("This language requires Pro plan", "Este idioma requer plano Pro", "Este idioma requiere plan Pro") }
}
