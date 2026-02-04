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
            }

            Section("Comportamento") {
                Toggle("Colar automaticamente", isOn: $settings.enableAutoPaste)
                Toggle("Fechar janela após colar", isOn: $settings.enableAutoClose)
                Toggle("Salvar histórico", isOn: $settings.enableHistory)
                Toggle("Efeitos sonoros", isOn: $settings.enableSounds)
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
}

#Preview {
    SettingsView()
}
