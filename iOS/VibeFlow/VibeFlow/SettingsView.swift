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
                    SecureField(L10n.geminiApiKey, text: $apiKeyInput)
                        .textContentType(.password)
                        .autocorrectionDisabled()

                    Button {
                        validateAndSaveKey()
                    } label: {
                        HStack {
                            Text(L10n.saveApiKey)
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
                    Text(L10n.apiConfiguration)
                } footer: {
                    VStack(alignment: .leading, spacing: 8) {
                        if settings.hasApiKey {
                            Label(L10n.apiKeyConfigured, systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                        Text(L10n.getApiKeyAt)
                    }
                }

                // Transcription Settings
                Section(L10n.transcription) {
                    Picker(L10n.defaultMode, selection: Binding(
                        get: { settings.selectedMode },
                        set: { settings.selectedMode = $0 }
                    )) {
                        ForEach(TranscriptionMode.allCases, id: \.self) { mode in
                            Label(mode.displayName, systemImage: mode.icon)
                                .tag(mode)
                        }
                    }

                    Picker(L10n.speechLanguage, selection: Binding(
                        get: { settings.selectedLanguage },
                        set: { settings.selectedLanguage = $0 }
                    )) {
                        ForEach(SpeechLanguage.allCases, id: \.self) { language in
                            Text("\(language.flag) \(language.displayName)")
                                .tag(language)
                        }
                    }

                    Toggle(L10n.translateToEnglish, isOn: Binding(
                        get: { settings.translateToEnglish },
                        set: { settings.translateToEnglish = $0 }
                    ))
                }

                // Keyboard Settings
                Section(L10n.keyboard) {
                    Toggle(L10n.hapticFeedback, isOn: Binding(
                        get: { settings.hapticFeedback },
                        set: { settings.hapticFeedback = $0 }
                    ))

                    Toggle(L10n.showWaveform, isOn: Binding(
                        get: { settings.showWaveform },
                        set: { settings.showWaveform = $0 }
                    ))

                    Button(L10n.openKeyboardSettings) {
                        openKeyboardSettings()
                    }
                }

                // About Section
                Section(L10n.about) {
                    HStack {
                        Text(L10n.version)
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text(L10n.totalTranscriptions)
                        Spacer()
                        Text("\(settings.totalTranscriptions)")
                            .foregroundStyle(.secondary)
                    }

                    Link(destination: URL(string: "https://aistudio.google.com/app/apikey")!) {
                        HStack {
                            Text(L10n.getApiKey)
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                        }
                    }
                }

                // Reset Section
                Section {
                    Button(L10n.resetAllSettings, role: .destructive) {
                        settings.resetAll()
                        apiKeyInput = ""
                    }
                }
            }
            .navigationTitle(L10n.settings)
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
