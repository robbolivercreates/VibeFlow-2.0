import SwiftUI
import Combine

class VibeFlowViewModel: ObservableObject {
    @Published var isRecording = false
    @Published var isProcessing = false
    @Published var statusText = L10n.ready
    @Published var error: String?
    @Published var selectedMode: TranscriptionMode = .code
    @Published var clarifyText: Bool = true
    @Published var needsAPIKey = false
    @Published var audioLevel: CGFloat = 0.0

    private let settings = SettingsManager.shared
    private let snippets = SnippetsManager.shared
    let audioRecorder = AudioRecorder()
    private var cancellables = Set<AnyCancellable>()

    // Command mode: stores selected text before recording
    private var commandModeSelectedText: String?
    
    init() {
        loadSettings()
        setupObservers()
        loadAPIKey()
    }
    
    private func loadSettings() {
        // Usar SettingsManager
        selectedMode = settings.selectedMode

        // Carregar preferência de clareza (padrão: true)
        if UserDefaults.standard.object(forKey: "clarifyText") != nil {
            clarifyText = UserDefaults.standard.bool(forKey: "clarifyText")
        } else {
            clarifyText = true
        }
    }
    
    private func setupObservers() {
        audioRecorder.$isRecording
            .assign(to: &$isRecording)

        audioRecorder.$recordingError
            .compactMap { $0 }
            .assign(to: &$error)

        audioRecorder.$audioLevel
            .assign(to: &$audioLevel)

        // Note: We no longer recreate service on language change.
        // The service is created just-in-time when recording stops,
        // using the current settings. This improves performance.
    }
    
    /// Obtém a API Key (prioridade: SettingsManager > Config.swift)
    private func getAPIKey() -> String? {
        // SettingsManager já verifica UserDefaults
        if settings.hasApiKey {
            return settings.apiKey
        }
        
        let configKey = Config.geminiAPIKey
        if !configKey.isEmpty && configKey != "SUA_API_KEY_AQUI" {
            return configKey
        }
        
        return nil
    }
    
    func loadAPIKey() {
        // Just check if API key exists - service is created just-in-time
        if getAPIKey() != nil {
            needsAPIKey = false
            error = nil
        } else {
            needsAPIKey = true
            error = L10n.configureAPIKey
        }
    }

    func reloadAPIKey() {
        loadSettings()
        loadAPIKey()
    }

    func updateMode(_ mode: TranscriptionMode) {
        selectedMode = mode
        settings.selectedMode = mode
        // No need to recreate service - it's created just-in-time with current settings
    }
    
    func toggleRecording() {
        if needsAPIKey {
            error = L10n.configureAPIKey
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

        // In command mode, capture selected text before recording
        if selectedMode == .command {
            commandModeSelectedText = ClipboardHelper.getSelectedText()
            if commandModeSelectedText != nil {
                print("[VibeFlow] Command mode: captured selected text (\(commandModeSelectedText!.count) chars)")
            } else {
                print("[VibeFlow] Command mode: no text selected, will transcribe as normal")
            }
        } else {
            commandModeSelectedText = nil
        }

        audioRecorder.startRecording()
    }
    
    private func stopRecording() {
        // Verificar se detectou fala antes de parar
        let hasSpeech = audioRecorder.isRecordingValid()
        
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
            print("[VibeFlow] Gravação ignorada - nenhuma fala detectada")
            
            // Notificar para fechar a janela
            NotificationCenter.default.post(
                name: .recordingCancelled,
                object: nil
            )
            return
        }
        
        statusText = L10n.processing

        Task {
            do {
                // Create service just-in-time with current settings for best performance
                guard let apiKey = self.getAPIKey() else {
                    await MainActor.run {
                        self.error = L10n.configureAPIKey
                        self.statusText = L10n.error
                        self.needsAPIKey = true
                    }
                    return
                }

                // Create fresh service with current mode and language
                let currentMode = self.selectedMode
                let currentLanguage = self.settings.outputLanguage
                let service = GeminiService(
                    apiKey: apiKey,
                    mode: currentMode,
                    outputLanguage: currentLanguage,
                    clarifyText: self.clarifyText
                )

                // Update processing state
                await MainActor.run {
                    self.isProcessing = true
                }

                // Use appropriate transcription method
                let transcribedText: String
                if currentMode == .command, let selectedText = self.commandModeSelectedText {
                    // Command mode with selected text
                    transcribedText = try await service.transcribeWithSelectedText(
                        audioData: audioData,
                        selectedText: selectedText
                    )
                } else {
                    // Normal transcription
                    transcribedText = try await service.transcribeAudio(audioData: audioData)
                }

                await MainActor.run {
                    // Clear command mode text
                    self.commandModeSelectedText = nil
                    self.isProcessing = false

                    if transcribedText.isEmpty {
                        self.error = L10n.noText
                        self.statusText = L10n.error
                    } else {
                        // Expandir snippets
                        let finalText = self.snippets.expand(transcribedText)

                        // Copiar e colar
                        ClipboardHelper.copyAndPaste(finalText)
                        self.statusText = L10n.pasted

                        // Registrar analytics
                        AnalyticsManager.shared.recordTranscription(characters: finalText.count)

                        // Learn from successful transcription for style personalization
                        WritingStyleManager.shared.learnFromTranscription(finalText, mode: currentMode)

                        // Notificar AppDelegate sobre transcrição completa
                        NotificationCenter.default.post(
                            name: .transcriptionComplete,
                            object: nil,
                            userInfo: ["text": finalText, "mode": currentMode]
                        )

                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                            self?.statusText = L10n.ready
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    self.commandModeSelectedText = nil
                    self.isProcessing = false
                    self.error = "\(L10n.error): \(error.localizedDescription)"
                    self.statusText = L10n.error
                }
            }
        }
    }
}
