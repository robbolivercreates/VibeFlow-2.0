import SwiftUI
import AVFoundation

// MARK: - Wizard Steps
enum WizardStep: Int, CaseIterable {
    case language = 0
    case welcome = 1
    case login = 2
    case permissions = 3
    case testRecording = 4
    case languages = 5
    case ready = 6

    var title: String {
        switch self {
        case .language: return L10n.chooseLanguage
        case .welcome: return "Bem-vindo"
        case .login: return L10n.loginToVoxAiGo
        case .permissions: return L10n.requiredPermissions
        case .testRecording: return L10n.testVoxAiGo
        case .languages: return L10n.languages
        case .ready: return "Pronto"
        }
    }

    var icon: String {
        switch self {
        case .language: return "globe"
        case .welcome: return "waveform.circle.fill"
        case .login: return "person.crop.circle.fill"
        case .permissions: return "lock.shield.fill"
        case .testRecording: return "mic.fill"
        case .languages: return "flag.fill"
        case .ready: return "checkmark.seal.fill"
        }
    }
}

// MARK: - Main Setup Wizard View
struct SetupWizardView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var settings = SettingsManager.shared

    @StateObject private var auth = AuthManager.shared
    @State private var currentStep: WizardStep = .welcome

    // Permissions
    @State private var microphonePermission: AVAuthorizationStatus = .notDetermined
    @State private var accessibilityPermission = false
    @State private var inputMonitoringPermission = false
    @State private var permissionTimer: Timer?

    // Test Recording
    @State private var isTestRecording = false
    @State private var testRecordingSuccess = false
    @State private var testTranscriptionResult: String?
    @State private var testAudioLevel: CGFloat = 0
    @State private var testRecordingTimer: Timer?
    @State private var shortcutTestPassed = false
    
    // Language selection
    @State private var selectedLanguage: AppLanguage = L10n.current

    // Languages
    @State private var languageCycleDemo = false
    @State private var demoLanguageIndex = 0
    private let demoLanguages: [SpeechLanguage] = [.english, .portuguese, .spanish]

    var body: some View {
        VStack(spacing: 0) {
            // Header with step indicator
            wizardHeader

            // Content
            ScrollView {
                VStack(spacing: 0) {
                    stepContent
                        .padding(.horizontal, 40)
                        .padding(.vertical, 30)
                }
            }

            // Footer with navigation
            wizardFooter
        }
        .frame(width: 680, height: 580)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            checkPermissions()
        }
        .onDisappear {
            permissionTimer?.invalidate()
            testRecordingTimer?.invalidate()
        }
    }

    // MARK: - Header

    private var wizardHeader: some View {
        VStack(spacing: 16) {
            // Step indicators
            HStack(spacing: 8) {
                ForEach(WizardStep.allCases, id: \.rawValue) { step in
                    StepIndicator(
                        step: step,
                        currentStep: currentStep,
                        isCompleted: step.rawValue < currentStep.rawValue
                    )

                    if step != .ready {
                        Rectangle()
                            .fill(step.rawValue < currentStep.rawValue ? Color.purple : Color(nsColor: .separatorColor))
                            .frame(height: 2)
                            .frame(maxWidth: 30)
                    }
                }
            }
            .padding(.horizontal, 40)
            .padding(.top, 24)

            // Current step title
            HStack(spacing: 10) {
                Image(systemName: currentStep.icon)
                    .font(.system(size: 20))
                    .foregroundStyle(.purple)

                Text(currentStep.title)
                    .font(.system(size: 18, weight: .semibold))
            }
            .padding(.bottom, 8)

            Divider()
        }
    }

    // MARK: - Footer

    private var wizardFooter: some View {
        VStack(spacing: 0) {
            Divider()

            HStack {
                // Back button
                if currentStep != .language {
                    Button(action: goBack) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                            Text(L10n.back)
                        }
                    }
                    .buttonStyle(.bordered)
                }

                Spacer()

                // Progress text
                Text("\(currentStep.rawValue + 1) de \(WizardStep.allCases.count)")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)

                Spacer()

                // Next/Finish button
                Button(action: goNext) {
                    HStack(spacing: 6) {
                        Text(currentStep == .ready ? L10n.startUsing : L10n.continueBtn)
                        if currentStep != .ready {
                            Image(systemName: "chevron.right")
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
                .disabled(!canProceed)
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 16)
        }
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case .language:
            languageSelectionContent
        case .welcome:
            welcomeContent
        case .login:
            loginContent
        case .permissions:
            permissionsContent
        case .testRecording:
            testRecordingContent
        case .languages:
            languagesContent
        case .ready:
            readyContent
        }
    }

    // MARK: - Language Selection Step

    private var languageSelectionContent: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "globe")
                    .font(.system(size: 60))
                    .foregroundStyle(.purple)
                
                Text(L10n.chooseLanguage)
                    .font(.system(size: 28, weight: .bold))
                
                Text(L10n.interfaceLanguageDesc)
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Language cards
            VStack(spacing: 16) {
                ForEach(AppLanguage.allCases) { language in
                    Button(action: {
                        selectedLanguage = language
                        UserDefaults.standard.set(language.rawValue, forKey: "appLanguage")
                    }) {
                        HStack(spacing: 16) {
                            Text(language.flag)
                                .font(.system(size: 40))
                            
                            Text(language.displayName)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            if selectedLanguage == language {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundStyle(.purple)
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedLanguage == language ? Color.purple.opacity(0.1) : Color(nsColor: .controlBackgroundColor))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(selectedLanguage == language ? Color.purple : Color.clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 40)
        }
    }

    // MARK: - Welcome Step

    private var welcomeContent: some View {
        VStack(spacing: 24) {
            // Logo
            VoxAiGoLogo(size: 80)
                .padding(.bottom, 8)

            Text("VoxAiGo")
                .font(.system(size: 32, weight: .bold))

            Text(L10n.vibeFlowTagline)
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            // Features grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                FeatureCard3(icon: "mic.fill", title: L10n.speakNaturally, description: L10n.speakNaturallyDesc)
                FeatureCard3(icon: "bolt.fill", title: L10n.ultraFast, description: L10n.ultraFastDesc)
                FeatureCard3(icon: "keyboard", title: L10n.simpleShortcut, description: L10n.simpleShortcutDesc)
                FeatureCard3(icon: "doc.on.clipboard", title: L10n.autoPaste, description: L10n.autoPasteDesc)
            }
            .padding(.top, 16)
        }
    }

    // MARK: - Login Step

    private var loginContent: some View {
        VStack(spacing: 20) {
            if auth.isAuthenticated {
                // Already logged in
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.green)

                    Text(L10n.loggedIn)
                        .font(.system(size: 18, weight: .semibold))

                    if let email = auth.userEmail {
                        Text(email)
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 40)
            } else {
                LoginView()
            }
        }
    }

    // MARK: - Permissions Step

    private var permissionsContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Permissoes Necessarias")
                    .font(.system(size: 18, weight: .semibold))

                Text("O VoxAiGo precisa de 3 permissoes para funcionar. Cada uma tem um papel importante:")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }

            // Permissions list
            VStack(spacing: 12) {
                // 1. Microfone
                PermissionCard(
                    icon: "mic.fill",
                    title: "🎤 " + L10n.microphone,
                    description: L10n.microphonePermDesc,
                    isGranted: microphonePermission == .authorized,
                    buttonText: "Permitir Microfone",
                    helpSteps: [
                        "Clique em \"Permitir Microfone\" acima",
                        "Na janela do macOS, clique em \"OK\" para autorizar"
                    ],
                    action: requestMicrophonePermission
                )

                // 2. Acessibilidade
                PermissionCard(
                    icon: "accessibility",
                    title: L10n.accessibilityTitle,
                    description: L10n.accessibilityDesc,
                    isGranted: accessibilityPermission,
                    buttonText: "Abrir Preferencias",
                    helpSteps: [
                        "Clique em \"Abrir Preferencias\" — ira abrir as Preferencias e o Finder",
                        "Arraste o icone do VoxAiGo do Finder para a lista de permissoes",
                        "Ative o toggle (chave) ao lado de \"VoxAiGo\"",
                        "Volte aqui — sera detectado automaticamente"
                    ],
                    action: openAccessibilitySettings
                )

                // 3. Input Monitoring
                PermissionCard(
                    icon: "keyboard",
                    title: L10n.inputMonitoringTitle,
                    description: L10n.inputMonitoringDesc,
                    isGranted: inputMonitoringPermission,
                    buttonText: "Abrir Preferencias",
                    helpSteps: [
                        "Clique em \"Abrir Preferencias\" — ira abrir as Preferencias e o Finder",
                        "Arraste o icone do VoxAiGo do Finder para a lista de permissoes",
                        "Ative o toggle (chave) ao lado de \"VoxAiGo\""
                    ],
                    action: openInputMonitoringSettings
                )
            }

            // Status summary
            if allPermissionsGranted {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text(L10n.allPermissionsGranted)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.green)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green.opacity(0.1))
                .cornerRadius(10)
            } else {
                let grantedCount = [microphonePermission == .authorized, accessibilityPermission, inputMonitoringPermission].filter { $0 }.count
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text(L10n.permissionsGranted(grantedCount, 3))
                        .font(.system(size: 14))
                        .foregroundStyle(.orange)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(10)
            }

            // General note
            if !allPermissionsGranted {
                HStack(spacing: 8) {
                    Image(systemName: "lock.shield.fill")
                        .foregroundStyle(.blue)
                    Text(L10n.permissionsSecurityNote)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .background(Color.blue.opacity(0.05))
                .cornerRadius(8)
            }
        }
        .onAppear {
            startPermissionChecking()
        }
        .onDisappear {
            permissionTimer?.invalidate()
        }
    }

    // MARK: - Test Recording Step

    private var testRecordingContent: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.testVoxAiGo)
                    .font(.system(size: 24, weight: .bold))

                Text(L10n.testInstructions)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Shortcut test
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(shortcutTestPassed ? Color.green.opacity(0.15) : Color.purple.opacity(0.15))
                            .frame(width: 50, height: 50)

                        if shortcutTestPassed {
                            Image(systemName: "checkmark")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(.green)
                        } else {
                            Text("⌥⌘")
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                                .foregroundStyle(.purple)
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(shortcutTestPassed ? "Atalho funcionando!" : "Teste o atalho de gravacao")
                            .font(.system(size: 15, weight: .medium))

                        Text(shortcutTestPassed ? "O atalho ⌥⌘ esta configurado corretamente" : "Segure ⌥⌘ (Option + Command) por 2 segundos")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if shortcutTestPassed {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.green)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(shortcutTestPassed ? Color.green.opacity(0.05) : Color.purple.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(shortcutTestPassed ? Color.green.opacity(0.3) : Color.purple.opacity(0.3), lineWidth: 1)
                        )
                )

                // Audio level indicator
                if isTestRecording {
                    VStack(spacing: 8) {
                        Text(L10n.recordingSpeakSomething)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.purple)

                        // Animated waveform
                        HStack(spacing: 4) {
                            ForEach(0..<12, id: \.self) { i in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.purple)
                                    .frame(width: 4, height: waveBarHeight(index: i))
                                    .animation(.easeInOut(duration: 0.15), value: testAudioLevel)
                            }
                        }
                        .frame(height: 40)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(10)
                }

                // Transcription result
                if let result = testTranscriptionResult {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "text.bubble.fill")
                                .foregroundStyle(.green)
                            Text(L10n.transcriptionResult)
                                .font(.system(size: 13, weight: .medium))
                        }

                        Text(result)
                            .font(.system(size: 14))
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(nsColor: .textBackgroundColor))
                            .cornerRadius(8)

                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text(L10n.transcriptionWorking)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.green)
                        }
                    }
                    .padding()
                    .background(Color.green.opacity(0.05))
                    .cornerRadius(10)
                }
            }

            // Manual test button (fallback)
            if !shortcutTestPassed {
                Button(action: simulateShortcutTest) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text(L10n.simulateTest)
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            // Tips
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.tips)
                    .font(.system(size: 13, weight: .medium))

                Text(L10n.shortcutTipsBody)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
        }
        .onAppear {
            listenForShortcutTest()
        }
        .onDisappear {
            testRecordingTimer?.invalidate()
        }
    }

    // MARK: - Languages Step

    private var languagesContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.languagesAndQuickSwitch)
                    .font(.system(size: 24, weight: .bold))

                Text(L10n.languagesDesc)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }

            // Current language display
            VStack(spacing: 16) {
                HStack {
                    Text(L10n.currentLanguage)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)

                    Spacer()

                    HStack(spacing: 8) {
                        Text(settings.outputLanguage.flag)
                            .font(.system(size: 24))
                        Text(settings.outputLanguage.displayName)
                            .font(.system(size: 15, weight: .medium))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(8)
                }

                // Cycle shortcut demo
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        Text("⌃⇧L")
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundStyle(.purple)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(8)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(L10n.switchLanguage)
                                .font(.system(size: 16, weight: .semibold))
                            Text(L10n.pressToSwitchLanguages)
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button("Testar") {
                            cycleLanguageDemo()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(nsColor: .controlBackgroundColor))
                )
            }

            // Favorite languages
            VStack(alignment: .leading, spacing: 12) {
                Text(L10n.favoriteLangsForQuickSwitch)
                    .font(.system(size: 14, weight: .medium))

                // Current favorites
                HStack(spacing: 8) {
                    ForEach(settings.favoriteLanguages) { lang in
                        HStack(spacing: 6) {
                            Text(lang.flag)
                            Text(lang.rawValue.uppercased())
                                .font(.system(size: 12, weight: .medium))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(6)
                    }
                }

                Text(L10n.addRemoveFavoritesInSettings)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            // All languages preview
            VStack(alignment: .leading, spacing: 12) {
                Text(L10n.supportedLanguages)
                    .font(.system(size: 14, weight: .medium))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(SpeechLanguage.allCases.prefix(15))) { lang in
                            HStack(spacing: 4) {
                                Text(lang.flag)
                                Text(lang.rawValue.uppercased())
                                    .font(.system(size: 11))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .cornerRadius(4)
                        }

                        Text("+\(SpeechLanguage.allCases.count - 15) mais")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Where to change
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(.blue)
                Text(L10n.manageLanguagesHint)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color.blue.opacity(0.05))
            .cornerRadius(8)
        }
    }

    // MARK: - Ready Step

    private var readyContent: some View {
        VStack(spacing: 24) {
            // Success icon
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 100, height: 100)

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(.green)
            }

            Text(L10n.startUsing)
                .font(.system(size: 28, weight: .bold))

            Text(L10n.vibeFlowTagline)
                .font(.system(size: 16))
                .foregroundStyle(.secondary)

            // Quick reference card
            VStack(alignment: .leading, spacing: 16) {
                Text(L10n.helpAndDocs)
                    .font(.system(size: 15, weight: .semibold))

                VStack(spacing: 12) {
                    QuickRefRow(keys: "⌥⌘", action: L10n.record, description: L10n.holdToRecord)
                    QuickRefRow(keys: "⌃⇧L", action: L10n.switchLanguage, description: L10n.pressToSwitchLanguages)
                    QuickRefRow(keys: "⌘⇧V", action: L10n.showHideShort, description: L10n.showHide)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )

            // Where to find settings
            HStack(spacing: 12) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Configuracoes")
                        .font(.system(size: 14, weight: .medium))
                    Text("Clique no icone do VoxAiGo na barra de menu > Abrir VoxAiGo")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
        }
    }

    // MARK: - Helper Methods

    private var canProceed: Bool {
        switch currentStep {
        case .language:
            return true
        case .welcome:
            return true
        case .login:
            return auth.isAuthenticated
        case .permissions:
            return allPermissionsGranted
        case .testRecording:
            return true // Optional step
        case .languages:
            return true
        case .ready:
            return true
        }
    }

    private var allPermissionsGranted: Bool {
        microphonePermission == .authorized && accessibilityPermission && inputMonitoringPermission
    }

    private func goBack() {
        if var previous = WizardStep(rawValue: currentStep.rawValue - 1) {
            // Skip login step going back if already authenticated (came from login window)
            if previous == .login && auth.isAuthenticated {
                previous = WizardStep(rawValue: previous.rawValue - 1) ?? previous
            }
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = previous
            }
        }
    }

    private func goNext() {
        if currentStep == .ready {
            settings.completeOnboarding()
            dismiss()
        } else if var next = WizardStep(rawValue: currentStep.rawValue + 1) {
            // Skip login step going forward if already authenticated (came from login window)
            if next == .login && auth.isAuthenticated {
                next = WizardStep(rawValue: next.rawValue + 1) ?? next
            }
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = next
            }
        }
    }

    private func checkPermissions() {
        microphonePermission = AVCaptureDevice.authorizationStatus(for: .audio)
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        accessibilityPermission = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        // Check input monitoring by testing if CGEvent.tapCreate works
        // This is the most reliable proxy for Input Monitoring permission
        let testMask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        if let testTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: testMask,
            callback: { _, _, event, _ in Unmanaged.passUnretained(event) },
            userInfo: nil
        ) {
            inputMonitoringPermission = true
            // Clean up test tap immediately
            CFMachPortInvalidate(testTap)
        } else {
            inputMonitoringPermission = false
        }
    }

    private func startPermissionChecking() {
        checkPermissions()
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
            DispatchQueue.main.async {
                self.checkPermissions()
            }
        }
    }

    private func requestMicrophonePermission() {
        AVCaptureDevice.requestAccess(for: .audio) { _ in
            DispatchQueue.main.async {
                checkPermissions()
            }
        }
    }

    private func openAccessibilitySettings() {
        // Open System Preferences at Accessibility
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
        
        // Also reveal VoxAiGo.app in Finder so user can drag it
        revealVoxAiGoInFinder()
    }

    private func openInputMonitoringSettings() {
        // Open System Preferences at Input Monitoring
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent")!
        NSWorkspace.shared.open(url)
        
        // Also reveal VoxAiGo.app in Finder so user can drag it
        revealVoxAiGoInFinder()
    }
    
    private func revealVoxAiGoInFinder() {
        let appPath = "/Applications/VoxAiGo.app"
        let appURL = URL(fileURLWithPath: appPath)
        if FileManager.default.fileExists(atPath: appPath) {
            NSWorkspace.shared.activateFileViewerSelecting([appURL])
        }
    }

    // Reusable help card for permission instructions
    private func permissionHelpCard(title: String, steps: String, note: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .medium))

            Text(steps)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .foregroundStyle(.orange)
                Text(note)
                    .font(.system(size: 11))
                    .foregroundStyle(.orange.opacity(0.8))
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }

    private func listenForShortcutTest() {
        // Simplified test - user can use the button or the actual shortcut
        testRecordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            // Check if recording started
            // This would integrate with the actual recording state
        }
    }

    private func simulateShortcutTest() {
        withAnimation {
            isTestRecording = true
        }

        // Simulate recording for 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                isTestRecording = false
                shortcutTestPassed = true
                testTranscriptionResult = "Este e um exemplo de transcricao. O VoxAiGo esta funcionando corretamente!"
            }
        }

        // Animate audio level
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if !isTestRecording {
                timer.invalidate()
                return
            }
            testAudioLevel = CGFloat.random(in: 0.2...0.9)
        }
    }

    private func waveBarHeight(index: Int) -> CGFloat {
        let baseHeight: CGFloat = 8
        let maxAdd: CGFloat = 30
        let variation = sin(Double(index) * 0.8 + Date().timeIntervalSince1970 * 8) * 0.5 + 0.5
        return baseHeight + maxAdd * testAudioLevel * CGFloat(variation)
    }

    private func cycleLanguageDemo() {
        settings.cycleToNextLanguage()
    }
}

