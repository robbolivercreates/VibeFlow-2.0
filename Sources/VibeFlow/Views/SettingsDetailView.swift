import SwiftUI
import AVFoundation

/// Clean settings view with row-based design (inspired by modern macOS apps)
struct SettingsDetailView: View {
    @StateObject private var settings = SettingsManager.shared
    @State private var showingResetConfirmation = false
    @State private var microphonePermission: AVAuthorizationStatus = .notDetermined
    @State private var accessibilityPermission = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // MARK: - Header
                headerSection

                // MARK: - API Configuration
                apiSection

                // MARK: - Behavior
                behaviorSection

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
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ajustes")
                .font(.system(size: 28, weight: .bold))

            Text("Configure o VibeFlow de acordo com suas preferencias.")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - API Section

    private var apiSection: some View {
        SettingsSection(title: "API", icon: "key") {
            VStack(spacing: 0) {
                // API Key
                SettingsRow(
                    title: "Google Gemini API Key",
                    subtitle: settings.apiKey.isEmpty ? "Nao configurada" : "••••••••" + settings.apiKey.suffix(4)
                ) {
                    SecureField("API Key", text: $settings.apiKey)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 200)
                }

                Divider().padding(.leading, 44)

                // Get API Key link
                SettingsRow(
                    title: "Obter API Key",
                    subtitle: "Google AI Studio"
                ) {
                    Link(destination: URL(string: "https://aistudio.google.com/app/apikey")!) {
                        HStack(spacing: 4) {
                            Text("Abrir")
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 10))
                        }
                        .font(.system(size: 13))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                Divider().padding(.leading, 44)

                // Model info
                SettingsRow(
                    title: "Modelo",
                    subtitle: "Versao da IA utilizada"
                ) {
                    Text("Gemini 2.0 Flash")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Behavior Section

    private var behaviorSection: some View {
        SettingsSection(title: "Comportamento", icon: "gearshape") {
            VStack(spacing: 0) {
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
                        placeholder: "⌃⌥L"
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
            }
        }
    }

    // MARK: - Advanced Section

    private var advancedSection: some View {
        SettingsSection(title: "Avancado", icon: "slider.horizontal.3") {
            VStack(spacing: 0) {
                SettingsRow(
                    title: "Setup Wizard",
                    subtitle: "Reconfigurar o VibeFlow do inicio"
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
                        settings.cycleLanguageShortcut = "⌃⌥L"
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                Divider().padding(.leading, 44)

                SettingsRow(
                    title: "Versao",
                    subtitle: "VibeFlow para macOS"
                ) {
                    Text("2.1.0")
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
                    .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
            )
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

// MARK: - Shortcut Editor

struct ShortcutEditor: View {
    @Binding var shortcut: String
    let placeholder: String

    @State private var isEditing = false
    @State private var tempShortcut = ""

    var body: some View {
        Button(action: {
            isEditing = true
            tempShortcut = ""
        }) {
            HStack(spacing: 6) {
                Text(isEditing ? (tempShortcut.isEmpty ? "..." : tempShortcut) : shortcut)
                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                    .foregroundStyle(isEditing ? .orange : .purple)

                if !isEditing {
                    Image(systemName: "pencil")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
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
        .background(
            ShortcutCaptureView(isActive: $isEditing, shortcut: $shortcut, tempShortcut: $tempShortcut)
                .frame(width: 0, height: 0)
        )
        .onAppear {
            tempShortcut = shortcut
        }
    }
}

// MARK: - Shortcut Capture View (NSViewRepresentable for macOS 13 compatibility)

struct ShortcutCaptureView: NSViewRepresentable {
    @Binding var isActive: Bool
    @Binding var shortcut: String
    @Binding var tempShortcut: String

    func makeNSView(context: Context) -> ShortcutCaptureNSView {
        let view = ShortcutCaptureNSView()
        view.delegate = context.coordinator
        return view
    }

    func updateNSView(_ nsView: ShortcutCaptureNSView, context: Context) {
        nsView.isActive = isActive
        if isActive {
            nsView.window?.makeFirstResponder(nsView)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject {
        let parent: ShortcutCaptureView

        init(_ parent: ShortcutCaptureView) {
            self.parent = parent
        }

        func handleKeyEvent(_ event: NSEvent) -> Bool {
            guard parent.isActive else { return false }

            var parts: [String] = []

            // Build modifier string
            if event.modifierFlags.contains(.control) {
                parts.append("⌃")
            }
            if event.modifierFlags.contains(.option) {
                parts.append("⌥")
            }
            if event.modifierFlags.contains(.shift) {
                parts.append("⇧")
            }
            if event.modifierFlags.contains(.command) {
                parts.append("⌘")
            }

            // Add key character if it's not just modifiers
            if let characters = event.charactersIgnoringModifiers?.uppercased(),
               !characters.isEmpty && characters != " " {
                // Filter out pure modifier keys
                let key = characters
                if !key.isEmpty && key != "\t" && key != "\r" && key != "\n" {
                    parts.append(key)
                }
            }

            let newShortcut = parts.joined()

            if !newShortcut.isEmpty && parts.count >= 2 {
                // Valid shortcut (at least one modifier + one key)
                parent.shortcut = newShortcut
                parent.isActive = false
                return true
            } else if !parts.isEmpty {
                // Show partial shortcut while typing
                parent.tempShortcut = newShortcut
                return true
            }

            return true
        }
    }
}

// MARK: - Shortcut Capture NSView

class ShortcutCaptureNSView: NSView {
    var isActive: Bool = false
    weak var delegate: ShortcutCaptureView.Coordinator?

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        if isActive, let delegate = delegate {
            if delegate.handleKeyEvent(event) {
                return
            }
        }
        super.keyDown(with: event)
    }

    override func flagsChanged(with event: NSEvent) {
        // Track modifier key changes
        if isActive, let delegate = delegate {
            _ = delegate.handleKeyEvent(event)
        }
        super.flagsChanged(with: event)
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
