import AppKit
import Carbon
import ApplicationServices

class ClipboardHelper {

    /// Verifica se tem permissão de Acessibilidade (sempre retorna true para evitar bloqueios)
    static func checkAccessibilityPermission() -> Bool {
        // Verificação desativada - permite funcionar mesmo sem permissão formal
        // O usuário pode precisar colar manualmente com Cmd+V
        return true
    }

    // Guarda referência ao app que estava ativo
    private static var previousApp: NSRunningApplication?

    /// Salva qual app estava ativo antes do VoxAiGo
    static func savePreviousApp() {
        // Filter out VoxAiGo itself — we only want the external app the user was working in
        let voxBundleId = Bundle.main.bundleIdentifier

        // First: look for a non-VoxAiGo app that is currently active
        let externalActive = NSWorkspace.shared.runningApplications.first {
            $0.isActive && $0.bundleIdentifier != voxBundleId
        }

        if let app = externalActive {
            // Found a clearly external active app — save it
            previousApp = app
        } else {
            // No external app is active right now (VoxAiGo or a HUD has focus).
            // Check the frontmost app; if it's external, save it.
            // If it's VoxAiGo, keep the EXISTING previousApp to avoid overwriting
            // with VoxAiGo when a mode-change HUD is on screen.
            let frontmost = NSWorkspace.shared.frontmostApplication
            if frontmost?.bundleIdentifier != voxBundleId {
                previousApp = frontmost
            }
            // else: previousApp stays unchanged — it still points to the real target app
        }

        print("[ClipboardHelper] previousApp = \(previousApp?.localizedName ?? "nil")")
    }

    /// Re-activate the previously saved app (without pasting).
    /// Used by Vox Transform to focus the source app before capturing selected text.
    static func restorePreviousApp() {
        guard let app = previousApp, !app.isTerminated else {
            print("[ClipboardHelper] restorePreviousApp: no valid previous app")
            return
        }
        print("[ClipboardHelper] restorePreviousApp → \(app.localizedName ?? "unknown")")
        app.activate(options: [.activateIgnoringOtherApps])
    }

    // MARK: - Clipboard Save/Restore

    /// Saved clipboard data: array of (type, data) pairs per pasteboard item
    private struct SavedClipboard {
        let items: [[(NSPasteboard.PasteboardType, Data)]]
    }

    /// Save all current clipboard contents (supports text, images, files, rich text, etc.)
    private static func saveClipboardContents() -> SavedClipboard? {
        let pasteboard = NSPasteboard.general
        guard let items = pasteboard.pasteboardItems, !items.isEmpty else { return nil }

        var savedItems: [[(NSPasteboard.PasteboardType, Data)]] = []

        for item in items {
            var itemData: [(NSPasteboard.PasteboardType, Data)] = []
            for type in item.types {
                if let data = item.data(forType: type) {
                    itemData.append((type, data))
                }
            }
            if !itemData.isEmpty {
                savedItems.append(itemData)
            }
        }

        return savedItems.isEmpty ? nil : SavedClipboard(items: savedItems)
    }

    /// Restore previously saved clipboard contents
    private static func restoreClipboardContents(_ saved: SavedClipboard?) {
        guard let saved = saved, !saved.items.isEmpty else { return }

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        var pasteboardItems: [NSPasteboardItem] = []
        for itemData in saved.items {
            let item = NSPasteboardItem()
            for (type, data) in itemData {
                item.setData(data, forType: type)
            }
            pasteboardItems.append(item)
        }

        pasteboard.writeObjects(pasteboardItems)
        print("[Clipboard] Restored previous clipboard contents (\(saved.items.count) items)")
    }

    // MARK: - Basic Clipboard Operations

