import Foundation
import Combine

/// Gerencia estatísticas de uso, gamificação e tempo economizado
class AnalyticsManager: ObservableObject {
    static let shared = AnalyticsManager()

    private let defaults = UserDefaults.standard
    private let calendar = Calendar.current

    // MARK: - Keys
    private enum Keys {
        static let totalTranscriptions = "analytics_total_transcriptions"
        static let totalCharacters = "analytics_total_characters"
        static let totalWords = "analytics_total_words"
        static let timeSavedMinutes = "analytics_time_saved_minutes"
        static let monthlyStats = "analytics_monthly_stats"
        static let firstUseDate = "analytics_first_use_date"
        static let totalRecordingTime = "analytics_total_recording_time"
        static let modeUsage = "analytics_mode_usage"
        static let lastUseDate = "analytics_last_use_date"
        static let currentStreak = "analytics_current_streak"
        static let longestStreak = "analytics_longest_streak"
        static let dailyUsage = "analytics_daily_usage"
        static let unlockedAchievements = "analytics_unlocked_achievements"
    }

    // MARK: - Published Properties
    @Published private(set) var totalTranscriptions: Int
    @Published private(set) var totalCharacters: Int
    @Published private(set) var totalWords: Int
    @Published private(set) var timeSavedMinutes: Double
    @Published private(set) var monthlyStats: [MonthlyStat]
    @Published private(set) var totalRecordingTime: Double // in seconds
    @Published private(set) var modeUsage: [String: Int] // mode rawValue -> count
    @Published private(set) var currentStreak: Int
    @Published private(set) var longestStreak: Int
    @Published private(set) var dailyUsage: [String: Int] // "yyyy-MM-dd" -> count
    @Published private(set) var unlockedAchievements: Set<String>

    // Constantes para cálculo de tempo
    private let avgTypingSpeedWPM = 40.0  // Palavras por minuto médio ao digitar
    private let avgWordLength = 5.0       // Caracteres por palavra

    // MARK: - Level System
    enum UserLevel: Int, CaseIterable {
        case iniciante = 1
        case aprendiz = 2
        case intermediario = 3
        case avancado = 4
        case expert = 5
        case mestre = 6
        case lenda = 7

        var name: String {
            switch self {
            case .iniciante: return "Iniciante"
            case .aprendiz: return "Aprendiz"
            case .intermediario: return "Intermediário"
            case .avancado: return "Avançado"
            case .expert: return "Expert"
            case .mestre: return "Mestre"
            case .lenda: return "Lenda"
            }
        }

        var icon: String {
            switch self {
            case .iniciante: return "star"
            case .aprendiz: return "star.leadinghalf.filled"
            case .intermediario: return "star.fill"
            case .avancado: return "star.circle"
            case .expert: return "star.circle.fill"
            case .mestre: return "crown"
            case .lenda: return "crown.fill"
            }
        }

        var minTranscriptions: Int {
            switch self {
            case .iniciante: return 0
            case .aprendiz: return 50
            case .intermediario: return 200
            case .avancado: return 500
            case .expert: return 1000
            case .mestre: return 2500
            case .lenda: return 5000
            }
        }

        var color: String {
            switch self {
            case .iniciante: return "gray"
            case .aprendiz: return "green"
            case .intermediario: return "blue"
            case .avancado: return "purple"
            case .expert: return "orange"
            case .mestre: return "red"
            case .lenda: return "yellow"
            }
        }

        static func forTranscriptions(_ count: Int) -> UserLevel {
            for level in Self.allCases.reversed() {
                if count >= level.minTranscriptions {
                    return level
                }
            }
            return .iniciante
        }
    }

    // MARK: - Achievements
    enum Achievement: String, CaseIterable {
        case firstTranscription = "first_transcription"
        case tenTranscriptions = "ten_transcriptions"
        case fiftyTranscriptions = "fifty_transcriptions"
        case hundredTranscriptions = "hundred_transcriptions"
        case fiveHundredTranscriptions = "five_hundred_transcriptions"
        case thousandTranscriptions = "thousand_transcriptions"

        case oneHourSaved = "one_hour_saved"
        case fiveHoursSaved = "five_hours_saved"
        case tenHoursSaved = "ten_hours_saved"
        case twentyFourHoursSaved = "twentyfour_hours_saved"

