import SwiftUI
import AppKit
import Combine

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
    var historyWindow: NSWindow?
    var snippetsWindow: NSWindow?
    var wizardWindow: NSWindow?
    var viewModel: VibeFlowViewModel?
    var isHoldToTalkActive = false
    var globalKeyMonitor: Any?
    var localKeyMonitor: Any?
    
    // Managers
    let settings = SettingsManager.shared
    let sounds = SoundManager.shared
    let history = HistoryManager.shared
    let snippets = SnippetsManager.shared
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Esconder dock icon
        NSApp.setActivationPolicy(.accessory)
        
        // Criar menu bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = AppIconGenerator.createMenuBarIcon()
            button.action = #selector(toggleWindow)
            button.target = self
            updateMenu()
        }
        
        // Criar view model
        let viewModel = VibeFlowViewModel()
        self.viewModel = viewModel
        
        // Criar janela flutuante
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
        
        // Observar mudanças
        setupObservers()
        
        // Mostrar wizard se necessário
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.checkOnboarding()
        }
    }
    
    // MARK: - Onboarding
    
    func checkOnboarding() {
        guard !settings.onboardingCompleted || !settings.hasApiKey else { return }
        showWizard()
    }
    
    @objc func resetAndShowWizard() {
        settings.resetOnboarding()
        showWizard()
    }
    
    func showWizard() {
        // Esconder janela principal se estiver visível
        window?.orderOut(nil)
        
        // Fechar wizard existente
        wizardWindow?.close()
        
        let wizardView = SetupWizardView()
        let hostingView = NSHostingView(rootView: wizardView)
        
        wizardWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 520),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        wizardWindow?.contentView = hostingView
        wizardWindow?.title = "Bem-vindo ao VibeFlow"
        wizardWindow?.center()
        wizardWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        // Observar fechamento
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: wizardWindow,
            queue: .main
        ) { [weak self] _ in
            self?.viewModel?.reloadAPIKey()
        }
    }
    
    // MARK: - Menu
    
    @objc func updateMenu() {
        let menu = NSMenu()
        
        // Título
        let titleItem = NSMenuItem(title: "VibeFlow 2.1", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)
        menu.addItem(NSMenuItem.separator())
        
        // Ações principais
        menu.addItem(NSMenuItem(title: L10n.showHide, action: #selector(toggleWindow), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        
        // Modos
        let modesMenu = NSMenu()
        for mode in TranscriptionMode.allCases {
            let item = NSMenuItem(title: mode.localizedName, action: #selector(selectMode(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = mode
            if settings.selectedMode == mode {
                item.state = .on
            }
            modesMenu.addItem(item)
        }
        let modesItem = NSMenuItem(title: L10n.defaultMode, action: nil, keyEquivalent: "")
        modesItem.submenu = modesMenu
        menu.addItem(modesItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Novos itens
        menu.addItem(NSMenuItem(title: "Histórico", action: #selector(showHistory), keyEquivalent: "y"))
        menu.addItem(NSMenuItem(title: "Snippets", action: #selector(showSnippets), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        
        // Settings
        menu.addItem(NSMenuItem(title: L10n.settings, action: #selector(showSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: L10n.quit, action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    @objc func selectMode(_ sender: NSMenuItem) {
        guard let mode = sender.representedObject as? TranscriptionMode else { return }
        settings.selectedMode = mode
        viewModel?.updateMode(mode)
        updateMenu()
    }
    
    // MARK: - Window Management
    
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
            // Posicionar na parte inferior da tela (15% acima da base)
            let y = screenRect.minY + (screenRect.height * 0.15)
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }
    }
    
    // MARK: - Settings
    
    @objc func showSettings() {
        if let existingWindow = settingsWindow, existingWindow.isVisible {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let settingsView = SettingsView()
        let hostingView = NSHostingView(rootView: settingsView)
        
        settingsWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 350),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        settingsWindow?.contentView = hostingView
        settingsWindow?.title = "VibeFlow - \(L10n.settingsTitle)"
        settingsWindow?.center()
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: settingsWindow,
            queue: .main
        ) { [weak self] _ in
            self?.viewModel?.reloadAPIKey()
        }
    }
    
    // MARK: - History
    
    @objc func showHistory() {
        if let existingWindow = historyWindow, existingWindow.isVisible {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let historyView = HistoryView()
        let hostingView = NSHostingView(rootView: historyView)
        
        historyWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 500),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        historyWindow?.contentView = hostingView
        historyWindow?.title = "VibeFlow - Histórico"
        historyWindow?.center()
        historyWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    // MARK: - Snippets
    
    @objc func showSnippets() {
        if let existingWindow = snippetsWindow, existingWindow.isVisible {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let snippetsView = SnippetsView()
        let hostingView = NSHostingView(rootView: snippetsView)
        
        snippetsWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 450),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        snippetsWindow?.contentView = hostingView
        snippetsWindow?.title = "VibeFlow - Snippets"
        snippetsWindow?.center()
        snippetsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    // MARK: - Global Shortcuts
    
    func setupGlobalShortcuts() {
        // Cmd+Shift+V - Toggle window
        globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.contains([.command, .shift]) && event.keyCode == 9 {
                DispatchQueue.main.async {
                    self?.toggleWindow()
                }
            }
        }
        
        // Hold-to-Talk: Option + Command
        NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            guard let self = self else { return }
            self.handleFlagsChanged(event)
        }
        
        // Monitor local também
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            guard let self = self else { return event }
            self.handleFlagsChanged(event)
            return event
        }
    }
    
    func handleFlagsChanged(_ event: NSEvent) {
        let optionAndCommandPressed = event.modifierFlags.contains([.option, .command])
        
        if optionAndCommandPressed && !isHoldToTalkActive {
            // Iniciar gravação
            isHoldToTalkActive = true
            
            // Som de início
            sounds.playStart()
            
            // Salvar app anterior
            ClipboardHelper.savePreviousApp()
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                // Mostrar janela
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
            
        } else if !optionAndCommandPressed && isHoldToTalkActive {
            // Parar gravação
            isHoldToTalkActive = false
            
            // Som de parada
            sounds.playStop()
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                if self.viewModel?.isRecording ?? false {
                    self.viewModel?.toggleRecording()
                }
            }
        }
    }
    
    // MARK: - Observers
    
    func setupObservers() {
        // Observar mudanças de modo
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateMenu),
            name: .modeChanged,
            object: nil
        )
        
        // Observar transcrições completas para salvar no histórico
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTranscriptionComplete(_:)),
            name: .transcriptionComplete,
            object: nil
        )
        
        // Observar gravação cancelada (sem fala) para fechar janela
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRecordingCancelled),
            name: .recordingCancelled,
            object: nil
        )
    }
    
    @objc func handleRecordingCancelled() {
        // Fechar janela se não houve fala
        DispatchQueue.main.async { [weak self] in
            self?.window?.orderOut(nil)
        }
    }
    
    @objc func handleTranscriptionComplete(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let text = userInfo["text"] as? String,
              let mode = userInfo["mode"] as? TranscriptionMode else { return }
        
        // Som de sucesso
        sounds.playSuccess()
        
        // Salvar no histórico
        history.add(text: text, mode: mode)
    }
    
    deinit {
        if let monitor = globalKeyMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = localKeyMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
