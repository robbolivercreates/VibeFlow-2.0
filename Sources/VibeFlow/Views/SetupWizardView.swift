import SwiftUI
import AVFoundation

// MARK: - Wizard Step
enum WizardStep: Int, CaseIterable {
    case login = 0
    case permissions = 1
    case testRecording = 2
    case modesTraining = 3
    case wakeWordTest = 4
    case languageSwitch = 5
    case ready = 6

    var title: String {
        switch self {
        case .login:          return "Bem-vindo ao VoxAiGo"
        case .permissions:    return "Permissões"
        case .testRecording:  return "Primeira Gravação"
        case .modesTraining:  return "Treinar Modos"
        case .wakeWordTest:   return "Comando de Voz"
        case .languageSwitch: return "Trocar Idioma"
        case .ready:          return "Pronto para decolar 🚀"
        }
    }

    var subtitle: String {
        switch self {
        case .login:          return "Entre na sua conta para começar"
        case .permissions:    return "Necessário para capturar voz e atalhos de teclado"
        case .testRecording:  return "Segure ⌥⌘ e fale qualquer coisa"
        case .modesTraining:  return "Pressione ⌃⇧M para ciclar pelos modos"
        case .wakeWordTest:   return "Diga \"Hey Vox, Email\" sem usar o teclado"
        case .languageSwitch: return "Mude o idioma de saída por voz ou pelo seletor"
        case .ready:          return "Você aprendeu tudo. Comece a usar agora."
        }
    }

    var leftIcon: String {
        switch self {
        case .login:          return "waveform.circle.fill"
        case .permissions:    return "lock.shield.fill"
        case .testRecording:  return "mic.fill"
        case .modesTraining:  return "square.grid.2x2.fill"
        case .wakeWordTest:   return "waveform.badge.mic"
        case .languageSwitch: return "globe"
        case .ready:          return "checkmark.seal.fill"
        }
    }
}

