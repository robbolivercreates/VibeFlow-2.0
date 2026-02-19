import SwiftUI
import AVFoundation
import IOKit

/// Clean settings view with row-based design (inspired by modern macOS apps)
struct SettingsDetailView: View {
    @StateObject private var settings = SettingsManager.shared
    @State private var showingResetConfirmation = false
    @State private var microphonePermission: AVAuthorizationStatus = .notDetermined
    @State private var accessibilityPermission = false
    @State private var inputMonitoringPermission = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // MARK: - Header
                headerSection

                // MARK: - API Configuration
                apiSection

                // MARK: - Behavior
                behaviorSection

                // MARK: - Conversation Reply
                conversationReplySection

                // MARK: - Shortcuts
                shortcutsSection

                // MARK: - Permissions
                permissionsSection

                // MARK: - Advanced
                advancedSection
            }
            .padding(32)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            checkPermissions()
        }
        .alert("Limpar Dados", isPresented: $showingResetConfirmation) {
            Button("Cancelar", role: .cancel) {}
            Button("Limpar", role: .destructive) {
                HistoryManager.shared.clear()
                WritingStyleManager.shared.clearAllSamples()
            }
        } message: {
            Text("Isso ira limpar todo o historico de transcricoes e amostras de estilo. Esta acao nao pode ser desfeita.")
        }
    }

    private func checkPermissions() {
        microphonePermission = AVCaptureDevice.authorizationStatus(for: .audio)
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
        accessibilityPermission = AXIsProcessTrustedWithOptions(options as CFDictionary)
        inputMonitoringPermission = IOHIDRequestAccess(kIOHIDRequestTypeListenEvent)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ajustes")
                .font(.system(size: 28, weight: .bold))

            Text("Configure o VoxAiGo de acordo com suas preferencias.")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Account Section

    private var apiSection: some View {
        SettingsSection(title: L10n.account, icon: "person.crop.circle") {
            AccountView()
        }
    }

    // MARK: - Behavior Section

    private var behaviorSection: some View {
        SettingsSection(title: "Comportamento", icon: "gearshape") {
            VStack(spacing: 0) {
                SettingsToggleRow(
                    title: L10n.launchAtLogin,
                    subtitle: L10n.launchAtLoginDescription,
                    isOn: $settings.launchAtLogin
                )

                Divider().padding(.leading, 44)

                SettingsToggleRow(
                    title: "Colar automaticamente",
                    subtitle: "Cola o texto transcrito automaticamente",
                    isOn: $settings.enableAutoPaste
                )

                Divider().padding(.leading, 44)

                SettingsToggleRow(
                    title: "Fechar apos colar",
                    subtitle: "Fecha a janela apos colar o texto",
                    isOn: $settings.enableAutoClose
                )

                Divider().padding(.leading, 44)

                SettingsToggleRow(
                    title: "Salvar historico",
                    subtitle: "Mantem um registro das transcricoes",
                    isOn: $settings.enableHistory
                )

                Divider().padding(.leading, 44)

                SettingsToggleRow(
                    title: "Efeitos sonoros",
                    subtitle: "Sons ao iniciar e parar gravacao",
                    isOn: $settings.enableSounds
                )

                Divider().padding(.leading, 44)

                SettingsToggleRow(
                    title: L10n.clarifyAndOrganize,
                    subtitle: L10n.clarifyDescription,
                    isOn: $settings.clarifyText
                )
            }
        }
    }

    // MARK: - Conversation Reply Section

    private var conversationReplySection: some View {
        SettingsSection(title: "Resposta de Conversa", icon: "bubble.left.and.bubble.right") {
            VStack(spacing: 0) {
                SettingsToggleRow(
                    title: "Habilitar Resposta de Conversa",
                    subtitle: "Traduz mensagens e responde no idioma do remetente",
                    isOn: $settings.enableConversationReply
                )

                if settings.enableConversationReply {
                    Divider().padding(.leading, 44)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("COMO FUNCIONA")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.secondary)

                        VStack(alignment: .leading, spacing: 8) {
                            ConversationReplyStepRow(number: "1", text: "Selecione uma mensagem em qualquer app (WhatsApp, Slack, email…)")
                            ConversationReplyStepRow(number: "2", text: "Pressione ⌃⇧R — um painel aparece com a tradução")
                            ConversationReplyStepRow(number: "3", text: "Leia a tradução no seu idioma")
                            ConversationReplyStepRow(number: "4", text: "Segure ⌥⌘ e fale sua resposta no seu idioma")
                            ConversationReplyStepRow(number: "5", text: "Sua resposta é traduzida automaticamente e colada no idioma deles")
                        }

                        HStack {
                            Text("Ativar com")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                            Spacer()
                            ShortcutBadge(shortcut: settings.conversationReplyShortcut)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
        }
    }

    // MARK: - Shortcuts Section

    private var shortcutsSection: some View {
        SettingsSection(title: "Atalhos", icon: "command") {
            VStack(spacing: 0) {
                SettingsRow(
                    title: "Gravar",
                    subtitle: "Segure para gravar"
                ) {
                    ShortcutEditor(
                        shortcut: $settings.shortcutRecordKey,
                        placeholder: "⌥⌘"
                    )
                }

                Divider().padding(.leading, 44)

                SettingsRow(
                    title: "Alternar idioma",
                    subtitle: "Cicla entre favoritos"
                ) {
                    ShortcutEditor(
                        shortcut: $settings.cycleLanguageShortcut,
                        placeholder: "⌃⇧L"
                    )
                }

                Divider().padding(.leading, 44)

                SettingsRow(
                    title: "Abrir janela",
                    subtitle: "Mostra/esconde a janela principal"
                ) {
                    ShortcutEditor(
                        shortcut: $settings.shortcutToggleKey,
                        placeholder: "⌘⇧V"
                    )
                }

                Divider().padding(.leading, 44)

                SettingsRow(
                    title: "Alternar modo",
                    subtitle: "Cicla entre modos de transcrição"
                ) {
                    ShortcutEditor(
                        shortcut: $settings.cycleModeShortcut,
                        placeholder: "⌃⇧M"
                    )
                }

                Divider().padding(.leading, 44)

                SettingsRow(
                    title: "Colar última",
                    subtitle: "Cola a última transcrição do histórico"
                ) {
                    ShortcutEditor(
                        shortcut: $settings.pasteLastShortcut,
                        placeholder: "⌃⇧V"
                    )
                }

                Divider().padding(.leading, 44)

                SettingsRow(
                    title: "Resposta de Conversa",
                    subtitle: "Traduz texto selecionado e responde no idioma deles"
                ) {
                    ShortcutEditor(
                        shortcut: $settings.conversationReplyShortcut,
                        placeholder: "⌃⇧R"
                    )
                }

                Divider().padding(.leading, 44)

                SettingsRow(
                    title: "Configuracoes",
                    subtitle: "Abre esta janela"
                ) {
                    ShortcutBadge(shortcut: "⌘,")
                }

                Divider().padding(.leading, 44)

                // Reset shortcuts hint
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                    Text("Clique em um atalho para editar. Pressione as teclas desejadas.")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
        }
    }

    // MARK: - Permissions Section

    private var permissionsSection: some View {
        SettingsSection(title: "Permissoes", icon: "lock.shield") {
            VStack(spacing: 0) {
                SettingsRow(
                    title: "Microfone",
                    subtitle: permissionStatusText(microphonePermission)
                ) {
                    PermissionBadge(
                        isGranted: microphonePermission == .authorized,
                        onRequest: {
                            AVCaptureDevice.requestAccess(for: .audio) { _ in
                                DispatchQueue.main.async {
                                    checkPermissions()
                                }
                            }
                        }
                    )
                }

                Divider().padding(.leading, 44)

                SettingsRow(
                    title: "Acessibilidade",
                    subtitle: accessibilityPermission ? "Permitido" : "Necessario para colar automaticamente"
                ) {
                    PermissionBadge(
                        isGranted: accessibilityPermission,
                        onRequest: {
                            let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                            NSWorkspace.shared.open(url)
                        }
                    )
                }

                Divider().padding(.leading, 44)

                SettingsRow(
                    title: "Input Monitoring",
                    subtitle: inputMonitoringPermission ? "Permitido" : "Necessario para atalhos globais"
                ) {
                    PermissionBadge(
                        isGranted: inputMonitoringPermission,
                        onRequest: {
                            let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent")!
                            NSWorkspace.shared.open(url)
                        }
                    )
                }
            }
        }
    }

    // MARK: - Advanced Section

    private var advancedSection: some View {
        SettingsSection(title: "Avancado", icon: "slider.horizontal.3") {
            VStack(spacing: 0) {
                SettingsRow(
                    title: "Setup Wizard",
                    subtitle: "Reconfigurar o VoxAiGo do inicio"
                ) {
                    Button("Abrir Wizard") {
                        // Use notification to open wizard window properly
                        NotificationCenter.default.post(name: .openSetupWizard, object: nil)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                Divider().padding(.leading, 44)

                SettingsRow(
                    title: "Limpar dados",
                    subtitle: "Remove historico e amostras de estilo"
                ) {
                    Button("Limpar") {
                        showingResetConfirmation = true
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .foregroundStyle(.red)
                }

                Divider().padding(.leading, 44)

                SettingsRow(
                    title: "Resetar atalhos",
                    subtitle: "Restaura atalhos para o padrao"
                ) {
                    Button("Resetar") {
                        settings.shortcutRecordKey = "⌥⌘"
                        settings.shortcutToggleKey = "⌘⇧V"
                        settings.cycleLanguageShortcut = "⌃⇧L"
                        settings.cycleModeShortcut = "⌃⇧M"
                        settings.pasteLastShortcut = "⌃⇧V"
                        settings.conversationReplyShortcut = "⌃⇧R"
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                Divider().padding(.leading, 44)

                SettingsRow(
                    title: "Versao",
                    subtitle: "VoxAiGo para macOS"
                ) {
                    Text(AppVersion.current)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func permissionStatusText(_ status: AVAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "Nao solicitado"
        case .restricted: return "Restrito"
        case .denied: return "Negado - abra Preferencias do Sistema"
        case .authorized: return "Permitido"
        @unknown default: return "Desconhecido"
        }
    }
}

// MARK: - Settings Section

struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)

                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 0) {
                content
            }
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
            )
        }
    }
}

// MARK: - Settings Row

struct SettingsRow<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let trailing: Content

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14))

                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            trailing
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Settings Toggle Row

struct SettingsToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        SettingsRow(title: title, subtitle: subtitle) {
            Toggle("", isOn: $isOn)
                .toggleStyle(.switch)
                .labelsHidden()
        }
    }
}

// MARK: - Shortcut Badge

struct ShortcutBadge: View {
    let shortcut: String

    var body: some View {
        Text(shortcut)
            .font(.system(size: 13, weight: .medium, design: .monospaced))
            .foregroundStyle(.purple)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.purple.opacity(0.1))
            .cornerRadius(6)
    }
}

