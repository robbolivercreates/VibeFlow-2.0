import SwiftUI
import AVFoundation

// MARK: - Localization
enum WizardLanguage: String, CaseIterable {
    case portuguese = "pt"
    case english = "en"
}

struct WizardStrings {
    let language: WizardLanguage
    
    // Titles
    var welcomeTitle: String {
        switch language {
        case .portuguese: return "Bem-vindo ao VibeFlow"
        case .english: return "Welcome to VibeFlow"
        }
    }
    
    var welcomeSubtitle: String {
        switch language {
        case .portuguese: return "Transforme sua voz em código e texto com inteligência artificial."
        case .english: return "Transform your voice into code and text with AI."
        }
    }
    
    // Features
    var feature1: String {
        switch language {
        case .portuguese: return "Fale naturalmente, escreva código"
        case .english: return "Speak naturally, write code"
        }
    }
    
    var feature2: String {
        switch language {
        case .portuguese: return "3 modos: Código, Texto e UX Design"
        case .english: return "3 modes: Code, Text, and UX Design"
        }
    }
    
    var feature3: String {
        switch language {
        case .portuguese: return "Atalho ⌥⌘ para gravar instantaneamente"
        case .english: return "⌥⌘ shortcut for instant recording"
        }
    }
    
    var feature4: String {
        switch language {
        case .portuguese: return "Cole automaticamente no app ativo"
        case .english: return "Auto-paste into the active app"
        }
    }
    
    // Buttons
    var startButton: String {
        switch language {
        case .portuguese: return "Começar"
        case .english: return "Start"
        }
    }
    
    var backButton: String {
        switch language {
        case .portuguese: return "Voltar"
        case .english: return "Back"
        }
    }
    
    var nextButton: String {
        switch language {
        case .portuguese: return "Próximo"
        case .english: return "Next"
        }
    }
    
    var finishButton: String {
        switch language {
        case .portuguese: return "Abrir VibeFlow"
        case .english: return "Open VibeFlow"
        }
    }
    
    // Mode Selection Step
    var modeTitle: String {
        switch language {
        case .portuguese: return "Escolha seu Modo"
        case .english: return "Choose Your Mode"
        }
    }
    
    var modeDescription: String {
        switch language {
        case .portuguese: return "Selecione como o VibeFlow deve processar suas transcrições:"
        case .english: return "Select how VibeFlow should process your transcriptions:"
        }
    }
    
    var modeCodeTitle: String {
        switch language {
        case .portuguese: return "Código"
        case .english: return "Code"
        }
    }
    
    var modeCodeDescription: String {
        switch language {
        case .portuguese: return "Para desenvolvedores. Otimizado para código limpo e estruturado."
        case .english: return "For developers. Optimized for clean, structured code."
        }
    }
    
    var modeTextTitle: String {
        switch language {
        case .portuguese: return "Texto"
        case .english: return "Text"
        }
    }
    
    var modeTextDescription: String {
        switch language {
        case .portuguese: return "Para emails e documentos. Linguagem natural e profissional."
        case .english: return "For emails and documents. Natural, professional language."
        }
    }
    
    var modeUXTitle: String {
        switch language {
        case .portuguese: return "UX Design"
        case .english: return "UX Design"
        }
    }
    
    var modeUXDescription: String {
        switch language {
        case .portuguese: return "Para designers. Criativo e focado em experiência do usuário."
        case .english: return "For designers. Creative and UX-focused."
        }
    }
    
    // API Step
    var apiTitle: String {
        switch language {
        case .portuguese: return "Configurar API Key"
        case .english: return "Configure API Key"
        }
    }
    
    var apiDescription: String {
        switch language {
        case .portuguese: return "O VibeFlow usa o Google Gemini para transcrever seu áudio. Você precisa de uma API key gratuita."
        case .english: return "VibeFlow uses Google Gemini to transcribe your audio. You need a free API key."
        }
    }
    
    var apiKeyLabel: String {
        switch language {
        case .portuguese: return "API Key do Gemini"
        case .english: return "Gemini API Key"
        }
    }
    
    var apiKeyPlaceholder: String {
        switch language {
        case .portuguese: return "Cole sua API key aqui"
        case .english: return "Paste your API key here"
        }
    }
    
    var validateButton: String {
        switch language {
        case .portuguese: return "Validar"
        case .english: return "Validate"
        }
    }
    
