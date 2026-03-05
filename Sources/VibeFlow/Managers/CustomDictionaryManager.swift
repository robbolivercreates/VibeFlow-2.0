import Foundation
import Combine

/// Manages the user's custom dictionary for word corrections and forbidden terms.
/// Entries are injected into every Gemini prompt so the AI knows the user's preferred terminology.
class CustomDictionaryManager: ObservableObject {
    static let shared = CustomDictionaryManager()

    private let defaults = UserDefaults.standard
    private let replacementsKey = "custom_dictionary_replacements"
    private let forbiddenKey = "custom_dictionary_forbidden"

    /// Word replacement: "Robinson" → "Robson"
    struct WordReplacement: Codable, Identifiable, Equatable {
        let id: UUID
        var wrong: String
        var correct: String

        init(wrong: String, correct: String) {
            self.id = UUID()
            self.wrong = wrong
            self.correct = correct
        }
    }

    /// Forbidden word: never use this term
    struct ForbiddenWord: Codable, Identifiable, Equatable {
        let id: UUID
        var word: String

        init(word: String) {
            self.id = UUID()
            self.word = word
        }
    }

    @Published var replacements: [WordReplacement] = []
    @Published var forbidden: [ForbiddenWord] = []

    private init() {
        loadReplacements()
        loadForbidden()
    }

    // MARK: - Persistence

    private func loadReplacements() {
        guard let data = defaults.data(forKey: replacementsKey) else { return }
        replacements = (try? JSONDecoder().decode([WordReplacement].self, from: data)) ?? []
    }

    private func loadForbidden() {
        guard let data = defaults.data(forKey: forbiddenKey) else { return }
        forbidden = (try? JSONDecoder().decode([ForbiddenWord].self, from: data)) ?? []
    }

    private func saveReplacements() {
        if let data = try? JSONEncoder().encode(replacements) {
            defaults.set(data, forKey: replacementsKey)
        }
    }

    private func saveForbidden() {
        if let data = try? JSONEncoder().encode(forbidden) {
            defaults.set(data, forKey: forbiddenKey)
        }
    }

    // MARK: - Management

    func addReplacement(wrong: String, correct: String) {
        let trimmedWrong = wrong.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCorrect = correct.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedWrong.isEmpty, !trimmedCorrect.isEmpty else { return }

        // Don't add duplicates
        guard !replacements.contains(where: { $0.wrong.lowercased() == trimmedWrong.lowercased() }) else { return }

        replacements.append(WordReplacement(wrong: trimmedWrong, correct: trimmedCorrect))
        saveReplacements()
        print("[CustomDictionary] Added replacement: '\(trimmedWrong)' → '\(trimmedCorrect)'")
    }

    func removeReplacement(_ replacement: WordReplacement) {
        replacements.removeAll { $0.id == replacement.id }
        saveReplacements()
    }

    func addForbidden(word: String) {
        let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard !forbidden.contains(where: { $0.word.lowercased() == trimmed.lowercased() }) else { return }

        forbidden.append(ForbiddenWord(word: trimmed))
        saveForbidden()
        print("[CustomDictionary] Added forbidden word: '\(trimmed)'")
    }

    func removeForbidden(_ word: ForbiddenWord) {
        forbidden.removeAll { $0.id == word.id }
        saveForbidden()
    }

    func clearAll() {
        replacements = []
        forbidden = []
        saveReplacements()
        saveForbidden()
        print("[CustomDictionary] Cleared all entries")
    }

    // MARK: - Prompt Generation

    /// Returns the dictionary prompt to inject into Gemini system prompts.
    /// Returns nil if the dictionary is empty.
    func getDictionaryPrompt() -> String? {
        guard !replacements.isEmpty || !forbidden.isEmpty else { return nil }

        var prompt = """

            USER'S CUSTOM DICTIONARY (CRITICAL — always apply these rules):

            """

        if !replacements.isEmpty {
            prompt += """

            WORD CORRECTIONS (always replace the wrong word with the correct one):

            """
            for r in replacements {
                prompt += "- \"\(r.wrong)\" → ALWAYS write \"\(r.correct)\" instead\n"
            }
        }

        if !forbidden.isEmpty {
            prompt += """

            FORBIDDEN WORDS (NEVER use these words or phrases in your output):

            """
            for f in forbidden {
                prompt += "- NEVER use \"\(f.word)\"\n"
            }
        }

        return prompt
    }

    var totalEntries: Int {
        replacements.count + forbidden.count
    }
}