        case threeeDayStreak = "three_day_streak"
        case sevenDayStreak = "seven_day_streak"
        case thirtyDayStreak = "thirty_day_streak"
        case hundredDayStreak = "hundred_day_streak"

        case speedDemon = "speed_demon" // WPM > 150
        case prolificDay = "prolific_day" // 50+ transcriptions in a day
        case nightOwl = "night_owl" // Use after midnight
        case earlyBird = "early_bird" // Use before 6am

        case allModes = "all_modes" // Used all transcription modes
        case thousandWords = "thousand_words"
        case tenThousandWords = "ten_thousand_words"

        var name: String {
            switch self {
            case .firstTranscription: return "Primeira Voz"
            case .tenTranscriptions: return "Começando"
            case .fiftyTranscriptions: return "Engajado"
            case .hundredTranscriptions: return "Centenário"
            case .fiveHundredTranscriptions: return "Veterano"
            case .thousandTranscriptions: return "Milésimo"
            case .oneHourSaved: return "Hora Poupada"
            case .fiveHoursSaved: return "Meio Expediente"
            case .tenHoursSaved: return "Dia Inteiro"
            case .twentyFourHoursSaved: return "Dia Completo"
            case .threeeDayStreak: return "Trinca"
            case .sevenDayStreak: return "Semana Perfeita"
            case .thirtyDayStreak: return "Mês Dedicado"
            case .hundredDayStreak: return "Centurião"
            case .speedDemon: return "Velocista"
            case .prolificDay: return "Dia Produtivo"
            case .nightOwl: return "Coruja"
            case .earlyBird: return "Madrugador"
            case .allModes: return "Versátil"
            case .thousandWords: return "Mil Palavras"
            case .tenThousandWords: return "Escritor"
            }
        }

        var description: String {
            switch self {
            case .firstTranscription: return "Fez sua primeira transcrição"
            case .tenTranscriptions: return "Completou 10 transcrições"
            case .fiftyTranscriptions: return "Completou 50 transcrições"
            case .hundredTranscriptions: return "Completou 100 transcrições"
            case .fiveHundredTranscriptions: return "Completou 500 transcrições"
            case .thousandTranscriptions: return "Completou 1000 transcrições"
            case .oneHourSaved: return "Economizou 1 hora de digitação"
            case .fiveHoursSaved: return "Economizou 5 horas de digitação"
            case .tenHoursSaved: return "Economizou 10 horas de digitação"
            case .twentyFourHoursSaved: return "Economizou 24 horas de digitação"
            case .threeeDayStreak: return "Usou 3 dias seguidos"
            case .sevenDayStreak: return "Usou 7 dias seguidos"
            case .thirtyDayStreak: return "Usou 30 dias seguidos"
            case .hundredDayStreak: return "Usou 100 dias seguidos"
            case .speedDemon: return "Falou mais de 150 palavras por minuto"
            case .prolificDay: return "Fez 50+ transcrições em um dia"
            case .nightOwl: return "Usou após meia-noite"
            case .earlyBird: return "Usou antes das 6h da manhã"
            case .allModes: return "Usou todos os modos de transcrição"
            case .thousandWords: return "Transcreveu 1000 palavras"
            case .tenThousandWords: return "Transcreveu 10000 palavras"
            }
        }

        var icon: String {
            switch self {
            case .firstTranscription: return "mic.fill"
            case .tenTranscriptions: return "10.circle.fill"
            case .fiftyTranscriptions: return "50.circle.fill"
            case .hundredTranscriptions: return "100.circle.fill"
            case .fiveHundredTranscriptions: return "star.fill"
            case .thousandTranscriptions: return "crown.fill"
            case .oneHourSaved: return "clock.fill"
            case .fiveHoursSaved: return "clock.badge.checkmark.fill"
            case .tenHoursSaved: return "deskclock.fill"
            case .twentyFourHoursSaved: return "24.circle.fill"
            case .threeeDayStreak: return "flame"
            case .sevenDayStreak: return "flame.fill"
            case .thirtyDayStreak: return "flame.circle"
            case .hundredDayStreak: return "flame.circle.fill"
            case .speedDemon: return "hare.fill"
            case .prolificDay: return "bolt.fill"
            case .nightOwl: return "moon.fill"
            case .earlyBird: return "sunrise.fill"
            case .allModes: return "square.grid.2x2.fill"
            case .thousandWords: return "text.word.spacing"
            case .tenThousandWords: return "books.vertical.fill"
            }
        }
    }

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
        self.totalWords = defaults.integer(forKey: Keys.totalWords)
        self.timeSavedMinutes = defaults.double(forKey: Keys.timeSavedMinutes)
        self.totalRecordingTime = defaults.double(forKey: Keys.totalRecordingTime)
        self.currentStreak = defaults.integer(forKey: Keys.currentStreak)
        self.longestStreak = defaults.integer(forKey: Keys.longestStreak)

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

