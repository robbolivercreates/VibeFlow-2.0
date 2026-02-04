import SwiftUI

/// Home dashboard with stats and recent transcriptions
struct HomeView: View {
    @StateObject private var history = HistoryManager.shared
    @StateObject private var analytics = AnalyticsManager.shared
    @StateObject private var settings = SettingsManager.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // MARK: - Header
                headerSection

                // MARK: - Stats Cards
                statsSection

                // MARK: - Recent Transcriptions
                recentSection
            }
            .padding(32)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(greetingText)
                .font(.system(size: 28, weight: .bold))

            HStack(spacing: 16) {
                // Current Mode
                HStack(spacing: 6) {
                    Circle()
                        .fill(settings.selectedMode.color)
                        .frame(width: 8, height: 8)
                    Text(settings.selectedMode.localizedName)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }

                // Current Language
                HStack(spacing: 6) {
                    Text(settings.outputLanguage.flag)
                        .font(.system(size: 12))
                    Text(settings.outputLanguage.displayName)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }

                // Shortcut hint
                Text("Segure ⌥⌘ para gravar")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(4)
            }
        }
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 {
            return "Bom dia"
        } else if hour < 18 {
            return "Boa tarde"
        } else {
            return "Boa noite"
        }
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            StatCard(
                title: "Transcricoes",
                value: "\(analytics.totalTranscriptions)",
                subtitle: subtitleForTranscriptions,
                icon: "waveform",
                color: .purple
            )

            StatCard(
                title: "Tempo Gravado",
                value: formatRecordingTime(analytics.totalRecordingTime),
                subtitle: "total acumulado",
                icon: "clock",
                color: .blue
            )

            StatCard(
                title: "Modo Favorito",
                value: analytics.mostUsedMode?.localizedName ?? "-",
                subtitle: "mais utilizado",
                icon: "star",
                color: .orange
            )

            StatCard(
                title: "Idiomas",
                value: "\(settings.favoriteLanguages.count)",
                subtitle: "configurados",
                icon: "globe",
                color: .green
            )
        }
    }

    private var subtitleForTranscriptions: String {
        if analytics.totalTranscriptions == 0 {
            return "comece a gravar"
        } else if analytics.totalTranscriptions < 10 {
            return "bom comeco"
        } else if analytics.totalTranscriptions < 50 {
            return "em progresso"
        } else if analytics.totalTranscriptions < 100 {
            return "usuario frequente"
        } else {
            return "usuario avancado"
        }
    }

    private func formatRecordingTime(_ seconds: Double) -> String {
        let totalMinutes = Int(seconds) / 60
        if totalMinutes < 1 {
            return "\(Int(seconds))s"
        } else if totalMinutes < 60 {
            return "\(totalMinutes)min"
        } else {
            let hours = totalMinutes / 60
            let mins = totalMinutes % 60
            if mins == 0 {
                return "\(hours)h"
            }
            return "\(hours)h \(mins)m"
        }
    }

    // MARK: - Recent Section

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recentes")
                    .font(.system(size: 18, weight: .semibold))

                Spacer()

                if !history.items.isEmpty {
                    Button("Ver tudo") {
                        // Could open full history view
                        NotificationCenter.default.post(name: .init("showHistory"), object: nil)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.purple)
                    .font(.system(size: 13))
                }
            }

            if history.items.isEmpty {
                emptyStateView
            } else {
                recentListView
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform.badge.plus")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)

            VStack(spacing: 4) {
                Text("Nenhuma transcricao ainda")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.secondary)

                Text("Segure ⌥⌘ para comecar a gravar")
                    .font(.system(size: 13))
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.05))
                .strokeBorder(Color.secondary.opacity(0.1), lineWidth: 1)
        )
    }

    private var recentListView: some View {
        VStack(spacing: 8) {
            ForEach(history.items.prefix(5)) { item in
                RecentTranscriptionRow(item: item)
            }
        }
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(color)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.primary)

                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)

                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(color.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Recent Transcription Row

struct RecentTranscriptionRow: View {
    let item: HistoryItem

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            // Mode indicator
            Circle()
                .fill(item.mode.color)
                .frame(width: 8, height: 8)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(item.text)
                    .font(.system(size: 13))
                    .lineLimit(2)
                    .foregroundStyle(.primary)

                HStack(spacing: 8) {
                    Text(item.mode.localizedName)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)

                    Text("•")
                        .foregroundStyle(.tertiary)

                    Text(formatDate(item.timestamp))
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            // Copy button (on hover)
            if isHovered {
                Button(action: copyToClipboard) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .transition(.opacity)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? Color.secondary.opacity(0.08) : Color.secondary.opacity(0.04))
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func copyToClipboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(item.text, forType: .string)
    }
}

#Preview {
    HomeView()
        .frame(width: 600, height: 500)
}
