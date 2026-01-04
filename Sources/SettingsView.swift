import SwiftUI
import AppKit

struct SettingsView: View {
    @AppStorage("GeminiAPIKey") private var savedAPIKey: String = ""
    @AppStorage("selectedMode") private var selectedModeRaw: String = TranscriptionMode.code.rawValue
    @AppStorage("translateToEnglish") private var translateToEnglish: Bool = false
    @AppStorage("clarifyText") private var clarifyText: Bool = true
    @AppStorage("appLanguage") private var appLanguage: String = "pt"
    
    @State private var apiKey: String = ""
    @State private var showKey: Bool = false
    @State private var saved: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection
            
            Divider()
            
            ScrollView {
                VStack(spacing: 24) {
                    // API Key
                    apiKeySection
                    
                    Divider()
                    
                    // Idioma da interface
                    languageSection
                    
                    Divider()
                    
                    // Modo padrão
                    modeSection
                    
                    Divider()
                    
                    // Clarear texto
                    clarifySection
                    
                    Divider()
                    
                    // Tradução
                    translationSection
                }
                .padding(24)
            }
            
            Divider()
            
            // Footer com botões
            footerSection
        }
        .frame(width: 500, height: 600)
        .onAppear {
            apiKey = savedAPIKey
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack {
            // Logo
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.4, green: 0.2, blue: 0.8),
                                Color(red: 0.2, green: 0.4, blue: 0.9)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)
                
                Image(systemName: "waveform")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("VibeFlow")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(L10n.settingsTitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(20)
        .background(.bar)
    }
    
    // MARK: - Language Section
    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(L10n.interfaceLanguage, systemImage: "globe")
                .font(.headline)
            
            Text(L10n.languageDescription)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Picker("", selection: $appLanguage) {
                ForEach(AppLanguage.allCases) { lang in
                    HStack {
                        Text(lang.flag)
                        Text(lang.displayName)
                    }
                    .tag(lang.rawValue)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 200)
        }
    }
    
    // MARK: - API Key Section
    private var apiKeySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(L10n.apiKeyLabel, systemImage: "key.fill")
                .font(.headline)
            
            HStack {
                if showKey {
                    TextField(L10n.apiKeyPlaceholder, text: $apiKey)
                        .textFieldStyle(.roundedBorder)
                } else {
                    SecureField(L10n.apiKeyPlaceholder, text: $apiKey)
                        .textFieldStyle(.roundedBorder)
                }
                
                Button(action: { showKey.toggle() }) {
                    Image(systemName: showKey ? "eye.slash" : "eye")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.borderless)
            }
            
            Button(L10n.getAPIKey) {
                if let url = URL(string: "https://makersuite.google.com/app/apikey") {
                    NSWorkspace.shared.open(url)
                }
            }
            .buttonStyle(.link)
            .font(.caption)
        }
    }
    
    // MARK: - Mode Section
    private var modeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(L10n.defaultMode, systemImage: "switch.2")
                .font(.headline)
            
            Text(L10n.defaultModeDescription)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Picker("", selection: $selectedModeRaw) {
                ForEach(TranscriptionMode.allCases) { mode in
                    HStack {
                        Image(systemName: mode.icon)
                        Text(mode.localizedName)
                    }
                    .tag(mode.rawValue)
                }
            }
            .pickerStyle(.radioGroup)
            
            // Descrição do modo selecionado
            modeDescription
        }
    }
    
    private var modeDescription: some View {
        Group {
            switch TranscriptionMode(rawValue: selectedModeRaw) ?? .code {
            case .code:
                descriptionCard(
                    icon: "chevron.left.forwardslash.chevron.right",
                    title: L10n.codeModeTitle,
                    description: L10n.codeModeDescription,
                    color: .green
                )
            case .text:
                descriptionCard(
                    icon: "text.alignleft",
                    title: L10n.textModeTitle,
                    description: L10n.textModeDescription,
                    color: .blue
                )
            case .uxDesign:
                descriptionCard(
                    icon: "paintbrush.pointed",
                    title: L10n.uxModeTitle,
                    description: L10n.uxModeDescription,
                    color: .purple
                )
            case .email:
                descriptionCard(
                    icon: "envelope",
                    title: L10n.emailModeTitle,
                    description: L10n.emailModeDescription,
                    color: .orange
                )
            }
        }
    }
    
    private func descriptionCard(icon: String, title: String, description: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
        )
    }
    
    // MARK: - Clarify Section
    private var clarifySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(L10n.textClarity, systemImage: "text.badge.checkmark")
                .font(.headline)
            
            Toggle(isOn: $clarifyText) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.clarifyAndOrganize)
                        .font(.subheadline)
                    
                    Text(L10n.clarifyDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .toggleStyle(.switch)
            
            if clarifyText {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text(L10n.removesFillers)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text(L10n.organizesSentences)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text(L10n.correctsGrammar)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.green.opacity(0.1))
                )
            }
        }
    }
    
    // MARK: - Translation Section
    private var translationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(L10n.translation, systemImage: "globe")
                .font(.headline)
            
            Toggle(isOn: $translateToEnglish) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.translateToEnglish)
                        .font(.subheadline)
                    
                    Text(L10n.translateDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .toggleStyle(.switch)
            
            if translateToEnglish {
                HStack {
                    Text("🇧🇷")
                    Image(systemName: "arrow.right")
                        .foregroundColor(.secondary)
                    Text("🇺🇸")
                    
                    Text("Português → English")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.blue.opacity(0.1))
                )
            }
        }
    }
    
    // MARK: - Footer
    private var footerSection: some View {
        HStack {
            if saved {
                Label(L10n.saved, systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .transition(.opacity)
            }
            
            Spacer()
            
            Button(L10n.cancel) {
                closeWindow()
            }
            .buttonStyle(.bordered)
            .keyboardShortcut(.cancelAction)
            
            Button(L10n.save) {
                saveSettings()
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)
            .disabled(apiKey.isEmpty)
        }
        .padding(20)
        .background(.bar)
    }
    
    // MARK: - Actions
    private func saveSettings() {
        savedAPIKey = apiKey
        saved = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            closeWindow()
        }
    }
    
    private func closeWindow() {
        if let window = NSApplication.shared.keyWindow {
            window.close()
        }
    }
}
