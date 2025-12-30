import SwiftUI
import Combine

class VibeFlowViewModel: ObservableObject {
    @Published var isRecording = false
    @Published var isProcessing = false
    @Published var statusText = L10n.ready
    @Published var error: String?
    @Published var selectedMode: TranscriptionMode = .code
    @Published var translateToEnglish: Bool = false
    @Published var clarifyText: Bool = true
    @Published var needsAPIKey = false
    
    // Callback chamado após colar com sucesso
    var onPasteComplete: (() -> Void)?
    
    private let audioRecorder = AudioRecorder()
    private var geminiService: GeminiService?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadSettings()
        setupObservers()
        loadAPIKey()
    }
    
    private func loadSettings() {
        // Carregar modo salvo
        if let modeRaw = UserDefaults.standard.string(forKey: "selectedMode"),
           let mode = TranscriptionMode(rawValue: modeRaw) {
            selectedMode = mode
        }
        
        // Carregar preferência de tradução
        translateToEnglish = UserDefaults.standard.bool(forKey: "translateToEnglish")
        
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
    }
    
    /// Obtém a API Key (prioridade: UserDefaults > Config.swift)
    private func getAPIKey() -> String? {
        if let savedKey = UserDefaults.standard.string(forKey: "GeminiAPIKey"), !savedKey.isEmpty {
            return savedKey
        }
        
        let configKey = Config.geminiAPIKey
        if !configKey.isEmpty && configKey != "SUA_API_KEY_AQUI" {
            return configKey
        }
        
        return nil
    }
    
    func loadAPIKey() {
        guard let apiKey = getAPIKey() else {
            needsAPIKey = true
            error = L10n.configureAPIKey
            return
        }
        
        needsAPIKey = false
        error = nil
        geminiService = GeminiService(apiKey: apiKey, mode: selectedMode, translateToEnglish: translateToEnglish, clarifyText: clarifyText)
        
        geminiService?.$isProcessing
            .assign(to: &$isProcessing)
        
        geminiService?.$error
            .compactMap { $0 }
            .assign(to: &$error)
    }
    
    func reloadAPIKey() {
        loadSettings()
        loadAPIKey()
        if let apiKey = getAPIKey() {
            geminiService = GeminiService(apiKey: apiKey, mode: selectedMode, translateToEnglish: translateToEnglish, clarifyText: clarifyText)
            geminiService?.$isProcessing
                .assign(to: &$isProcessing)
            geminiService?.$error
                .compactMap { $0 }
                .assign(to: &$error)
        }
    }
    
    func updateMode(_ mode: TranscriptionMode) {
        selectedMode = mode
        UserDefaults.standard.set(mode.rawValue, forKey: "selectedMode")
        
        if let apiKey = getAPIKey() {
            geminiService = GeminiService(apiKey: apiKey, mode: mode, translateToEnglish: translateToEnglish, clarifyText: clarifyText)
            geminiService?.$isProcessing
                .assign(to: &$isProcessing)
            geminiService?.$error
                .compactMap { $0 }
                .assign(to: &$error)
        }
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
        audioRecorder.startRecording()
    }
    
    private func stopRecording() {
        guard let _ = audioRecorder.stopRecording(),
              let audioData = audioRecorder.getRecordingData() else {
            error = L10n.recordingError
            statusText = L10n.error
            return
        }
        
        statusText = L10n.processing
        
        Task {
            do {
                guard let service = geminiService else {
                await MainActor.run {
                    error = L10n.configureAPIKey
                    statusText = L10n.error
                    needsAPIKey = true
                }
                    return
                }
                
                let transcribedText = try await service.transcribeAudio(audioData: audioData)
                
                await MainActor.run {
                    if transcribedText.isEmpty {
                        error = L10n.noText
                        statusText = L10n.error
                    } else {
                        ClipboardHelper.copyAndPaste(transcribedText)
                        statusText = L10n.pasted
                        
                        onPasteComplete?()
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            self.statusText = L10n.ready
                        }
                    }
                }
            } catch {
            await MainActor.run {
                self.error = "\(L10n.error): \(error.localizedDescription)"
                self.statusText = L10n.error
            }
            }
        }
    }
}
