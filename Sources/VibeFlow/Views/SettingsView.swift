import SwiftUI
import AVFoundation
import IOKit

/// View de configurações do VoxAiGo
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var settings = SettingsManager.shared
    @State private var showingResetConfirmation = false
    @State private var showingWizard = false
    @State private var microphonePermission: AVAuthorizationStatus = .notDetermined
    @State private var accessibilityPermission = false
    @State private var inputMonitoringPermission = false

    // Easter egg state
    @State private var versionTapCount = 0
    @State private var showEasterEggPrompt = false
    @State private var easterEggPassword = ""
    @StateObject private var subscription = SubscriptionManager.shared

    private func activateEasterEgg() {
        if easterEggPassword == "voxdev" {
            subscription.activateDevMode()
        }
        showEasterEggPrompt = false
        easterEggPassword = ""
    }
    
    var body: some View {
        TabView {
            // Tab: Geral
            generalTab
                .tabItem {
                    Label(L10n.general, systemImage: "gear")
                }
            
            // Tab: Account
            accountTab
                .tabItem {
                    Label(L10n.account, systemImage: "person.crop.circle")
                }
            
            // Tab: Wizard & Permissões
            wizardPermissionsTab
                .tabItem {
                    Label(L10n.setupWizard, systemImage: "wand.and.stars")
                }
            
            // Tab: Avançado
            advancedTab
                .tabItem {
                    Label(L10n.advanced, systemImage: "slider.horizontal.3")
                }
        }
        .padding(20)
        .frame(width: 500, height: 400)
        .onAppear {
            checkPermissions()
        }
        .sheet(isPresented: $showingWizard) {
            SetupWizardView()
        }
    }
    
    private func checkPermissions() {
        microphonePermission = AVCaptureDevice.authorizationStatus(for: .audio)
        
        // Verificar acessibilidade
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        accessibilityPermission = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        // Verificar Input Monitoring (via IOHIDRequestAccess)
        inputMonitoringPermission = IOHIDRequestAccess(kIOHIDRequestTypeListenEvent)
    }
    
    // MARK: - Tabs
    
    private var generalTab: some View {
        Form {
            Section {
                Picker(L10n.defaultMode, selection: $settings.selectedMode) {
                    ForEach(TranscriptionMode.allCases, id: \.self) { mode in
                        Text(mode.localizedName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                Text(L10n.modeDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section(L10n.outputLanguage) {
                Picker(L10n.languages, selection: $settings.outputLanguage) {
                    ForEach(SpeechLanguage.allCases) { language in
                        Text(language.displayWithFlag).tag(language)
                    }
                }
                .pickerStyle(.menu)

                Text(L10n.outputLanguageDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                // Atalho para ciclar idiomas
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(L10n.shortcutToChangeLanguage)
                            .font(.system(size: 13, weight: .medium))
                        Spacer()
                        Text(settings.cycleLanguageShortcut)
                            .foregroundStyle(VoxTheme.accent)
                            .font(.system(.body, design: .monospaced, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(VoxTheme.accentMuted)
                            .cornerRadius(4)
                    }
                    
                    Text(L10n.pressCtrlShiftL)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Section(L10n.favoriteLangsForQuickSwitch) {
                Text(L10n.selectFrequentLanguages)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                // List of all languages with checkmarks for favorites
                let columns = [GridItem(.adaptive(minimum: 120))]
                LazyVGrid(columns: columns, alignment: .leading, spacing: 4) {
                    ForEach(SpeechLanguage.allCases) { language in
                        Button(action: {
                            toggleFavorite(language: language)
                        }) {
                            HStack(spacing: 4) {
                                Text(language.flag)
                                    .font(.system(size: 12))
                                Text(language.rawValue.uppercased())
                                    .font(.system(size: 11))
                                Spacer()
                                if settings.favoriteLanguages.contains(language) {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10))
                                        .foregroundStyle(VoxTheme.accent)
                                }
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(
                                settings.favoriteLanguages.contains(language)
                                ? VoxTheme.accent.opacity(0.1)
                                : Color.clear
                            )
                            .cornerRadius(4)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Section(L10n.behavior) {
                Toggle(L10n.autoPasteToggle, isOn: $settings.enableAutoPaste)
                Toggle(L10n.autoClose, isOn: $settings.enableAutoClose)
                Toggle(L10n.saveHistory, isOn: $settings.enableHistory)
                Toggle(L10n.soundEffects, isOn: $settings.enableSounds)
            }

            Section(L10n.personalization) {
                Toggle(L10n.styleLearning, isOn: $settings.enableStyleLearning)

                Text(L10n.writingStyleDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if WritingStyleManager.shared.totalSamples > 0 {
                    HStack {
                        Text(L10n.samplesSaved(WritingStyleManager.shared.totalSamples))
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Button(L10n.clear) {
                            WritingStyleManager.shared.clearAllSamples()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }
        }
    }

    private var accountTab: some View {
        Form {
            AccountView(onVersionTap: {
                versionTapCount += 1
                if versionTapCount >= 5 {
                    versionTapCount = 0
                    showEasterEggPrompt = true
                }
            })

            // Easter egg: BYOK section (hidden by default)
            if settings.byokEnabled {
                Section("BYOK (Bring Your Own Key)") {
                    SecureField("Gemini API Key", text: $settings.byokApiKey)
                        .textFieldStyle(.roundedBorder)

                    Text(L10n.byokDescription)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Toggle(L10n.byokToggle, isOn: $settings.byokEnabled)
                }
            }

            // Easter egg prompt
            if showEasterEggPrompt {
                Section {
                    HStack {
                        SecureField("Password", text: $easterEggPassword)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit {
                                activateEasterEgg()
                            }

                        Button("OK") {
                            activateEasterEgg()
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
        }
    }
    
    private var wizardPermissionsTab: some View {
        Form {
            Section(L10n.setupWizard) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.setupWizard)
                            .font(.body)
                        
                        Text(L10n.rerunWizard)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(L10n.openWizardShort) {
                        showingWizard = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
            
            Section(L10n.permissions) {
                // Microfone
                HStack {
                    Image(systemName: "microphone.fill")
                        .foregroundStyle(microphonePermission == .authorized ? VoxTheme.accent : .white)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.microphone)
                            .font(.body)
                        
                        Text(permissionStatusText(microphonePermission))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    if microphonePermission != .authorized {
                        Button(L10n.request) {
                            AVCaptureDevice.requestAccess(for: .audio) { _ in
                                DispatchQueue.main.async {
                                    checkPermissions()
                                }
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(VoxTheme.accent)
                    }
                }

                // Acessibilidade
                HStack {
                    Image(systemName: "accessibility")
                        .foregroundStyle(accessibilityPermission ? VoxTheme.accent : .white)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.accessibility)
                            .font(.body)
                        
                        Text(accessibilityPermission ? L10n.allowed : L10n.requiredForAutoPaste)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    if !accessibilityPermission {
                        Button(L10n.openPreferences) {
                            let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                            NSWorkspace.shared.open(url)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(VoxTheme.accent)
                    }
                }

                // Input Monitoring
                HStack {
                    Image(systemName: "keyboard")
                        .foregroundStyle(inputMonitoringPermission ? VoxTheme.accent : .white)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.inputMonitoring)
                            .font(.body)
                        
                        Text(inputMonitoringPermission ? L10n.allowed : L10n.requiredForShortcuts)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    if !inputMonitoringPermission {
                        Button(L10n.allow) {
                            let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent")!
                            NSWorkspace.shared.open(url)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(VoxTheme.accent)
                    }
                }
            }

            Section {
                Text(L10n.permissionsHint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var advancedTab: some View {
        Form {
            // MARK: Voice Commands (Wake Word)
            Section {
                // Enable toggle
                Toggle(isOn: $settings.wakeWordEnabled) {
                    Label(L10n.wakeWordEnabled, systemImage: "waveform.badge.mic")
                }

                if settings.wakeWordEnabled {
                    // Wake word text field
                    HStack {
                        Text(L10n.wakeWordLabel)
                            .foregroundStyle(.primary)
                        Spacer()
                        TextField("Hey Vox", text: $settings.wakeWord)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 140)
                            .multilineTextAlignment(.trailing)
                    }

                    // Live preview
                    HStack(spacing: 4) {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                        Text(L10n.wakeWordPreview(settings.wakeWord.isEmpty ? "Hey Vox" : settings.wakeWord))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 2)
                }
            } header: {
                Text(L10n.voiceCommandsTitle)
            } footer: {
                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.wakeWordExplanation)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Divider()

                    Text(L10n.wakeWordModes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)
            }

            // MARK: Shortcuts
            Section(L10n.shortcuts) {
                HStack {
                    Text(L10n.record)
                    Spacer()
                    Text("⌥⌘ (segure)")
                        .foregroundStyle(.secondary)
                        .font(.system(.body, design: .monospaced))
                }

                HStack {
                    Text(L10n.showHideShort)
                    Spacer()
                    Text("⌘⇧V")
                        .foregroundStyle(.secondary)
                        .font(.system(.body, design: .monospaced))
                }

                HStack {
                    Text(L10n.cycleMode)
                    Spacer()
                    Text(settings.cycleModeShortcut)
                        .foregroundStyle(.secondary)
                        .font(.system(.body, design: .monospaced))
                }

                HStack {
                    Text(L10n.settingsTitle)
                    Spacer()
                    Text("⌘,")
                        .foregroundStyle(.secondary)
                        .font(.system(.body, design: .monospaced))
                }
            }

            Section(L10n.data) {
                Button(L10n.clearHistory) {
                    HistoryManager.shared.clear()
                }
                .foregroundStyle(VoxTheme.danger)
                .disabled(HistoryManager.shared.items.isEmpty)
            }

            Section(L10n.support) {
                Link(destination: URL(string: "https://github.com/seu-usuario/voxaigo")!) {
                    HStack {
                        Image(systemName: "questionmark.circle")
                        Text(L10n.helpAndDocs)
                    }
                }
            }
        }
    }

    
    // MARK: - Helpers
    
    private func permissionStatusText(_ status: AVAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return L10n.statusNotDetermined
        case .restricted: return L10n.statusRestricted
        case .denied: return L10n.statusDenied
        case .authorized: return L10n.statusAuthorized
        @unknown default: return L10n.statusUnknown
        }
    }
    
    private func toggleFavorite(language: SpeechLanguage) {
        if let index = settings.favoriteLanguages.firstIndex(of: language) {
            // Don't remove if it's the last favorite
            if settings.favoriteLanguages.count > 1 {
                settings.favoriteLanguages.remove(at: index)
            }
        } else {
            settings.favoriteLanguages.append(language)
            // Sort to maintain consistent order
            settings.favoriteLanguages.sort { $0.displayName < $1.displayName }
        }
    }
}

// MARK: - BYOK Localization

extension L10n {
    static var byokDescription: String { t("Use your own Gemini API key directly (bypasses server).", "Use sua propria chave API do Gemini diretamente (bypassa o servidor).", "Usa tu propia clave API de Gemini directamente (bypassa el servidor).") }
    static var byokToggle: String { t("Enable BYOK", "Ativar BYOK", "Activar BYOK") }

    // Wake word
    static var voiceCommandsTitle: String { t("Voice Commands", "Comandos de Voz", "Comandos de Voz") }
    static var wakeWordEnabled: String { t("Enable voice mode switching", "Ativar troca de modo por voz", "Activar cambio de modo por voz") }
    static var wakeWordLabel: String { t("Wake Word", "Palavra de Ativação", "Palabra de Activación") }
    static func wakeWordPreview(_ word: String) -> String {
        t("Say \"\(word), Email\" to switch to Email mode",
          "Diga \"\(word), Email\" para mudar para o modo Email",
          "Di \"\(word), Email\" para cambiar al modo Email")
    }
    static var wakeWordExplanation: String {
        t("While recording (hold ⌥⌘), start by saying your wake word followed by the mode name. The app will switch modes without pasting any text. You can also use keyboard shortcuts below.",
          "Durante a gravação (segure ⌥⌘), comece dizendo a palavra de ativação seguida do nome do modo. O app troca o modo sem colar nenhum texto. Você também pode usar os atalhos de teclado abaixo.",
          "Durante la grabación (mantén ⌥⌘), empieza diciendo la palabra de activación seguida del nombre del modo. La app cambia el modo sin pegar texto. También puedes usar los atajos de teclado.")
    }
    static var wakeWordModes: String {
        t("Available modes: Text, Chat, Code, Vibe Coder, Email, Formal, Social, X, Summary, Topics, Meeting, UX Design, Translation, Creative, Custom",
          "Modos disponíveis: Texto, Chat, Código, Vibe Coder, Email, Formal, Social, X, Resumo, Tópicos, Reunião, UX Design, Tradução, Criativo, Meu Modo",
          "Modos disponibles: Texto, Chat, Código, Vibe Coder, Email, Formal, Social, X, Resumen, Temas, Reunión, UX Design, Traducción, Creativo, Mi Modo")
    }
    static var cycleMode: String { t("Cycle mode", "Ciclar modo", "Ciclar modo") }
}


#Preview {
    SettingsView()
}
