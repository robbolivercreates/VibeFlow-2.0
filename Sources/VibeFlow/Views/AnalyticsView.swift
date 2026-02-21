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
                Text(L10n.statistics)
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                Button(L10n.close) {
                    dismiss()
                }
                .keyboardShortcut(.escape, modifiers: [])
            }
            .padding()

            // Tab Picker
            Picker("", selection: $selectedTab) {
                Text(L10n.summary).tag(0)
                Text(L10n.achievements).tag(1)
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
                    title: L10n.timeSavedHeader,
                    value: analytics.getFormattedTimeSaved(),
                    icon: "clock.arrow.circlepath",
                    color: VoxTheme.accent
                )

                StatCard2(
                    title: L10n.transcriptions,
                    value: "\(analytics.totalTranscriptions)",
                    icon: "mic.fill",
                    color: VoxTheme.accent
                )

                StatCard2(
                    title: L10n.words,
                    value: formatNumber(analytics.totalWords),
                    icon: "text.word.spacing",
                    color: VoxTheme.accent
                )

                StatCard2(
                    title: L10n.recordedTimeHeader,
                    value: analytics.getFormattedRecordingTime(),
                    icon: "waveform",
                    color: VoxTheme.accent
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
                    Text(L10n.timeSavedPerMonth)
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
                    Text(L10n.levelN(analytics.currentLevel.rawValue))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(analytics.currentLevel.name)
                        .font(.title2)
                        .fontWeight(.bold)
                }

                Spacer()

                if analytics.transcriptionsToNextLevel > 0 {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(L10n.nextLevel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(analytics.transcriptionsToNextLevel) transcrições")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                } else {
                    Text(L10n.maxLevel)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(VoxTheme.accent)
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
        .background(VoxTheme.surface)
        .cornerRadius(16)
    }

    private var levelColor: Color {
        // All levels use gold accent for cohesive B&W&Gold design
        return VoxTheme.accent
    }

    // MARK: - Streak Card

    private var streakCard: some View {
        HStack(spacing: 16) {
            // Current Streak
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(analytics.currentStreak > 0 ? VoxTheme.accent : .gray)
                    Text("\(analytics.currentStreak)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                }
                Text(L10n.currentStreak)
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
                        .foregroundStyle(VoxTheme.accent)
                    Text("\(analytics.longestStreak)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                }
                Text(L10n.longestStreak)
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
                        .foregroundStyle(VoxTheme.accent)
                    Text("\(analytics.todayTranscriptions)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                }
                Text(L10n.today)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .background(VoxTheme.surface)
        .cornerRadius(16)
    }

    // MARK: - Speed Stats Card

    private var speedStatsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.speed)
                .font(.headline)

            HStack(spacing: 20) {
                // Speaking WPM
                VStack(spacing: 4) {
                    Text(String(format: "%.0f", analytics.averageSpeakingWPM))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(VoxTheme.accent)
                    Text(L10n.wpmSpeaking)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                // vs Typing
                VStack(spacing: 4) {
                    Text("40")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.gray)
                    Text(L10n.wpmTyping)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                // Multiplier
                VStack(spacing: 4) {
                    Text(String(format: "%.1fx", analytics.efficiencyMultiplier))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(VoxTheme.accent)
                    Text(L10n.faster)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(VoxTheme.surface)
        .cornerRadius(16)
    }

    // MARK: - Efficiency Message

    private var efficiencyMessage: some View {
        HStack {
            Image(systemName: "lightbulb.fill")
                .foregroundStyle(VoxTheme.accent)

            if analytics.timeSavedMinutes > 60 {
                let hours = Int(analytics.timeSavedMinutes / 60)
                Text(L10n.timeSavedHours(hours))
                    .font(.subheadline)
            } else if analytics.timeSavedMinutes > 0 {
                let words = Int((analytics.timeSavedMinutes * 40))
                Text(L10n.timeSavedWords(formatNumber(words)))
                    .font(.subheadline)
            } else {
                Text(L10n.startUsingToSeeTime)
                    .font(.subheadline)
            }

            Spacer()
        }
        .padding()
        .background(VoxTheme.accent.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Achievements Tab

    private var achievementsTab: some View {
        VStack(spacing: 16) {
            // Achievement Counter
            HStack {
                Image(systemName: "medal.fill")
                    .foregroundStyle(VoxTheme.accent)
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
                .foregroundStyle(isUnlocked ? VoxTheme.accent : .gray.opacity(0.4))

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
                .fill(isUnlocked ? VoxTheme.accent.opacity(0.1) : VoxTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isUnlocked ? VoxTheme.accent.opacity(0.3) : Color.clear, lineWidth: 1)
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
        .background(VoxTheme.surface)
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
                            .fill(VoxTheme.accent.gradient)
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
            .background(VoxTheme.surface)
            .cornerRadius(12)
        }
    }

    private func shortMonth(_ monthString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        guard let date = formatter.date(from: monthString) else { return "?" }

        formatter.dateFormat = "MMM"
        formatter.locale = Locale(identifier: L10n.current.rawValue == "pt" ? "pt_BR" : L10n.current.rawValue == "es" ? "es_ES" : "en_US")
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
