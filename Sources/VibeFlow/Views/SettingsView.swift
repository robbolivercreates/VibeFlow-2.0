import SwiftUI
import AVFoundation
import IOKit

/// View de configurações do VibeFlow
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var settings = SettingsManager.shared
    @State private var showingResetConfirmation = false
    @State private var showingWizard = false
    @State private var microphonePermission: AVAuthorizationStatus = .notDetermined
    @State private var accessibilityPermission = false
    @State private var inputMonitoringPermission = false
    
    var body: some View {
        TabView {
            // Tab: Geral
            generalTab
                .tabItem {
                    Label(L10n.general, systemImage: "gear")
                }
            
            // Tab: API
            apiTab
                .tabItem {
                    Label(L10n.api, systemImage: "key")
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
                            .foregroundStyle(.purple)
                            .font(.system(.body, design: .monospaced, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.purple.opacity(0.1))
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
                                        .foregroundStyle(.blue)
                                }
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(
                                settings.favoriteLanguages.contains(language)
                                ? Color.blue.opacity(0.1)
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
                        Text("\(WritingStyleManager.shared.totalSamples) \(L10n.samplesSaved)")
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

    private var apiTab: some View {
        Form {
            Section(L10n.geminiAPI) {
                SecureField(L10n.api, text: $settings.apiKey)
                    .textFieldStyle(.roundedBorder)
                
                Text(L10n.apiKeyStoredInKeychain)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Link(destination: URL(string: "https://aistudio.google.com/app/apikey")!) {
                    HStack {
                        Image(systemName: "arrow.up.right.square")
                        Text(L10n.getAPIKeyGoogleAI)
                    }
                }
                .padding(.top, 4)
            }
            
            Section(L10n.about) {
                HStack {
                    Text(L10n.model)
                    Spacer()
                    Text(L10n.geminiModel)
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text(L10n.version)
                    Spacer()
                    Text(AppVersion.current)
                        .foregroundStyle(.secondary)
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
                        .foregroundStyle(microphonePermission == .authorized ? .green : .orange)
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
                            .foregroundStyle(.green)
                    }
                }
                
                // Acessibilidade
                HStack {
                    Image(systemName: "accessibility")
                        .foregroundStyle(accessibilityPermission ? .green : .orange)
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
                            .foregroundStyle(.green)
                    }
                }
                
                // Input Monitoring
                HStack {
                    Image(systemName: "keyboard")
                        .foregroundStyle(inputMonitoringPermission ? .green : .orange)
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
                            .foregroundStyle(.green)
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
                .foregroundStyle(.red)
                .disabled(HistoryManager.shared.items.isEmpty)
            }
            
            Section(L10n.support) {
                Link(destination: URL(string: "https://github.com/seu-usuario/vibeflow")!) {
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

#Preview {
    SettingsView()
}
