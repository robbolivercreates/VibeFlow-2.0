import Foundation

/// Formatador local de modos para uso offline (Whisper).
/// Pro users: formatação por modo baseada em regras.
/// Free users: apenas correção de pontuação.
struct LocalModeFormatter {

    // MARK: - Public API

    /// Formata texto Whisper de acordo com o modo selecionado (Pro offline)
    static func format(_ text: String, mode: TranscriptionMode) -> String {
        let cleaned = cleanSpeechArtifacts(text)

        switch mode {
        case .text:
            return formatText(cleaned)
        case .chat:
            return formatChat(cleaned)
        case .email:
            return formatEmail(cleaned)
        case .formal:
            return formatFormal(cleaned)
        case .social:
            return formatSocial(cleaned)
        case .xTweet:
            return formatTweet(cleaned)
        case .summary:
            return formatSummary(cleaned)
        case .topics:
            return formatTopics(cleaned)
        case .meeting:
            return formatMeeting(cleaned)
        case .code:
            return cleaned // Code is literal — don't transform
        case .vibeCoder:
            return formatVibeCoder(cleaned)
        case .translation:
            return formatText(cleaned) // No local translation possible
        case .creative:
            return formatCreative(cleaned)
        case .uxDesign:
            return formatUXDesign(cleaned)
        case .custom:
            return formatText(cleaned)
        }
    }

    /// Correção básica de pontuação (Free users)
    static func fixPunctuation(_ text: String) -> String {
        let cleaned = cleanSpeechArtifacts(text)
        return capitalizeSentences(ensureEndPunctuation(cleaned))
    }

    // MARK: - Speech Cleanup

    private static func cleanSpeechArtifacts(_ text: String) -> String {
        var result = text

        // Remove common speech fillers
        let fillers = [
            // English
            "\\buh\\b", "\\bum\\b", "\\bah\\b", "\\ber\\b", "\\bhmm\\b", "\\bhm\\b",
            "\\byou know\\b", "\\blike\\b(?=\\s*,)", "\\bso\\b(?=\\s*,)",
            // Portuguese
            "\\bahn\\b", "\\béé\\b", "\\btipo\\b(?=\\s*,)", "\\bné\\b(?=\\s*[,.])"
        ]

        for filler in fillers {
            if let regex = try? NSRegularExpression(pattern: filler, options: .caseInsensitive) {
                result = regex.stringByReplacingMatches(
                    in: result,
                    range: NSRange(result.startIndex..., in: result),
                    withTemplate: ""
                )
            }
        }

        // Remove double spaces
        while result.contains("  ") {
            result = result.replacingOccurrences(of: "  ", with: " ")
        }

        // Remove orphan commas from filler removal
        result = result.replacingOccurrences(of: " ,", with: ",")
        result = result.replacingOccurrences(of: ",,", with: ",")

        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Mode Formatters

    private static func formatText(_ text: String) -> String {
        let sentences = splitSentences(text)
        let capitalized = sentences.map { capitalizeSentence($0) }

        // Group into paragraphs (every ~3 sentences)
        var paragraphs: [String] = []
        var current: [String] = []
        for s in capitalized {
            current.append(s)
            if current.count >= 3 {
                paragraphs.append(current.joined(separator: " "))
                current = []
            }
        }
        if !current.isEmpty {
            paragraphs.append(current.joined(separator: " "))
        }

        return ensureEndPunctuation(paragraphs.joined(separator: "\n\n"))
    }

    private static func formatChat(_ text: String) -> String {
        // Chat: keep casual, minimal punctuation
        var result = text.trimmingCharacters(in: .whitespacesAndNewlines)
        // Lowercase first letter for casual feel (unless starts with "I" or proper noun)
        if let first = result.first, first.isUppercase, first != "I" {
            result = result.prefix(1).lowercased() + result.dropFirst()
        }
        return result
    }

    private static func formatEmail(_ text: String) -> String {
        let body = capitalizeSentences(ensureEndPunctuation(text))
        let lines = body.components(separatedBy: ". ")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        var paragraphs: [String] = []
        var current: [String] = []
        for line in lines {
            current.append(ensureEndPunctuation(line))
            if current.count >= 2 {
                paragraphs.append(current.joined(separator: " "))
                current = []
            }
        }
        if !current.isEmpty {
            paragraphs.append(current.joined(separator: " "))
        }

        let bodyText = paragraphs.joined(separator: "\n\n")
        return "Prezado(a),\n\n\(bodyText)\n\nAtenciosamente,"
    }

    private static func formatFormal(_ text: String) -> String {
        var result = text
        // Informal → Formal substitutions
        let substitutions: [(String, String)] = [
            ("\\bpra\\b", "para"),
            ("\\btá\\b", "está"),
            ("\\btô\\b", "estou"),
            ("\\bvô\\b", "vou"),
            ("\\ba gente\\b", "nós"),
            ("\\bque nem\\b", "assim como"),
            ("\\bdaí\\b", "então"),
            ("\\bnão é\\b", "não se trata de"),
            ("\\bmuito bom\\b", "excelente"),
            ("\\blegal\\b", "adequado"),
        ]

        for (pattern, replacement) in substitutions {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                result = regex.stringByReplacingMatches(
                    in: result,
                    range: NSRange(result.startIndex..., in: result),
                    withTemplate: replacement
                )
            }
        }

        return capitalizeSentences(ensureEndPunctuation(result))
    }