// MARK: - Helper Views

struct StepIndicator: View {
    let step: WizardStep
    let currentStep: WizardStep
    let isCompleted: Bool

    private var isActive: Bool {
        step == currentStep
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(isCompleted ? Color.purple : (isActive ? Color.purple.opacity(0.2) : Color(nsColor: .controlBackgroundColor)))
                .frame(width: 32, height: 32)

            if isCompleted {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
            } else {
                Text("\(step.rawValue + 1)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(isActive ? .purple : .secondary)
            }
        }
    }
}

struct FeatureCard3: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(.purple)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                Text(description)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(10)
    }
}

struct InstructionRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Text("\(number)")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(Circle().fill(Color.purple))

            Text(text)
                .font(.system(size: 13))
        }
    }
}

struct PermissionCard: View {
    let icon: String
    let title: String
    let description: String
    let isGranted: Bool
    let buttonText: String
    let helpSteps: [String]
    let action: () -> Void

    init(icon: String, title: String, description: String, isGranted: Bool, buttonText: String, helpSteps: [String] = [], action: @escaping () -> Void) {
        self.icon = icon
        self.title = title
        self.description = description
        self.isGranted = isGranted
        self.buttonText = buttonText
        self.helpSteps = helpSteps
        self.action = action
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main row
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isGranted ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: isGranted ? "checkmark" : icon)
                        .font(.system(size: 18))
                        .foregroundStyle(isGranted ? .green : .orange)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 14, weight: .medium))
                    Text(description)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                if isGranted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.green)
                } else {
                    Button(buttonText, action: action)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                }
            }

            // Inline instructions when not granted
            if !isGranted && !helpSteps.isEmpty {
                Divider()
                    .padding(.vertical, 8)

                VStack(alignment: .leading, spacing: 5) {
                    Text("Como fazer:")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.orange)

                    ForEach(Array(helpSteps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 6) {
                            Text("\(index + 1).")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundStyle(.orange.opacity(0.8))
                                .frame(width: 16, alignment: .trailing)
                            Text(step)
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.leading, 60) // align with text, past the icon
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isGranted ? Color.green.opacity(0.05) : Color(nsColor: .controlBackgroundColor))
        )
    }
}

struct QuickRefRow: View {
    let keys: String
    let action: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Text(keys)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundStyle(.purple)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.purple.opacity(0.1))
                .cornerRadius(6)

            VStack(alignment: .leading, spacing: 2) {
                Text(action)
                    .font(.system(size: 13, weight: .medium))
                Text(description)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}

#Preview {
    SetupWizardView()
}
