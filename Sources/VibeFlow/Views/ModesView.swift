import SwiftUI

/// Transcription modes management view
struct ModesView: View {
    @StateObject private var settings = SettingsManager.shared
    @StateObject private var analytics = AnalyticsManager.shared
    @StateObject private var subscription = SubscriptionManager.shared
    @State private var showUpgradeModal = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // MARK: - Header
                headerSection

                // MARK: - Current Mode
                currentModeSection

                // MARK: - All Modes
                allModesSection

                // MARK: - Conversation Reply Feature
                conversationReplyModeSection

                // MARK: - Mode Tips
                tipSection
            }
            .padding(32)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .sheet(isPresented: $showUpgradeModal) {
            UpgradeModalView(isPresented: $showUpgradeModal)
        }
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
                        isPro: !subscription.canUseMode(mode),
                        usageCount: analytics.modeUsage[mode.rawValue] ?? 0,
                        onSelect: {
                            if subscription.canUseMode(mode) {
                                settings.selectedMode = mode
                            } else {
                                showUpgradeModal = true
                            }
                        }
                    )
                }
            }
        }
    }

    // MARK: - Conversation Reply Feature

    private var conversationReplyModeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Funcionalidade Especial")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)

            ConversationReplyFeatureCard(showUpgrade: $showUpgradeModal)
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
    let isPro: Bool
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
                            .fill(isPro ? Color.gray.opacity(0.1) : mode.color.opacity(isSelected ? 0.2 : 0.1))
                            .frame(width: 40, height: 40)

                        Image(systemName: mode.icon)
                            .font(.system(size: 16))
                            .foregroundStyle(isPro ? Color.gray : mode.color)

                        // Pro lock overlay
                        if isPro {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(3)
                                .background(Color.orange)
                                .clipShape(Circle())
                                .offset(x: 13, y: 13)
                        }
                    }

                    // Info
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 8) {
                            Text(mode.localizedName)
                                .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                                .foregroundStyle(isPro ? .secondary : (isSelected ? mode.color : .primary))

                            if isPro {
                                // Pro badge
                                HStack(spacing: 3) {
                                    Image(systemName: "diamond.fill")
                                        .font(.system(size: 7))
                                    Text("PRO")
                                        .font(.system(size: 9, weight: .bold))
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    LinearGradient(colors: [Color.orange, Color.pink], startPoint: .leading, endPoint: .trailing)
                                )
                                .cornerRadius(4)
                            } else if isSelected {
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
                .fill(isPro ? Color(nsColor: .controlBackgroundColor).opacity(0.5) : (isSelected ? mode.color.opacity(0.06) : (isHovered ? Color(nsColor: .controlColor).opacity(0.1) : Color(nsColor: .controlBackgroundColor))))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isPro ? Color.orange.opacity(0.25) : (isSelected ? mode.color.opacity(0.25) : Color(nsColor: .separatorColor)), lineWidth: 1)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Upgrade Modal

struct UpgradeModalView: View {
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.orange, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 64, height: 64)
                    Image(systemName: "diamond.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                }

                Text("Recurso Pro")
                    .font(.system(size: 22, weight: .bold))

                Text("Este modo está disponível apenas no plano Pro.\nDesbloqueie acesso ilimitado a todos os recursos.")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 32)
            .padding(.horizontal, 32)

            // Features list
            VStack(alignment: .leading, spacing: 10) {
                ModeProFeatureRow(icon: "infinity", text: "Transcrições ilimitadas por mês")
                ModeProFeatureRow(icon: "waveform.and.mic", text: "Todos os 5 modos (Email, UX Design, Comando)")
                ModeProFeatureRow(icon: "globe", text: "15+ idiomas disponíveis")
                ModeProFeatureRow(icon: "sparkles", text: "Aprendizado de estilo pessoal")
                ModeProFeatureRow(icon: "text.badge.plus", text: "Snippets personalizados")
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.orange.opacity(0.06))
            )
            .padding(.horizontal, 24)
            .padding(.top, 20)

            // Pricing
            VStack(spacing: 8) {
                Text("A partir de")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("R$14,90")
                        .font(.system(size: 32, weight: .bold))
                    Text("/mês")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                Text("(plano anual) · ou R$19,90/mês")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 20)

            // Buttons
            VStack(spacing: 10) {
                Button(action: {
                    SubscriptionManager.shared.openUpgradeURL(annual: false)
                    isPresented = false
                }) {
                    HStack {
                        Image(systemName: "diamond.fill")
                        Text("Assinar Pro — R$19,90/mês")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(colors: [.orange, .pink], startPoint: .leading, endPoint: .trailing)
                    )
                    .foregroundStyle(.white)
                    .cornerRadius(10)
                }
                .buttonStyle(.borderless)

                Button(action: {
                    SubscriptionManager.shared.openUpgradeURL(annual: true)
                    isPresented = false
                }) {
                    Text("Plano Anual — R$14,90/mês (economize 25%)")
                        .font(.system(size: 13))
                        .foregroundStyle(.orange)
                }
                .buttonStyle(.borderless)

                Button("Agora não") { isPresented = false }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)
                    .font(.system(size: 13))
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 28)
        }
        .frame(width: 380)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

