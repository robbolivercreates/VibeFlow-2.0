import Foundation

/// Proxies transcription through Supabase Edge Function (which calls Gemini server-side)
class SupabaseService {
    private let mode: TranscriptionMode
    private let outputLanguage: SpeechLanguage
    private let clarifyText: Bool

    init(mode: TranscriptionMode, outputLanguage: SpeechLanguage, clarifyText: Bool) {
        self.mode = mode
        self.outputLanguage = outputLanguage
        self.clarifyText = clarifyText
    }

    /// Transcribe audio via Supabase Edge Function
    func transcribeAudio(audioData: Data) async throws -> String {
        guard let token = AuthManager.shared.accessToken else {
            throw AuthError.notAuthenticated
        }

        let url = URL(string: "\(SupabaseConfig.url)/functions/v1/transcribe")!
        let audioBase64 = audioData.base64EncodedString()

        let systemPrompt = mode.systemPrompt(outputLanguage: outputLanguage, clarifyText: clarifyText, wakeWord: SettingsManager.shared.wakeWord)

        let body: [String: Any] = [
            "audio": audioBase64,
            "mode": mode.apiName,
            "language": outputLanguage.rawValue,
            "systemPrompt": systemPrompt,
            "temperature": mode.temperature,
            "maxOutputTokens": mode.maxOutputTokens
        ]

        return try await sendRequest(url: url, token: token, body: body)
    }

    /// Cleans up pre-transcribed text using the mode's system prompt (no audio).
    /// Used by Whisper-first pipeline: Whisper transcribes locally → this formats via Gemini.
    /// Sends ~85% fewer input tokens than sending raw audio.
    func cleanupText(_ rawText: String) async throws -> String {
        guard let token = AuthManager.shared.accessToken else {
            throw AuthError.notAuthenticated
        }

        let url = URL(string: "\(SupabaseConfig.url)/functions/v1/transcribe")!

        let systemPrompt = mode.systemPrompt(outputLanguage: outputLanguage, clarifyText: clarifyText, wakeWord: SettingsManager.shared.wakeWord)

        let body: [String: Any] = [
            "text": rawText,
            "mode": mode.apiName,
            "language": outputLanguage.rawValue,
            "systemPrompt": systemPrompt,
            "temperature": mode.temperature,
            "maxOutputTokens": mode.maxOutputTokens
        ]

        return try await sendRequest(url: url, token: token, body: body)
    }

    /// Transcribe audio with selected text (Command Mode) via Supabase Edge Function
    func transcribeWithSelectedText(audioData: Data, selectedText: String) async throws -> String {
        guard let token = AuthManager.shared.accessToken else {
            throw AuthError.notAuthenticated
        }

        let url = URL(string: "\(SupabaseConfig.url)/functions/v1/transcribe")!
        let audioBase64 = audioData.base64EncodedString()

        let systemPrompt = mode.systemPrompt(outputLanguage: outputLanguage, clarifyText: clarifyText, wakeWord: SettingsManager.shared.wakeWord)

        let body: [String: Any] = [
            "audio": audioBase64,
            "mode": mode.apiName,
            "language": outputLanguage.rawValue,
            "systemPrompt": systemPrompt,
            "temperature": mode.temperature,
            "maxOutputTokens": mode.maxOutputTokens,
            "selectedText": selectedText
        ]

        return try await sendRequest(url: url, token: token, body: body)
    }

    // MARK: - Conversation Reply

