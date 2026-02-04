import Foundation
import Combine

/// Manages writing style samples for personalization
class WritingStyleManager: ObservableObject {
    static let shared = WritingStyleManager()

    private let defaults = UserDefaults.standard
    private let samplesKey = "writing_style_samples"
    private let maxSamplesPerMode = 5
    private let minTextLength = 50

    @Published var samples: [StyleSample] = []

    struct StyleSample: Codable, Identifiable {
        let id: UUID
        let text: String
        let mode: TranscriptionMode
        let timestamp: Date

        init(text: String, mode: TranscriptionMode) {
            self.id = UUID()
            self.text = text
            self.mode = mode
            self.timestamp = Date()
        }
    }

    private init() {
        loadSamples()
    }

    // MARK: - Persistence

    private func loadSamples() {
        guard let data = defaults.data(forKey: samplesKey) else {
            samples = []
            return
        }

        do {
            samples = try JSONDecoder().decode([StyleSample].self, from: data)
        } catch {
            print("[WritingStyleManager] Failed to decode samples: \(error)")
            samples = []
        }
    }

    private func saveSamples() {
        do {
            let data = try JSONEncoder().encode(samples)
            defaults.set(data, forKey: samplesKey)
        } catch {
            print("[WritingStyleManager] Failed to encode samples: \(error)")
        }
    }

    // MARK: - Learning

    /// Records a successful transcription as a style sample
    func learnFromTranscription(_ text: String, mode: TranscriptionMode) {
        // Don't learn from command mode (it's transformations, not user's style)
        guard mode != .command else { return }

        // Only learn from sufficiently long text
        guard text.count >= minTextLength else { return }

        // Check if style learning is enabled
        guard SettingsManager.shared.enableStyleLearning else { return }

        // Create new sample
        let sample = StyleSample(text: text, mode: mode)
        samples.append(sample)

        // Prune old samples to keep only recent ones per mode
        pruneSamples()

        saveSamples()
        print("[WritingStyleManager] Learned new sample for \(mode.rawValue) mode (\(text.count) chars)")
    }

    private func pruneSamples() {
        // Group by mode
        var byMode: [TranscriptionMode: [StyleSample]] = [:]
        for sample in samples {
            byMode[sample.mode, default: []].append(sample)
        }

        // Keep only the most recent samples per mode
        var pruned: [StyleSample] = []
        for (_, modeSamples) in byMode {
            let sorted = modeSamples.sorted { $0.timestamp > $1.timestamp }
            pruned.append(contentsOf: sorted.prefix(maxSamplesPerMode))
        }

        samples = pruned
    }

    // MARK: - Prompt Generation

    /// Returns style samples for injection into prompts
    func getStylePrompt(for mode: TranscriptionMode) -> String? {
        guard SettingsManager.shared.enableStyleLearning else { return nil }

        let modeSamples = samples
            .filter { $0.mode == mode }
            .sorted { $0.timestamp > $1.timestamp }
            .prefix(3)

        guard !modeSamples.isEmpty else { return nil }

        var prompt = """

            WRITING STYLE PERSONALIZATION:
            Match the user's writing style based on these previous examples:

            """

        for (index, sample) in modeSamples.enumerated() {
            // Truncate very long samples
            let truncated = sample.text.count > 300
                ? String(sample.text.prefix(300)) + "..."
                : sample.text
            prompt += """

            Example \(index + 1):
            \(truncated)

            """
        }

        prompt += """

            Mimic their vocabulary, sentence structure, tone, and formatting preferences.
            """

        return prompt
    }

    // MARK: - Management

    /// Clears all learned style samples
    func clearAllSamples() {
        samples = []
        saveSamples()
        print("[WritingStyleManager] Cleared all style samples")
    }

    /// Clears samples for a specific mode
    func clearSamples(for mode: TranscriptionMode) {
        samples.removeAll { $0.mode == mode }
        saveSamples()
        print("[WritingStyleManager] Cleared style samples for \(mode.rawValue)")
    }

    /// Returns count of samples per mode
    func sampleCounts() -> [TranscriptionMode: Int] {
        var counts: [TranscriptionMode: Int] = [:]
        for sample in samples {
            counts[sample.mode, default: 0] += 1
        }
        return counts
    }

    /// Total number of samples
    var totalSamples: Int {
        samples.count
    }
}
