import Foundation
import Combine

/// Gerencia estatísticas de uso e tempo economizado
class AnalyticsManager: ObservableObject {
    static let shared = AnalyticsManager()
    
    private let defaults = UserDefaults.standard
    private let calendar = Calendar.current
    
    // MARK: - Keys
    private enum Keys {
        static let totalTranscriptions = "analytics_total_transcriptions"
        static let totalCharacters = "analytics_total_characters"
        static let timeSavedMinutes = "analytics_time_saved_minutes"
        static let monthlyStats = "analytics_monthly_stats"
        static let firstUseDate = "analytics_first_use_date"
        static let totalRecordingTime = "analytics_total_recording_time"
        static let modeUsage = "analytics_mode_usage"
    }
    
    // MARK: - Published Properties
    @Published private(set) var totalTranscriptions: Int
    @Published private(set) var totalCharacters: Int
    @Published private(set) var timeSavedMinutes: Double
    @Published private(set) var monthlyStats: [MonthlyStat]
    @Published private(set) var totalRecordingTime: Double // in seconds
    @Published private(set) var modeUsage: [String: Int] // mode rawValue -> count
    
    // Constantes para cálculo de tempo
    private let avgTypingSpeedWPM = 40.0  // Palavras por minuto médio
    private let avgWordLength = 5.0       // Caracteres por palavra
    
    struct MonthlyStat: Codable, Identifiable {
        var id = UUID()
        let month: String  // "2026-02"
        let transcriptions: Int
        let characters: Int
        let timeSavedMinutes: Double
        
        var formattedMonth: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM"
            guard let date = formatter.date(from: month) else { return month }
            
            formatter.dateFormat = "MMMM yyyy"
            formatter.locale = Locale(identifier: "pt_BR")
            return formatter.string(from: date).capitalized
        }
    }
    
    // MARK: - Init
    private init() {
        self.totalTranscriptions = defaults.integer(forKey: Keys.totalTranscriptions)
        self.totalCharacters = defaults.integer(forKey: Keys.totalCharacters)
        self.timeSavedMinutes = defaults.double(forKey: Keys.timeSavedMinutes)
        self.totalRecordingTime = defaults.double(forKey: Keys.totalRecordingTime)

        if let data = defaults.data(forKey: Keys.monthlyStats),
           let stats = try? JSONDecoder().decode([MonthlyStat].self, from: data) {
            self.monthlyStats = stats
        } else {
            self.monthlyStats = []
        }

        if let data = defaults.data(forKey: Keys.modeUsage),
           let usage = try? JSONDecoder().decode([String: Int].self, from: data) {
            self.modeUsage = usage
        } else {
            self.modeUsage = [:]
        }

        // Registrar primeira data de uso
        if defaults.object(forKey: Keys.firstUseDate) == nil {
            defaults.set(Date(), forKey: Keys.firstUseDate)
        }
    }
    
    // MARK: - Public Methods
    
    func recordTranscription(characters: Int, mode: TranscriptionMode? = nil, recordingDuration: Double = 0) {
        totalTranscriptions += 1
        totalCharacters += characters
        totalRecordingTime += recordingDuration

        // Record mode usage
        if let mode = mode {
            modeUsage[mode.rawValue, default: 0] += 1
        }

        // Calcular tempo economizado
        // Fórmula: (caracteres / avg_word_length) / WPM
        let words = Double(characters) / avgWordLength
        let minutesSaved = words / avgTypingSpeedWPM
        timeSavedMinutes += minutesSaved

        // Atualizar estatísticas mensais
        updateMonthlyStats(characters: characters, minutesSaved: minutesSaved)

        // Salvar
        save()
    }

    /// Returns the most used transcription mode
    var mostUsedMode: TranscriptionMode? {
        guard !modeUsage.isEmpty else { return nil }
        guard let maxEntry = modeUsage.max(by: { $0.value < $1.value }) else { return nil }
        return TranscriptionMode(rawValue: maxEntry.key)
    }
    
    func getFormattedTimeSaved() -> String {
        let hours = Int(timeSavedMinutes / 60)
        let minutes = Int(timeSavedMinutes.truncatingRemainder(dividingBy: 60))
        
        if hours > 0 {
            return "\(hours)h \(minutes)min"
        } else {
            return "\(minutes)min"
        }
    }
    
    func getAverageTranscriptionsPerDay() -> Double {
        guard let firstUse = defaults.object(forKey: Keys.firstUseDate) as? Date else { return 0 }
        let days = calendar.dateComponents([.day], from: firstUse, to: Date()).day ?? 1
        return Double(totalTranscriptions) / Double(max(days, 1))
    }
    
    func getCurrentMonthStats() -> MonthlyStat? {
        let currentMonth = getCurrentMonthString()
        return monthlyStats.first { $0.month == currentMonth }
    }
    
    // MARK: - Private Methods
    
    private func updateMonthlyStats(characters: Int, minutesSaved: Double) {
        let currentMonth = getCurrentMonthString()
        
        if let index = monthlyStats.firstIndex(where: { $0.month == currentMonth }) {
            // Atualizar mês existente
            let existing = monthlyStats[index]
            let updated = MonthlyStat(
                month: currentMonth,
                transcriptions: existing.transcriptions + 1,
                characters: existing.characters + characters,
                timeSavedMinutes: existing.timeSavedMinutes + minutesSaved
            )
            monthlyStats[index] = updated
        } else {
            // Criar novo mês
            let newStat = MonthlyStat(
                month: currentMonth,
                transcriptions: 1,
                characters: characters,
                timeSavedMinutes: minutesSaved
            )
            monthlyStats.append(newStat)
        }
        
        // Manter apenas últimos 12 meses
        if monthlyStats.count > 12 {
            monthlyStats.sort { $0.month > $1.month }
            monthlyStats = Array(monthlyStats.prefix(12))
        }
    }
    
    private func getCurrentMonthString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: Date())
    }
    
    private func save() {
        defaults.set(totalTranscriptions, forKey: Keys.totalTranscriptions)
        defaults.set(totalCharacters, forKey: Keys.totalCharacters)
        defaults.set(timeSavedMinutes, forKey: Keys.timeSavedMinutes)
        defaults.set(totalRecordingTime, forKey: Keys.totalRecordingTime)

        if let data = try? JSONEncoder().encode(monthlyStats) {
            defaults.set(data, forKey: Keys.monthlyStats)
        }

        if let data = try? JSONEncoder().encode(modeUsage) {
            defaults.set(data, forKey: Keys.modeUsage)
        }
    }
    
    func reset() {
        totalTranscriptions = 0
        totalCharacters = 0
        timeSavedMinutes = 0
        totalRecordingTime = 0
        modeUsage = [:]
        monthlyStats = []
        save()
    }
}