// MARK: - Main View
struct SetupWizardView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var settings = SettingsManager.shared
    @StateObject private var auth = AuthManager.shared

    @State private var currentStep: WizardStep = .login

    // Permissions
    @State private var microphonePermission: AVAuthorizationStatus = .notDetermined
    @State private var accessibilityPermission = false
    @State private var inputMonitoringPermission = false
    @State private var permissionTimer: Timer?

    // Real Recording Test
    @State private var transcriptionResult: String? = nil
    @State private var isListeningForTranscription = false

    // Modes Training
    @State private var modeChangedCount = 0
    @State private var currentDemoMode: TranscriptionMode = SettingsManager.shared.selectedMode
    private let requiredModeCycles = 3

    // Wake Word Test
    @State private var wakeWordDetected = false
    @State private var detectedWakeCommand: String? = nil

    // Language Switch
    @State private var languageChanged = false
    @State private var selectedPickerLanguage: SpeechLanguage = SettingsManager.shared.outputLanguage

    // Notification observers
    @State private var observers: [Any] = []

    var body: some View {
        HStack(spacing: 0) {
            // ── Left Panel (40%) ──────────────────────────────────
            leftPanel
                .frame(width: 280)
                .background(Color.black)

            // ── Right Panel (60%) ─────────────────────────────────
            VStack(spacing: 0) {
                // Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        rightContent
                            .padding(36)
                    }
                }

                // Footer: progress + navigation
                wizardFooter
            }
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 780, height: 540)
        .onAppear {
            checkPermissions()
            registerObservers()
        }
        .onDisappear {
            removeObservers()
            permissionTimer?.invalidate()
        }
    }

    // MARK: - Left Panel

    private var leftPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Logo at top
            VStack(alignment: .leading, spacing: 6) {
                VoxAiGoLogo(size: 36)
                Text("VoxAiGo")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 28)
            .padding(.top, 32)

            Spacer()

            // Step visual
            leftVisual
                .padding(.horizontal, 28)

            Spacer()

            // Step label
            VStack(alignment: .leading, spacing: 6) {
                Text(currentStep.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                Text(currentStep.subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.5))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 24)
        }
    }

    @ViewBuilder
    private var leftVisual: some View {
        switch currentStep {
        case .login:
            VStack(spacing: 16) {
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(VoxTheme.accent)
                Text("Transforme voz em texto\ncom inteligência artificial")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }

        case .permissions:
            VStack(spacing: 12) {
                ForEach(["mic.fill", "accessibility", "keyboard"], id: \.self) { icon in
                    HStack(spacing: 10) {
                        Image(systemName: icon)
                            .font(.system(size: 18))
                            .foregroundStyle(VoxTheme.accent)
                            .frame(width: 32)
                        Rectangle()
                            .fill(.white.opacity(0.08))
                            .frame(height: 1)
                    }
                }
            }

        case .testRecording:
            VStack(spacing: 16) {
                Image(systemName: transcriptionResult != nil ? "checkmark.circle.fill" : "mic.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(transcriptionResult != nil ? Color.green : VoxTheme.accent)
                    .animation(.spring(), value: transcriptionResult != nil)
                Text(transcriptionResult != nil ? "Gravação funcionando!" : "Segure ⌥⌘ e fale")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }

        case .modesTraining:
            VStack(spacing: 12) {
                Image(systemName: currentDemoMode.icon)
                    .font(.system(size: 56))
                    .foregroundStyle(VoxTheme.accent)
                    .animation(.spring(), value: currentDemoMode.rawValue)
                Text(currentDemoMode.rawValue)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                Text("\(modeChangedCount)/\(requiredModeCycles) modos")
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.5))
            }

        case .wakeWordTest:
            VStack(spacing: 16) {
                Image(systemName: wakeWordDetected ? "checkmark.circle.fill" : "waveform.badge.mic")
                    .font(.system(size: 72))
                    .foregroundStyle(wakeWordDetected ? Color.green : VoxTheme.accent)
                    .animation(.spring(), value: wakeWordDetected)
                if !wakeWordDetected {
                    Text("\"\(settings.wakeWord), Email\"")
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.6))
                } else {
                    Text("Comando detectado! ✅")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.green.opacity(0.8))
                }
            }

        case .languageSwitch:
            VStack(spacing: 12) {
                Text(settings.outputLanguage.flag)
                    .font(.system(size: 64))
                    .animation(.spring(), value: settings.outputLanguage.rawValue)
                Text(settings.outputLanguage.displayName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .animation(.easeInOut, value: settings.outputLanguage.rawValue)
            }

        case .ready:
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(VoxTheme.accent.opacity(0.15))
                        .frame(width: 100, height: 100)
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(VoxTheme.accent)
                }
                Text("Bem-vindo!")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
    }

    // MARK: - Right Content

    @ViewBuilder
    private var rightContent: some View {
        switch currentStep {
        case .login:       loginContent
        case .permissions: permissionsContent
        case .testRecording: testRecordingContent
        case .modesTraining: modesTrainingContent
        case .wakeWordTest: wakeWordContent
        case .languageSwitch: languageSwitchContent
        case .ready:       readyContent
        }
    }

    // MARK: Step: Login

    private var loginContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            stepHeader(title: "Entre na sua conta", subtitle: "Crie uma conta gratuita ou faça login para começar a usar o VoxAiGo.")

            if auth.isAuthenticated {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(VoxTheme.accent)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Logado com sucesso!")
                            .font(.system(size: 15, weight: .semibold))
                        if let email = auth.userEmail {
                            Text(email)
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(VoxTheme.accent.opacity(0.08))
                .cornerRadius(12)
            } else {
                LoginView()
            }
        }
    }

    // MARK: Step: Permissions

    private var permissionsContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            stepHeader(title: "Permissões necessárias", subtitle: "O VoxAiGo precisa de 3 permissões para capturar sua voz e responder ao atalho de teclado.")

            VStack(spacing: 10) {
                PermissionCard(
                    icon: "mic.fill",
                    title: "🎤 Microfone",
                    description: "Para gravar sua voz durante a ditação.",
                    isGranted: microphonePermission == .authorized,
                    buttonText: "Permitir Microfone",
                    helpSteps: ["Clique em \"Permitir Microfone\"", "Na janela do macOS, clique em \"OK\""],
                    action: requestMicrophonePermission
                )
                PermissionCard(
                    icon: "accessibility",
                    title: "Acessibilidade",
                    description: "Para colar o texto automaticamente onde você está digitando.",
                    isGranted: accessibilityPermission,
                    buttonText: "Abrir Preferências",
                    helpSteps: ["Clique em \"Abrir Preferências\"", "Arraste o ícone do VoxAiGo para a lista", "Ative o toggle ao lado de \"VoxAiGo\""],
                    action: openAccessibilitySettings
                )
                PermissionCard(
                    icon: "keyboard",
                    title: "Monitoramento de Entrada",
                    description: "Para detectar o atalho ⌥⌘ sem que o VoxAiGo precise estar em foco.",
                    isGranted: inputMonitoringPermission,
                    buttonText: "Abrir Preferências",
                    helpSteps: ["Clique em \"Abrir Preferências\"", "Adicione e ative o VoxAiGo na lista"],
                    action: openInputMonitoringSettings
                )
            }

            if allPermissionsGranted {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(VoxTheme.accent)
                    Text("Todas as permissões concedidas. Pode continuar!").font(.system(size: 13, weight: .medium)).foregroundStyle(VoxTheme.accent)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(VoxTheme.accent.opacity(0.08))
                .cornerRadius(10)
            }
        }
        .onAppear { startPermissionChecking() }
        .onDisappear { permissionTimer?.invalidate() }
    }

    // MARK: Step: Real Recording Test

    private var testRecordingContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            stepHeader(title: "Faça sua primeira gravação", subtitle: "Segure ⌥⌘ (Option + Command), fale qualquer coisa e solte. O resultado aparecerá abaixo.")

            // Shortcut visual badge
            HStack(spacing: 12) {
                Text("⌥⌘")
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundStyle(VoxTheme.accent)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(VoxTheme.accent.opacity(0.12))
                    .cornerRadius(8)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Segurar para gravar")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Option + Command — solte para transcrever")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)

            // Result area
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "text.bubble")
                        .foregroundStyle(.secondary)
                    Text("Resultado da transcrição")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                    if transcriptionResult != nil {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(VoxTheme.accent)
                    }
                }

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(NSColor.controlBackgroundColor))
                        .frame(minHeight: 90)
                    if let result = transcriptionResult {
                        Text(result)
                            .font(.system(size: 14))
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Text("Aguardando gravação…")
                            .font(.system(size: 14))
                            .foregroundStyle(.tertiary)
                            .padding(12)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(transcriptionResult != nil ? VoxTheme.accent.opacity(0.4) : Color.clear, lineWidth: 1.5)
                )

                if transcriptionResult != nil {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(VoxTheme.accent).font(.caption)
                        Text("Transcrição funcionando! Pode continuar.")
                            .font(.caption).foregroundStyle(VoxTheme.accent)
                    }
                }
            }

            // Tip
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill").foregroundStyle(.yellow).font(.caption)
                Text("Dica: No modo **Text**, a transcrição é colada automaticamente onde você estava digitando.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .padding(10)
            .background(Color.yellow.opacity(0.06))
            .cornerRadius(8)
        }
    }

    // MARK: Step: Modes Training

    private let featuredModes: [(TranscriptionMode, String)] = [
        (.text, "Transcrição limpa sem formatação extra"),
        (.vibeCoder, "Converte sua fala em prompt otimizado para AI"),
        (.email, "Formata automaticamente como e-mail profissional"),
        (.meeting, "Gera atas e action items da reunião"),
        (.social, "Adapta o texto para redes sociais")
    ]

    private var modesTrainingContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            stepHeader(title: "Treinar ciclo de modos", subtitle: "Existem 3 formas de trocar de modo. Teste pelo menos \(requiredModeCycles) vezes para avançar.")

            // Method 1: Keyboard shortcut ⌃⇧M
            HStack(spacing: 12) {
                Text("⌃⇧M")
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundStyle(VoxTheme.accent)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(VoxTheme.accent.opacity(0.12)).cornerRadius(8)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Atalho de teclado")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Control + Shift + M — cicla para o próximo modo")
                        .font(.system(size: 12)).foregroundStyle(.secondary)
                }
                Spacer()
                // Counter badge
                Text("\(min(modeChangedCount, requiredModeCycles))/\(requiredModeCycles)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(modeChangedCount >= requiredModeCycles ? VoxTheme.accent : .secondary)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(modeChangedCount >= requiredModeCycles ? VoxTheme.accent.opacity(0.12) : Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)

            // Method 2: Voice command
            HStack(spacing: 12) {
                Image(systemName: "waveform.badge.mic")
                    .font(.system(size: 20))
                    .foregroundStyle(VoxTheme.accent)
                    .frame(width: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Comando de voz")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Diga \"\(settings.wakeWord), Email\" ou \"\(settings.wakeWord), Coder\" durante a gravação")
                        .font(.system(size: 12)).foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)

            // Method 3: Cycle next shortcut
            HStack(spacing: 12) {
                Text("⌃⇧N")
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundStyle(VoxTheme.accent)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(VoxTheme.accent.opacity(0.12)).cornerRadius(8)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Atalho alternativo")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Control + Shift + N — outra forma de ciclar modos")
                        .font(.system(size: 12)).foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)

            // Progress dots
            HStack(spacing: 6) {
                ForEach(0..<requiredModeCycles, id: \.self) { i in
                    Circle()
                        .fill(i < modeChangedCount ? VoxTheme.accent : Color(NSColor.separatorColor))
                        .frame(width: 10, height: 10)
                        .animation(.spring(), value: modeChangedCount)
                }
                Spacer()
            }

            // Featured modes list
            VStack(spacing: 8) {
                ForEach(featuredModes, id: \.0.rawValue) { mode, desc in
                    HStack(spacing: 12) {
                        Image(systemName: mode.icon)
                            .font(.system(size: 16))
                            .foregroundStyle(currentDemoMode == mode ? VoxTheme.accent : .secondary)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(mode.rawValue)
                                .font(.system(size: 13, weight: currentDemoMode == mode ? .semibold : .regular))
                                .foregroundStyle(currentDemoMode == mode ? .primary : .secondary)
                            Text(desc)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        Spacer()
                        if currentDemoMode == mode {
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(VoxTheme.accent)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(currentDemoMode == mode ? VoxTheme.accent.opacity(0.07) : Color.clear)
                    .cornerRadius(8)
                    .animation(.easeInOut(duration: 0.2), value: currentDemoMode.rawValue)
                }
            }
        }
    }

    // MARK: Step: Wake Word Test

    private var wakeWordContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            stepHeader(title: "Comando de voz", subtitle: "Sem tocar no teclado — use sua voz para mudar de modo.")

            // Instruction card
            VStack(alignment: .leading, spacing: 12) {
                Text("Como fazer:")
                    .font(.system(size: 13, weight: .semibold))

                VStack(alignment: .leading, spacing: 8) {
                    WizardInstructionRow(number: "1", text: "Segure ⌥⌘ normalmente")
                    WizardInstructionRow(number: "2", text: "Fale: \"\(settings.wakeWord), Email\"")
                    WizardInstructionRow(number: "3", text: "Solte — o modo muda automaticamente")
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)

            // Result
            if wakeWordDetected {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.green)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Comando detectado!")
                            .font(.system(size: 15, weight: .semibold))
                        if let cmd = detectedWakeCommand {
                            Text(cmd)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.green.opacity(0.08))
                .cornerRadius(12)
            } else {
                HStack(spacing: 8) {
                    ProgressView().scaleEffect(0.7)
                    Text("Aguardando comando \"\(settings.wakeWord), Email\"…")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
            }

            // Wake word tip
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill").foregroundStyle(VoxTheme.accent).font(.caption)
                Text("Você pode personalizar a palavra de ativação em Configurações → Comandos de Voz.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            .padding(10).background(VoxTheme.accent.opacity(0.05)).cornerRadius(8)
        }
    }

    // MARK: Step: Language Switch

    private var languageSwitchContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            stepHeader(title: "Trocar idioma de saída", subtitle: "Use sua voz ou o seletor abaixo para mudar o idioma em que o texto será escrito.")

            // Voice option
            VStack(alignment: .leading, spacing: 10) {
                Label("Por voz", systemImage: "waveform.badge.mic")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                HStack(spacing: 10) {
                    Text("\"\(settings.wakeWord), Inglês\"")
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundStyle(VoxTheme.accent)
                    Text("ou")
                        .foregroundStyle(.secondary)
                    Text("\"\(settings.wakeWord), próximo idioma\"")
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundStyle(VoxTheme.accent)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)

            Divider()

            // Manual picker
            VStack(alignment: .leading, spacing: 10) {
                Label("Ou selecione manualmente", systemImage: "hand.point.up")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                Picker("", selection: $selectedPickerLanguage) {
                    ForEach(SpeechLanguage.allCases, id: \.self) { lang in
                        Text("\(lang.flag) \(lang.displayName)").tag(lang)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
                .onChange(of: selectedPickerLanguage) { newLang in
                    settings.outputLanguage = newLang
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)

            if languageChanged {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                    Text("Idioma alterado para \(settings.outputLanguage.flag) \(settings.outputLanguage.displayName)!")
                        .font(.system(size: 13, weight: .medium)).foregroundStyle(.green)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.green.opacity(0.08)).cornerRadius(10)
            }
        }
    }

    // MARK: Step: Ready

    private var readyContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            stepHeader(title: "Tudo configurado! 🎉", subtitle: "Aqui está o resumo de tudo que você pode fazer com o VoxAiGo.")

            // Cheat sheet
            VStack(alignment: .leading, spacing: 8) {
                Text("Guia rápido de atalhos")
                    .font(.system(size: 13, weight: .semibold))
                    .padding(.bottom, 4)

                Group {
                    QuickRefRow(keys: "⌥⌘", action: "Gravar", description: "Segurar para gravar, soltar para transcrever")
                    QuickRefRow(keys: "⌃⇧M", action: "Ciclar Modos", description: "Próximo modo na lista")
                    QuickRefRow(keys: "⌃⇧L", action: "Ciclar Idiomas", description: "Idiomas favoritos em ordem")
                    QuickRefRow(keys: "⌘,", action: "Configurações", description: "Personalizar tudo")
                    QuickRefRow(keys: "⌘⇧V", action: "Mostrar/Ocultar", description: "Janela principal do VoxAiGo")
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)

            // Voice commands hint
            VStack(alignment: .leading, spacing: 8) {
                Label("Comandos de voz", systemImage: "waveform.badge.mic")
                    .font(.system(size: 13, weight: .semibold))
                    .padding(.bottom, 2)
                ForEach([
                    ("\(settings.wakeWord), Email", "Mudar para modo E-mail"),
                    ("\(settings.wakeWord), Inglês", "Mudar para inglês"),
                    ("\(settings.wakeWord), próximo idioma", "Avançar idioma")
                ], id: \.0) { cmd, desc in
                    HStack {
                        Text("\"\(cmd)\"")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(VoxTheme.accent)
                        Text("→ \(desc)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(VoxTheme.accent.opacity(0.05))
            .cornerRadius(12)
        }
    }

    // MARK: - Footer

    private var wizardFooter: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 16) {
                // Back
                if currentStep != .login {
                    Button(action: goBack) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left").font(.caption)
                            Text("Voltar")
                        }
                    }
                    .buttonStyle(.bordered)
                }

                Spacer()

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(NSColor.separatorColor))
                        RoundedRectangle(cornerRadius: 3)
                            .fill(VoxTheme.accent)
                            .frame(width: geo.size.width * CGFloat(currentStep.rawValue + 1) / CGFloat(WizardStep.allCases.count))
                            .animation(.spring(), value: currentStep.rawValue)
                    }
                }
                .frame(width: 120, height: 4)

                Text("\(currentStep.rawValue + 1) de \(WizardStep.allCases.count)")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)

                Spacer()

                // Skip (for optional steps)
                if canSkip {
                    Button("Pular") { goNext() }
                        .buttonStyle(.bordered)
                        .foregroundStyle(.secondary)
                }

                // Next / Finish
                Button(action: goNext) {
                    HStack(spacing: 6) {
                        Text(currentStep == .ready ? "Começar!" : "Continuar")
                        if currentStep != .ready {
                            Image(systemName: "chevron.right").font(.caption)
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(VoxTheme.accent)
                .disabled(!canProceed)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
        }
    }

    // MARK: - Navigation

    private var canProceed: Bool {
        switch currentStep {
        case .login:          return auth.isAuthenticated
        case .permissions:    return allPermissionsGranted
        case .testRecording:  return transcriptionResult != nil
        case .modesTraining:  return modeChangedCount >= requiredModeCycles
        case .wakeWordTest:   return wakeWordDetected  // also skippable
        case .languageSwitch: return languageChanged    // also skippable
        case .ready:          return true
        }
    }

    private var canSkip: Bool {
        currentStep == .wakeWordTest || currentStep == .languageSwitch
    }

    private func goNext() {
        withAnimation(.easeInOut) {
            if currentStep == .ready {
                completeWizard()
            } else if let next = WizardStep(rawValue: currentStep.rawValue + 1) {
                currentStep = next
            }
        }
    }

    private func goBack() {
        withAnimation(.easeInOut) {
            if let prev = WizardStep(rawValue: currentStep.rawValue - 1) {
                currentStep = prev
            }
        }
    }

    private func completeWizard() {
        settings.onboardingCompleted = true
        dismiss()
    }

    // MARK: - Real Notification Observers

    private func registerObservers() {
        let nc = NotificationCenter.default

        // Real transcription result
        let t = nc.addObserver(forName: .transcriptionComplete, object: nil, queue: .main) { notif in
            if let text = notif.object as? String, !text.isEmpty {
                self.transcriptionResult = text
            } else if let text = notif.userInfo?["text"] as? String, !text.isEmpty {
                self.transcriptionResult = text
            }
        }

        // Real mode change (for training step)
        let m = nc.addObserver(forName: .modeChanged, object: nil, queue: .main) { notif in
            if let mode = notif.object as? TranscriptionMode {
                self.currentDemoMode = mode
            } else {
                self.currentDemoMode = SettingsManager.shared.selectedMode
            }
            if self.currentStep == .modesTraining {
                self.modeChangedCount = min(self.modeChangedCount + 1, 10)
            }
        }

        // Real wake word command
        let w = nc.addObserver(forName: .wakeWordCommand, object: nil, queue: .main) { notif in
            self.wakeWordDetected = true
            if let text = notif.object as? String {
                self.detectedWakeCommand = text
            } else if let info = notif.userInfo,
                      let modeRaw = info["mode"] as? String {
                self.detectedWakeCommand = "→ Modo: \(modeRaw)"
            } else if let info = notif.userInfo,
                      let langRaw = info["language"] as? String {
                self.detectedWakeCommand = "→ Idioma: \(langRaw)"
            }
        }

        // Real language change
        let l = nc.addObserver(forName: .languageChanged, object: nil, queue: .main) { _ in
            if self.currentStep == .languageSwitch {
                self.languageChanged = true
            }
        }

        observers = [t, m, w, l]
    }

    private func removeObservers() {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
        observers = []
    }

    // MARK: - Permissions Helpers

    private var allPermissionsGranted: Bool {
        microphonePermission == .authorized && accessibilityPermission && inputMonitoringPermission
    }

    private func checkPermissions() {
        microphonePermission = AVCaptureDevice.authorizationStatus(for: .audio)
        accessibilityPermission = AXIsProcessTrusted()
        inputMonitoringPermission = CGRequestPostEventAccess()
    }

    private func startPermissionChecking() {
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            checkPermissions()
        }
    }

    private func requestMicrophonePermission() {
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            DispatchQueue.main.async {
                self.microphonePermission = granted ? .authorized : .denied
            }
        }
    }

    private func openAccessibilitySettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
    }

    private func openInputMonitoringSettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent")!)
    }
}

