import SwiftUI
import AppKit

@main
struct VibeFlowApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var window: NSWindow?
    var settingsWindow: NSWindow?
    var viewModel: VibeFlowViewModel?
    var isHoldToTalkActive = false
    var globalKeyDownMonitor: Any?
    var globalKeyUpMonitor: Any?
    var localKeyDownMonitor: Any?
    var localKeyUpMonitor: Any?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Esconder dock icon
        NSApp.setActivationPolicy(.accessory)
        
        // Criar menu bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            // Usar ícone personalizado
            button.image = AppIconGenerator.createMenuBarIcon()
            button.action = #selector(toggleWindow)
            button.target = self
            
            // Menu de contexto (atualizado dinamicamente)
            updateMenu()
        }
        
        // Criar janela flutuante
        let viewModel = VibeFlowViewModel()
        self.viewModel = viewModel
        
        // O ClipboardHelper agora esconde o app automaticamente após colar
        // Não precisamos mais do callback aqui
        
        let contentView = ContentView()
            .environmentObject(viewModel)
        
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 100),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window?.contentView = NSHostingView(rootView: contentView)
        window?.isReleasedWhenClosed = false
        window?.level = .floating
        window?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window?.backgroundColor = .clear
        window?.isOpaque = false
        window?.hasShadow = true
        window?.center()
        window?.orderOut(nil)
        
        // Configurar atalhos globais
        setupGlobalShortcuts()
        
        // Observar mudanças de idioma
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateMenu),
            name: UserDefaults.didChangeNotification,
            object: nil
        )
    }
    
    @objc func updateMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: L10n.showHide, action: #selector(toggleWindow), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: L10n.settings, action: #selector(showSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: L10n.quit, action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem?.menu = menu
    }
    
    @objc func toggleWindow() {
        guard let window = window else { return }
        if window.isVisible {
            window.orderOut(nil)
        } else {
            centerWindow()
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    func centerWindow() {
        guard let window = window else { return }
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let windowRect = window.frame
            let x = screenRect.midX - windowRect.width / 2
            let y = screenRect.midY - windowRect.height / 2
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }
    }
    
    @objc func showSettings() {
        // Se já existe uma janela de configurações, traz para frente
        if let existingWindow = settingsWindow, existingWindow.isVisible {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        // Criar nova janela de configurações
        let settingsView = SettingsView()
        let hostingView = NSHostingView(rootView: settingsView)
        
        settingsWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 600),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        settingsWindow?.contentView = hostingView
        settingsWindow?.title = "VibeFlow - \(L10n.settingsTitle)"
        settingsWindow?.center()
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        // Quando a janela fechar, recarregar a API key
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: settingsWindow,
            queue: .main
        ) { [weak self] _ in
            self?.viewModel?.reloadAPIKey()
        }
    }
    
    func setupGlobalShortcuts() {
        // Atalho global: Cmd+Shift+V para abrir/fechar janela
        globalKeyDownMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // Cmd+Shift+V - Toggle window
            if event.modifierFlags.contains([.command, .shift]) && event.keyCode == 9 {
                DispatchQueue.main.async {
                    self?.toggleWindow()
                }
            }
        }
        
        // Hold-to-Talk: Option + Command (ambas as teclas devem estar pressionadas)
        globalKeyDownMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            guard let self = self else { return }
            
            let optionAndCommandPressed = event.modifierFlags.contains([.option, .command])
            
            if optionAndCommandPressed && !self.isHoldToTalkActive {
                // Option + Command pressionados - salvar app atual e iniciar gravação
                self.isHoldToTalkActive = true
                
                // IMPORTANTE: Salvar qual app estava ativo ANTES de mostrar o VibeFlow
                ClipboardHelper.savePreviousApp()
                
                DispatchQueue.main.async {
                    // Mostrar janela se não estiver visível
                    if !(self.window?.isVisible ?? false) {
                        self.centerWindow()
                        self.window?.makeKeyAndOrderFront(nil)
                        NSApp.activate(ignoringOtherApps: true)
                    }
                    // Iniciar gravação
                    if !(self.viewModel?.isRecording ?? false) {
                        self.viewModel?.toggleRecording()
                    }
                }
            } else if !optionAndCommandPressed && self.isHoldToTalkActive {
                // Teclas soltas - parar gravação
                self.isHoldToTalkActive = false
                DispatchQueue.main.async {
                    if self.viewModel?.isRecording ?? false {
                        self.viewModel?.toggleRecording()
                    }
                }
            }
        }
        
        // Monitor local para quando a janela está ativa
        localKeyDownMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            guard let self = self else { return event }
            
            let optionAndCommandPressed = event.modifierFlags.contains([.option, .command])
            
            if optionAndCommandPressed && !self.isHoldToTalkActive {
                self.isHoldToTalkActive = true
                DispatchQueue.main.async {
                    if !(self.viewModel?.isRecording ?? false) {
                        self.viewModel?.toggleRecording()
                    }
                }
            } else if !optionAndCommandPressed && self.isHoldToTalkActive {
                self.isHoldToTalkActive = false
                DispatchQueue.main.async {
                    if self.viewModel?.isRecording ?? false {
                        self.viewModel?.toggleRecording()
                    }
                }
            }
            
            return event
        }
    }
    
    deinit {
        if let monitor = globalKeyDownMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = globalKeyUpMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = localKeyDownMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = localKeyUpMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
