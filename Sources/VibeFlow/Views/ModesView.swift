import SwiftUI

/// Transcription modes management view
struct ModesView: View {
    @StateObject private var settings = SettingsManager.shared
    @StateObject private var analytics = AnalyticsManager.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // MARK: - Header
                headerSection

                // MARK: - Current Mode
                currentModeSection

                // MARK: - All Modes
                allModesSection

                // MARK: - Mode Tips
                tipSection
            }
            .padding(32)
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Modos")
                .font(.system(size: 28, weight: .bold))

            Text("Cada modo otimiza a transcricao para um tipo especifico de conteudo. Escolha o modo ideal para sua tarefa.")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Current Mode

    private var currentModeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Modo Atual")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                // Mode icon
                ZStack {
                    Circle()
                        .fill(settings.selectedMode.color.opacity(0.15))
                        .frame(width: 56, height: 56)

                    Image(systemName: settings.selectedMode.icon)
                        .font(.system(size: 24))
                        .foregroundStyle(settings.selectedMode.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(settings.selectedMode.localizedName)
                        .font(.system(size: 18, weight: .semibold))

                    Text(settings.selectedMode.shortDescription)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Temperature indicator
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Criatividade")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)

                    HStack(spacing: 4) {
                        ForEach(0..<5) { i in
                            Circle()
                                .fill(i < temperatureLevel ? settings.selectedMode.color : Color(nsColor: .controlColor).opacity(0.1))
                                .frame(width: 6, height: 6)
                        }
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(settings.selectedMode.color.opacity(0.3), lineWidth: 1)
            )
        }
    }

    private var temperatureLevel: Int {
        let temp = settings.selectedMode.temperature
        if temp < 0.3 { return 1 }
        if temp < 0.5 { return 2 }
        if temp < 0.7 { return 3 }
        if temp < 0.9 { return 4 }
        return 5
    }

    // MARK: - All Modes

    private var allModesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Todos os Modos")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                ForEach(TranscriptionMode.allCases, id: \.self) { mode in
                    ModeCard2(
                        mode: mode,
                        isSelected: mode == settings.selectedMode,
                        usageCount: analytics.modeUsage[mode.rawValue] ?? 0,
                        onSelect: { settings.selectedMode = mode }
                    )
                }
            }
        }
    }

    // MARK: - Tips

    private var tipSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb")
                    .foregroundStyle(.yellow)
                Text("Dica")
                    .font(.system(size: 13, weight: .medium))
            }

            Text("O modo e automaticamente salvo. Voce pode trocar de modo a qualquer momento, mesmo durante uma sessao de gravacao.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.yellow.opacity(0.08))
        )
    }
}

// MARK: - Mode Card

struct ModeCard2: View {
    let mode: TranscriptionMode
    let isSelected: Bool
    let usageCount: Int
    let onSelect: () -> Void

    @State private var isHovered = false
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main row
            HStack(spacing: 14) {
                // Tappable area for selecting mode
                HStack(spacing: 14) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(mode.color.opacity(isSelected ? 0.2 : 0.1))
                            .frame(width: 40, height: 40)

                        Image(systemName: mode.icon)
                            .font(.system(size: 16))
                            .foregroundStyle(mode.color)
                    }

                    // Info
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 8) {
                            Text(mode.localizedName)
                                .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                                .foregroundStyle(isSelected ? mode.color : .primary)

                            if isSelected {
                                Text("ATIVO")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(mode.color)
                                    .cornerRadius(4)
                            }
                        }

                        Text(mode.shortDescription)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Usage count
                    if usageCount > 0 {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(usageCount)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.secondary)
                            Text("usos")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture(perform: onSelect)

                // Expand button (separate from select area)
                Button(action: { withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() } }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
            }
            .padding(14)

            // Expanded details
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()

                    Text(mode.detailedDescription)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(2)
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? mode.color.opacity(0.06) : (isHovered ? Color(nsColor: .controlColor).opacity(0.1) : Color(nsColor: .controlBackgroundColor)))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? mode.color.opacity(0.25) : Color(nsColor: .separatorColor), lineWidth: 1)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

#Preview {
    ModesView()
        .frame(width: 600, height: 700)
}