        if let data = defaults.data(forKey: Keys.dailyUsage),
           let usage = try? JSONDecoder().decode([String: Int].self, from: data) {
            self.dailyUsage = usage
        } else {
            self.dailyUsage = [:]
        }

        if let data = defaults.data(forKey: Keys.unlockedAchievements),
           let achievements = try? JSONDecoder().decode(Set<String>.self, from: data) {
            self.unlockedAchievements = achievements
        } else {
            self.unlockedAchievements = []
        }

        // Registrar primeira data de uso
        if defaults.object(forKey: Keys.firstUseDate) == nil {
            defaults.set(Date(), forKey: Keys.firstUseDate)
        }

        // Check and update streak on init
        updateStreakOnLoad()
    }

    // MARK: - Public Methods

    func recordTranscription(characters: Int, mode: TranscriptionMode? = nil, recordingDuration: Double = 0) {
        totalTranscriptions += 1
        totalCharacters += characters
        totalRecordingTime += recordingDuration

        // Calculate words
        let words = Int(Double(characters) / avgWordLength)
        totalWords += words

        // Record mode usage
        if let mode = mode {
            modeUsage[mode.rawValue, default: 0] += 1
        }

        // Calcular tempo economizado
        // Fórmula: (caracteres / avg_word_length) / WPM
        let wordsDouble = Double(characters) / avgWordLength
        let minutesSaved = wordsDouble / avgTypingSpeedWPM
        timeSavedMinutes += minutesSaved

        // Update daily usage and streak
        updateDailyUsage()

        // Atualizar estatísticas mensais
        updateMonthlyStats(characters: characters, minutesSaved: minutesSaved)

        // Check achievements
        checkAchievements(recordingDuration: recordingDuration, words: words)

        // Salvar
        save()
    }

    // MARK: - Gamification Computed Properties

    /// Current user level based on total transcriptions
    var currentLevel: UserLevel {
        UserLevel.forTranscriptions(totalTranscriptions)
    }

    /// Progress to next level (0.0 - 1.0)
    var levelProgress: Double {
        let current = currentLevel
        let allLevels = UserLevel.allCases
        guard let currentIndex = allLevels.firstIndex(of: current),
              currentIndex < allLevels.count - 1 else {
            return 1.0 // Max level
        }
        let nextLevel = allLevels[currentIndex + 1]
        let progress = Double(totalTranscriptions - current.minTranscriptions) /
                       Double(nextLevel.minTranscriptions - current.minTranscriptions)
        return min(max(progress, 0), 1)
    }

    /// Transcriptions needed for next level
    var transcriptionsToNextLevel: Int {
        let current = currentLevel
        let allLevels = UserLevel.allCases
        guard let currentIndex = allLevels.firstIndex(of: current),
              currentIndex < allLevels.count - 1 else {
            return 0 // Max level
        }
        let nextLevel = allLevels[currentIndex + 1]
        return nextLevel.minTranscriptions - totalTranscriptions
    }

    /// Average speaking speed in words per minute (based on real data)
    var averageSpeakingWPM: Double {
        guard totalRecordingTime > 0 else { return 0 }
        let minutes = totalRecordingTime / 60.0
        return Double(totalWords) / minutes
    }

    /// Efficiency multiplier: how many times faster than typing
    var efficiencyMultiplier: Double {
        guard averageSpeakingWPM > 0 else { return 0 }
        return averageSpeakingWPM / avgTypingSpeedWPM
    }

    /// Today's transcription count
    var todayTranscriptions: Int {
        let today = getTodayString()
        return dailyUsage[today] ?? 0
    }

    /// Returns the most used transcription mode
    var mostUsedMode: TranscriptionMode? {
        guard !modeUsage.isEmpty else { return nil }
        guard let maxEntry = modeUsage.max(by: { $0.value < $1.value }) else { return nil }
        return TranscriptionMode(rawValue: maxEntry.key)
    }

    /// Number of days using the app
    var daysUsingApp: Int {
        guard let firstUse = defaults.object(forKey: Keys.firstUseDate) as? Date else { return 1 }
        let days = calendar.dateComponents([.day], from: firstUse, to: Date()).day ?? 1
        return max(days, 1)
    }

    /// Sorted achievements (unlocked first)
    var sortedAchievements: [Achievement] {
        Achievement.allCases.sorted { a, b in
            let aUnlocked = unlockedAchievements.contains(a.rawValue)
            let bUnlocked = unlockedAchievements.contains(b.rawValue)
            if aUnlocked != bUnlocked {
                return aUnlocked
            }
            return a.rawValue < b.rawValue
        }
    }

    /// Unlocked achievement count
    var unlockedAchievementCount: Int {
        unlockedAchievements.count
    }

    /// Total achievement count
    var totalAchievementCount: Int {
        Achievement.allCases.count
    }

    func isAchievementUnlocked(_ achievement: Achievement) -> Bool {
        unlockedAchievements.contains(achievement.rawValue)
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

    func getFormattedRecordingTime() -> String {
        let totalMinutes = Int(totalRecordingTime / 60)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 {
            return "\(hours)h \(minutes)min"
        } else {
            return "\(minutes)min"
        }
    }

    func getAverageTranscriptionsPerDay() -> Double {
        return Double(totalTranscriptions) / Double(daysUsingApp)
    }

    func getCurrentMonthStats() -> MonthlyStat? {
        let currentMonth = getCurrentMonthString()
        return monthlyStats.first { $0.month == currentMonth }
    }

    // MARK: - Private Methods

    private func updateStreakOnLoad() {
        let today = getTodayString()
        let yesterday = getYesterdayString()

        guard let lastUseString = defaults.string(forKey: Keys.lastUseDate) else {
            // First time use
            return
        }

        if lastUseString != today && lastUseString != yesterday {
            // Streak broken
            currentStreak = 0
            save()
        }
    }

    private func updateDailyUsage() {
        let today = getTodayString()
        let yesterday = getYesterdayString()
        let previousCount = dailyUsage[today] ?? 0

        dailyUsage[today] = previousCount + 1

        // Update streak
        let lastUseString = defaults.string(forKey: Keys.lastUseDate)

        if lastUseString != today {
            // First transcription of the day
            if lastUseString == yesterday {
                // Continuing streak
                currentStreak += 1
            } else if lastUseString == nil {
                // First ever use
                currentStreak = 1
            } else {
                // Streak was broken, starting new
                currentStreak = 1
            }

            if currentStreak > longestStreak {
                longestStreak = currentStreak
            }
        }

        defaults.set(today, forKey: Keys.lastUseDate)

        // Clean up old daily data (keep last 90 days)
        cleanupOldDailyData()
    }

    private func cleanupOldDailyData() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let cutoffDate = calendar.date(byAdding: .day, value: -90, to: Date()) ?? Date()

        dailyUsage = dailyUsage.filter { key, _ in
            guard let date = formatter.date(from: key) else { return false }
            return date >= cutoffDate
        }
    }

    private func checkAchievements(recordingDuration: Double, words: Int) {
        var newAchievements: [Achievement] = []

        // Transcription milestones
        if totalTranscriptions >= 1 && !isAchievementUnlocked(.firstTranscription) {
            newAchievements.append(.firstTranscription)
        }
        if totalTranscriptions >= 10 && !isAchievementUnlocked(.tenTranscriptions) {
            newAchievements.append(.tenTranscriptions)
        }
        if totalTranscriptions >= 50 && !isAchievementUnlocked(.fiftyTranscriptions) {
            newAchievements.append(.fiftyTranscriptions)
        }
        if totalTranscriptions >= 100 && !isAchievementUnlocked(.hundredTranscriptions) {
            newAchievements.append(.hundredTranscriptions)
        }
        if totalTranscriptions >= 500 && !isAchievementUnlocked(.fiveHundredTranscriptions) {
            newAchievements.append(.fiveHundredTranscriptions)
        }
        if totalTranscriptions >= 1000 && !isAchievementUnlocked(.thousandTranscriptions) {
            newAchievements.append(.thousandTranscriptions)
        }

        // Time saved milestones
        if timeSavedMinutes >= 60 && !isAchievementUnlocked(.oneHourSaved) {
            newAchievements.append(.oneHourSaved)
        }
        if timeSavedMinutes >= 300 && !isAchievementUnlocked(.fiveHoursSaved) {
            newAchievements.append(.fiveHoursSaved)
        }
        if timeSavedMinutes >= 600 && !isAchievementUnlocked(.tenHoursSaved) {
            newAchievements.append(.tenHoursSaved)
        }
        if timeSavedMinutes >= 1440 && !isAchievementUnlocked(.twentyFourHoursSaved) {
            newAchievements.append(.twentyFourHoursSaved)
        }

        // Streak milestones
        if currentStreak >= 3 && !isAchievementUnlocked(.threeeDayStreak) {
            newAchievements.append(.threeeDayStreak)
        }
        if currentStreak >= 7 && !isAchievementUnlocked(.sevenDayStreak) {
            newAchievements.append(.sevenDayStreak)
        }
        if currentStreak >= 30 && !isAchievementUnlocked(.thirtyDayStreak) {
            newAchievements.append(.thirtyDayStreak)
        }
        if currentStreak >= 100 && !isAchievementUnlocked(.hundredDayStreak) {
            newAchievements.append(.hundredDayStreak)
        }

        // Speed achievement (check this transcription's WPM)
        if recordingDuration > 0 {
            let thisWPM = (Double(words) / recordingDuration) * 60
            if thisWPM > 150 && !isAchievementUnlocked(.speedDemon) {
                newAchievements.append(.speedDemon)
            }
        }

        // Daily prolific
        let today = getTodayString()
        if (dailyUsage[today] ?? 0) >= 50 && !isAchievementUnlocked(.prolificDay) {
            newAchievements.append(.prolificDay)
        }

        // Time-based achievements
        let hour = calendar.component(.hour, from: Date())
        if hour >= 0 && hour < 5 && !isAchievementUnlocked(.nightOwl) {
            newAchievements.append(.nightOwl)
        }
        if hour >= 5 && hour < 6 && !isAchievementUnlocked(.earlyBird) {
            newAchievements.append(.earlyBird)
        }

        // All modes
        let allModes = TranscriptionMode.allCases
        let usedModes = modeUsage.keys.count
        if usedModes >= allModes.count && !isAchievementUnlocked(.allModes) {
            newAchievements.append(.allModes)
        }

        // Word milestones
        if totalWords >= 1000 && !isAchievementUnlocked(.thousandWords) {
            newAchievements.append(.thousandWords)
        }
        if totalWords >= 10000 && !isAchievementUnlocked(.tenThousandWords) {
            newAchievements.append(.tenThousandWords)
        }

        // Unlock new achievements
        for achievement in newAchievements {
            unlockedAchievements.insert(achievement.rawValue)
            // Could post notification for UI to show achievement popup
            NotificationCenter.default.post(name: .achievementUnlocked, object: achievement)
        }
    }

    private func getTodayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    private func getYesterdayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        return formatter.string(from: yesterday)
    }

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
        defaults.set(totalWords, forKey: Keys.totalWords)
        defaults.set(timeSavedMinutes, forKey: Keys.timeSavedMinutes)
        defaults.set(totalRecordingTime, forKey: Keys.totalRecordingTime)
        defaults.set(currentStreak, forKey: Keys.currentStreak)
        defaults.set(longestStreak, forKey: Keys.longestStreak)

        if let data = try? JSONEncoder().encode(monthlyStats) {
            defaults.set(data, forKey: Keys.monthlyStats)
        }

        if let data = try? JSONEncoder().encode(modeUsage) {
            defaults.set(data, forKey: Keys.modeUsage)
        }

        if let data = try? JSONEncoder().encode(dailyUsage) {
            defaults.set(data, forKey: Keys.dailyUsage)
        }

        if let data = try? JSONEncoder().encode(unlockedAchievements) {
            defaults.set(data, forKey: Keys.unlockedAchievements)
        }
    }

    func reset() {
        totalTranscriptions = 0
        totalCharacters = 0
        totalWords = 0
        timeSavedMinutes = 0
        totalRecordingTime = 0
        currentStreak = 0
        longestStreak = 0
        modeUsage = [:]
        monthlyStats = []
        dailyUsage = [:]
        unlockedAchievements = []
        defaults.removeObject(forKey: Keys.lastUseDate)
        save()
    }
}

// MARK: - Notifications
extension Notification.Name {
    static let achievementUnlocked = Notification.Name("achievementUnlocked")
}