    /// Detects the source language and translates text. Text-only, no audio.
    /// Calls the same /transcribe edge function with {text, targetLanguage} instead of audio.
    static func detectAndTranslate(
        text: String,
        targetLanguage: SpeechLanguage
    ) async throws -> (translation: String, fromLanguageName: String, fromLanguageCode: String) {
        guard let token = AuthManager.shared.accessToken else {
            throw AuthError.notAuthenticated
        }

        let url = URL(string: "\(SupabaseConfig.url)/functions/v1/transcribe")!

        let body: [String: Any] = [
            "text": text,
            "targetLanguage": targetLanguage.displayName
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(DeviceManager.shared.deviceID, forHTTPHeaderField: "X-Device-ID")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            if code == 401 { throw AuthError.tokenExpired }
            throw SupabaseTranscriptionError.serverError("HTTP \(code)")
        }

        guard let json = try? JSONDecoder().decode(TranscriptionResponse.self, from: data),
              let rawText = json.text, !rawText.isEmpty else {
            throw SupabaseTranscriptionError.noTranscription
        }

        // Edge function returns the Gemini JSON string as `text`
        var jsonText = rawText
        if jsonText.hasPrefix("```") {
            jsonText = jsonText
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        guard let jsonData = jsonText.data(using: .utf8),
              let parsed = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let translation = parsed["translation"] as? String,
              let fromLanguageName = parsed["fromLanguageName"] as? String,
              let fromLanguageCode = parsed["fromLanguageCode"] as? String else {
            throw SupabaseTranscriptionError.serverError("Invalid translation response")
        }

        return (translation, fromLanguageName, fromLanguageCode.uppercased())
    }

    /// Transcribes audio and translates it to toLanguage.
    /// Uses the existing audio path with a translation-specific system prompt.
    func translateSpeechReply(audioData: Data, toLanguage: String) async throws -> String {
        guard let token = AuthManager.shared.accessToken else {
            throw AuthError.notAuthenticated
        }

        let url = URL(string: "\(SupabaseConfig.url)/functions/v1/transcribe")!
        let audioBase64 = audioData.base64EncodedString()

        let replySystemPrompt = """
        You are a professional translator.
        Transcribe the audio and immediately translate it to \(toLanguage).
        Output ONLY the translated text in \(toLanguage). No greeting, no explanation, no original text.
        """

        let body: [String: Any] = [
            "audio": audioBase64,
            "mode": "text",
            "systemPrompt": replySystemPrompt,
            "temperature": 0.2,
            "maxOutputTokens": 2048
        ]

        return try await sendRequest(url: url, token: token, body: body)
    }

    // MARK: - Vox Transform: Text-to-Text

    /// Transforms selected text based on a voice instruction via Supabase Edge Function.
    static func transformText(
        selectedText: String,
        instruction: String,
        mode: TranscriptionMode?,
        outputLanguage: SpeechLanguage
    ) async throws -> String {
        guard let token = AuthManager.shared.accessToken else {
            throw AuthError.notAuthenticated
        }

        let url = URL(string: "\(SupabaseConfig.url)/functions/v1/transcribe")!

        let systemPrompt: String
        if let mode = mode {
            systemPrompt = """
            You are an AI text transformation assistant. Rewrite the provided text in the style of "\(mode.localizedName)" mode.
            \(mode.systemPrompt(outputLanguage: outputLanguage, clarifyText: false)
                .replacingOccurrences(of: "O usuário está ditando", with: "O usuário selecionou um texto e quer")
                .replacingOccurrences(of: "Transcreva o áudio", with: "Reescreva o texto"))

            CRITICAL: Output ONLY the transformed text. No greetings, no explanations.
            Keep the output in \(outputLanguage.fullName).
            """
        } else {
            systemPrompt = """
            You are an AI text transformation assistant.
            The user selected text and gave this instruction: "\(instruction)"
            Execute the instruction on the provided text.
            Output ONLY the result. No greetings, no explanations.
            Output in \(outputLanguage.fullName) unless the instruction specifies otherwise.
            """
        }

        let body: [String: Any] = [
            "text": "[SELECTED TEXT]\n\(selectedText)\n[END SELECTED TEXT]\n\nExecute the transformation. Output ONLY the result:",
            "mode": mode?.apiName ?? "text",
            "systemPrompt": systemPrompt,
            "temperature": mode?.temperature ?? 0.3,
            "maxOutputTokens": mode?.maxOutputTokens ?? 2048
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(DeviceManager.shared.deviceID, forHTTPHeaderField: "X-Device-ID")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            if code == 401 { throw AuthError.tokenExpired }
            throw SupabaseTranscriptionError.serverError("Transform failed (HTTP \(code))")
        }

        guard let result = try? JSONDecoder().decode(TranscriptionResponse.self, from: data),
              let text = result.text, !text.isEmpty else {
            throw SupabaseTranscriptionError.noTranscription
        }

        // Update usage stats if available
        if let usage = result.usage {
            await MainActor.run {
                SubscriptionManager.shared.freeTranscriptionsUsed = usage.used
            }
        }

        // Clean markdown
        var cleaned = text
        cleaned = cleaned.replacingOccurrences(of: "```", with: "")
        let greetings = ["Aqui está:", "Aqui está o texto:", "Claro!", "Claro,", "Here is:", "Sure!"]
        for greeting in greetings {
            if cleaned.lowercased().hasPrefix(greeting.lowercased()) {
                cleaned = String(cleaned.dropFirst(greeting.count))
                break
            }
        }

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Private

    private func sendRequest(url: URL, token: String, body: [String: Any], isRetry: Bool = false) async throws -> String {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(DeviceManager.shared.deviceID, forHTTPHeaderField: "X-Device-ID")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 60

        let (data, response) = try await URLSession.shared.data(for: request)
        print("[Supabase] Response received, status: \((response as? HTTPURLResponse)?.statusCode ?? -1)")

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseTranscriptionError.noResponse
        }

        // Decode JSON first (all fields optional so this tolerates error bodies)
        // Fall back to raw body string if not valid JSON
        let result = try? JSONDecoder().decode(TranscriptionResponse.self, from: data)
        let rawBody = String(data: data, encoding: .utf8) ?? ""

        // Auto-refresh and retry once on 401
        if httpResponse.statusCode == 401 && !isRetry {
            await AuthManager.shared.refreshSession()
            if let newToken = AuthManager.shared.accessToken {
                print("[Supabase] Retrying with refreshed token...")
                return try await sendRequest(url: url, token: newToken, body: body, isRetry: true)
            }
            throw AuthError.tokenExpired
        }
        if httpResponse.statusCode == 401 {
            throw AuthError.tokenExpired
        }

        if httpResponse.statusCode == 429 {
            // 429 response has used/limit at root level (not inside usage)
            let usedCount = result?.used ?? result?.usage?.used ?? 0
            let limitCount = result?.limit ?? result?.usage?.limit ?? 100
            // Sync counter so the app shows the correct value
            await MainActor.run {
                SubscriptionManager.shared.freeTranscriptionsUsed = usedCount
            }
            throw SupabaseTranscriptionError.freeLimitReached(
                used: usedCount,
                limit: limitCount
            )
        }

        if httpResponse.statusCode == 403 {
            throw SupabaseTranscriptionError.proFeatureRequired(result?.error ?? "Pro feature")
        }

        if httpResponse.statusCode != 200 {
            // Include raw body so user sees the actual server error, not a cryptic JSON error
            let msg = result?.error ?? (rawBody.isEmpty ? "HTTP \(httpResponse.statusCode)" : "\(httpResponse.statusCode): \(rawBody.prefix(200))")
            throw SupabaseTranscriptionError.serverError(msg)
        }

        guard let text = result?.text, !text.isEmpty else {
            print("[Supabase] ❌ No text in response. Raw body: \(rawBody.prefix(300))")
            throw SupabaseTranscriptionError.noTranscription
        }

        print("[Supabase] ✅ Transcription: '\(text.prefix(80))' (\(text.count) chars)")

        // Update usage stats if available
        if let usage = result?.usage {
            await MainActor.run {
                SubscriptionManager.shared.freeTranscriptionsUsed = usage.used
            }
        }

        return cleanMarkdown(text)
    }

    /// Remove markdown code blocks and greetings (same as GeminiService)
    private func cleanMarkdown(_ text: String) -> String {
        var result = text

        let codeBlockPattern = "```[a-zA-Z]*\\n?"
        if let regex = try? NSRegularExpression(pattern: codeBlockPattern) {
            result = regex.stringByReplacingMatches(
                in: result,
                range: NSRange(result.startIndex..., in: result),
                withTemplate: ""
            )
        }

        result = result.replacingOccurrences(of: "```", with: "")

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

// MARK: - Errors

enum SupabaseTranscriptionError: LocalizedError {
    case noResponse
    case noTranscription
    case serverError(String)
    case freeLimitReached(used: Int, limit: Int)
    case proFeatureRequired(String)

    var errorDescription: String? {
        switch self {
        case .noResponse:
            return "No response from server"
        case .noTranscription:
            return "No transcription result"
        case .serverError(let msg):
            return "Server error: \(msg)"
        case .freeLimitReached(let used, let limit):
            return "Free limit reached (\(used)/\(limit)). Upgrade to Pro for unlimited."
        case .proFeatureRequired(let feature):
            return "\(feature) - Available on Pro plan only."
        }
    }
}
