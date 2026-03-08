import SwiftUI

/// Transcription modes management view — organized by category
struct ModesView: View {
    @StateObject private var settings = SettingsManager.shared
    @StateObject private var analytics = AnalyticsManager.shared
    @StateObject private var subscription = SubscriptionManager.shared
    @State private var showUpgradeModal = false
    @State private var upgradeContext: UpgradeContext = .generic
    @State private var editingCustomMode: CustomModeDefinition? = nil

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
                    favoriteModesSection
                    currentModeSection
                    categorizedModesSection
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

    // MARK: - Favorites

    private var favoriteModesSection: some View {
        Group {
            if !settings.favoriteModes.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(.yellow)
                        Text("Favoritos")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                    }

                    // Favorite mode chips in a horizontal flow
                    HStack(spacing: 8) {
                        ForEach(settings.favoriteModes, id: \.self) { mode in
                            Button(action: {
                                if subscription.canUseMode(mode) {
                                    settings.selectedMode = mode
                                } else {
                                    upgradeContext = .mode(mode)
                                    showUpgradeModal = true
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: mode.icon)
                                        .font(.system(size: 12))
                                    Text(mode.localizedName)
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .foregroundStyle(mode == settings.selectedMode ? .white : mode.color)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(mode == settings.selectedMode ? mode.color : mode.color.opacity(0.1))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(mode.color.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        Spacer()
                    }
                }
            }
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
                    HStack(spacing: 8) {
                        Text(settings.selectedMode.localizedName)
                            .font(.system(size: 18, weight: .semibold))

                        // Show active toggle info
                        if settings.selectedMode == .text && settings.textFormalTone {
                            toggleBadge("Formal")
                        } else if settings.selectedMode == .summary && settings.summaryBulletFormat {
                            toggleBadge("Bullets")
                        } else if settings.selectedMode == .social && settings.socialTweetMode {
                            toggleBadge("Tweet")
                        }
                    }

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

    private func toggleBadge(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(settings.selectedMode.color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(settings.selectedMode.color.opacity(0.15))
            .cornerRadius(4)
    }

    private var temperatureLevel: Int {
        let temp = settings.selectedMode.temperature
        if temp < 0.3 { return 1 }
        if temp < 0.5 { return 2 }
        if temp < 0.7 { return 3 }
        if temp < 0.9 { return 4 }
        return 5
    }

    // MARK: - Categorized Modes

    private var categorizedModesSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(ModeCategory.allCases, id: \.self) { category in
                if category == .custom {
                    customModesSection
                } else {
                    categorySection(category)
                }
            }
        }
    }

    private func categorySection(_ category: ModeCategory) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Category header
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                Text(category.rawValue)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            // Mode cards
            VStack(spacing: 8) {
                ForEach(ModeCategory.modes(for: category), id: \.self) { mode in
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

    // MARK: - Custom Modes (Meus Modos)

    private var customModesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Category header
            HStack(spacing: 8) {
                Image(systemName: ModeCategory.custom.icon)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                Text(ModeCategory.custom.rawValue)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)

                Spacer()

                // Mode count
                Text("\(settings.customModes.count) modo\(settings.customModes.count == 1 ? "" : "s")")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            // Custom mode cards
            VStack(spacing: 8) {
                ForEach(settings.customModes) { customMode in
                    CustomModeCard(
                        customMode: customMode,
                        isSelected: settings.selectedMode == .custom && settings.activeCustomModeId == customMode.id,
                        onSelect: {
                            if subscription.canUseMode(.custom) {
                                settings.selectedMode = .custom
                                settings.activeCustomModeId = customMode.id
                            } else {
                                upgradeContext = .mode(.custom)
                                showUpgradeModal = true
                            }
                        },
                        onDelete: {
                            withAnimation {
                                settings.customModes.removeAll { $0.id == customMode.id }
                                if settings.activeCustomModeId == customMode.id {
                                    settings.activeCustomModeId = settings.customModes.first?.id
                                }
                            }
                        },
                        onUpdate: { updated in
                            if let index = settings.customModes.firstIndex(where: { $0.id == updated.id }) {
                                settings.customModes[index] = updated
                            }
                        }
                    )
                }
            }

            // Add new custom mode button
            Button(action: addCustomMode) {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.1))
                            .frame(width: 40, height: 40)
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Criar Novo Modo")
                            .font(.system(size: 14, weight: .medium))
                        Text("Defina um prompt personalizado")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6]))
                        .foregroundStyle(Color.secondary.opacity(0.3))
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func addCustomMode() {
        // Check limits
        let isPro = subscription.isPro || TrialManager.shared.isTrialActive()
        if !isPro && settings.customModes.count >= 3 {
            upgradeContext = .generic
            showUpgradeModal = true
            return
        }

        let newMode = CustomModeDefinition()
        withAnimation {
            settings.customModes.append(newMode)
            settings.activeCustomModeId = newMode.id
            settings.selectedMode = .custom
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

                // Favorite star button
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        settings.toggleFavorite(mode)
                    }
                }) {
                    Image(systemName: settings.isFavorite(mode) ? "star.fill" : "star")
                        .font(.system(size: 14))
                        .foregroundStyle(settings.isFavorite(mode) ? .yellow : .secondary.opacity(0.5))
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                .help(settings.isFavorite(mode) ? "Remover dos favoritos" : (settings.favoriteModes.count >= 4 ? "Máximo 4 favoritos" : "Adicionar aos favoritos"))

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

                    // Mode-specific toggles
                    if mode == .text {
                        modeToggle(
                            label: "Tom Formal",
                            description: "Usa linguagem corporativa e profissional",
                            isOn: Binding(
                                get: { settings.textFormalTone },
                                set: { settings.textFormalTone = $0 }
                            ),
                            color: mode.color
                        )
                    }

                    if mode == .summary {
                        modeToggle(
                            label: "Formato Tópicos",
                            description: "Usa bullet points ao invés de parágrafos",
                            isOn: Binding(
                                get: { settings.summaryBulletFormat },
                                set: { settings.summaryBulletFormat = $0 }
                            ),
                            color: mode.color
                        )
                    }

                    if mode == .social {
                        modeToggle(
                            label: "Modo Tweet",
                            description: "Limita a 280 caracteres (formato X/Twitter)",
                            isOn: Binding(
                                get: { settings.socialTweetMode },
                                set: { settings.socialTweetMode = $0 }
                            ),
                            color: mode.color
                        )
                    }

                    // Custom prompt editor (only for Meu Modo — legacy single mode)
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

    /// Reusable toggle row for mode options
    private func modeToggle(label: String, description: String, isOn: Binding<Bool>, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Divider()
                .padding(.vertical, 6)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.system(size: 13, weight: .medium))
                    Text(description)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Toggle("", isOn: isOn)
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .scaleEffect(0.8)
            }
        }
    }
}

