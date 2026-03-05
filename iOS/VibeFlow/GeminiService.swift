import Foundation
import AVFoundation

/// Service to communicate with Google Gemini API for audio transcription
final class GeminiService {
    static let shared = GeminiService()

    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"

    private init() {}

    /// Transcribe audio data using Gemini API
    /// - Parameters:
    ///   - audioData: Audio data in supported format (m4a, wav, mp3)
    ///   - mode: Transcription mode to use
    ///   - language: Expected speech language
    ///   - translateToEnglish: Whether to translate output to English
    /// - Returns: Transcribed text
    func transcribe(
        audioData: Data,
        mode: TranscriptionMode,
        language: SpeechLanguage,
        translateToEnglish: Bool
    ) async throws -> String {
        let settings = SharedSettings.shared

        guard !settings.apiKey.isEmpty else {
            throw GeminiError.noAPIKey
        }

        let url = URL(string: "\(baseURL)?key=\(settings.apiKey)")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Build the prompt
        var prompt = mode.systemPrompt
        prompt += "\n\nExpected language: \(language.displayName)"

        if translateToEnglish && language != .english {
            prompt += "\n\nIMPORTANT: Translate the output to English."
        }

        prompt += "\n\nTranscribe the following audio:"

        // Build request body
        let base64Audio = audioData.base64EncodedString()

        let body: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt],
                        [
                            "inline_data": [
                                "mime_type": "audio/m4a",
                                "data": base64Audio
                            ]
                        ]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": mode.temperature,
                "maxOutputTokens": 2048
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw GeminiError.apiError(message)
            }
            throw GeminiError.httpError(httpResponse.statusCode)
        }

        // Parse response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            throw GeminiError.parseError
        }

        // Update statistics
        settings.incrementTranscriptions()

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Validate API key by making a simple request
    func validateAPIKey(_ key: String) async -> Bool {
        let url = URL(string: "\(baseURL)?key=\(key)")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": "Say 'OK' and nothing else."]
                    ]
                ]
            ],
            "generationConfig": [
                "maxOutputTokens": 10
            ]
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (_, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 200
            }
        } catch {
            return false
        }

        return false
    }
}

// MARK: - Errors

enum GeminiError: LocalizedError {
    case noAPIKey
    case invalidResponse
    case httpError(Int)
    case apiError(String)
    case parseError

    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "No API key configured. Please add your Gemini API key in the VibeFlow app."
        case .invalidResponse:
            return "Invalid response from server."
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .apiError(let message):
            return "API error: \(message)"
        case .parseError:
            return "Failed to parse response."
        }
    }
}
