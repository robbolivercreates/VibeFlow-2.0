import SwiftUI

struct SettingsView: View {
    @State private var settings = SharedSettings.shared
    @State private var apiKeyInput = ""
    @State private var isValidatingKey = false
    @State private var showingKeyStatus = false
    @State private var keyIsValid = false

    var body: some View {
        NavigationStack {
            Form {
                // API Key Section
                Section {
                    SecureField("Gemini API Key", text: $apiKeyInput)
                        .textContentType(.password)
                        .autocorrectionDisabled()

                    Button {
                        validateAndSaveKey()
                    } label: {
                        HStack {
                            Text("Save API Key")
                            Spacer()
                            if isValidatingKey {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else if showingKeyStatus {
                                Image(systemName: keyIsValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundStyle(keyIsValid ? .green : .red)
                            }
                        }
                    }
                    .disabled(apiKeyInput.isEmpty || isValidatingKey)
                } header: {
                    Text("API Configuration")
                } footer: {
                    VStack(alignment: .leading, spacing: 8) {
                        if settings.hasApiKey {
                            Label("API key configured", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                        Text("Get your free API key at aistudio.google.com")
                    }
                }

                // Transcription Settings
                Section("Transcription") {
                    Picker("Default Mode", selection: Binding(
                        get: { settings.selectedMode },
                        set: { settings.selectedMode = $0 }
                    )) {
                        ForEach(TranscriptionMode.allCases, id: \.self) { mode in
                            Label(mode.displayName, systemImage: mode.icon)
                                .tag(mode)
                        }
                    }

                    Picker("Speech Language", selection: Binding(
                        get: { settings.selectedLanguage },
                        set: { settings.selectedLanguage = $0 }
                    )) {
                        ForEach(SpeechLanguage.allCases, id: \.self) { language in
                            Text("\(language.flag) \(language.displayName)")
                                .tag(language)
                        }
                    }

                    Toggle("Translate to English", isOn: Binding(
                        get: { settings.translateToEnglish },
                        set: { settings.translateToEnglish = $0 }
                    ))
                }

                // Keyboard Settings
                Section("Keyboard") {
                    Toggle("Haptic Feedback", isOn: Binding(
                        get: { settings.hapticFeedback },
                        set: { settings.hapticFeedback = $0 }
                    ))

                    Toggle("Show Waveform Animation", isOn: Binding(
                        get: { settings.showWaveform },
                        set: { settings.showWaveform = $0 }
                    ))

                    Button("Open Keyboard Settings") {
                        openKeyboardSettings()
                    }
                }

                // About Section
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Total Transcriptions")
                        Spacer()
                        Text("\(settings.totalTranscriptions)")
                            .foregroundStyle(.secondary)
                    }

                    Link(destination: URL(string: "https://aistudio.google.com/app/apikey")!) {
                        HStack {
                            Text("Get Gemini API Key")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                        }
                    }
                }

                // Reset Section
                Section {
                    Button("Reset All Settings", role: .destructive) {
                        settings.resetAll()
                        apiKeyInput = ""
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                // Don't show actual key, but indicate if one exists
                if settings.hasApiKey {
                    apiKeyInput = String(repeating: "*", count: 20)
                }
            }
        }
    }

    private func validateAndSaveKey() {
        // Don't validate if user just sees asterisks (key already saved)
        if apiKeyInput.contains("*") && settings.hasApiKey {
            return
        }

        isValidatingKey = true
        showingKeyStatus = false

        Task {
            let isValid = await GeminiService.shared.validateAPIKey(apiKeyInput)

            await MainActor.run {
                isValidatingKey = false
                showingKeyStatus = true
                keyIsValid = isValid

                if isValid {
                    settings.apiKey = apiKeyInput
                    apiKeyInput = String(repeating: "*", count: 20)

                    // Haptic feedback
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                } else {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.error)
                }

                // Hide status after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showingKeyStatus = false
                }
            }
        }
    }

    private func openKeyboardSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    SettingsView()
}