// MARK: - Helper Views

private struct WizardInstructionRow: View {
    let number: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(number)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(VoxTheme.accent)
                .clipShape(Circle())
            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(.primary)
        }
    }
}

private func stepHeader(title: String, subtitle: String) -> some View {
    VStack(alignment: .leading, spacing: 6) {
        Text(title)
            .font(.system(size: 22, weight: .bold))
        Text(subtitle)
            .font(.system(size: 14))
            .foregroundStyle(.secondary)
    }
}

// MARK: - Shared Helper Components

struct PermissionCard: View {
    let icon: String
    let title: String
    let description: String
    let isGranted: Bool
    let buttonText: String
    let helpSteps: [String]
    let action: () -> Void

    init(icon: String, title: String, description: String, isGranted: Bool, buttonText: String, helpSteps: [String] = [], action: @escaping () -> Void) {
        self.icon = icon; self.title = title; self.description = description
        self.isGranted = isGranted; self.buttonText = buttonText
        self.helpSteps = helpSteps; self.action = action
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isGranted ? VoxTheme.accent.opacity(0.15) : VoxTheme.surface)
                        .frame(width: 44, height: 44)
                    Image(systemName: isGranted ? "checkmark" : icon)
                        .font(.system(size: 18))
                        .foregroundStyle(isGranted ? VoxTheme.accent : .white)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.system(size: 14, weight: .medium))
                    Text(description).font(.system(size: 12)).foregroundStyle(.secondary).lineLimit(2)
                }
                Spacer()
                if isGranted {
                    Image(systemName: "checkmark.circle.fill").font(.system(size: 24)).foregroundStyle(VoxTheme.accent)
                } else {
                    Button(buttonText, action: action).buttonStyle(.borderedProminent).controlSize(.small)
                }
            }
            if !isGranted && !helpSteps.isEmpty {
                Divider().padding(.vertical, 8)
                VStack(alignment: .leading, spacing: 5) {
                    Text("Como fazer:").font(.system(size: 11, weight: .semibold)).foregroundStyle(VoxTheme.accent)
                    ForEach(Array(helpSteps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 6) {
                            Text("\(index + 1).").font(.system(size: 11, weight: .bold, design: .monospaced)).foregroundStyle(VoxTheme.accent.opacity(0.8)).frame(width: 16, alignment: .trailing)
                            Text(step).font(.system(size: 11)).foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.leading, 60)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(isGranted ? VoxTheme.accent.opacity(0.05) : VoxTheme.surface))
    }
}

struct QuickRefRow: View {
    let keys: String
    let action: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Text(keys)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(VoxTheme.accent)
                .padding(.horizontal, 8).padding(.vertical, 5)
                .background(VoxTheme.accent.opacity(0.1)).cornerRadius(6)
            VStack(alignment: .leading, spacing: 2) {
                Text(action).font(.system(size: 13, weight: .medium))
                Text(description).font(.system(size: 12)).foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}

#Preview {
    SetupWizardView()
}
