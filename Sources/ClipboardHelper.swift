import AppKit
import Carbon
import ApplicationServices

class ClipboardHelper {
    
    /// Verifica se tem permissão de Acessibilidade
    static func checkAccessibilityPermission() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
    
    // Guarda referência ao app que estava ativo
    private static var previousApp: NSRunningApplication?
    
    /// Salva qual app estava ativo antes do VibeFlow
    static func savePreviousApp() {
        // Pega o app que está na frente (exceto o próprio VibeFlow)
        let apps = NSWorkspace.shared.runningApplications.filter { 
            $0.isActive && $0.bundleIdentifier != Bundle.main.bundleIdentifier 
        }
        previousApp = apps.first ?? NSWorkspace.shared.frontmostApplication
    }
    
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

    /// Simula Cmd+C para copiar texto selecionado
    private static func simulateCopy() {
        guard let source = CGEventSource(stateID: .combinedSessionState) else {
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

    /// Obtém o texto selecionado no app ativo usando Cmd+C
    static func getSelectedText() -> String? {
        guard checkAccessibilityPermission() else {
            print("⚠️ Sem permissão de Acessibilidade para obter texto selecionado")
            return nil
        }

        // Salvar clipboard atual
        let previousClipboard = readFromClipboard()

        // Limpar clipboard
        NSPasteboard.general.clearContents()

        // Simular Cmd+C
        simulateCopy()

        // Esperar um pouco para o sistema processar
        usleep(100000) // 100ms

        // Ler o texto copiado
        let selectedText = readFromClipboard()

        // Restaurar clipboard anterior se não conseguiu copiar nada
        if selectedText == nil || selectedText?.isEmpty == true {
            if let previous = previousClipboard {
                copyToClipboard(previous)
            }
            return nil
        }

        return selectedText
    }
    
    /// Simula Cmd+V usando CGEvent
    private static func simulatePaste() {
        // Criar source de eventos
        guard let source = CGEventSource(stateID: .combinedSessionState) else {
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
    
    /// Copia texto e cola no app anterior
    static func copyAndPaste(_ text: String) {
        // Verificar permissão de acessibilidade
        if !checkAccessibilityPermission() {
            print("⚠️ Sem permissão de Acessibilidade! O texto foi copiado, use Cmd+V para colar.")
            copyToClipboard(text)
            return
        }
        
        // Copiar para o clipboard primeiro
        copyToClipboard(text)
        
        print("✓ Texto copiado para clipboard: \(text.prefix(30))...")
        
        // Pegar app anterior
        let appToActivate = previousApp ?? NSWorkspace.shared.runningApplications.first { 
            $0.activationPolicy == .regular && 
            $0.bundleIdentifier != Bundle.main.bundleIdentifier &&
            !$0.isTerminated
        }
        
        // Esconder VibeFlow
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
            }
        }
    }
}
