import Foundation

class GeminiService: ObservableObject {
    @Published var isProcessing = false
    @Published var error: String?

    private let apiKey: String
    private let systemPrompt: String
    private let temperature: Float
    private let maxOutputTokens: Int
    private let thinkingLevel: String
    private let useGrounding: Bool
    private static let model = "gemini-3.1-flash-lite-preview"
    private static let baseURL = "https://generativelanguage.googleapis.com/v1beta/models"

    /// Inicializa o serviço com a API key, modo, idioma de saída e clareza
    init(apiKey: String, mode: TranscriptionMode, outputLanguage: SpeechLanguage, clarifyText: Bool) {
        self.apiKey = apiKey
        self.systemPrompt = mode.systemPrompt(outputLanguage: outputLanguage, clarifyText: clarifyText, wakeWord: SettingsManager.shared.wakeWord)
        self.temperature = mode.temperature
        self.maxOutputTokens = mode.maxOutputTokens
        self.thinkingLevel = mode.thinkingLevel
        self.useGrounding = mode.useGrounding
    }

    /// Transcreve áudio usando Gemini multimodal (REST direto)
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

        let prompt = "Transcreva e processe o áudio a seguir conforme suas instruções:"
        let audioBase64 = audioData.base64EncodedString()

        let body = buildRequestBody(
            prompt: prompt,
            audioBase64: audioBase64
        )

