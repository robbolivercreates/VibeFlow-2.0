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
        // Copiar para o clipboard primeiro
        copyToClipboard(text)
        
        print("Texto copiado para clipboard: \(text.prefix(30))...")
        
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
