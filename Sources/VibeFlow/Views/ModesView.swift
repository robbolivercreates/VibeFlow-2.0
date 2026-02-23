import SwiftUI

/// Transcription modes management view
struct ModesView: View {
    @StateObject private var settings = SettingsManager.shared
    @StateObject private var analytics = AnalyticsManager.shared
    @StateObject private var subscription = SubscriptionManager.shared
    @State private var showUpgradeModal = false
    @State private var upgradeContext: UpgradeContext = .generic

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Fixed header
            headerSection
                .padding(.horizontal, 32)
                .padding(.top, 32)
                .padding(.bottom, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(VoxTheme.background)
                .zIndex(1)

            Divider()

            // Scrollable content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    currentModeSection
                    allModesSection
                    conversationReplyModeSection
                    tipSection
                }
                .padding(32)
            }
            .clipped()
        }
        .background(VoxTheme.background)
        .sheet(isPresented: $showUpgradeModal) {
            UpgradeModalView(isPresented: $showUpgradeModal, context: upgradeContext)
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
                                .fill(i < temperatureLevel ? settings.selectedMode.color : VoxTheme.surface.opacity(0.1))
                                .frame(width: 6, height: 6)
                        }
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(VoxTheme.surface)
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
                                upgradeContext = .mode(mode)
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
                    .foregroundStyle(VoxTheme.accent)
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
                .fill(VoxTheme.accent.opacity(0.08))
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
    @StateObject private var settings = SettingsManager.shared

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
                                .background(VoxTheme.accent)
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
                                    Image(systemName: "crown.fill")
                                        .font(.system(size: 7))
                                    Text("PRO")
                                        .font(.system(size: 9, weight: .bold))
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    VoxTheme.goldGradient
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

                    // Custom prompt editor (only for Meu Modo)
                    if mode == .custom {
                        VStack(alignment: .leading, spacing: 8) {
                            Divider()
                                .padding(.vertical, 4)

                            Text("SEU PROMPT")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.secondary)

                            TextEditor(text: $settings.customModePrompt)
                                .font(.system(size: 13))
                                .scrollContentBackground(.hidden)
                                .padding(10)
                                .frame(minHeight: 100, maxHeight: 200)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(VoxTheme.background)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(VoxTheme.surfaceBorder, lineWidth: 1)
                                )

                            if settings.customModePrompt.isEmpty {
                                Text("Ex: \"Transcreva como legendas para YouTube, com timestamps a cada 30 segundos\"")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                                    .italic()
                            }

                            HStack(spacing: 6) {
                                Image(systemName: "info.circle")
                                    .font(.system(size: 11))
                                    .foregroundStyle(mode.color)
                                Text("Escreva instrucoes claras e diretas. A IA vai seguir exatamente o que voce pedir.")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isPro ? VoxTheme.surface.opacity(0.5) : (isSelected ? mode.color.opacity(0.06) : (isHovered ? VoxTheme.surface.opacity(0.1) : VoxTheme.surface)))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isPro ? VoxTheme.accent.opacity(0.25) : (isSelected ? mode.color.opacity(0.25) : VoxTheme.surfaceBorder), lineWidth: 1)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Upgrade Modal

// MARK: - Upgrade Context

enum UpgradeContext: Equatable {
    case mode(TranscriptionMode)
    case language(SpeechLanguage)
    case snippets
    case wakeWord
    case generic
}

struct UpgradeModalView: View {
    @Binding var isPresented: Bool
    var context: UpgradeContext = .generic
    @State private var isAnnual = true

    var body: some View {
        VStack(spacing: 0) {
            // Header with app logo
            VStack(spacing: 12) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.2), radius: 4, y: 2)

                Text(L10n.upgradeTitle(for: context))
                    .font(.system(size: 22, weight: .bold))
                    .multilineTextAlignment(.center)

