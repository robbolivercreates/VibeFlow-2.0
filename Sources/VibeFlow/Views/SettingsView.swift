import SwiftUI
import AVFoundation

/// View de configurações do VibeFlow
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var settings = SettingsManager.shared
    @State private var showingResetConfirmation = false
    @State private var showingWizard = false
    @State private var microphonePermission: AVAuthorizationStatus = .notDetermined
    @State private var accessibilityPermission = false
    
    var body: some View {
        TabView {
            // Tab: Geral
            generalTab
                .tabItem {
                    Label("Geral", systemImage: "gear")
                }
            
            // Tab: API
            apiTab
                .tabItem {
                    Label("API", systemImage: "key")
                }
            
            // Tab: Wizard & Permissões
            wizardPermissionsTab
                .tabItem {
                    Label("Wizard", systemImage: "wand.and.stars")
                }
            
            // Tab: Avançado
            advancedTab
                .tabItem {
                    Label("Avançado", systemImage: "slider.horizontal.3")
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
    }
    
    // MARK: - Tabs
    
    private var generalTab: some View {
        Form {
            Section {
                Picker("Modo padrão", selection: $settings.selectedMode) {
                    ForEach(TranscriptionMode.allCases, id: \.self) { mode in
                        Text(mode.localizedName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                Text("O modo determina como o Gemini processa seu áudio.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Idioma de saida") {
                Picker("Idioma", selection: $settings.outputLanguage) {
                    ForEach(SpeechLanguage.allCases) { language in
                        Text(language.displayWithFlag).tag(language)
                    }
                }
                .pickerStyle(.menu)

                Text("O texto transcrito sera gerado neste idioma, independente do idioma falado.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                // Atalho para ciclar idiomas
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Atalho para mudar idioma")
                        Spacer()
                        Text(settings.cycleLanguageShortcut)
                            .foregroundStyle(.purple)
                            .font(.system(.body, design: .monospaced, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(4)
                    }
                    
                    Text("Pressione ⌥⇧L (Option+Shift+L) para alternar entre idiomas favoritos")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Section("Idiomas Favoritos") {
                Text("Selecione os idiomas que você usa com frequência para alternar rapidamente com ⌥⇧L")
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

            Section("Comportamento") {
                Toggle("Colar automaticamente", isOn: $settings.enableAutoPaste)
                Toggle("Fechar janela após colar", isOn: $settings.enableAutoClose)
                Toggle("Salvar histórico", isOn: $settings.enableHistory)
                Toggle("Efeitos sonoros", isOn: $settings.enableSounds)
            }

            Section("Personalizacao") {
                Toggle("Aprender meu estilo de escrita", isOn: $settings.enableStyleLearning)

                Text("VibeFlow aprende seu estilo com base nas transcricoes anteriores para personalizar os resultados.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if WritingStyleManager.shared.totalSamples > 0 {
                    HStack {
                        Text("\(WritingStyleManager.shared.totalSamples) amostras salvas")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Button("Limpar") {
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
            Section("Google Gemini API") {
                SecureField("API Key", text: $settings.apiKey)
                    .textFieldStyle(.roundedBorder)
                
                Text("Sua API key é armazenada localmente no Keychain do macOS.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Link(destination: URL(string: "https://aistudio.google.com/app/apikey")!) {
                    HStack {
                        Image(systemName: "arrow.up.right.square")
                        Text("Obter API key no Google AI Studio")
                    }
                }
                .padding(.top, 4)
            }
            
            Section("Informações") {
                HStack {
                    Text("Modelo")
                    Spacer()
                    Text("Gemini 2.0 Flash")
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    Text("Versão")
                    Spacer()
                    Text("2.1.0")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    private var wizardPermissionsTab: some View {
        Form {
            Section("Setup Wizard") {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Wizard de Configuração")
                            .font(.body)
                        
                        Text("Execute o wizard novamente para reconfigurar o VibeFlow")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Abrir Wizard") {
                        showingWizard = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
            
            Section("Permissões") {
                // Microfone
                HStack {
                    Image(systemName: "microphone.fill")
                        .foregroundStyle(microphonePermission == .authorized ? .green : .orange)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Microfone")
                            .font(.body)
                        
                        Text(permissionStatusText(microphonePermission))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    if microphonePermission != .authorized {
                        Button("Solicitar") {
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
                        Text("Acessibilidade")
                            .font(.body)
                        
                        Text(accessibilityPermission ? "Permitido" : "Necessário para colar automaticamente")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    if !accessibilityPermission {
                        Button("Abrir Preferências") {
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
            }
            
            Section {
                Text("O VibeFlow precisa de permissão de Acessibilidade para simular o comando ⌘V (colar) automaticamente.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var advancedTab: some View {
        Form {
            Section("Atalhos") {
                HStack {
                    Text("Gravar")
                    Spacer()
                    Text("⌥⌘ (segure)")
                        .foregroundStyle(.secondary)
                        .font(.system(.body, design: .monospaced))
                }
                
                HStack {
                    Text("Mostrar/Esconder")
                    Spacer()
                    Text("⌘⇧V")
                        .foregroundStyle(.secondary)
                        .font(.system(.body, design: .monospaced))
                }
                
                HStack {
                    Text("Configurações")
                    Spacer()
                    Text("⌘,")
                        .foregroundStyle(.secondary)
                        .font(.system(.body, design: .monospaced))
                }
            }
            
            Section("Dados") {
                Button("Limpar histórico") {
                    HistoryManager.shared.clear()
                }
                .foregroundStyle(.red)
                .disabled(HistoryManager.shared.items.isEmpty)
            }
            
            Section("Suporte") {
                Link(destination: URL(string: "https://github.com/seu-usuario/vibeflow")!) {
                    HStack {
                        Image(systemName: "questionmark.circle")
                        Text("Ajuda e documentação")
                    }
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func permissionStatusText(_ status: AVAuthorizationStatus) -> String {
        switch status {
        case .notDetermined:
            return "Não solicitado"
        case .restricted:
            return "Restrito"
        case .denied:
            return "Negado"
        case .authorized:
            return "Permitido"
        @unknown default:
            return "Desconhecido"
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