    private static func formatSocial(_ text: String) -> String {
        let sentences = splitSentences(text)
        guard !sentences.isEmpty else { return text }

        var lines: [String] = []

        // First sentence as hook
        if let first = sentences.first {
            lines.append(capitalizeSentence(ensureEndPunctuation(first)))
        }

        // Rest as short lines
        for s in sentences.dropFirst() {
            lines.append(capitalizeSentence(ensureEndPunctuation(s)))
        }

        // Add engagement CTA
        lines.append("\nO que você acha? 💬")

        return lines.joined(separator: "\n")
    }

    private static func formatTweet(_ text: String) -> String {
        let cleaned = capitalizeSentences(ensureEndPunctuation(text))
        // Truncate to 280 chars
        if cleaned.count > 280 {
            let truncated = String(cleaned.prefix(277))
            // Find last space to avoid cutting words
            if let lastSpace = truncated.lastIndex(of: " ") {
                return String(truncated[..<lastSpace]) + "..."
            }
            return truncated + "..."
        }
        return cleaned
    }

    private static func formatSummary(_ text: String) -> String {
        let sentences = splitSentences(text)
        // Keep ~30% of sentences (at least 1)
        let keepCount = max(1, sentences.count * 3 / 10)
        let kept = Array(sentences.prefix(keepCount))
        return capitalizeSentences(ensureEndPunctuation(kept.joined(separator: " ")))
    }

    private static func formatTopics(_ text: String) -> String {
        let sentences = splitSentences(text)
        let bullets = sentences.map { sentence in
            "• " + capitalizeSentence(ensureEndPunctuation(sentence.trimmingCharacters(in: .whitespaces)))
        }
        return bullets.joined(separator: "\n")
    }

    private static func formatMeeting(_ text: String) -> String {
        let sentences = splitSentences(text)

        var topics: [String] = []
        var actions: [String] = []

        let actionKeywords = ["precisa", "deve", "vai", "need", "will", "should",
                              "próximo passo", "next step", "ação", "action", "fazer"]

        for sentence in sentences {
            let lower = sentence.lowercased()
            if actionKeywords.contains(where: { lower.contains($0) }) {
                actions.append("• " + capitalizeSentence(ensureEndPunctuation(sentence.trimmingCharacters(in: .whitespaces))))
            } else {
                topics.append("• " + capitalizeSentence(ensureEndPunctuation(sentence.trimmingCharacters(in: .whitespaces))))
            }
        }

        var output = "ASSUNTOS DISCUTIDOS:\n"
        if topics.isEmpty {
            output += "• (Sem tópicos identificados)\n"
        } else {
            output += topics.joined(separator: "\n") + "\n"
        }

        output += "\nAÇÕES / PRÓXIMOS PASSOS:\n"
        if actions.isEmpty {
            output += "• (Sem ações identificadas)"
        } else {
            output += actions.joined(separator: "\n")
        }

        return output
    }

    private static func formatVibeCoder(_ text: String) -> String {
        // Remove fluff, keep it direct
        var result = text
        let fluffPatterns = [
            "\\beu quero que\\b", "\\beu preciso que\\b", "\\bpor favor\\b",
            "\\bi want you to\\b", "\\bi need you to\\b", "\\bplease\\b",
            "\\bpoderia\\b", "\\bcould you\\b"
        ]
        for pattern in fluffPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                result = regex.stringByReplacingMatches(
                    in: result,
                    range: NSRange(result.startIndex..., in: result),
                    withTemplate: ""
                )
            }
        }
        // Clean up spaces
        while result.contains("  ") {
            result = result.replacingOccurrences(of: "  ", with: " ")
        }
        return capitalizeSentence(ensureEndPunctuation(result.trimmingCharacters(in: .whitespacesAndNewlines)))
    }

    private static func formatCreative(_ text: String) -> String {
        let sentences = splitSentences(text)
        let capitalized = sentences.map { capitalizeSentence(ensureEndPunctuation($0)) }

        // Creative: each sentence gets its own line for rhythm
        return capitalized.joined(separator: "\n")
    }

    private static func formatUXDesign(_ text: String) -> String {
        let sentences = splitSentences(text)
        // Format as numbered steps
        let numbered = sentences.enumerated().map { index, sentence in
            "\(index + 1). " + capitalizeSentence(ensureEndPunctuation(sentence.trimmingCharacters(in: .whitespaces)))
        }
        return numbered.joined(separator: "\n")
    }

    // MARK: - Utility

    private static func splitSentences(_ text: String) -> [String] {
        let delimiters = CharacterSet(charactersIn: ".!?")
        let components = text.components(separatedBy: delimiters)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        return components
    }

    private static func capitalizeSentence(_ text: String) -> String {
        guard let first = text.first else { return text }
        return first.uppercased() + text.dropFirst()
    }

    private static func capitalizeSentences(_ text: String) -> String {
        // Capitalize after . ! ?
        var result = text
        let pattern = "([.!?])\\s+([a-záàãâéêíóôõúç])"
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let nsString = result as NSString
            let matches = regex.matches(in: result, range: NSRange(location: 0, length: nsString.length))
            for match in matches {
                let letterRange = match.range(at: 2)
                let nsResult = (result as NSString)
                let letter = nsResult.substring(with: letterRange).uppercased()
                result = nsResult.replacingCharacters(in: letterRange, with: letter)
            }
        }
        // Capitalize first character
        if let first = result.first, !first.isUppercase {
            result = first.uppercased() + result.dropFirst()
        }
        return result
    }

    private static func ensureEndPunctuation(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return trimmed }
        let lastChar = trimmed.last!
        if !".!?:".contains(lastChar) {
            return trimmed + "."
        }
        return trimmed
    }
}
