import SwiftUI

/// View de estatísticas e analytics
struct AnalyticsView: View {
    @StateObject private var analytics = AnalyticsManager.shared
    @Environment(\.dismiss) private var dismiss
    
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
            
            ScrollView {
                VStack(spacing: 20) {
                    // Cards principais
                    HStack(spacing: 16) {
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
                    }
                    .padding(.horizontal)
                    
                    // Caracteres digitados
                    StatCard2(
                        title: "Caracteres Digitados",
                        value: "\(analytics.totalCharacters)",
                        icon: "textformat",
                        color: .orange
                    )
                    .padding(.horizontal)
                    
                    // Gráfico mensal
                    if !analytics.monthlyStats.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Tempo Economizado por Mês")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            MonthlyChart(stats: analytics.monthlyStats)
                                .frame(height: 200)
                                .padding(.horizontal)
                        }
                    }
                    
                    // Média diária
                    HStack {
                        Label {
                            Text("Média de \(String(format: "%.1f", analytics.getAverageTranscriptionsPerDay())) transcrições por dia")
                        } icon: {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .foregroundStyle(.secondary)
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding(.vertical)
            }
        }
        .frame(width: 500, height: 550)
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
                    .font(.system(size: 28, weight: .bold, design: .rounded))
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
                        // Barra
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.green.gradient)
                            .frame(width: 30, height: max(20, CGFloat(stat.timeSavedMinutes / maxValue) * 120))
                        
                        // Mês abreviado
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
}

#Preview {
    AnalyticsView()
}
