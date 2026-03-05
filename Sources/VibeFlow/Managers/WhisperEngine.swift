import Foundation
import WhisperKit

class WhisperEngine: ObservableObject {
    static let shared = WhisperEngine()

    @Published var isReady = false
    @Published var isLoading = false

    private var whisperKit: WhisperKit?

    private init() {}

    /// Initialize WhisperKit with model from app bundle or auto-download
    func setup() async {
        guard whisperKit == nil else { return }

        await MainActor.run { isLoading = true }

        do {
            // Try to load model from app bundle first
            let bundleModelPath = Bundle.main.resourcePath.map { "\($0)/whisper-small" }

            let config: WhisperKitConfig
            if let path = bundleModelPath,
               FileManager.default.fileExists(atPath: path) {
                config = WhisperKitConfig(
                    model: "openai_whisper-small",
                    modelFolder: path,
                    verbose: false
                )
                print("[WhisperEngine] Loading model from bundle: \(path)")
            } else {
                // Fallback: auto-download from Hugging Face (first use)
                config = WhisperKitConfig(
                    model: "openai_whisper-small",
                    verbose: false
                )
                print("[WhisperEngine] Model not in bundle — downloading from Hugging Face")
            }

            let kit = try await WhisperKit(config)
            self.whisperKit = kit

            await MainActor.run {
                self.isReady = true
                self.isLoading = false
            }
            print("[WhisperEngine] Ready")
        } catch {
            await MainActor.run { self.isLoading = false }
            print("[WhisperEngine] Setup failed: \(error.localizedDescription)")
        }
    }

    /// Transcribe audio data (M4A format) to text
    /// - Parameters:
    ///   - audioData: Raw audio in M4A format
    ///   - language: ISO 639-1 code (e.g. "pt", "en") to force transcription language.
    ///              When nil, Whisper auto-detects (may translate to English).
    func transcribe(audioData: Data, language: String? = nil) async throws -> String {
        // Ensure engine is ready
        if whisperKit == nil {
            await setup()
        }

        guard let kit = whisperKit else {
            throw WhisperEngineError.notReady
        }

        // Write audio data to temp file (WhisperKit needs a file path)
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("whisper_\(Date().timeIntervalSince1970).m4a")
        try audioData.write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        // Force transcription in the specified language (prevents auto-translate to English)
        let options = DecodingOptions(
            task: .transcribe,
            language: language
        )

        // Transcribe — WhisperKit handles M4A → 16kHz PCM conversion
        let results = try await kit.transcribe(audioPath: tempURL.path, decodeOptions: options)

        let text = results.map { $0.text }.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)

        if text.isEmpty {
            throw WhisperEngineError.noSpeechDetected
        }

        print("[WhisperEngine] Transcribed (lang=\(language ?? "auto")): \(text.prefix(80))...")
        return text
    }
}

enum WhisperEngineError: LocalizedError {
    case notReady
    case noSpeechDetected

    var errorDescription: String? {
        switch self {
        case .notReady:
            return "Whisper engine not ready. Please wait for model to load."
        case .noSpeechDetected:
            return "No speech detected in audio."
        }
    }
}