    var validatingText: String {
        switch language {
        case .portuguese: return "Validando..."
        case .english: return "Validating..."
        }
    }
    
    var validKey: String {
        switch language {
        case .portuguese: return "✓ API key válida!"
        case .english: return "✓ Valid API key!"
        }
    }
    
    var invalidKey: String {
        switch language {
        case .portuguese: return "✗ API key inválida"
        case .english: return "✗ Invalid API key"
        }
    }
    
    var getApiKeyButton: String {
        switch language {
        case .portuguese: return "Obter API key gratuita no Google AI Studio"
        case .english: return "Get free API key from Google AI Studio"
        }
    }
    
    var apiKeySecurity: String {
        switch language {
        case .portuguese: return "Sua API key é armazenada localmente e nunca é compartilhada."
        case .english: return "Your API key is stored locally and never shared."
        }
    }
    
    // Shortcuts Step
    var shortcutsTitle: String {
        switch language {
        case .portuguese: return "Atalhos de Teclado"
        case .english: return "Keyboard Shortcuts"
        }
    }
    
    var shortcutsDescription: String {
        switch language {
        case .portuguese: return "Aprenda os atalhos essenciais para usar o VibeFlow:"
        case .english: return "Learn the essential shortcuts to use VibeFlow:"
        }
    }
    
    var shortcutRecord: String {
        switch language {
        case .portuguese: return "Segure para gravar, solte para parar"
        case .english: return "Hold to record, release to stop"
        }
    }
    
    var shortcutToggle: String {
        switch language {
        case .portuguese: return "Mostrar/esconder janela"
        case .english: return "Show/hide window"
        }
    }
    
    var shortcutSettings: String {
        switch language {
        case .portuguese: return "Abrir configurações"
        case .english: return "Open settings"
        }
    }
    
    var shortcutQuit: String {
        switch language {
        case .portuguese: return "Sair do app"
        case .english: return "Quit app"
        }
    }
    
    // Settings toggles
    var enableSounds: String {
        switch language {
        case .portuguese: return "Efeitos sonoros"
        case .english: return "Sound effects"
        }
    }
    
    var enableHistory: String {
        switch language {
        case .portuguese: return "Salvar histórico"
        case .english: return "Save history"
        }
    }
    
    var enableAutoPaste: String {
        switch language {
        case .portuguese: return "Colar automaticamente"
        case .english: return "Auto-paste"
        }
    }
    
    var enableAutoClose: String {
        switch language {
        case .portuguese: return "Fechar janela após colar"
        case .english: return "Close window after paste"
        }
    }
    
    // Ready Step
    var readyTitle: String {
        switch language {
        case .portuguese: return "Tudo pronto!"
        case .english: return "All set!"
        }
    }
    
    var readyDescription: String {
        switch language {
        case .portuguese: return "O VibeFlow está configurado e pronto para usar."
        case .english: return "VibeFlow is configured and ready to use."
        }
    }
    
    var nextSteps: String {
        switch language {
        case .portuguese: return "Próximos passos:"
        case .english: return "Next steps:"
        }
    }
    
    var step1: String {
        switch language {
        case .portuguese: return "Clique no ícone laranja na barra de menu"
        case .english: return "Click the orange icon in the menu bar"
        }
    }
    
    var step2: String {
        switch language {
        case .portuguese: return "Segure ⌥⌘ para começar a gravar"
        case .english: return "Hold ⌥⌘ to start recording"
        }
    }
    
    var step3: String {
        switch language {
        case .portuguese: return "Fale naturalmente sobre o que precisa"
        case .english: return "Speak naturally about what you need"
        }
    }
    
    var step4: String {
        switch language {
        case .portuguese: return "Solte ⌥⌘ e veja a mágica acontecer ✨"
        case .english: return "Release ⌥⌘ and watch the magic happen ✨"
        }
    }
    
    // Errors
    var errorRequired: String {
        switch language {
        case .portuguese: return "Por favor, insira uma API key"
        case .english: return "Please enter an API key"
        }
    }
    
    var errorValidateFirst: String {
        switch language {
        case .portuguese: return "Valide sua API key primeiro"
        case .english: return "Please validate your API key first"
        }
    }
    
    // Permissions Step
    var permissionsTitle: String {
        switch language {
        case .portuguese: return "Permissões Necessárias"
        case .english: return "Required Permissions"
        }
    }
    
