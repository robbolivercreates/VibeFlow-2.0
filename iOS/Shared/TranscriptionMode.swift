import Foundation

/// Transcription modes available in VibeFlow
enum TranscriptionMode: String, CaseIterable, Codable {
    case code = "code"
    case text = "text"
    case email = "email"
    case uxDesign = "ux_design"

    var displayName: String {
        switch self {
        case .code: return "Code"
        case .text: return "Text"
        case .email: return "Email"
        case .uxDesign: return "UX Design"
        }
    }

    var icon: String {
        switch self {
        case .code: return "chevron.left.forwardslash.chevron.right"
        case .text: return "doc.text"
        case .email: return "envelope"
        case .uxDesign: return "paintbrush"
        }
    }

    var color: String {
        switch self {
        case .code: return "blue"
        case .text: return "green"
        case .email: return "orange"
        case .uxDesign: return "purple"
        }
    }

    var temperature: Float {
        switch self {
        case .code: return 0.1
        case .text: return 0.3
        case .email: return 0.4
        case .uxDesign: return 0.5
        }
    }

    var systemPrompt: String {
        switch self {
        case .code:
            return """
            You are a code transcription assistant. Convert spoken language into clean, functional code.

            Rules:
            - Output ONLY code, no explanations or markdown
            - Convert natural language like "function sum" to actual code: func sum()
            - Use proper syntax for the detected programming language
            - Remove filler words (um, uh, like, you know)
            - Be concise and precise
            """

        case .text:
            return """
            You are a text transcription assistant. Clean up spoken text into well-written prose.

            Rules:
            - Output ONLY the cleaned text, no explanations
            - Fix grammar and punctuation
            - Remove filler words and hesitations
            - Maintain the speaker's intent and meaning
            - Do not add content that wasn't spoken
            """

        case .email:
            return """
            You are an email transcription assistant. Format spoken content as professional emails.

            Rules:
            - Output ONLY the email content, no explanations
            - Use professional email formatting
            - Fix spelling and grammar
            - Maintain appropriate tone (formal/informal based on content)
            - Do not invent greetings or signatures unless spoken
            """

        case .uxDesign:
            return """
            You are a UX design transcription assistant. Convert spoken descriptions into structured UX documentation.

            Rules:
            - Output structured UX descriptions
            - Use proper UX terminology (components, flows, interactions)
            - Translate casual terms to professional UI/UX vocabulary
            - Format as clear, scannable bullet points when appropriate
            - Be concise but comprehensive
            """
        }
    }
}