// MARK: - Shortcut Editor (NSEvent-based, works on macOS 13+)

struct ShortcutEditor: View {
    @Binding var shortcut: String
    let placeholder: String

    @State private var isEditing = false
    @State private var tempShortcut = ""
    @State private var eventMonitor: Any?

    var body: some View {
        Button(action: {
            if isEditing {
                stopEditing()
            } else {
                startEditing()
            }
        }) {
            HStack(spacing: 6) {
                Text(isEditing ? (tempShortcut.isEmpty ? "Pressione..." : tempShortcut) : shortcut)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(isEditing ? .orange : .purple)

                if !isEditing {
                    Image(systemName: "pencil")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                } else {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.orange)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(isEditing ? Color.orange.opacity(0.15) : Color.purple.opacity(0.1))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isEditing ? Color.orange : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onDisappear {
            stopEditing()
        }
    }

    private func startEditing() {
        isEditing = true
        tempShortcut = ""

        // Listen for key events using NSEvent (works on macOS 13+)
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

            var parts: [String] = []

            if modifiers.contains(.control) { parts.append("⌃") }
            if modifiers.contains(.option) { parts.append("⌥") }
            if modifiers.contains(.shift) { parts.append("⇧") }
            if modifiers.contains(.command) { parts.append("⌘") }

            // Escape to cancel
            if event.keyCode == 53 {
                DispatchQueue.main.async {
                    stopEditing()
                }
                return nil
            }

            // Get key character from keyCode
            let keyChar = keyCodeToDisplayChar(event.keyCode)

            if !keyChar.isEmpty {
                parts.append(keyChar)
            }

            let newShortcut = parts.joined()

            if parts.count >= 2 && !keyChar.isEmpty {
                // Valid: at least one modifier + one key letter
                DispatchQueue.main.async {
                    shortcut = newShortcut
                    stopEditing()
                }
                return nil // consume the event
            } else if !parts.isEmpty {
                DispatchQueue.main.async {
                    tempShortcut = newShortcut
                }
                return nil
            }

            return nil
        }
    }

    private func stopEditing() {
        isEditing = false
        tempShortcut = ""
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    /// Map key codes to display characters (macOS virtual key codes)
    private func keyCodeToDisplayChar(_ keyCode: UInt16) -> String {
        let keyMap: [UInt16: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
            8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
            16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6", 23: "5",
            24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0", 30: "]", 31: "O",
            32: "U", 33: "[", 34: "I", 35: "P", 37: "L", 38: "J", 40: "K",
            45: "N", 46: "M",
            36: "↩", 48: "⇥", 49: "Space", 50: "`", 51: "⌫"
        ]
        return keyMap[keyCode] ?? ""
    }
}

// MARK: - Conversation Reply Step Row

struct ConversationReplyStepRow: View {
    let number: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(number)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 16, height: 16)
                .background(Circle().fill(Color.purple))

            Text(text)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
    }
}

// MARK: - Permission Badge

struct PermissionBadge: View {
    let isGranted: Bool
    let onRequest: () -> Void

    var body: some View {
        if isGranted {
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("OK")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.green)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.green.opacity(0.1))
            .cornerRadius(6)
        } else {
            Button("Permitir", action: onRequest)
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
    }
}

#Preview {
    SettingsDetailView()
        .frame(width: 600, height: 800)
}