    var permissionsDescription: String {
        switch language {
        case .portuguese: return "O VibeFlow precisa das seguintes permissões para funcionar corretamente:"
        case .english: return "VibeFlow needs the following permissions to work properly:"
        }
    }
    
    var microphonePermissionTitle: String {
        switch language {
        case .portuguese: return "Microfone"
        case .english: return "Microphone"
        }
    }
    
    var microphonePermissionDesc: String {
        switch language {
        case .portuguese: return "Para gravar sua voz e transcrever para texto"
        case .english: return "To record your voice and transcribe to text"
        }
    }
    
    var accessibilityPermissionTitle: String {
        switch language {
        case .portuguese: return "Acessibilidade"
        case .english: return "Accessibility"
        }
    }
    
    var accessibilityPermissionDesc: String {
        switch language {
        case .portuguese: return "Para colar o texto automaticamente no app ativo (⌘V)"
        case .english: return "To automatically paste text into the active app (⌘V)"
        }
    }
    
    var grantPermissionButton: String {
        switch language {
        case .portuguese: return "Conceder Permissão"
        case .english: return "Grant Permission"
        }
    }
    
    var permissionGranted: String {
        switch language {
        case .portuguese: return "Permissão concedida ✓"
        case .english: return "Permission granted ✓"
        }
    }
    
    var permissionRequired: String {
        switch language {
        case .portuguese: return "Permissão necessária"
        case .english: return "Permission required"
        }
    }
    
    // Language selection
    var selectLanguage: String {
        switch language {
        case .portuguese: return "Idioma"
        case .english: return "Language"
        }
    }
}