                Text(L10n.upgradeDescription(for: context))
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 28)
            .padding(.horizontal, 32)

            // Features list
            VStack(alignment: .leading, spacing: 10) {
                ModeProFeatureRow(icon: "sparkles", text: L10n.upgradeFeatureSmartFormatting)
                ModeProFeatureRow(icon: "infinity", text: L10n.upgradeFeatureUnlimited)
                ModeProFeatureRow(icon: "waveform.and.mic", text: L10n.upgradeFeatureAllModes)
                ModeProFeatureRow(icon: "globe", text: L10n.upgradeFeatureAllLanguages)
                ModeProFeatureRow(icon: "text.badge.plus", text: L10n.upgradeFeatureSnippets)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(VoxTheme.accentMuted)
            )
            .padding(.horizontal, 24)
            .padding(.top, 20)

            // Pricing toggle
            upgradeToggle
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 28)
        }
        .frame(width: 420)
        .background(VoxTheme.background)
    }

    private var upgradeToggle: some View {
        VStack(spacing: 14) {
            // Toggle
            HStack(spacing: 0) {
                toggleBtn(title: L10n.pricingMonthly, selected: !isAnnual) { isAnnual = false }
                toggleBtn(title: L10n.pricingAnnual, selected: isAnnual, badge: "-25%") { isAnnual = true }
            }
            .background(Color.gray.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Price
            VStack(spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(isAnnual ? "R$22,40" : "R$29,90")
                        .font(.system(size: 36, weight: .bold))
                    Text("/\(L10n.month)")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                if isAnnual {
                    HStack(spacing: 4) {
                        Text("R$29,90")
                            .font(.system(size: 12))
                            .strikethrough()
                            .foregroundStyle(.secondary)
                        Text(L10n.pricingAnnualBilled)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Subscribe
            Button(action: {
                SubscriptionManager.shared.openUpgradeURL(annual: isAnnual)
                isPresented = false
            }) {
                HStack {
                    Image(systemName: "crown.fill")
                    Text(isAnnual ? L10n.pricingSubscribeAnnual : L10n.pricingSubscribeMonthly)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(VoxTheme.goldGradient)
                .foregroundStyle(.white)
                .cornerRadius(10)
            }
            .buttonStyle(.borderless)

            Button(L10n.upgradeNotNow) { isPresented = false }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
                .font(.system(size: 13))
        }
    }

    private func toggleBtn(title: String, selected: Bool, badge: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title).font(.system(size: 13, weight: selected ? .semibold : .regular))
                if let badge = badge {
                    Text(badge)
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 5).padding(.vertical, 2)
                        .background(VoxTheme.accent.opacity(0.2))
                        .foregroundStyle(VoxTheme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(selected ? Color.white.opacity(0.1) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.borderless)
    }
}

private struct ModeProFeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(VoxTheme.accent)
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
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 7))
                                Text("PRO")
                                    .font(.system(size: 9, weight: .bold))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                VoxTheme.goldGradient
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
                        .tint(VoxTheme.accent)
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
                .fill(isHovered ? featureColor.opacity(0.04) : VoxTheme.surface)
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

// MARK: - Upgrade Modal Localization

extension L10n {
    static var upgradeProFeature: String { t("AI Feature — Pro Only", "Funcionalidade I.A. — Exclusivo Pro", "Funcion I.A. — Exclusivo Pro") }
    static var upgradeProDescription: String { t(
        "This AI mode requires the Pro plan.\nUnlock the Agente Vox inteligente and all features.",
        "Este modo com I.A. requer o plano Pro.\nDesbloqueie o Agente Vox inteligente e todos os recursos.",
        "Este modo con I.A. requiere el plan Pro.\nDesbloquea el Agente Vox inteligente y todas las funciones."
    ) }
    static var upgradeFeatureUnlimited: String { t("Unlimited transcriptions + AI features", "Transcricoes ilimitadas + funcionalidades de I.A.", "Transcripciones ilimitadas + funciones de I.A.") }
    static var upgradeFeatureAllModes: String { t("All 15 AI modes (Vibe Coder, Social, Meeting...)", "Todos os 15 modos com I.A. (Vibe Coder, Social, Reuniao...)", "Los 15 modos con I.A. (Vibe Coder, Social, Reunion...)") }
    static var upgradeFeatureAllLanguages: String { t("30 languages available", "30 idiomas disponiveis", "30 idiomas disponibles") }
    static var upgradeFeatureSmartFormatting: String { t("Agente Vox — intelligent formatting", "Agente Vox — formatacao inteligente", "Agente Vox — formato inteligente") }
    static var upgradeFeatureSnippets: String { t("Custom snippets", "Snippets personalizados", "Fragmentos personalizados") }
    static var upgradeNotNow: String { t("Continue without AI", "Continuar sem I.A.", "Continuar sin I.A.") }
    static func upgradeTitle(for ctx: UpgradeContext) -> String {
        switch ctx {
        case .mode(let m): return t("Mode \(m.localizedName) — Pro Only", "Modo \(m.localizedName) — Exclusivo Pro", "Modo \(m.localizedName) — Exclusivo Pro")
        case .language(let l): return t("\(l.flag) \(l.displayName) — Pro Only", "\(l.flag) \(l.displayName) — Exclusivo Pro", "\(l.flag) \(l.displayName) — Exclusivo Pro")
        case .snippets: return t("Snippets — Pro Only", "Snippets — Exclusivo Pro", "Fragmentos — Exclusivo Pro")
        case .wakeWord: return t("Voice Commands — Pro Only", "Comandos de Voz — Exclusivo Pro", "Comandos de Voz — Exclusivo Pro")
        case .generic: return upgradeProFeature
        }
    }
    static func upgradeDescription(for ctx: UpgradeContext) -> String {
        switch ctx {
        case .mode(let m): return t("The \(m.localizedName) mode uses advanced AI.\nUnlock all 15 modes with Pro.", "O modo \(m.localizedName) usa I.A. avancada.\nDesbloqueie todos os 15 modos com o Pro.", "El modo \(m.localizedName) usa I.A. avanzada.\nDesbloquea los 15 modos con Pro.")
        case .language(let l): return t("\(l.displayName) requires Pro.\nFree: Portuguese and English.", "\(l.displayName) requer o plano Pro.\nGratuitos: Portugues e Ingles.", "\(l.displayName) requiere Pro.\nGratuitos: Portugues e Ingles.")
        case .snippets: return t("Custom snippets require Pro.", "Snippets personalizados requerem o Pro.", "Fragmentos personalizados requieren Pro.")
        case .wakeWord: return t("Voice commands require Pro.\nSwitch modes hands-free while recording.", "Comandos de voz requerem o Pro.\nAlterne modos sem as maos durante a gravacao.", "Comandos de voz requieren Pro.\nAlterna modos sin manos durante la grabacion.")
        case .generic: return upgradeProDescription
        }
    }
}

#Preview {
    ModesView()
        .frame(width: 600, height: 700)
}