// MARK: - Custom Mode Card

struct CustomModeCard: View {
    let customMode: CustomModeDefinition
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    let onUpdate: (CustomModeDefinition) -> Void

    @State private var isHovered = false
    @State private var isExpanded = false
    @State private var editName: String = ""
    @State private var editPrompt: String = ""

    private var modeColor: Color {
        customMode.color
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main row
            HStack(spacing: 14) {
                HStack(spacing: 14) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(modeColor.opacity(isSelected ? 0.2 : 0.1))
                            .frame(width: 40, height: 40)

                        Image(systemName: customMode.icon)
                            .font(.system(size: 16))
                            .foregroundStyle(modeColor)
                    }

                    // Info
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 8) {
                            Text(customMode.name)
                                .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                                .foregroundStyle(isSelected ? modeColor : .primary)

                            if isSelected {
                                Text("ATIVO")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(modeColor)
                                    .cornerRadius(4)
                            }
                        }

                        Text(customMode.prompt.isEmpty ? "Sem prompt definido" : String(customMode.prompt.prefix(60)) + (customMode.prompt.count > 60 ? "..." : ""))
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()
                }
                .contentShape(Rectangle())
                .onTapGesture(perform: onSelect)

                // Expand button
                Button(action: {
                    if !isExpanded {
                        editName = customMode.name
                        editPrompt = customMode.prompt
                    }
                    withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
            }
            .padding(14)

            // Expanded: edit prompt
            if isExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    Divider()

                    // Name field
                    VStack(alignment: .leading, spacing: 4) {
                        Text("NOME")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.secondary)

                        TextField("Nome do modo", text: $editName)
                            .textFieldStyle(.plain)
                            .font(.system(size: 13))
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(VoxTheme.background)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(VoxTheme.surfaceBorder, lineWidth: 1)
                            )
                            .onChange(of: editName) { newValue in
                                var updated = customMode
                                updated.name = newValue
                                onUpdate(updated)
                            }
                    }

                    // Prompt field
                    VStack(alignment: .leading, spacing: 4) {
                        Text("PROMPT")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.secondary)

                        TextEditor(text: $editPrompt)
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
                            .onChange(of: editPrompt) { newValue in
                                var updated = customMode
                                updated.prompt = newValue
                                onUpdate(updated)
                            }

                        if editPrompt.isEmpty {
                            Text("Ex: \"Transcreva como legendas para YouTube\" ou \"Reformule como roteiro de podcast\"")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                                .italic()
                        }
                    }

                    // Delete button
                    HStack {
                        Spacer()
                        Button(action: onDelete) {
                            HStack(spacing: 4) {
                                Image(systemName: "trash")
                                    .font(.system(size: 11))
                                Text("Excluir")
                                    .font(.system(size: 12))
                            }
                            .foregroundStyle(.red.opacity(0.8))
                        }
                        .buttonStyle(.borderless)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected ? modeColor.opacity(0.06) : (isHovered ? VoxTheme.surface.opacity(0.1) : VoxTheme.surface))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? modeColor.opacity(0.25) : VoxTheme.surfaceBorder, lineWidth: 1)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) { isHovered = hovering }
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
    static var upgradeFeatureAllModes: String { t("All AI modes + custom modes", "Todos os modos com I.A. + modos personalizados", "Todos los modos con I.A. + modos personalizados") }
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
        case .mode(let m): return t("The \(m.localizedName) mode uses advanced AI.\nUnlock all modes with Pro.", "O modo \(m.localizedName) usa I.A. avancada.\nDesbloqueie todos os modos com o Pro.", "El modo \(m.localizedName) usa I.A. avanzada.\nDesbloquea todos los modos con Pro.")
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
