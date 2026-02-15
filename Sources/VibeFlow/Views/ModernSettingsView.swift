import SwiftUI
import AVFoundation

/// View de configurações moderna e reorganizada
struct ModernSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var settings = SettingsManager.shared
    @State private var showingResetConfirmation = false
    @State private var showingWizard = false
    @State private var microphonePermission: AVAuthorizationStatus = .notDetermined
    @State private var accessibilityPermission = false
    @State private var inputMonitoringPermission = false
    @State private var selectedTab: SettingsTab = .general
    
    enum SettingsTab: String, CaseIterable {
        case general = "Geral"
        case language = "Idioma"
        case shortcuts = "Atalhos"
        case permissions = "Permissões"
        
        var icon: String {
            switch self {
            case .general: return "gear"
            case .language: return "globe"
            case .shortcuts: return "keyboard"
            case .permissions: return "lock.shield"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            Divider()
            
            // Tab Navigation
            tabNavigation
            
            Divider()
            
            // Content
            ScrollView {
                VStack(spacing: 24) {
                    switch selectedTab {
                    case .general:
                        GeneralSettingsSection()
                    case .language:
                        LanguageSettingsSection()
                    case .shortcuts:
                        ShortcutsSettingsSection()
                    case .permissions:
                        PermissionsSettingsSection(
                            microphonePermission: $microphonePermission,
                            accessibilityPermission: $accessibilityPermission,
                            inputMonitoringPermission: $inputMonitoringPermission
                        )
                    }
                }
                .padding(24)
            }
            
            Divider()
            
            // Footer
            footerView
        }
        .frame(width: 550, height: 500)
        .background(Color(.windowBackgroundColor))
        .onAppear {
            checkPermissions()
        }
        .sheet(isPresented: $showingWizard) {
            SetupWizardView()
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Configurações")
                    .font(.system(size: 20, weight: .semibold))
                Text("Personalize seu VibeFlow")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.secondary.opacity(0.6))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    // MARK: - Tab Navigation
    private var tabNavigation: some View {
        HStack(spacing: 0) {
            ForEach(SettingsTab.allCases, id: \.self) { tab in
                TabButton(
                    title: tab.rawValue,
                    icon: tab.icon,
                    isSelected: selectedTab == tab
                ) {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedTab = tab
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
    
    // MARK: - Footer
    private var footerView: some View {
        HStack {
            Text("VibeFlow v2.1")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Button("Abrir Wizard") {
                showingWizard = true
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
    
    private func checkPermissions() {
        microphonePermission = AVCaptureDevice.authorizationStatus(for: .audio)
        
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        accessibilityPermission = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        // Check input monitoring via CGEvent tap probe
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
            CFMachPortInvalidate(testTap)
        } else {
            inputMonitoringPermission = false
        }
    }
}

// MARK: - Tab Button
struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                Text(title)
                    .font(.system(size: 11, weight: isSelected ? .medium : .regular))
            }
            .foregroundStyle(isSelected ? .white : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - General Settings Section
struct GeneralSettingsSection: View {
    @StateObject private var settings = SettingsManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            // Modo padrão
            SettingsCard(title: "Modo de Transcrição", icon: "waveform") {
                VStack(spacing: 8) {
                    ForEach(TranscriptionMode.allCases, id: \.self) { mode in
                        ModeSelectionRow(
                            mode: mode,
                            isSelected: settings.selectedMode == mode
                        ) {
                            settings.selectedMode = mode
                        }
                    }
                }
            }
            
            // Comportamento
            SettingsCard(title: "Comportamento", icon: "switch.2") {
                VStack(spacing: 0) {
                    ToggleRow(
                        title: "Colar automaticamente",
                        subtitle: "Cola o texto no app ativo",
                        isOn: $settings.enableAutoPaste
                    )
                    
                    Divider().padding(.leading, 32)
                    
                    ToggleRow(
                        title: "Fechar após colar",
                        subtitle: "Esconde a janela automaticamente",
                        isOn: $settings.enableAutoClose
                    )
                    
                    Divider().padding(.leading, 32)
                    
                    ToggleRow(
                        title: "Efeitos sonoros",
                        subtitle: "Toca sons ao gravar e processar",
                        isOn: $settings.enableSounds
                    )
                    
                    Divider().padding(.leading, 32)
                    
                    ToggleRow(
                        title: "Salvar histórico",
                        subtitle: "Mantém as últimas 50 transcrições",
                        isOn: $settings.enableHistory
                    )
                }
            }
        }
    }
}

// MARK: - Language Settings Section
struct LanguageSettingsSection: View {
    @StateObject private var settings = SettingsManager.shared
    @State private var showingLanguageSelector = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Idioma atual
            SettingsCard(title: "Idioma de Saída", icon: "globe") {
                VStack(spacing: 12) {
                    // Botão principal para selecionar idioma
                    Button(action: { showingLanguageSelector = true }) {
                        HStack {
                            Text(settings.outputLanguage.flag)
                                .font(.system(size: 28))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(settings.outputLanguage.displayName)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(.primary)
                                
                                Text("Toque para mudar")
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.blue.opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    
                    // Atalho
                    HStack {
                        Text("Atalho para mudar idioma")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        HStack(spacing: 2) {
                            ShortcutKey(text: "⌃")
                            ShortcutKey(text: "⇧")
                            ShortcutKey(text: "L")
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            
            // Idiomas favoritos
            SettingsCard(title: "Idiomas Favoritos", icon: "star.fill") {
                VStack(spacing: 12) {
                    Text("Selecione os idiomas para ciclar rapidamente")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Mostrar favoritos selecionados
                    FlowLayout2(spacing: 8) {
                        ForEach(settings.favoriteLanguages) { language in
                            FavoriteLanguageBadge(
                                language: language,
                                isActive: settings.outputLanguage == language
                            )
                        }
                    }
                    
                    Divider()
                    
                    // Botão para editar favoritos
                    Button(action: { showingLanguageSelector = true }) {
                        HStack {
                            Image(systemName: "pencil")
                            Text("Editar favoritos")
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.blue)
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
        .sheet(isPresented: $showingLanguageSelector) {
            LanguageSelectorView2()
        }
    }
}

// MARK: - Language Selector View (Dropdown style)
struct LanguageSelectorView2: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var settings = SettingsManager.shared
    @State private var searchText = ""
    
    var filteredLanguages: [SpeechLanguage] {
        if searchText.isEmpty {
            return SpeechLanguage.allCases.sorted { $0.displayName < $1.displayName }
        }
        return SpeechLanguage.allCases
            .filter { $0.displayName.lowercased().contains(searchText.lowercased()) ||
                      $0.fullName.lowercased().contains(searchText.lowercased()) }
            .sorted { $0.displayName < $1.displayName }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Selecionar Idioma")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Escolha seu idioma de saída")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.secondary.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
            .padding(20)
            
            Divider()
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Buscar idioma...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(10)
            .background(Color(.controlBackgroundColor))
            .cornerRadius(8)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            
            // Seção de favoritos
            if !settings.favoriteLanguages.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("FAVORITOS")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 20)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(settings.favoriteLanguages) { language in
                                FavoriteButton(
                                    language: language,
                                    isSelected: settings.outputLanguage == language
                                ) {
                                    settings.outputLanguage = language
                                    dismiss()
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.vertical, 8)
                
                Divider()
                    .padding(.horizontal, 20)
            }
            
            // Lista de todos os idiomas
            List(filteredLanguages) { language in
                LanguageRow2(
                    language: language,
                    isSelected: settings.outputLanguage == language,
                    isFavorite: settings.favoriteLanguages.contains(language)
                ) {
                    settings.outputLanguage = language
                    dismiss()
                } toggleFavorite: {
                    toggleFavorite(language)
                }
                .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))
                .listRowBackground(Color.clear)
            }
            .listStyle(.plain)
            
            // Footer info
            HStack {
                Text("\(settings.favoriteLanguages.count) favoritos")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("Clique na estrela para adicionar/remover favoritos")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(Color(.controlBackgroundColor).opacity(0.5))
        }
        .frame(width: 400, height: 500)
    }
    
    private func toggleFavorite(_ language: SpeechLanguage) {
        if let index = settings.favoriteLanguages.firstIndex(of: language) {
            if settings.favoriteLanguages.count > 1 {
                settings.favoriteLanguages.remove(at: index)
            }
        } else {
            settings.favoriteLanguages.append(language)
        }
    }
}

// MARK: - Language Row
struct LanguageRow2: View {
    let language: SpeechLanguage
    let isSelected: Bool
    let isFavorite: Bool
    let onSelect: () -> Void
    let toggleFavorite: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Text(language.flag)
                    .font(.system(size: 24))
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(language.displayName)
                        .font(.system(size: 14, weight: isSelected ? .medium : .regular))
                    
                    Text(language.fullName)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Star button
                Button(action: toggleFavorite) {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .font(.system(size: 14))
                        .foregroundStyle(isFavorite ? .yellow : .secondary.opacity(0.4))
                }
                .buttonStyle(.plain)
                .onTapGesture { toggleFavorite() }
                
                // Checkmark
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.blue)
                }
            }
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        )
    }
}

// MARK: - Favorite Button
struct FavoriteButton: View {
    let language: SpeechLanguage
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(language.flag)
                    .font(.system(size: 24))
                Text(language.rawValue.uppercased())
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(isSelected ? .white : .primary)
            .frame(width: 60, height: 56)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.blue : Color(.controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Shortcut Settings Section
struct ShortcutsSettingsSection: View {
    var body: some View {
        VStack(spacing: 20) {
            SettingsCard(title: "Atalhos de Teclado", icon: "keyboard") {
                VStack(spacing: 16) {
                    SettingsShortcutRow(
                        action: "Gravar (segure)",
                        shortcut: "⌥⌘",
                        description: "Segure para gravar, solte para processar"
                    )
                    
                    SettingsShortcutRow(
                        action: "Mostrar/Esconder",
                        shortcut: "⌘⇧V",
                        description: "Alterna a janela do VibeFlow"
                    )
                    
                    SettingsShortcutRow(
                        action: "Mudar Idioma",
                        shortcut: "⌃⇧L",
                        description: "Cicla entre os idiomas favoritos"
                    )
                    
                    SettingsShortcutRow(
                        action: "Configurações",
                        shortcut: "⌘,",
                        description: "Abre esta janela"
                    )
                    
                    SettingsShortcutRow(
                        action: "Histórico",
                        shortcut: "⌘Y",
                        description: "Mostra o histórico de transcrições"
                    )
                }
            }
        }
    }
}

// MARK: - Permissions Settings Section
struct PermissionsSettingsSection: View {
    @Binding var microphonePermission: AVAuthorizationStatus
    @Binding var accessibilityPermission: Bool
    @Binding var inputMonitoringPermission: Bool
    @State private var cgEventTapActive = false
    @State private var isCheckingDiagnostics = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Permissions Card
            SettingsCard(title: "Permissões do Sistema", icon: "lock.shield") {
                VStack(spacing: 16) {
                    // Microfone
                    SettingsPermissionRow(
                        icon: "microphone.fill",
                        title: "Microfone",
                        description: "Para gravar sua voz",
                        isGranted: microphonePermission == .authorized,
                        action: requestMicrophone
                    )
                    
                    // Acessibilidade
                    SettingsPermissionRow(
                        icon: "accessibility",
                        title: "Acessibilidade",
                        description: "Para colar texto automaticamente",
                        isGranted: accessibilityPermission,
                        action: openAccessibilitySettings
                    )
                    
                    // Input Monitoring
                    SettingsPermissionRow(
                        icon: "keyboard",
                        title: "Monitoramento de Teclado",
                        description: "Para atalhos globais (⌃⇧L, ⌃⇧M, ⌃⇧V)",
                        isGranted: inputMonitoringPermission,
                        action: openInputMonitoringSettings
                    )
                }
            }
            
            // Diagnostics Card
            SettingsCard(title: "Diagnóstico", icon: "stethoscope") {
                VStack(spacing: 12) {
                    DiagnosticRow(
                        title: "Microfone",
                        status: microphonePermission == .authorized,
                        detail: microphonePermission == .authorized ? "Funcionando" : "Sem permissão"
                    )
                    
                    DiagnosticRow(
                        title: "Acessibilidade",
                        status: accessibilityPermission,
                        detail: accessibilityPermission ? "Funcionando" : "Sem permissão"
                    )
                    
                    DiagnosticRow(
                        title: "Input Monitoring",
                        status: inputMonitoringPermission,
                        detail: inputMonitoringPermission ? "Funcionando" : "Sem permissão"
                    )
                    
                    DiagnosticRow(
                        title: "CGEvent Tap (Atalhos Globais)",
                        status: cgEventTapActive,
                        detail: cgEventTapActive ? "Ativo e capturando teclas" : "Inativo — atalhos não funcionarão em segundo plano"
                    )
                    
                    Divider()
                    
                    Button(action: recheckAll) {
                        HStack(spacing: 6) {
                            if isCheckingDiagnostics {
                                ProgressView()
                                    .scaleEffect(0.7)
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                            Text("Verificar Tudo")
                        }
                        .font(.system(size: 13, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.bordered)
                    .disabled(isCheckingDiagnostics)
                }
            }
            
            // Tip
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundStyle(.yellow)
                    Text("Dica: Se os atalhos pararem de funcionar")
                        .font(.system(size: 12, weight: .medium))
                }
                
                Text("Quando o VibeFlow é atualizado, o macOS pode revogar as permissões. Nesse caso, vá em Ajustes do Sistema → Privacidade e remova/re-adicione o VibeFlow nas seções de Acessibilidade e Monitoramento de Teclado.")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .padding(12)
            .background(Color.yellow.opacity(0.08))
            .cornerRadius(8)
        }
        .onAppear {
            checkCGEventTap()
        }
    }
    
    private func requestMicrophone() {
        AVCaptureDevice.requestAccess(for: .audio) { _ in
            DispatchQueue.main.async {
                microphonePermission = AVCaptureDevice.authorizationStatus(for: .audio)
            }
        }
    }
    
    private func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
    
    private func openInputMonitoringSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent")!
        NSWorkspace.shared.open(url)
    }
    
    private func checkCGEventTap() {
        // Check if the AppDelegate has an active CGEvent tap
        if let appDelegate = NSApp.delegate as? AppDelegate,
           let tap = appDelegate.globalKeyTap {
            cgEventTapActive = CGEvent.tapIsEnabled(tap: tap)
        } else {
            cgEventTapActive = false
        }
    }
    
    private func recheckAll() {
        isCheckingDiagnostics = true
        
        // Refresh permissions
        microphonePermission = AVCaptureDevice.authorizationStatus(for: .audio)
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        accessibilityPermission = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        // Re-probe input monitoring
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
            CFMachPortInvalidate(testTap)
        } else {
            inputMonitoringPermission = false
        }
        
        // Retry global key tap if permissions are now granted
        if inputMonitoringPermission && accessibilityPermission {
            if let appDelegate = NSApp.delegate as? AppDelegate {
                appDelegate.setupGlobalKeyTap()
            }
        }
        
        // Check tap after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            checkCGEventTap()
            isCheckingDiagnostics = false
        }
    }
}

// MARK: - Diagnostic Row
struct DiagnosticRow: View {
    let title: String
    let status: Bool
    let detail: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: status ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 14))
                .foregroundStyle(status ? .green : .red)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                Text(detail)
                    .font(.system(size: 10))
                    .foregroundStyle(status ? Color.secondary : Color.red.opacity(0.7))
            }
            
            Spacer()
        }
    }
}

