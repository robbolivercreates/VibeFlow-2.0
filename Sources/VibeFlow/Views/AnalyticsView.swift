import SwiftUI

/// View de estatísticas e gamificação
struct AnalyticsView: View {
    @StateObject private var analytics = AnalyticsManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Estatísticas")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                Button("Fechar") {
                    dismiss()
                }
                .keyboardShortcut(.escape, modifiers: [])
            }
            .padding()

            // Tab Picker
            Picker("", selection: $selectedTab) {
                Text("Resumo").tag(0)
                Text("Conquistas").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            ScrollView {
                if selectedTab == 0 {
                    summaryTab
                } else {
                    achievementsTab
                }
            }
        }
        .frame(width: 520, height: 620)
    }

    // MARK: - Summary Tab

    private var summaryTab: some View {
        VStack(spacing: 20) {
            // Level Card
            levelCard
                .padding(.horizontal)
                .padding(.top)

            // Streak Card
            streakCard
                .padding(.horizontal)

            // Main Stats Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatCard2(
                    title: "Tempo Economizado",
                    value: analytics.getFormattedTimeSaved(),
                    icon: "clock.arrow.circlepath",
                    color: .green
                )

                StatCard2(
                    title: "Transcrições",
                    value: "\(analytics.totalTranscriptions)",
                    icon: "mic.fill",
                    color: .blue
                )

                StatCard2(
                    title: "Palavras",
                    value: formatNumber(analytics.totalWords),
                    icon: "text.word.spacing",
                    color: .purple
                )

                StatCard2(
                    title: "Tempo Gravado",
                    value: analytics.getFormattedRecordingTime(),
                    icon: "waveform",
                    color: .orange
                )
            }
            .padding(.horizontal)

            // Speed Stats
            speedStatsCard
                .padding(.horizontal)

            // Efficiency Message
            efficiencyMessage
                .padding(.horizontal)

            // Monthly Chart
            if !analytics.monthlyStats.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Tempo Economizado por Mês")
                        .font(.headline)
                        .padding(.horizontal)

                    MonthlyChart(stats: analytics.monthlyStats)
                        .frame(height: 180)
                        .padding(.horizontal)
                }
            }

            Spacer(minLength: 20)
        }
        .padding(.vertical)
    }

    // MARK: - Level Card

    private var levelCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: analytics.currentLevel.icon)
                    .font(.system(size: 28))
                    .foregroundStyle(levelColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Nível \(analytics.currentLevel.rawValue)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(analytics.currentLevel.name)
                        .font(.title2)
                        .fontWeight(.bold)
                }

                Spacer()

                if analytics.transcriptionsToNextLevel > 0 {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Próximo nível")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(analytics.transcriptionsToNextLevel) transcrições")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                } else {
                    Text("Nível Máximo!")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(.yellow)
                }
            }

            // Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(levelColor.gradient)
                        .frame(width: geo.size.width * analytics.levelProgress, height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(16)
    }

    private var levelColor: Color {
        switch analytics.currentLevel.color {
        case "gray": return .gray
        case "green": return .green
        case "blue": return .blue
        case "purple": return .purple
        case "orange": return .orange
        case "red": return .red
        case "yellow": return .yellow
        default: return .blue
        }
    }

    // MARK: - Streak Card

    private var streakCard: some View {
        HStack(spacing: 16) {
            // Current Streak
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(analytics.currentStreak > 0 ? .orange : .gray)
                    Text("\(analytics.currentStreak)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                }
                Text("Streak atual")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            Divider()
                .frame(height: 40)

            // Longest Streak
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "trophy.fill")
                        .foregroundStyle(.yellow)
                    Text("\(analytics.longestStreak)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                }
                Text("Maior streak")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)

            Divider()
                .frame(height: 40)

            // Today
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .foregroundStyle(.blue)
                    Text("\(analytics.todayTranscriptions)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                }
                Text("Hoje")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(16)
    }

    // MARK: - Speed Stats Card

    private var speedStatsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Velocidade")
                .font(.headline)

            HStack(spacing: 20) {
                // Speaking WPM
                VStack(spacing: 4) {
                    Text(String(format: "%.0f", analytics.averageSpeakingWPM))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.blue)
                    Text("WPM falando")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                // vs Typing
                VStack(spacing: 4) {
                    Text("40")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.gray)
                    Text("WPM digitando")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                // Multiplier
                VStack(spacing: 4) {
                    Text(String(format: "%.1fx", analytics.efficiencyMultiplier))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.green)
                    Text("mais rápido")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(16)
    }

    // MARK: - Efficiency Message

    private var efficiencyMessage: some View {
        HStack {
            Image(systemName: "lightbulb.fill")
                .foregroundStyle(.yellow)

            if analytics.timeSavedMinutes > 60 {
                let hours = Int(analytics.timeSavedMinutes / 60)
                Text("Você economizou **\(hours) hora\(hours > 1 ? "s" : "")** que seriam gastas digitando!")
                    .font(.subheadline)
            } else if analytics.timeSavedMinutes > 0 {
                let words = Int((analytics.timeSavedMinutes * 40))
                Text("Você economizou tempo equivalente a digitar **\(formatNumber(words)) palavras**!")
                    .font(.subheadline)
            } else {
                Text("Comece a usar o VibeFlow para ver quanto tempo você economiza!")
                    .font(.subheadline)
            }

            Spacer()
        }
        .padding()
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Achievements Tab

    private var achievementsTab: some View {
        VStack(spacing: 16) {
            // Achievement Counter
            HStack {
                Image(systemName: "medal.fill")
                    .foregroundStyle(.yellow)
                Text("\(analytics.unlockedAchievementCount) de \(analytics.totalAchievementCount) conquistas")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top)

            // Achievement Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(analytics.sortedAchievements, id: \.rawValue) { achievement in
                    AchievementCard(
                        achievement: achievement,
                        isUnlocked: analytics.isAchievementUnlocked(achievement)
                    )
                }
            }
            .padding(.horizontal)

            Spacer(minLength: 20)
        }
        .padding(.vertical)
    }

    // MARK: - Helpers

    private func formatNumber(_ number: Int) -> String {
        if number >= 1000 {
            return String(format: "%.1fk", Double(number) / 1000)
        }
        return "\(number)"
    }
}

