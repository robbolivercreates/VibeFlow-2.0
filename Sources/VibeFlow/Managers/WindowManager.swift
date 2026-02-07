import SwiftUI
import AppKit

/// Gerenciador centralizado de janelas do VibeFlow
/// Evita que o app feche quando janelas secundárias são fechadas
class WindowManager: ObservableObject {
    static let shared = WindowManager()
    
    // MARK: - Window References
    private var windows: [WindowType: NSWindow] = [:]
    private var windowDelegates: [WindowType: WindowDelegate] = [:]
    
    // MARK: - Window Type
    enum WindowType: String, CaseIterable {
        case mainFloating = "main"
        case settings = "settings"
        case history = "history"
        case snippets = "snippets"
        case analytics = "analytics"
        case wizard = "wizard"
        case license = "license"
        
        var title: String {
            switch self {
            case .mainFloating: return "VibeFlow"
            case .settings: return "Configurações"
            case .history: return "Histórico"
            case .snippets: return "Snippets"
            case .analytics: return "Estatísticas"
            case .wizard: return "Bem-vindo ao VibeFlow"
            case .license: return "Ativar VibeFlow"
            }
        }
        
        var size: NSSize {
            switch self {
            case .mainFloating: return NSSize(width: 280, height: 100)
            case .settings: return NSSize(width: 500, height: 400)
            case .history: return NSSize(width: 550, height: 600)
            case .snippets: return NSSize(width: 450, height: 450)
            case .analytics: return NSSize(width: 500, height: 550)
            case .wizard: return NSSize(width: 600, height: 520)
            case .license: return NSSize(width: 400, height: 500)
            }
        }
        
        var styleMask: NSWindow.StyleMask {
            switch self {
            case .mainFloating:
                return [.borderless, .fullSizeContentView]
            case .settings, .snippets, .analytics, .license:
                return [.titled, .closable]
            case .history:
                return [.titled, .closable, .resizable]
            case .wizard:
                return [.titled, .closable]
            }
        }
        
        var isFloating: Bool {
            self == .mainFloating
        }
    }
    
    // MARK: - Window Delegate
    private class WindowDelegate: NSObject, NSWindowDelegate {
        let type: WindowType
        let onClose: (() -> Void)?
        
        init(type: WindowType, onClose: (() -> Void)? = nil) {
            self.type = type
            self.onClose = onClose
            super.init()
        }
        
        func windowWillClose(_ notification: Notification) {
            onClose?()
        }
        
        func windowShouldClose(_ sender: NSWindow) -> Bool {
            // Sempre permitir fechamento - o app não vai terminar
            return true
        }
    }
    
    private init() {}
    
    // MARK: - Window Management
    
    /// Mostra uma janela do tipo especificado
    func show<T: View>(
        _ type: WindowType,
        content: T,
        onClose: (() -> Void)? = nil,
        bringToFront: Bool = true
    ) {
        // Se já existe, trazer para frente
        if let existingWindow = windows[type], existingWindow.isVisible {
            if bringToFront {
                existingWindow.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
            return
        }
        
        // Criar nova janela
        let hostingView = NSHostingView(rootView: content)
        
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: type.size),
            styleMask: type.styleMask,
            backing: .buffered,
            defer: false
        )
        
        window.contentView = hostingView
        window.title = "VibeFlow - \(type.title)"
        window.isReleasedWhenClosed = false
        
        // Configurações específicas por tipo
        if type.isFloating {
            window.level = .floating
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
            window.backgroundColor = .clear
            window.isOpaque = false
            window.hasShadow = true
        } else {
            window.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        }
        
        // Configurar delegate
        let delegate = WindowDelegate(type: type) { [weak self] in
            onClose?()
            // Não remover da lista - mantém referência para reabrir
        }
        window.delegate = delegate
        windowDelegates[type] = delegate
        
        // Salvar referência
        windows[type] = window
        
        // Mostrar
        window.center()
        if bringToFront {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    /// Esconde uma janela específica
    func hide(_ type: WindowType) {
        windows[type]?.orderOut(nil)
    }
    
    /// Fecha uma janela específica
    func close(_ type: WindowType) {
        windows[type]?.close()
    }
    
    /// Toggle visibilidade de uma janela
    func toggle(_ type: WindowType) {
        guard let window = windows[type] else { return }
        
        if window.isVisible {
            hide(type)
        } else {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    /// Verifica se uma janela está visível
    func isVisible(_ type: WindowType) -> Bool {
        windows[type]?.isVisible ?? false
    }
    
    /// Fecha todas as janelas secundárias (mantém a principal flutuante)
    func closeAllSecondary() {
        WindowType.allCases
            .filter { !$0.isFloating }
            .forEach { close($0) }
    }
    
    /// Esconde todas as janelas
    func hideAll() {
        WindowType.allCases.forEach { hide($0) }
    }
    
    /// Centraliza uma janela na tela principal
    func center(_ type: WindowType) {
        windows[type]?.center()
    }
    
    /// Posiciona a janela flutuante na parte inferior da tela
    func positionFloatingWindowAtBottom() {
        guard let window = windows[.mainFloating] else { return }
        
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let windowRect = window.frame
            let x = screenRect.midX - windowRect.width / 2
            let y = screenRect.minY + (screenRect.height * 0.15)
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }
    }
}

// MARK: - Convenience Extensions

extension WindowManager {
    /// Mostra a janela de configurações
    func showSettings(onClose: (() -> Void)? = nil) {
        show(.settings, content: SettingsView(), onClose: onClose)
    }
    
    /// Mostra a janela de histórico
    func showHistory() {
        show(.history, content: HistoryView())
    }
    
    /// Mostra a janela de snippets
    func showSnippets() {
        show(.snippets, content: SnippetsView())
    }
    
    /// Mostra a janela de analytics
    func showAnalytics() {
        show(.analytics, content: AnalyticsView())
    }
    
    /// Mostra o wizard
    func showWizard(onClose: (() -> Void)? = nil) {
        show(.wizard, content: SetupWizardView(), onClose: onClose)
    }
    
    /// Mostra a janela de licença
    // TODO: Implement LicenseActivationView
    // func showLicense(onClose: (() -> Void)? = nil) {
    //     show(.license, content: LicenseActivationView(), onClose: onClose)
    // }
}
