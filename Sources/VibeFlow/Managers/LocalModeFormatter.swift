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
            if SettingsManager.shared.textFormalTone {
                return formatFormal(cleaned)
            }
            return formatText(cleaned)
        case .chat:
            return formatChat(cleaned)
        case .email:
            return formatEmail(cleaned)
        case .social:
            if SettingsManager.shared.socialTweetMode {
                return formatTweet(cleaned)
            }
            return formatSocial(cleaned)
        case .summary:
            if SettingsManager.shared.summaryBulletFormat {
                return formatTopics(cleaned)
            }
            return formatSummary(cleaned)
        case .meeting:
            return formatMeeting(cleaned)
        case .code:
            return formatCode(cleaned)
        case .vibeCoder:
            return formatVibeCoder(cleaned)
        case .creative:
            return formatCreative(cleaned)
        case .uxDesign:
            return formatUXDesign(cleaned)
        case .custom:
            return formatText(cleaned)
        case .translation:
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
            "\\buh\\b", "\\bum\\b", "\\blike\\b", "\\byou know\\b",
            "\\bactually\\b", "\\bbasically\\b",
            // Portuguese
            "\\bné\\b", "\\bne\\b", "\\btipo\\b", "\\bassim\\b",
            "\\bentão\\b", "\\bé\\b", "\\bah\\b", "\\bhm\\b",
            "\\bquer dizer\\b"
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

        // Clean up extra spaces
        while result.contains("  ") {
            result = result.replacingOccurrences(of: "  ", with: " ")
        }
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
        for sentence in capitalized {
            current.append(sentence)
            if current.count >= 3 {
                paragraphs.append(current.joined(separator: " "))
                current = []
            }
        }
        if !current.isEmpty {
            paragraphs.append(current.joined(separator: " "))
        }

        return paragraphs.joined(separator: "\n\n")
    }

    private static func formatChat(_ text: String) -> String {
        var result = ensureEndPunctuation(text)
        // Chat: lowercase first letter (casual)
        if let first = result.first, first.isUppercase, first != "I" {
            result = result.prefix(1).lowercased() + result.dropFirst()
        }
        return result
    }

    private static func formatEmail(_ text: String) -> String {
        let body = capitalizeSentences(ensureEndPunctuation(text))
        let lines = body.components(separatedBy: ". ")
            .map { $0.trimmingCharacters(in: .whitespaces) }

        // Group by ~2 sentences per paragraph
        var paragraphs: [String] = []
        var current: [String] = []
        for line in lines {
            current.append(line)
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
            ("\\bto\\b", "estou"),
            ("\\ba gente\\b", "nós"),
            ("\\bvc\\b", "você"),
            ("\\bvcs\\b", "vocês"),
            ("\\btbm\\b", "também"),
            ("\\bblz\\b", "beleza"),
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
        if let hook = sentences.first {
            lines.append(capitalizeSentence(ensureEndPunctuation(hook)))
        }

        // Remaining as body (one per line)
        for sentence in sentences.dropFirst() {
            lines.append(capitalizeSentence(ensureEndPunctuation(sentence)))
        }

        return lines.joined(separator: "\n")
    }

    private static func formatTweet(_ text: String) -> String {
        let cleaned = capitalizeSentences(ensureEndPunctuation(text))
        if cleaned.count <= 280 { return cleaned }

        // Truncate at 277 chars + "..."
        let truncated = String(cleaned.prefix(277))
        if let lastSpace = truncated.lastIndex(of: " ") {
            return String(truncated[..<lastSpace]) + "..."
        }
        return truncated + "..."
    }

    private static func formatSummary(_ text: String) -> String {
        let sentences = splitSentences(text)
        // Keep ~30% of sentences (at least 1)
        let keepCount = max(1, sentences.count * 3 / 10)
        let kept = Array(sentences.prefix(keepCount))
        return kept.map { capitalizeSentence(ensureEndPunctuation($0)) }.joined(separator: " ")
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

        for sentence in sentences {
            let lower = sentence.lowercased()
            if lower.contains("fazer") || lower.contains("precis") ||
               lower.contains("ação") || lower.contains("próximo") ||
               lower.contains("do") || lower.contains("need") ||
               lower.contains("action") || lower.contains("next") {
                actions.append("• " + capitalizeSentence(ensureEndPunctuation(sentence)))
            } else {
                topics.append("• " + capitalizeSentence(ensureEndPunctuation(sentence)))
            }
        }

        var output = "ASSUNTOS DISCUTIDOS:\n"
        output += topics.isEmpty ? "• (Sem tópicos identificados)" : topics.joined(separator: "\n")

        output += "\n\nAÇÕES / PRÓXIMOS PASSOS:\n"
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
            "\\bpoderia\\b", "\\bgostaria que\\b", "\\bseria bom se\\b",
            "\\bi want you to\\b", "\\bi need you to\\b", "\\bplease\\b",
            "\\bcould you\\b", "\\bwould you\\b"
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
        return capitalizeSentence(ensureEndPunctuation(result.trimmingCharacters(in: .whitespacesAndNewlines)))
    }

    private static func formatCode(_ text: String) -> String {
        // For offline, just return cleaned text (no AI to interpret)
        return text
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
            "\(index + 1). " + capitalizeSentence(ensureEndPunctuation(sentence))
        }
        return numbered.joined(separator: "\n")
    }

    // MARK: - Helpers

    private static func splitSentences(_ text: String) -> [String] {
        let components = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
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
            let range = NSRange(result.startIndex..., in: result)
            result = regex.stringByReplacingMatches(in: result, range: range, withTemplate: "$1 $2")
        }
        // Capitalize first character
        if let first = result.first, first.isLowercase {
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