// MARK: - Supporting Views

struct SettingsCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(.blue)
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(.primary)
            
            content
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.controlBackgroundColor).opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                )
        )
    }
}

struct ModeSelectionRow: View {
    let mode: TranscriptionMode
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: mode.icon)
                    .font(.system(size: 14))
                    .foregroundStyle(modeColor)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(mode.localizedName)
                        .font(.system(size: 13, weight: isSelected ? .medium : .regular))
                    
                    Text(modeDescription)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.blue)
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private var modeColor: Color {
        switch mode {
        case .code: return Color(red: 0.2, green: 0.6, blue: 1.0)
        case .text: return Color(red: 0.3, green: 0.8, blue: 0.4)
        case .email: return Color(red: 1.0, green: 0.5, blue: 0.2)
        case .uxDesign: return Color(red: 0.8, green: 0.4, blue: 0.9)
        case .command: return Color(red: 0.9, green: 0.3, blue: 0.5)
        }
    }
    
    private var modeDescription: String {
        switch mode {
        case .code: return "Converte linguagem natural em código"
        case .text: return "Transcrição limpa de texto"
        case .email: return "Formata como email profissional"
        case .uxDesign: return "Para documentação de design"
        case .command: return "Transforma texto selecionado"
        }
    }
}

struct ToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13))
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .toggleStyle(.switch)
        .padding(.vertical, 8)
    }
}