    /// Copia texto para o clipboard
    static func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }

    /// Lê texto do clipboard
    static func readFromClipboard() -> String? {
        return NSPasteboard.general.string(forType: .string)
    }

    /// Simula Cmd+C para copiar texto selecionado.
    /// Uses .privateState to avoid interference from physically held modifier keys
    /// (e.g., when triggered by ⌃⇧R, Ctrl+Shift are still held and would pollute .combinedSessionState).
    private static func simulateCopy() {
        guard let source = CGEventSource(stateID: .privateState) else {
            return
        }

        // Key code para 'C' é 8
        let cKeyCode: CGKeyCode = 0x08

        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: cKeyCode, keyDown: true) else {
            return
        }
        keyDown.flags = .maskCommand

        guard let keyUp = CGEvent(keyboardEventSource: source, virtualKey: cKeyCode, keyDown: false) else {
            return
        }
        keyUp.flags = .maskCommand

        keyDown.post(tap: .cgAnnotatedSessionEventTap)
        keyUp.post(tap: .cgAnnotatedSessionEventTap)
    }

    /// Simulates Cmd+C via AppleScript (System Events) — more compatible with web apps
    /// that ignore CGEvent-based synthetic key events (e.g. Telegram Web).
    private static func simulateCopyViaAppleScript() {
        let script = NSAppleScript(source: """
            tell application "System Events"
                keystroke "c" using command down
            end tell
        """)
        var error: NSDictionary?
        script?.executeAndReturnError(&error)
        if let error = error {
            print("[ClipboardHelper] AppleScript copy error: \(error)")
        }
    }

    /// Obtém o texto selecionado no app ativo usando Cmd+C
    /// Tries CGEvent first (fast), then AppleScript fallback (more compatible with web apps).
    static func getSelectedText() -> String? {
        // Salvar clipboard atual
        let savedClipboard = saveClipboardContents()

        // Limpar clipboard
        NSPasteboard.general.clearContents()

        // Attempt 1: CGEvent-based Cmd+C (works for most native apps)
        simulateCopy()
        usleep(150000) // 150ms

        var selectedText = readFromClipboard()

        // Attempt 2: AppleScript fallback (works for web apps like Telegram Web)
        if selectedText == nil || selectedText?.isEmpty == true {
            print("[ClipboardHelper] CGEvent copy failed, trying AppleScript fallback...")
            NSPasteboard.general.clearContents()
            simulateCopyViaAppleScript()
            usleep(200000) // 200ms — AppleScript needs a bit more time
            selectedText = readFromClipboard()
        }

        // Restaurar clipboard anterior se não conseguiu copiar nada
        if selectedText == nil || selectedText?.isEmpty == true {
            restoreClipboardContents(savedClipboard)
            return nil
        }

        // Restore clipboard even on success (we already have the selected text in memory)
        restoreClipboardContents(savedClipboard)
        return selectedText
    }

    /// Simula Cmd+V usando CGEvent
    /// Uses .privateState to avoid interference from physically held modifier keys
    /// (e.g., when triggered by ⌥⌘, Option+Command are still held and would pollute .combinedSessionState).
    private static func simulatePaste() {
        // Criar source de eventos
        guard let source = CGEventSource(stateID: .privateState) else {
            print("Não foi possível criar CGEventSource")
            return
        }

        // Key code para 'V' é 9
        let vKeyCode: CGKeyCode = 0x09

        // Criar evento key down com Command
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true) else {
            return
        }
        keyDown.flags = .maskCommand

        // Criar evento key up com Command
        guard let keyUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false) else {
            return
        }
        keyUp.flags = .maskCommand

        // Postar os eventos
        keyDown.post(tap: .cgAnnotatedSessionEventTap)
        keyUp.post(tap: .cgAnnotatedSessionEventTap)
    }

    /// Copia texto e cola no app anterior, then restores the original clipboard
    static func copyAndPaste(_ text: String) {
        // Save current clipboard contents BEFORE overwriting
        let savedClipboard = saveClipboardContents()

        // Copiar para o clipboard primeiro
        copyToClipboard(text)

        print("✓ Texto copiado para clipboard: \(text.prefix(30))...")

        // Pegar app anterior
        let appToActivate = previousApp ?? NSWorkspace.shared.runningApplications.first {
            $0.activationPolicy == .regular &&
            $0.bundleIdentifier != Bundle.main.bundleIdentifier &&
            !$0.isTerminated
        }

        // Esconder VoxAiGo
        DispatchQueue.main.async {
            NSApp.hide(nil)
        }

        // Ativar app anterior e colar
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if let app = appToActivate {
                print("→ Ativando app: \(app.localizedName ?? "unknown")")
                let activated = app.activate(options: [.activateIgnoringOtherApps])
                print("→ App ativado: \(activated)")
            }

            // Esperar o app ganhar foco e então colar
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                print("→ Simulando Cmd+V...")
                simulatePaste()
                print("✓ Paste enviado!")

                // Restore original clipboard after paste is processed
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    restoreClipboardContents(savedClipboard)
                }
            }
        }
    }
}