// MARK: - Main View
struct SetupWizardView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var settings = SettingsManager.shared
    @State private var currentStep = 0
    @State private var apiKeyInput = ""
    @State private var isValidating = false
    @State private var validationError: String?
    @State private var isKeyValid: Bool? = nil
    @State private var language: WizardLanguage = .portuguese
    @State private var selectedMode: TranscriptionMode = .code
    @State private var microphonePermission: AVAuthorizationStatus = .notDetermined
    @State private var accessibilityPermission = false
    @State private var permissionCheckTimer: Timer?
    
    private let totalSteps = 6
    
    private var strings: WizardStrings {
        WizardStrings(language: language)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Language selector (top right)
            HStack {
                Spacer()
                Picker("", selection: $language) {
                    Text("🇧🇷 PT").tag(WizardLanguage.portuguese)
                    Text("🇺🇸 EN").tag(WizardLanguage.english)
                }
                .pickerStyle(.segmented)
                .frame(width: 120)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            
            // Progresso
            ProgressView(value: Double(currentStep + 1), total: Double(totalSteps))
                .padding(.horizontal, 30)
                .padding(.top, 12)
            
            // Conteúdo da etapa
            Group {
                switch currentStep {
                case 0:
                    welcomeStep
                case 1:
                    modeSelectionStep
                case 2:
                    apiKeyStep
                case 3:
                    permissionsStep
                case 4:
                    shortcutsStep
                case 5:
                    readyStep
                default:
                    EmptyView()
                }
            }
            .padding(30)
            
            Spacer()
            
            // Botões de navegação
            HStack {
                if currentStep > 0 && currentStep < 5 {
                    Button(strings.backButton) {
                        withAnimation {
                            currentStep -= 1
                        }
                    }
                    .buttonStyle(.bordered)
                }
                
                Spacer()
                
                if currentStep < 4 {
                    Button(currentStep == 0 ? strings.startButton : strings.nextButton) {
                        if currentStep == 2 {
                            if apiKeyInput.isEmpty {
                                validationError = strings.errorRequired
                                return
                            }
                            if isKeyValid != true {
                                validationError = strings.errorValidateFirst
                                return
                            }
                        }
                        // Verificar permissões na etapa 3
                        if currentStep == 3 && !allPermissionsGranted {
                            return
                        }
                        withAnimation {
                            currentStep += 1
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(currentStep == 3 && !allPermissionsGranted)
                    .disabled(currentStep == 2 && (apiKeyInput.isEmpty || isKeyValid != true))
                } else {
                    Button(strings.finishButton) {
                        settings.completeOnboarding()
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 20)
        }
        .frame(width: 620, height: 540)
        .onAppear {
            apiKeyInput = settings.apiKey
            isKeyValid = settings.hasApiKey ? true : nil
            selectedMode = settings.selectedMode
            checkPermissions()
        }
    }
    
    private func checkPermissions() {
        microphonePermission = AVCaptureDevice.authorizationStatus(for: .audio)
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        accessibilityPermission = AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    private var allPermissionsGranted: Bool {
        microphonePermission == .authorized && accessibilityPermission
    }
    
    // MARK: - Steps
    
    private var welcomeStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 70))
                .foregroundStyle(.orange)
            
            Text(strings.welcomeTitle)
                .font(.title)
                .fontWeight(.bold)
            
            Text(strings.welcomeSubtitle)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 12) {
                FeatureRow(icon: "mic.fill", text: strings.feature1)
                FeatureRow(icon: "bolt.fill", text: strings.feature2)
                FeatureRow(icon: "keyboard.fill", text: strings.feature3)
                FeatureRow(icon: "doc.on.clipboard", text: strings.feature4)
            }
            .padding(.top, 10)
        }
    }
    
    private var modeSelectionStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .font(.title2)
                    .foregroundStyle(.orange)
                
                Text(strings.modeTitle)
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            Text(strings.modeDescription)
                .font(.body)
                .foregroundStyle(.secondary)
            
            VStack(spacing: 12) {
                ModeCard(
                    icon: "chevron.left.forwardslash.chevron.right",
                    title: strings.modeCodeTitle,
                    description: strings.modeCodeDescription,
                    color: .blue,
                    isSelected: selectedMode == .code
                ) {
                    selectedMode = .code
                    settings.selectedMode = .code
                }
                
                ModeCard(
                    icon: "text.alignleft",
                    title: strings.modeTextTitle,
                    description: strings.modeTextDescription,
                    color: .green,
                    isSelected: selectedMode == .text
                ) {
                    selectedMode = .text
                    settings.selectedMode = .text
                }
                
                ModeCard(
                    icon: "paintbrush",
                    title: strings.modeUXTitle,
                    description: strings.modeUXDescription,
                    color: .purple,
                    isSelected: selectedMode == .uxDesign
                ) {
                    selectedMode = .uxDesign
                    settings.selectedMode = .uxDesign
                }
            }
        }
    }
    
    private var apiKeyStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "key.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)
                
                Text(strings.apiTitle)
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            Text(strings.apiDescription)
                .font(.body)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(strings.apiKeyLabel)
                    .font(.headline)
                
                HStack(spacing: 8) {
                    SecureField(strings.apiKeyPlaceholder, text: $apiKeyInput)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: apiKeyInput) { _ in
                            validationError = nil
                            isKeyValid = nil
                            settings.apiKey = apiKeyInput
                        }
                    
                    Button(isValidating ? "" : strings.validateButton) {
                        validateAPIKey()
                    }
                    .buttonStyle(.bordered)
                    .disabled(apiKeyInput.isEmpty || isValidating)
                    .frame(width: 80)
                    .overlay {
                        if isValidating {
                            ProgressView()
                                .scaleEffect(0.6)
                        }
                    }
                }
                
                // Status da validação
                if let isValid = isKeyValid {
                    HStack {
                        Image(systemName: isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                        Text(isValid ? strings.validKey : strings.invalidKey)
                    }
                    .font(.caption)
                    .foregroundStyle(isValid ? .green : .red)
                }
                
                if let error = validationError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            
            Link(destination: URL(string: "https://aistudio.google.com/app/apikey")!) {
                HStack {
                    Image(systemName: "arrow.up.right.square")
                    Text(strings.getApiKeyButton)
                }
                .font(.callout)
            }
            
            Text(strings.apiKeySecurity)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    private var permissionsStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lock.shield")
                    .font(.title2)
                    .foregroundStyle(.orange)
                
                Text(strings.permissionsTitle)
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            Text(strings.permissionsDescription)
                .font(.body)
                .foregroundStyle(.secondary)
            
            // Microfone
            PermissionRow(
                icon: "microphone.fill",
                title: strings.microphonePermissionTitle,
                description: strings.microphonePermissionDesc,
                isGranted: microphonePermission == .authorized,
                action: {
                    AVCaptureDevice.requestAccess(for: .audio) { _ in
                        DispatchQueue.main.async {
                            checkPermissions()
                        }
                    }
                }
            )
            
            // Acessibilidade
            PermissionRow(
                icon: "accessibility",
                title: strings.accessibilityPermissionTitle,
                description: strings.accessibilityPermissionDesc,
                isGranted: accessibilityPermission,
                action: {
                    let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                    NSWorkspace.shared.open(url)
                }
            )
            
            if !allPermissionsGranted {
                Text(strings.permissionRequired)
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .padding(.top, 8)
            }
        }
        .onAppear {
            // Iniciar timer para verificar permissões periodicamente
            checkPermissions()
            permissionCheckTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                checkPermissions()
            }
        }
        .onDisappear {
            // Parar timer ao sair da etapa
            permissionCheckTimer?.invalidate()
            permissionCheckTimer = nil
        }
    }
    
    private var shortcutsStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "keyboard")
                    .font(.title2)
                    .foregroundStyle(.orange)
                
                Text(strings.shortcutsTitle)
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            Text(strings.shortcutsDescription)
                .font(.body)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 12) {
                ShortcutRow(keys: "⌥⌘", description: strings.shortcutRecord)
                ShortcutRow(keys: "⌘⇧V", description: strings.shortcutToggle)
                ShortcutRow(keys: "⌘,", description: strings.shortcutSettings)
                ShortcutRow(keys: "⌘Q", description: strings.shortcutQuit)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 10) {
                Toggle(strings.enableSounds, isOn: $settings.enableSounds)
                Toggle(strings.enableHistory, isOn: $settings.enableHistory)
                Toggle(strings.enableAutoPaste, isOn: $settings.enableAutoPaste)
                Toggle(strings.enableAutoClose, isOn: $settings.enableAutoClose)
            }
        }
    }
    
    private var readyStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 70))
                .foregroundStyle(.green)
            
            Text(strings.readyTitle)
                .font(.title)
                .fontWeight(.bold)
            
            Text(strings.readyDescription)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 12) {
                Text(strings.nextSteps)
                    .font(.headline)
                
                StepRow(number: 1, text: strings.step1)
                StepRow(number: 2, text: strings.step2)
                StepRow(number: 3, text: strings.step3)
                StepRow(number: 4, text: strings.step4)
            }
            .padding(.top, 10)
        }
    }
    
    // MARK: - Methods
    
    private func validateAPIKey() {
        guard !apiKeyInput.isEmpty else { return }
        
        isValidating = true
        isKeyValid = nil
        validationError = nil
        
        Task {
            let isValid = await validateKey(apiKeyInput)
            
            await MainActor.run {
                isValidating = false
                isKeyValid = isValid
                
                if isValid {
                    settings.apiKey = apiKeyInput
                }
            }
        }
    }
    
    private func validateKey(_ key: String) async -> Bool {
        // Fazer uma chamada de teste para a API do Gemini
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=\(key)") else {
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "contents": [
                ["parts": [["text": "Hi"]]]
            ],
            "generationConfig": [
                "maxOutputTokens": 1
            ]
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            return false
        }
        request.httpBody = jsonData
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 200
            }
            return false
        } catch {
            return false
        }
    }
}

// MARK: - Helper Views

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.orange)
                .frame(width: 24)
            
            Text(text)
                .font(.body)
        }
    }
}

struct ModeCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundStyle(color)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? color : .secondary)
            }
            .padding()
            .background(isSelected ? color.opacity(0.1) : Color.secondary.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ShortcutRow: View {
    let keys: String
    let description: String
    
    var body: some View {
        HStack {
            Text(keys)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.semibold)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.15))
                .cornerRadius(6)
            
            Text(description)
                .font(.body)
            
            Spacer()
        }
    }
}

struct StepRow: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text("\(number)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(Circle().fill(Color.orange))
            
            Text(text)
                .font(.body)
        }
    }
}

// MARK: - Permission Row
struct PermissionRow: View {
    let icon: String
    let title: String
    let description: String
    let isGranted: Bool
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Ícone
            ZStack {
                Circle()
                    .fill(isGranted ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: isGranted ? "checkmark" : icon)
                    .font(.system(size: 16))
                    .foregroundStyle(isGranted ? .green : .orange)
            }
            
            // Texto
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Botão ou checkmark
            if isGranted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.green)
            } else {
                Button("Permitir") {
                    action()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(12)
    }
}

#Preview {
    SetupWizardView()
}