struct ShortcutKey: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .medium))
            .frame(width: 20, height: 20)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                    )
            )
    }
}

struct SettingsShortcutRow: View {
    let action: String
    let shortcut: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            // Shortcut display
            HStack(spacing: 2) {
                ForEach(Array(shortcut), id: \.self) { char in
                    ShortcutKey(text: String(char))
                }
            }
            
            VStack(alignment: .leading, spacing: 1) {
                Text(action)
                    .font(.system(size: 13))
                Text(description)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
}

struct SettingsPermissionRow: View {
    let icon: String
    let title: String
    let description: String
    let isGranted: Bool
    let action: () -> Void
    
    private var statusColor: Color {
        isGranted ? .green : .orange
    }
    
    private var statusIcon: String {
        isGranted ? "checkmark.circle.fill" : "exclamationmark.circle.fill"
    }
    
    private var statusText: String {
        isGranted ? "Permitido" : "Necessário"
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(statusColor)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                Text(description)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Image(systemName: statusIcon)
                    .foregroundStyle(statusColor)
                
                if !isGranted {
                    Button("Configurar") {
                        action()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                } else {
                    Text(statusText)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(statusColor.opacity(0.08))
        )
    }
}

struct FavoriteLanguageBadge: View {
    let language: SpeechLanguage
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Text(language.flag)
                .font(.system(size: 14))
            Text(language.rawValue.uppercased())
                .font(.system(size: 11, weight: .medium))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(isActive ? Color.blue : Color(.controlBackgroundColor))
        )
        .foregroundStyle(isActive ? .white : .primary)
    }
}

// MARK: - Flow Layout
struct FlowLayout2: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
                
                self.size.width = max(self.size.width, x)
            }
            
            self.size.height = y + rowHeight
        }
    }
}

#Preview {
    ModernSettingsView()
}
