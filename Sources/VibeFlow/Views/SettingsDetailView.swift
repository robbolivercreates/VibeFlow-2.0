import SwiftUI
import AVFoundation
import IOKit

/// Clean settings view with row-based design (inspired by modern macOS apps)
struct SettingsDetailView: View {
    @StateObject private var settings = SettingsManager.shared
    @StateObject private var subscription = SubscriptionManager.shared
    @State private var showingResetConfirmation = false
    @State private var showingOfflineAlert = false
    @State private var microphonePermission: AVAuthorizationStatus = .notDetermined
    @State private var accessibilityPermission = false
    @State private var inputMonitoringPermission = false

    // Easter egg state
    @State private var versionTapCount = 0
    @State private var showEasterEggPrompt = false
    @State private var easterEggPassword = ""

    // Dev tools state
    @State private var devLoading = false
    @State private var devStatusMessage = ""

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
                    apiSection
                    behaviorSection
                    conversationReplySection
                    wakeWordSection
                    shortcutsSection
                    permissionsSection
                    advancedSection

                    supportSection

                    if subscription.devModeActive {
                        developerSection
                    }
                }
                .padding(32)
            }
            .clipped()
        }
        .background(VoxTheme.background)
        .onAppear {
            checkPermissions()
        }
        .alert("Limpar Dados", isPresented: $showingResetConfirmation) {
            Button("Cancelar", role: .cancel) {}
            Button("Limpar", role: .destructive) {
                HistoryManager.shared.clear()
                WritingStyleManager.shared.clearAllSamples()
            }
        } message: {
            Text("Isso ira limpar todo o historico de transcricoes e amostras de estilo. Esta acao nao pode ser desfeita.")
        }
        .alert("Modo Offline Ativado", isPresented: $showingOfflineAlert) {
            Button("Entendi") {}
        } message: {
            Text("O modo offline usa transcrição local simplificada.\n\n• Sem formatação inteligente\n• Sem remoção de hesitações\n• Sem tradução automática\n• Modo ajustado para Texto\n\nPara voltar ao Vox AI, desative o Modo Offline.")
        }
    }

    private func checkPermissions() {
        microphonePermission = AVCaptureDevice.authorizationStatus(for: .audio)
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        accessibilityPermission = AXIsProcessTrustedWithOptions(options as CFDictionary)
        inputMonitoringPermission = IOHIDRequestAccess(kIOHIDRequestTypeListenEvent)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ajustes")
                .font(.system(size: 28, weight: .bold))

            Text("Configure o VoxAiGo de acordo com suas preferencias.")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Account Section

    private var apiSection: some View {
        SettingsSection(title: L10n.account, icon: "person.crop.circle") {
            AccountView(onVersionTap: {
                versionTapCount += 1
                if versionTapCount >= 5 {
                    versionTapCount = 0
                    showEasterEggPrompt = true
                }
            })

            if showEasterEggPrompt {
                HStack(spacing: 8) {
                    SecureField("Password", text: $easterEggPassword)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { activateEasterEgg() }

                    Button("OK") { activateEasterEgg() }
                        .buttonStyle(.bordered)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
        }
    }

    private func activateEasterEgg() {
        if easterEggPassword == "voxdev" {
            subscription.activateDevMode()
        }
        showEasterEggPrompt = false
        easterEggPassword = ""
    }

    // MARK: - Behavior Section

    private var behaviorSection: some View {
        SettingsSection(title: "Comportamento", icon: "gearshape") {
            VStack(spacing: 0) {
                SettingsToggleRow(
                    title: L10n.launchAtLogin,
                    subtitle: L10n.launchAtLoginDescription,
                    isOn: $settings.launchAtLogin
                )

                Divider().padding(.leading, 44)

                SettingsToggleRow(
                    title: "Colar automaticamente",
                    subtitle: "Cola o texto transcrito automaticamente",
                    isOn: $settings.enableAutoPaste
                )

                Divider().padding(.leading, 44)

                SettingsToggleRow(
                    title: "Fechar apos colar",
                    subtitle: "Fecha a janela apos colar o texto",
                    isOn: $settings.enableAutoClose
                )

                Divider().padding(.leading, 44)

                SettingsToggleRow(
                    title: "Salvar historico",
                    subtitle: "Mantem um registro das transcricoes",
                    isOn: $settings.enableHistory
                )

                Divider().padding(.leading, 44)

                SettingsToggleRow(
                    title: "Efeitos sonoros",
                    subtitle: "Sons ao iniciar e parar gravacao",
                    isOn: $settings.enableSounds
                )

                Divider().padding(.leading, 44)

                SettingsToggleRow(
                    title: L10n.clarifyAndOrganize,
                    subtitle: L10n.clarifyDescription,
                    isOn: $settings.clarifyText
                )

                if subscription.isPro {
                    Divider().padding(.leading, 44)

                    SettingsToggleRow(
                        title: "Modo Offline",
                        subtitle: settings.offlineMode
                            ? "Transcrição local simplificada"
                            : "Vox AI — transcrição inteligente",
                        isOn: Binding(
                            get: { settings.offlineMode },
                            set: { newValue in
                                settings.offlineMode = newValue
                                if newValue {
                                    // Auto-switch to Text mode (only free mode available offline)
                                    if !SubscriptionManager.freeModes.contains(settings.selectedMode) {
                                        settings.selectedMode = .text
                                    }
                                    showingOfflineAlert = true
                                    // Validate subscription immediately when offline mode is enabled
                                    Task { await SubscriptionManager.shared.fetchProfile() }
                                }
                                // Rebuild menu bar to show/hide offline indicator
                                NotificationCenter.default.post(name: .offlineModeChanged, object: nil)
                            }
                        )
                    )
                }
            }
        }
    }

    // MARK: - Conversation Reply Section

    private var conversationReplySection: some View {
        SettingsSection(title: "Resposta de Conversa", icon: "bubble.left.and.bubble.right") {
            VStack(spacing: 0) {
                SettingsToggleRow(
                    title: "Habilitar Resposta de Conversa",
                    subtitle: "Traduz mensagens e responde no idioma do remetente",
                    isOn: $settings.enableConversationReply
                )

                if settings.enableConversationReply {
                    Divider().padding(.leading, 44)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("COMO FUNCIONA")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.secondary)

                        VStack(alignment: .leading, spacing: 8) {
                            ConversationReplyStepRow(number: "1", text: "Selecione uma mensagem em qualquer app (WhatsApp, Slack, email…)")
                            ConversationReplyStepRow(number: "2", text: "Pressione ⌃⇧R — um painel aparece com a tradução")
                            ConversationReplyStepRow(number: "3", text: "Leia a tradução no seu idioma")
                            ConversationReplyStepRow(number: "4", text: "Segure ⌥⌘ e fale sua resposta no seu idioma")
                            ConversationReplyStepRow(number: "5", text: "Sua resposta é traduzida automaticamente e colada no idioma deles")
                        }

                        HStack {
                            Text("Ativar com")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                            Spacer()
                            ShortcutBadge(shortcut: settings.conversationReplyShortcut)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
        }
    }

    // MARK: - Wake Word / Voice Commands Section

    private var wakeWordSection: some View {
        SettingsSection(title: "Comandos de Voz", icon: "waveform.badge.mic") {
            VStack(spacing: 0) {
                // Enable toggle
                HStack {
                    SettingsToggleRow(
                        title: "Ativar comandos de voz",
                        subtitle: subscription.isPro || TrialManager.shared.isTrialActive()
                            ? "Troque de modo ou idioma dizendo o nome do assistente"
                            : "Recurso exclusivo Pro — troque de modo por voz",
                        isOn: Binding(
                            get: { settings.wakeWordEnabled },
                            set: { newValue in
                                if subscription.isPro || TrialManager.shared.isTrialActive() {
                                    settings.wakeWordEnabled = newValue
                                }
                            }
                        )
                    )

                    if !subscription.isPro && !TrialManager.shared.isTrialActive() {
                        HStack(spacing: 3) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 8))
                            Text("PRO")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(VoxTheme.goldGradient)
                        .cornerRadius(4)
                        .padding(.trailing, 16)
                    }
                }

                if settings.wakeWordEnabled && (subscription.isPro || TrialManager.shared.isTrialActive()) {
                    Divider().padding(.leading, 44)

                    // Custom assistant name
                    SettingsRow(
                        title: "Nome do assistente",
                        subtitle: "Personalize o nome que você diz para ativar"
                    ) {
                        TextField("Vox", text: $settings.wakeWord)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 120)
                            .multilineTextAlignment(.trailing)
                    }

                    Divider().padding(.leading, 44)

                    // Live preview of commands
                    VStack(alignment: .leading, spacing: 8) {
                        let name = settings.wakeWord.isEmpty ? "Vox" : settings.wakeWord

                        Text("COMO USAR")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.secondary)

                        VStack(alignment: .leading, spacing: 6) {
                            wakeWordExample(
                                command: "\"\(name), Email\"",
                                result: "Muda para modo Email"
                            )
                            wakeWordExample(
                                command: "\"\(name), Português\"",
                                result: "Muda para Português"
                            )
                            wakeWordExample(
                                command: "\"\(name), Tradução\"",
                                result: "Muda para modo Tradução"
                            )
                        }

                        // Test button
                        HStack {
                            Spacer()
                            Button(action: {
                                NotificationCenter.default.post(
                                    name: .wakeWordCommand,
                                    object: nil,
                                    userInfo: [
                                        "label": "Email",
                                        "icon": "envelope.fill",
                                        "type": "mode"
                                    ]
                                )
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 10))
                                    Text("Testar")
                                        .font(.system(size: 12, weight: .medium))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(VoxTheme.accent.opacity(0.15))
                                .foregroundStyle(VoxTheme.accent)
                                .cornerRadius(6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    Divider().padding(.leading, 44)

                    // Command language
                    SettingsRow(
                        title: "Idioma dos comandos",
                        subtitle: "Seu idioma nativo para os comandos de voz"
                    ) {
                        Picker("", selection: $settings.commandLanguage) {
                            ForEach(SpeechLanguage.allCases, id: \.self) { lang in
                                Text("\(lang.flag) \(lang.displayName)").tag(lang)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 150)
                    }
                }
            }
        }
    }

    private func wakeWordExample(command: String, result: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "mic.fill")
                .font(.system(size: 10))
                .foregroundStyle(VoxTheme.accent)
                .frame(width: 16)

            Text(command)
                .font(.system(size: 12, weight: .medium))

            Image(systemName: "arrow.right")
                .font(.system(size: 9))
                .foregroundStyle(.secondary)

            Text(result)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Shortcuts Section

    private var shortcutsSection: some View {
        SettingsSection(title: "Atalhos", icon: "command") {
            VStack(spacing: 0) {
                SettingsRow(
                    title: "Gravar",
                    subtitle: "Segure para gravar"
                ) {
                    ShortcutEditor(
                        shortcut: $settings.shortcutRecordKey,
                        placeholder: "⌥⌘"
                    )
                }

                Divider().padding(.leading, 44)

                SettingsRow(
                    title: "Alternar idioma",
                    subtitle: "Cicla entre favoritos"
                ) {
                    ShortcutEditor(
                        shortcut: $settings.cycleLanguageShortcut,
                        placeholder: "⌃⇧L"
                    )
                }

                Divider().padding(.leading, 44)

                SettingsRow(
                    title: "Abrir janela",
                    subtitle: "Mostra/esconde a janela principal"
                ) {
                    ShortcutEditor(
                        shortcut: $settings.shortcutToggleKey,
                        placeholder: "⌘⇧V"
                    )
                }

                Divider().padding(.leading, 44)

                SettingsRow(
                    title: "Alternar modo",
                    subtitle: "Cicla entre modos de transcrição"
                ) {
                    ShortcutEditor(
                        shortcut: $settings.cycleModeShortcut,
                        placeholder: "⌃⇧M"
                    )
                }

                Divider().padding(.leading, 44)

                SettingsRow(
                    title: "Colar última",
                    subtitle: "Cola a última transcrição do histórico"
                ) {
                    ShortcutEditor(
                        shortcut: $settings.pasteLastShortcut,
                        placeholder: "⌃⇧V"
                    )
                }

                Divider().padding(.leading, 44)

                SettingsRow(
                    title: "Resposta de Conversa",
                    subtitle: "Traduz texto selecionado e responde no idioma deles"
                ) {
                    ShortcutEditor(
                        shortcut: $settings.conversationReplyShortcut,
                        placeholder: "⌃⇧R"
                    )
                }

                Divider().padding(.leading, 44)

                SettingsRow(
                    title: "Configuracoes",
                    subtitle: "Abre esta janela"
                ) {
                    ShortcutBadge(shortcut: "⌘,")
                }

                Divider().padding(.leading, 44)

                // Reset shortcuts hint
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                    Text("Clique em um atalho para editar. Pressione as teclas desejadas.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
        }
    }

    // MARK: - Permissions Section

    private var permissionsSection: some View {
        SettingsSection(title: "Permissoes", icon: "lock.shield") {
            VStack(spacing: 0) {
                SettingsRow(
                    title: "Microfone",
                    subtitle: permissionStatusText(microphonePermission)
                ) {
                    PermissionBadge(
                        isGranted: microphonePermission == .authorized,
                        onRequest: {
                            AVCaptureDevice.requestAccess(for: .audio) { _ in
                                DispatchQueue.main.async {
                                    checkPermissions()
                                }
                            }
                        }
                    )
                }

                Divider().padding(.leading, 44)

                SettingsRow(
                    title: "Acessibilidade",
                    subtitle: accessibilityPermission ? "Permitido" : "Necessario para colar automaticamente"
                ) {
                    PermissionBadge(
                        isGranted: accessibilityPermission,
                        onRequest: {
                            let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                            NSWorkspace.shared.open(url)
                        }
                    )
                }

                Divider().padding(.leading, 44)

                SettingsRow(
                    title: "Input Monitoring",
                    subtitle: inputMonitoringPermission ? "Permitido" : "Necessario para atalhos globais"
                ) {
                    PermissionBadge(
                        isGranted: inputMonitoringPermission,
                        onRequest: {
                            let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent")!
                            NSWorkspace.shared.open(url)
                        }
                    )
                }
            }
        }
    }

    // MARK: - Advanced Section

    private var advancedSection: some View {
        SettingsSection(title: "Avancado", icon: "slider.horizontal.3") {
            VStack(spacing: 0) {
                SettingsRow(
                    title: "Setup Wizard",
                    subtitle: "Reconfigurar o VoxAiGo do inicio"
                ) {
                    Button("Abrir Wizard") {
                        // Use notification to open wizard window properly
                        NotificationCenter.default.post(name: .openSetupWizard, object: nil)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                Divider().padding(.leading, 44)

                SettingsRow(
                    title: "Limpar dados",
                    subtitle: "Remove historico e amostras de estilo"
                ) {
                    Button("Limpar") {
                        showingResetConfirmation = true
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .foregroundStyle(VoxTheme.danger)
                }

                Divider().padding(.leading, 44)

                SettingsRow(
                    title: "Resetar atalhos",
                    subtitle: "Restaura atalhos para o padrao"
                ) {
                    Button("Resetar") {
                        settings.shortcutRecordKey = "⌥⌘"
                        settings.shortcutToggleKey = "⌘⇧V"
                        settings.cycleLanguageShortcut = "⌃⇧L"
                        settings.cycleModeShortcut = "⌃⇧M"
                        settings.pasteLastShortcut = "⌃⇧V"
                        settings.conversationReplyShortcut = "⌃⇧R"
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                Divider().padding(.leading, 44)

                SettingsRow(
                    title: "Versao",
                    subtitle: "VoxAiGo para macOS"
                ) {
                    Text(AppVersion.current)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Support Section

    private var supportSection: some View {
        SettingsSection(title: "Ajuda", icon: "questionmark.circle") {
            VStack(spacing: 0) {
                Button(action: {
                    if let url = URL(string: "https://www.voxaigo.com/suporte") {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "lifepreserver")
                            .font(.system(size: 16))
                            .foregroundStyle(.blue)
                            .frame(width: 32)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Suporte e Ajuda")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.primary)
                            Text("Tutoriais, FAQ e contato")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Divider().padding(.leading, 44)

                Button(action: {
                    if let url = URL(string: "https://www.voxaigo.com/dashboard") {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "chart.bar")
                            .font(.system(size: 16))
                            .foregroundStyle(VoxTheme.accent)
                            .frame(width: 32)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Dashboard")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.primary)
                            Text("Estatisticas e gerenciamento da conta")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Developer Section (devMode only)

    @StateObject private var trial = TrialManager.shared

    private var developerSection: some View {
        SettingsSection(title: "Developer Tools", icon: "hammer.fill") {
            VStack(spacing: 0) {

                // MARK: Status
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("STATUS")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(subscription.isPro ? "PRO" : (trial.isTrialActive() ? "TRIAL" : "FREE"))
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(subscription.isPro ? VoxTheme.accent : (trial.isTrialActive() ? .green : .orange))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(subscription.isPro ? VoxTheme.accent.opacity(0.15) : (trial.isTrialActive() ? Color.green.opacity(0.15) : Color.orange.opacity(0.15)))
                            )
                    }
                    devInfoRow("isPro (efetivo)", subscription.isPro ? "YES" : "NO")
                    devInfoRow("Trial", trialStateLabel)
                    devInfoRow("Online Valid.", subscription.needsOnlineValidation ? "EXPIRADO ⚠️" : subscription.devOnlineValidationLabel)
                    devInfoRow("Auth", AuthManager.shared.userEmail ?? "não autenticado")
                    devInfoRow("Offline engine", WhisperEngine.shared.isReady ? "pronto ✓" : "não carregado")
                    devInfoRow("Free tx usadas", "\(subscription.whisperTranscriptionsUsed)/\(SubscriptionManager.whisperMonthlyLimit)")
                    devInfoRow("Trial tx usadas", "\(trial.trialTranscriptionsUsed)/\(TrialManager.trialTranscriptionLimit)")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                Divider().padding(.leading, 16)

                // MARK: Novo Usuário — simula primeiro acesso completo
                SettingsRow(
                    title: "Novo usuário",
                    subtitle: "Wizard + trial auto-inicia + HUD boas-vindas (1.5s)"
                ) {
                    Button("Simular") {
                        // Reset tudo para estado de dispositivo novo
                        subscription.deactivateDevGrantPro()
                        subscription.deactivateForceFree()
                        subscription.devSetWhisperUsage(0)
                        subscription.devResetOnlineValidation()
                        settings.selectedMode = .text
                        settings.outputLanguage = .portuguese
                        UserDefaults.standard.removeObject(forKey: "trial_expired_shown")
                        // Reset wizard para abrir novamente
                        settings.onboardingCompleted = false
                        Task {
                            // Reset trial para .unknown (novo dispositivo)
                            trial.devResetTrial()
                            // Abre wizard
                            await MainActor.run {
                                NotificationCenter.default.post(name: .openSetupWizard, object: nil)
                            }
                            // autoStartTrialIfEligible: inicia trial + posta showWelcomeTrial após 1.5s
                            await trial.autoStartTrialIfEligible()
                            await MainActor.run { devStatusMessage = "→ NOVO USUÁRIO (wizard + trial)" }
                        }
                    }
                    .buttonStyle(.borderedProminent).controlSize(.small)
                    .tint(.purple)
                }

                Divider().padding(.leading, 44)

                // MARK: Cenários (3 modos principais — sincroniza com Supabase)
                SettingsRow(
                    title: "Simular cenário",
                    subtitle: "Altera o estado no servidor (Supabase)"
                ) {
                    HStack(spacing: 8) {
                        // FREE — PATCH server: plan=free, status=inactive + expira trial
                        Button("Free") {
                            devStatusMessage = "Sincronizando..."
                            Task {
                                trial.devExpireTrial()
                                let ok = await subscription.devSetPlanOnSupabase("free")
                                subscription.devSetWhisperUsage(0)
                                let _ = await subscription.devSetFreeUsageOnSupabase(0)
                                await MainActor.run {
                                    subscription.devResetOnlineValidation()
                                    settings.selectedMode = .text
                                    settings.outputLanguage = .portuguese
                                    UserDefaults.standard.removeObject(forKey: "trial_expired_shown")
                                    devStatusMessage = ok ? "→ FREE (server ✓)" : "→ FREE (local only ⚠️)"
                                }
                            }
                        }
                        .buttonStyle(.bordered).controlSize(.small)
                        .foregroundStyle(.orange)

                        // TRIAL — PATCH server: plan=free + inicia trial (registra device no server)
                        Button("Trial") {
                            devStatusMessage = "Sincronizando..."
                            Task {
                                // 1. Reset + start trial FIRST (so isTrialActive()=true before fetchProfile)
                                trial.devResetTrial()
                                await trial.startTrial()
                                // 2. Now PATCH server (fetchProfile inside will see trial active → won't disable wake word)
                                let ok = await subscription.devSetPlanOnSupabase("free")
                                subscription.devSetWhisperUsage(0)
                                let _ = await subscription.devSetFreeUsageOnSupabase(0)
                                await MainActor.run {
                                    subscription.devResetOnlineValidation()
                                    settings.wakeWordEnabled = true  // Re-enable wake word for trial
                                    UserDefaults.standard.removeObject(forKey: "trial_expired_shown")
                                    devStatusMessage = ok ? "→ TRIAL (server ✓)" : "→ TRIAL (local only ⚠️)"
                                }
                            }
                        }
                        .buttonStyle(.bordered).controlSize(.small)
                        .foregroundStyle(.green)

                        // PRO — PATCH server: plan=pro, status=active, expires_at=+30d
                        Button("Pro") {
                            devStatusMessage = "Sincronizando..."
                            Task {
                                let ok = await subscription.devSetPlanOnSupabase("pro", expiresInDays: 30)
                                await MainActor.run {
                                    subscription.devResetOnlineValidation()
                                    settings.wakeWordEnabled = true  // Enable wake word for Pro
                                    devStatusMessage = ok ? "→ PRO (server ✓)" : "→ PRO (local only ⚠️)"
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent).controlSize(.small)
                    }
                }

                // Status feedback
                if !devStatusMessage.isEmpty {
                    HStack {
                        Spacer()
                        Text(devStatusMessage)
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundStyle(devStatusMessage.contains("ERRO") ? .red : .green)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 6)
                }

                Divider().padding(.leading, 44)

                // MARK: Testar Modais
                SettingsRow(
                    title: "Testar modais",
                    subtitle: "Abre as telas de aviso do fluxo"
                ) {
                    HStack(spacing: 6) {
                        Button("Welcome") {
                            NotificationCenter.default.post(name: .showWelcomeTrial, object: nil)
                        }
                        .buttonStyle(.bordered).controlSize(.mini)
                        Button("Expired") {
                            NotificationCenter.default.post(name: .showTrialExpired, object: nil)
                        }
                        .buttonStyle(.bordered).controlSize(.mini)
                        Button("Locked") {
                            NotificationCenter.default.post(name: .showMonthlyLimit, object: nil)
                        }
                        .buttonStyle(.bordered).controlSize(.mini)
                        Button("Reminder") {
                            NotificationCenter.default.post(name: .showUpgradeReminder, object: nil)
                        }
                        .buttonStyle(.bordered).controlSize(.mini)
                    }
                }

                Divider().padding(.leading, 44)

                // MARK: Preview HUDs (para screenshots)
                SettingsRow(
                    title: "Preview HUDs",
                    subtitle: subscription.devFreezeHUDs ? "Congelados (30s) — tire screenshots" : "Toque para ver cada HUD"
                ) {
                    VStack(alignment: .trailing, spacing: 6) {
                        Toggle("Congelar", isOn: $subscription.devFreezeHUDs)
                            .toggleStyle(.switch)
                            .controlSize(.mini)

                        HStack(spacing: 6) {
                            Button("Idioma") {
                                NotificationCenter.default.post(name: .devPreviewLanguageHUD, object: nil)
                            }
                            .buttonStyle(.bordered).controlSize(.mini)
                            Button("Modo") {
                                NotificationCenter.default.post(name: .devPreviewModeHUD, object: nil)
                            }
                            .buttonStyle(.bordered).controlSize(.mini)
                            Button("Vox") {
                                NotificationCenter.default.post(name: .devPreviewWakeWordHUD, object: nil)
                            }
                            .buttonStyle(.bordered).controlSize(.mini)
                        }
                        HStack(spacing: 6) {
                            Button("Colar") {
                                NotificationCenter.default.post(name: .devPreviewPasteHUD, object: nil)
                            }
                            .buttonStyle(.bordered).controlSize(.mini)
                            Button("Sem hist.") {
                                NotificationCenter.default.post(name: .devPreviewNoHistoryHUD, object: nil)
                            }
                            .buttonStyle(.bordered).controlSize(.mini)
                            Button("Gravação") {
                                NotificationCenter.default.post(name: .devPreviewRecordingHUD, object: nil)
                            }
                            .buttonStyle(.bordered).controlSize(.mini)
                        }
                    }
                }

                Divider().padding(.leading, 44)

                // MARK: Free tx (local + Supabase)
                SettingsRow(
                    title: "Free tx (local + server)",
                    subtitle: "Seta \(subscription.whisperTranscriptionsUsed)/\(SubscriptionManager.whisperMonthlyLimit) — sincroniza com Supabase"
                ) {
                    HStack(spacing: 6) {
                        ForEach([0, 50, 74, 75], id: \.self) { count in
                            Button("\(count)") {
                                subscription.devSetWhisperUsage(count)
                                Task {
                                    let ok = await subscription.devSetFreeUsageOnSupabase(count)
                                    await MainActor.run {
                                        devStatusMessage = ok ? "→ Free tx: \(count)/75 ✓ server" : "→ Free tx: \(count) (local only)"
                                    }
                                }
                            }
                            .buttonStyle(.bordered).controlSize(.mini)
                            .foregroundStyle(count == 75 ? VoxTheme.danger : count == 74 ? .orange : .primary)
                        }
                    }
                }

                // MARK: Trial tx (local apenas — não sincroniza com Supabase)
                SettingsRow(
                    title: "Trial tx (local)",
                    subtitle: "\(trial.trialTranscriptionsUsed)/\(TrialManager.trialTranscriptionLimit) usadas"
                ) {
                    HStack(spacing: 6) {
                        ForEach([0, 49, 50], id: \.self) { count in
                            Button("\(count)") {
                                trial.trialTranscriptionsUsed = count
                                UserDefaults.standard.set(count, forKey: "trial_transcriptions_used")
                                devStatusMessage = "→ Trial tx: \(count)/50"
                            }
                            .buttonStyle(.bordered).controlSize(.mini)
                            .foregroundStyle(count == 50 ? VoxTheme.danger : count == 49 ? .orange : .primary)
                        }
                    }
                }

                Divider().padding(.leading, 44)

                // MARK: Utilitários
                SettingsRow(
                    title: "Utilitários",
                    subtitle: "Ações avulsas"
                ) {
                    HStack(spacing: 6) {
                        Button("Wizard") {
                            NotificationCenter.default.post(name: .openSetupWizard, object: nil)
                        }
                        .buttonStyle(.bordered).controlSize(.small)

                        Button("Refresh") {
                            Task { await subscription.fetchProfile() }
                        }
                        .buttonStyle(.bordered).controlSize(.small)

                        Button("Limpar hist.") {
                            HistoryManager.shared.clear()
                        }
                        .buttonStyle(.bordered).controlSize(.small)
                        .foregroundStyle(VoxTheme.danger)
                    }
                }

                Divider().padding(.leading, 44)

                // MARK: Sair
                SettingsRow(
                    title: "Sair do Dev Mode",
                    subtitle: "Remove esta seção e desativa overrides"
                ) {
                    Button("Desativar") {
                        subscription.deactivateDevMode()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .foregroundStyle(VoxTheme.danger)
                }
            }
        }
    }

    private var trialStateLabel: String {
        switch trial.trialState {
        case .unknown: return "Não iniciado"
        case .active(let days): return "\(days)d restantes (\(trial.trialTranscriptionsUsed)/\(TrialManager.trialTranscriptionLimit) usados)"
        case .expired: return "Expirado"
        }
    }

    private func devInfoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
    }

    private func permissionStatusText(_ status: AVAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "Nao solicitado"
        case .restricted: return "Restrito"
        case .denied: return "Negado - abra Preferencias do Sistema"
        case .authorized: return "Permitido"
        @unknown default: return "Desconhecido"
        }
    }
}

// MARK: - Settings Section

struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)

                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 0) {
                content
            }
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(VoxTheme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(VoxTheme.surfaceBorder, lineWidth: 1)
            )
        }
    }
}

// MARK: - Settings Row

struct SettingsRow<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let trailing: Content

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14))

                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            trailing
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Settings Toggle Row

struct SettingsToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        SettingsRow(title: title, subtitle: subtitle) {
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .labelsHidden()
        }
    }
}

// MARK: - Shortcut Badge

struct ShortcutBadge: View {
    let shortcut: String

    var body: some View {
        Text(shortcut)
            .font(.system(size: 13, weight: .medium, design: .monospaced))
            .foregroundStyle(VoxTheme.accent)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(VoxTheme.accentMuted)
            .cornerRadius(6)
    }
}

// MARK: - Shortcut Editor (NSEvent-based, works on macOS 13+)

struct ShortcutEditor: View {
    @Binding var shortcut: String
    let placeholder: String

    @State private var isEditing = false
    @State private var tempShortcut = ""
    @State private var eventMonitor: Any?

    /// Global flag — when true, AppDelegate skips all shortcut processing so
    /// the capture editor can intercept the key press cleanly.
    static var isCapturing = false

    var body: some View {
        Button(action: {
            if isEditing {
                stopEditing()
            } else {
                startEditing()
            }
        }) {
            HStack(spacing: 6) {
                Text(isEditing ? (tempShortcut.isEmpty ? "Pressione..." : tempShortcut) : shortcut)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(isEditing ? VoxTheme.accent : VoxTheme.accent)

                if !isEditing {
                    Image(systemName: "pencil")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                } else {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(VoxTheme.accent)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(isEditing ? VoxTheme.accent.opacity(0.15) : VoxTheme.accentMuted)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isEditing ? VoxTheme.accent : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onDisappear {
            stopEditing()
        }
    }

    private func startEditing() {
        isEditing = true
        tempShortcut = ""
        ShortcutEditor.isCapturing = true

        // Ensure our window is key so local monitor receives events.
        // Necessary for .accessory-policy apps where windows don't auto-steal focus.
        NSApp.activate(ignoringOtherApps: true)
        NSApp.mainWindow?.makeKeyAndOrderFront(nil)

        // Listen for key events using NSEvent (works on macOS 13+)
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

            var parts: [String] = []

            if modifiers.contains(.control) { parts.append("⌃") }
            if modifiers.contains(.option) { parts.append("⌥") }
            if modifiers.contains(.shift) { parts.append("⇧") }
            if modifiers.contains(.command) { parts.append("⌘") }

            // Escape to cancel
            if event.keyCode == 53 {
                DispatchQueue.main.async {
                    stopEditing()
                }
                return nil
            }

            // Get key character from keyCode
            let keyChar = keyCodeToDisplayChar(event.keyCode)

            if !keyChar.isEmpty {
                parts.append(keyChar)
            }

            let newShortcut = parts.joined()

            if parts.count >= 2 && !keyChar.isEmpty {
                // Valid: at least one modifier + one key letter
                DispatchQueue.main.async {
                    shortcut = newShortcut
                    stopEditing()
                }
                return nil // consume the event
            } else if !parts.isEmpty {
                DispatchQueue.main.async {
                    tempShortcut = newShortcut
                }
                return nil
            }

            return nil
        }
    }

    private func stopEditing() {
        isEditing = false
        tempShortcut = ""
        ShortcutEditor.isCapturing = false
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    /// Map key codes to display characters (macOS virtual key codes)
    private func keyCodeToDisplayChar(_ keyCode: UInt16) -> String {
        let keyMap: [UInt16: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
            8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
            16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6", 23: "5",
            24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0", 30: "]", 31: "O",
            32: "U", 33: "[", 34: "I", 35: "P", 37: "L", 38: "J", 40: "K",
            45: "N", 46: "M",
            36: "↩", 48: "⇥", 49: "Space", 50: "`", 51: "⌫"
        ]
        return keyMap[keyCode] ?? ""
    }
}

// MARK: - Conversation Reply Step Row

struct ConversationReplyStepRow: View {
    let number: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(number)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 16, height: 16)
                .background(Circle().fill(VoxTheme.accent))

            Text(text)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
    }
}

// MARK: - Permission Badge

struct PermissionBadge: View {
    let isGranted: Bool
    let onRequest: () -> Void

    var body: some View {
        if isGranted {
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(VoxTheme.accent)
                Text("OK")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(VoxTheme.accent)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(VoxTheme.accent.opacity(0.1))
            .cornerRadius(6)
        } else {
            Button("Permitir", action: onRequest)
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
    }
}

#Preview {
    SettingsDetailView()
        .frame(width: 600, height: 800)
}