private struct ModeProFeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(.orange)
                .frame(width: 20)
            Text(text)
                .font(.system(size: 13))
        }
    }
}

// MARK: - Conversation Reply Feature Card

struct ConversationReplyFeatureCard: View {
    @StateObject private var settings = SettingsManager.shared
    @StateObject private var subscription = SubscriptionManager.shared
    @Binding var showUpgrade: Bool
    @State private var isExpanded = false
    @State private var isHovered = false

    private let featureColor = Color(red: 0.4, green: 0.72, blue: 1.0)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main row
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    Circle()
                        .fill(featureColor.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 16))
                        .foregroundStyle(featureColor)
                }

                // Info
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text("Resposta de Conversa")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.primary)

                        // Pro badge
                        if !subscription.isPro {
                            HStack(spacing: 3) {
                                Image(systemName: "diamond.fill")
                                    .font(.system(size: 7))
                                Text("PRO")
                                    .font(.system(size: 9, weight: .bold))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                LinearGradient(colors: [Color.orange, Color.pink], startPoint: .leading, endPoint: .trailing)
                            )
                            .cornerRadius(4)
                        } else if settings.enableConversationReply {
                            Text("ATIVO")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(featureColor)
                                .cornerRadius(4)
                        }
                    }

                    Text("Traduza mensagens recebidas e responda no idioma deles")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Toggle or upgrade button
                if subscription.isPro {
                    Toggle("", isOn: $settings.enableConversationReply)
                        .toggleStyle(.switch)
                        .labelsHidden()
                        .scaleEffect(0.8)
                } else {
                    Button("Ativar Pro") { showUpgrade = true }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(.orange)
                }

                // Expand button
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

            // Expanded: how it works
            if isExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    Divider()

                    Text("COMO FUNCIONA")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 8) {
                        CRModeStepRow(number: "1", color: featureColor, text: "Selecione uma mensagem em qualquer app (WhatsApp, Slack, email…)")
                        CRModeStepRow(number: "2", color: featureColor, text: "Pressione ⌃⇧R — um painel flutua com a tradução no seu idioma")
                        CRModeStepRow(number: "3", color: featureColor, text: "Leia a tradução. Você tem 15 segundos antes de fechar automaticamente")
                        CRModeStepRow(number: "4", color: featureColor, text: "Segure ⌥⌘ e fale sua resposta normalmente")
                        CRModeStepRow(number: "5", color: featureColor, text: "Sua resposta é traduzida para o idioma deles e colada automaticamente")
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "globe")
                            .font(.system(size: 11))
                            .foregroundStyle(featureColor)
                        Text("Funciona com qualquer combinação de idiomas — nenhuma configuração necessária.")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isHovered ? featureColor.opacity(0.04) : Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(featureColor.opacity(0.25), lineWidth: 1)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) { isHovered = hovering }
        }
    }
}

private struct CRModeStepRow: View {
    let number: String
    let color: Color
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(number)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 16, height: 16)
                .background(Circle().fill(color))

            Text(text)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
    }
}

#Preview {
    ModesView()
        .frame(width: 600, height: 700)
}