        let text = try await sendRequest(body: body)
        return cleanMarkdown(text)
    }

    /// Cleans up pre-transcribed text using the mode's system prompt (no audio).
    /// Used as fallback for long recordings: Whisper transcribes locally → this cleans up via Gemini.
    func cleanupText(_ rawText: String) async throws -> String {
        await MainActor.run {
            isProcessing = true
            error = nil
        }

        defer {
            Task { @MainActor in
                isProcessing = false
            }
        }

        var body: [String: Any] = [
            "system_instruction": ["parts": [["text": systemPrompt]]],
            "contents": [["parts": [["text": rawText]]]],
            "generationConfig": [
                "temperature": temperature,
                "maxOutputTokens": maxOutputTokens,
                "thinkingConfig": ["thinkingLevel": thinkingLevel]
            ]
        ]

        if useGrounding {
            body["tools"] = [["google_search": [:] as [String: Any]]]
        }

        let text = try await sendRequest(body: body)
        return cleanMarkdown(text)
    }

    /// Transcreve áudio com texto selecionado para Command Mode
    func transcribeWithSelectedText(audioData: Data, selectedText: String) async throws -> String {
        await MainActor.run {
            isProcessing = true
            error = nil
        }

        defer {
            Task { @MainActor in
                isProcessing = false
            }
        }

        let prompt = """
        [SELECTED TEXT]
        \(selectedText)
        [END SELECTED TEXT]

        Listen to the voice command and transform the selected text accordingly:
        """

        let audioBase64 = audioData.base64EncodedString()

        let body = buildRequestBody(
            prompt: prompt,
            audioBase64: audioBase64
        )

        let text = try await sendRequest(body: body)
        return cleanMarkdown(text)
    }

    // MARK: - Conversation Reply: Text Translation

    /// Detects the source language and translates text into targetLanguage.
    /// Used by the Conversation Reply feature (no audio needed).
    static func detectAndTranslate(
        text: String,
        targetLanguage: SpeechLanguage,
        apiKey: String
    ) async throws -> (translation: String, fromLanguageName: String, fromLanguageCode: String) {
        let prompt = """
        Translate the following text to \(targetLanguage.displayName).
        Detect the source language.
        Respond with valid JSON only — no markdown, no explanation:
        {"translation":"<translated text>","fromLanguageName":"<source language in English>","fromLanguageCode":"<ISO 639-1 code, e.g. ja>"}

        Text:
        \(text)
        """

        let body: [String: Any] = [
            "contents": [["parts": [["text": prompt]]]],
            "generationConfig": [
                "temperature": 0.1,
                "maxOutputTokens": 2048,
                "thinkingConfig": ["thinkingLevel": "minimal"]
            ]
        ]

        guard let url = URL(string: "\(baseURL)/\(model):generateContent?key=\(apiKey)") else {
            throw GeminiError.invalidRequest
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw GeminiError.apiError(statusCode: code, message: "Translation failed (HTTP \(code))")
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]] else {
            throw GeminiError.noResponse
        }

        let textParts = parts.compactMap { part -> String? in
            if part["thought"] as? Bool == true { return nil }
            return part["text"] as? String
        }

        var responseText = textParts.joined().trimmingCharacters(in: .whitespacesAndNewlines)

        // Strip markdown fences if Gemini added them despite instructions
        if responseText.hasPrefix("```") {
            responseText = responseText
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        guard let jsonData = responseText.data(using: .utf8),
              let parsed = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let translation = parsed["translation"] as? String,
              let fromLanguageName = parsed["fromLanguageName"] as? String,
              let fromLanguageCode = parsed["fromLanguageCode"] as? String else {
            throw GeminiError.noResponse
        }

        return (translation, fromLanguageName, fromLanguageCode.uppercased())
    }

    // MARK: - Conversation Reply: Speech → Target Language

    /// Transcribes audio and translates it directly to toLanguage.
    /// Used when user records their reply in conversation mode.
    func translateSpeechReply(audioData: Data, toLanguage: String) async throws -> String {
        let replySystemPrompt = """
        You are a professional translator.
        Transcribe the audio and immediately translate it to \(toLanguage).
        Output ONLY the translated text in \(toLanguage). No greeting, no explanation, no original text.
        """

        let audioBase64 = audioData.base64EncodedString()

        let body: [String: Any] = [
            "system_instruction": ["parts": [["text": replySystemPrompt]]],
            "contents": [[
                "parts": [
                    ["text": "Translate this audio to \(toLanguage):"],
                    ["inline_data": ["mime_type": "audio/m4a", "data": audioBase64]]
                ]
            ]],
            "generationConfig": [
                "temperature": 0.2,
                "maxOutputTokens": 2048,
                "thinkingConfig": ["thinkingLevel": "low"]
            ]
        ]

        let text = try await sendRequest(body: body)
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Vox Transform: Text-to-Text

    /// Transforms selected text based on a voice instruction (no audio needed).
    /// If `mode` is provided, uses that mode's system prompt adapted for transformation.
    /// Otherwise, treats `instruction` as a free-form command for the AI.
    static func transformText(
        selectedText: String,
        instruction: String,
        mode: TranscriptionMode?,
        outputLanguage: SpeechLanguage,
        apiKey: String
    ) async throws -> String {
        let systemPrompt: String

        if let mode = mode {
            // Use the mode's template adapted for text transformation
            systemPrompt = """
            You are an AI text transformation assistant. The user has selected existing text and wants you to rewrite it.

            TASK: Rewrite the provided text in the style of "\(mode.localizedName)" mode.
            \(mode.systemPrompt(outputLanguage: outputLanguage, clarifyText: false)
                .replacingOccurrences(of: "O usuário está ditando", with: "O usuário selecionou um texto e quer")
                .replacingOccurrences(of: "Transcreva o áudio", with: "Reescreva o texto")
                .replacingOccurrences(of: "audio", with: "text"))

            CRITICAL RULES:
            1. Output ONLY the transformed text, no explanations, no greetings
            2. Do NOT say "Aqui está", "Claro", "Here is" or any introduction
            3. Transform the ENTIRE selected text, don't summarize unless asked
            4. Keep the output in \(outputLanguage.fullName)
            """
        } else {
            // Free-form instruction
            systemPrompt = """
            You are an AI text transformation assistant. The user has selected existing text and given a voice instruction about what to do with it.

            INSTRUCTION FROM USER: "\(instruction)"

            CRITICAL RULES:
            1. Execute the user's instruction on the provided text
            2. Output ONLY the result, no explanations, no greetings, no "Aqui está"
            3. If the instruction is unclear, interpret it as best you can
            4. Output in \(outputLanguage.fullName) unless the instruction specifies otherwise
            """
        }

        let prompt = """
        [SELECTED TEXT]
        \(selectedText)
        [END SELECTED TEXT]

        Execute the transformation as instructed. Output ONLY the result:
        """

        let body: [String: Any] = [
            "system_instruction": ["parts": [["text": systemPrompt]]],
            "contents": [["parts": [["text": prompt]]]],
            "generationConfig": [
                "temperature": mode?.temperature ?? 0.3,
                "maxOutputTokens": mode?.maxOutputTokens ?? 2048,
                "thinkingConfig": ["thinkingLevel": mode?.thinkingLevel ?? "low"]
            ]
        ]

        guard let url = URL(string: "\(baseURL)/\(model):generateContent?key=\(apiKey)") else {
            throw GeminiError.invalidRequest
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw GeminiError.apiError(statusCode: code, message: "Transform failed (HTTP \(code))")
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]] else {
            throw GeminiError.noResponse
        }

        let textParts = parts.compactMap { part -> String? in
            if part["thought"] as? Bool == true { return nil }
            return part["text"] as? String
        }

        guard !textParts.isEmpty else {
            throw GeminiError.noResponse
        }

        // Clean markdown artifacts
        var result = textParts.joined()
        result = result.replacingOccurrences(of: "```", with: "")
        let greetings = ["Aqui está:", "Aqui está o texto:", "Claro!", "Claro,", "Here is:", "Sure!"]
        for greeting in greetings {
            if result.lowercased().hasPrefix(greeting.lowercased()) {
                result = String(result.dropFirst(greeting.count))
                break
            }
        }

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Private REST API

    /// Constrói o body JSON para a API do Gemini
    private func buildRequestBody(prompt: String, audioBase64: String) -> [String: Any] {
        var body: [String: Any] = [
            "system_instruction": [
                "parts": [["text": systemPrompt]]
            ],
            "contents": [
                [
                    "parts": [
                        ["text": prompt],
                        [
                            "inline_data": [
                                "mime_type": "audio/m4a",
                                "data": audioBase64
                            ]
                        ]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": temperature,
                "maxOutputTokens": maxOutputTokens,
                "thinkingConfig": [
                    "thinkingLevel": thinkingLevel
                ]
            ]
        ]

        // Enable Google Search grounding only for modes that need it (e.g. Custom)
        if useGrounding {
            body["tools"] = [["google_search": [:] as [String: Any]]]
        }

        return body
    }

    /// Envia request HTTP para a API do Gemini
    private func sendRequest(body: [String: Any]) async throws -> String {
        guard let url = URL(string: "\(Self.baseURL)/\(Self.model):generateContent?key=\(apiKey)") else {
            throw GeminiError.invalidRequest
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120  // 2 min timeout for large audio payloads
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        // Debug: log request body (truncated) to check grounding tools
        if useGrounding, let bodyJson = String(data: request.httpBody!, encoding: .utf8) {
            print("🔍 [GeminiService] Request body with grounding: \(bodyJson.prefix(500))")
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch let urlError as URLError {
            switch urlError.code {
            case .timedOut:
                throw GeminiError.timeout
            case .notConnectedToInternet, .networkConnectionLost:
                throw GeminiError.networkError
            default:
                throw GeminiError.networkError
            }
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.noResponse
        }

        // Check for payload too large (413) or rate limit (429)
        if httpResponse.statusCode == 413 {
            throw GeminiError.payloadTooLarge
        }

        guard httpResponse.statusCode == 200 else {
            // Tentar extrair mensagem de erro da API
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorInfo = errorJson["error"] as? [String: Any],
               let message = errorInfo["message"] as? String {
                throw GeminiError.apiError(statusCode: httpResponse.statusCode, message: message)
            }
            throw GeminiError.apiError(statusCode: httpResponse.statusCode, message: "HTTP \(httpResponse.statusCode)")
        }

        // Parse da resposta JSON
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]] else {
            // Debug: log raw response when parsing fails
            if let rawString = String(data: data, encoding: .utf8) {
                print("🔍 [GeminiService] Raw API response: \(rawString.prefix(2000))")
            }
            throw GeminiError.noResponse
        }

        // Debug: log grounding metadata if present
        if let groundingMeta = firstCandidate["groundingMetadata"] {
            print("🌐 [GeminiService] Grounding metadata found: \(groundingMeta)")
        }

        // Extrair texto (ignorar partes de "thought" se houver)
        let textParts = parts.compactMap { part -> String? in
            // Pular partes de thinking (se a API retornar mesmo com budget 0)
            if part["thought"] as? Bool == true { return nil }
            return part["text"] as? String
        }

        guard !textParts.isEmpty else {
            throw GeminiError.noResponse
        }

        return textParts.joined()
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

        // Remove markdown bold (**text** → text)
        if let boldRegex = try? NSRegularExpression(pattern: "\\*\\*(.+?)\\*\\*") {
            result = boldRegex.stringByReplacingMatches(
                in: result,
                range: NSRange(result.startIndex..., in: result),
                withTemplate: "$1"
            )
        }

        // Remove markdown italic (*text* → text), but not bullet points
        if let italicRegex = try? NSRegularExpression(pattern: "(?<!\\n)(?<!^)\\*(.+?)\\*", options: []) {
            result = italicRegex.stringByReplacingMatches(
                in: result,
                range: NSRange(result.startIndex..., in: result),
                withTemplate: "$1"
            )
        }

        // Remove markdown headers (### Header → Header)
        if let headerRegex = try? NSRegularExpression(pattern: "^#{1,6}\\s+", options: .anchorsMatchLines) {
            result = headerRegex.stringByReplacingMatches(
                in: result,
                range: NSRange(result.startIndex..., in: result),
                withTemplate: ""
            )
        }

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
    case invalidRequest
    case timeout
    case networkError
    case payloadTooLarge
    case apiError(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .noResponse:
            return "No response from Gemini"
        case .invalidAudio:
            return "Invalid audio"
        case .invalidRequest:
            return "Invalid request"
        case .timeout:
            return "Request timed out. Try a shorter recording."
        case .networkError:
            return "Network error. Check your internet connection."
        case .payloadTooLarge:
            return "Recording too long for direct upload."
        case .apiError(let statusCode, let message):
            return "API error (\(statusCode)): \(message)"
        }
    }
}
