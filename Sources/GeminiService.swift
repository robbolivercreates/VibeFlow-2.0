import Foundation
import GoogleGenerativeAI

class GeminiService: ObservableObject {
    @Published var isProcessing = false
    @Published var error: String?
    
    private let model: GenerativeModel
    
    /// Inicializa o serviço com a API key, modo, idioma de saída e clareza
    init(apiKey: String, mode: TranscriptionMode, outputLanguage: SpeechLanguage, clarifyText: Bool) {
        let systemPrompt = mode.systemPrompt(outputLanguage: outputLanguage, clarifyText: clarifyText)
        
        // Usar temperatura dinâmica por modo
        let temperature = mode.temperature
        let maxTokens = mode.maxOutputTokens
        
        self.model = GenerativeModel(
            name: "gemini-2.0-flash",
            apiKey: apiKey,
            generationConfig: GenerationConfig(
                temperature: temperature,
                maxOutputTokens: maxTokens
            ),
            systemInstruction: ModelContent(role: "system", parts: [.text(systemPrompt)])
        )
    }
    
    /// Transcreve áudio usando Gemini multimodal
    func transcribeAudio(audioData: Data) async throws -> String {
        await MainActor.run {
            isProcessing = true
            error = nil
        }
        
        defer {
            Task { @MainActor in
                isProcessing = false
            }
        }
        
        // Criar prompt para transcrição
        let prompt = "Transcreva e processe o áudio a seguir conforme suas instruções:"
        
        // Enviar áudio para o Gemini
        let response = try await model.generateContent(
            prompt,
            ModelContent.Part.data(mimetype: "audio/m4a", audioData)
        )
        
        guard let text = response.text else {
            throw GeminiError.noResponse
        }
        
        // Limpar resposta (remover markdown residual)
        return cleanMarkdown(text)
    }
    
    /// Remove markdown de código e cumprimentos
    private func cleanMarkdown(_ text: String) -> String {
        var result = text
        
        // Remove blocos de código markdown
        let codeBlockPattern = "```[a-zA-Z]*\\n?"
        if let regex = try? NSRegularExpression(pattern: codeBlockPattern) {
            result = regex.stringByReplacingMatches(
                in: result,
                range: NSRange(result.startIndex..., in: result),
                withTemplate: ""
            )
        }
        
        // Remove ``` finais
        result = result.replacingOccurrences(of: "```", with: "")
        
        // Remove cumprimentos comuns
        let greetings = [
            "Olá!", "Olá,", "Oi!", "Claro!", "Claro,",
            "Aqui está:", "Aqui está o código:", "Aqui está o texto:",
            "Segue o código:", "Segue:", "Certo!",
            "Hello!", "Hi!", "Sure!", "Here is:", "Here's the code:"
        ]
        
        for greeting in greetings {
            if result.lowercased().hasPrefix(greeting.lowercased()) {
                result = String(result.dropFirst(greeting.count))
                break
            }
        }
        
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

enum GeminiError: LocalizedError {
    case noResponse
    case invalidAudio
    
    var errorDescription: String? {
        switch self {
        case .noResponse:
            return "Sem resposta do Gemini"
        case .invalidAudio:
            return "Áudio inválido"
        }
    }
}