// MARK: - Achievement Card

struct AchievementCard: View {
    let achievement: AnalyticsManager.Achievement
    let isUnlocked: Bool

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: achievement.icon)
                .font(.system(size: 24))
                .foregroundStyle(isUnlocked ? .yellow : .gray.opacity(0.4))

            Text(achievement.name)
                .font(.system(size: 12, weight: .semibold))
                .lineLimit(1)

            Text(achievement.description)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isUnlocked ? Color.yellow.opacity(0.1) : Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isUnlocked ? Color.yellow.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .opacity(isUnlocked ? 1 : 0.6)
    }
}

// MARK: - Stat Card

struct StatCard2: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(16)
    }
}

// MARK: - Monthly Chart

struct MonthlyChart: View {
    let stats: [AnalyticsManager.MonthlyStat]

    private var maxValue: Double {
        stats.map { $0.timeSavedMinutes }.max() ?? 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(stats.suffix(6)) { stat in
                    VStack(spacing: 4) {
                        // Value label
                        Text(formatMinutes(stat.timeSavedMinutes))
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)

                        // Bar
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.green.gradient)
                            .frame(width: 36, height: max(20, CGFloat(stat.timeSavedMinutes / maxValue) * 100))

                        // Month label
                        Text(shortMonth(stat.month))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(12)
        }
    }

    private func shortMonth(_ monthString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        guard let date = formatter.date(from: monthString) else { return "?" }

        formatter.dateFormat = "MMM"
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.string(from: date).uppercased()
    }

    private func formatMinutes(_ minutes: Double) -> String {
        if minutes >= 60 {
            return String(format: "%.0fh", minutes / 60)
        }
        return String(format: "%.0fm", minutes)
    }
}

#Preview {
    AnalyticsView()
}
