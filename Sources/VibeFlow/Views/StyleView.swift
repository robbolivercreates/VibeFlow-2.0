import SwiftUI

/// Writing style learning management view
struct StyleView: View {
    @StateObject private var styleManager = WritingStyleManager.shared
    @StateObject private var settings = SettingsManager.shared
    @State private var selectedMode: TranscriptionMode? = nil
    @State private var showingClearConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // MARK: - Header
                headerSection

                // MARK: - Toggle
                toggleSection

                // MARK: - How it Works
                if settings.enableStyleLearning {
                    howItWorksSection
                }

                // MARK: - Samples
                if settings.enableStyleLearning {
                    samplesSection
                }
            }
            .padding(32)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .alert("Limpar Amostras", isPresented: $showingClearConfirmation) {
            Button("Cancelar", role: .cancel) {}
            Button("Limpar", role: .destructive) {
                if let mode = selectedMode {
                    styleManager.clearSamples(for: mode)
                } else {
                    styleManager.clearAllSamples()
                }
                selectedMode = nil
            }
        } message: {
            if let mode = selectedMode {
                Text("Deseja limpar todas as amostras do modo \(mode.localizedName)?")
            } else {
                Text("Deseja limpar todas as amostras de estilo?")
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Estilo de Escrita")
                .font(.system(size: 28, weight: .bold))

            Text("O VibeFlow aprende seu estilo de escrita para personalizar as transcricoes, imitando seu vocabulario, tom e formatacao.")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Toggle

    private var toggleSection: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Aprendizado de Estilo")
                    .font(.system(size: 15, weight: .medium))

                Text("Quando ativado, o VibeFlow analisa suas transcricoes para aprender seu estilo unico.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("", isOn: $settings.enableStyleLearning)
                .toggleStyle(.switch)
                .labelsHidden()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(settings.enableStyleLearning ? Color.purple.opacity(0.3) : Color.secondary.opacity(0.15), lineWidth: 1)
        )
    }

    // MARK: - How it Works

    private var howItWorksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Como Funciona")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)

            HStack(alignment: .top, spacing: 24) {
                FeatureCard(
                    icon: "waveform",
                    title: "1. Voce Fala",
                    description: "Faca transcricoes normalmente usando o VibeFlow."
                )

                FeatureCard(
                    icon: "brain",
                    title: "2. IA Aprende",
                    description: "Textos com 50+ caracteres sao salvos como amostras."
                )

                FeatureCard(
                    icon: "text.quote",
                    title: "3. Personalizacao",
                    description: "Futuras transcricoes imitam seu estilo."
                )
            }
        }
    }

    // MARK: - Samples

    private var samplesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Amostras Aprendidas")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)

                Spacer()

                if styleManager.totalSamples > 0 {
                    Button(action: {
                        selectedMode = nil
                        showingClearConfirmation = true
                    }) {
                        Text("Limpar Tudo")
                            .font(.system(size: 12))
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                }
            }

            if styleManager.totalSamples == 0 {
                emptyStateView
            } else {
                samplesGridView
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "text.badge.plus")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)

            VStack(spacing: 4) {
                Text("Nenhuma amostra ainda")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.secondary)

                Text("Faca algumas transcricoes para o VibeFlow aprender seu estilo")
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

    private var samplesGridView: some View {
        VStack(spacing: 12) {
            let counts = styleManager.sampleCounts()

            ForEach(TranscriptionMode.allCases.filter { $0 != .command }, id: \.self) { mode in
                let count = counts[mode] ?? 0

                StyleModeCard(
                    mode: mode,
                    sampleCount: count,
                    samples: styleManager.samples.filter { $0.mode == mode },
                    onClear: {
                        selectedMode = mode
                        showingClearConfirmation = true
                    }
                )
            }
        }
    }
}

// MARK: - Feature Card

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(.purple)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))

                Text(description)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }
}

// MARK: - Style Mode Card

struct StyleModeCard: View {
    let mode: TranscriptionMode
    let sampleCount: Int
    let samples: [WritingStyleManager.StyleSample]
    let onClear: () -> Void

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 12) {
                // Mode indicator
                ZStack {
                    Circle()
                        .fill(mode.color.opacity(0.15))
                        .frame(width: 36, height: 36)

                    Image(systemName: mode.icon)
                        .font(.system(size: 14))
                        .foregroundStyle(mode.color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(mode.localizedName)
                        .font(.system(size: 14, weight: .medium))

                    Text("\(sampleCount) amostra\(sampleCount == 1 ? "" : "s")")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if sampleCount > 0 {
                    // Progress bar
                    HStack(spacing: 2) {
                        ForEach(0..<5) { i in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(i < sampleCount ? mode.color : Color.secondary.opacity(0.2))
                                .frame(width: 16, height: 4)
                        }
                    }

                    Button(action: { withAnimation { isExpanded.toggle() } }) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12))
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(14)

            // Expanded samples
            if isExpanded && sampleCount > 0 {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()

                    ForEach(samples.sorted(by: { $0.timestamp > $1.timestamp })) { sample in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(sample.text)
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                                .lineLimit(3)

                            Text(formatDate(sample.timestamp))
                                .font(.system(size: 10))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.secondary.opacity(0.05))
                        .cornerRadius(6)
                    }

                    Button(action: onClear) {
                        HStack {
                            Image(systemName: "trash")
                                .font(.system(size: 11))
                            Text("Limpar amostras deste modo")
                                .font(.system(size: 12))
                        }
                        .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color.secondary.opacity(0.1), lineWidth: 1)
        )
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    StyleView()
        .frame(width: 600, height: 700)
}
