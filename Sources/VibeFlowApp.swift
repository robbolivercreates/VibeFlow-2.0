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

    // Language notification window (retained to prevent memory issues)
    var languageNotificationWindow: NSWindow?
    var lastLanguageCycleTime: Date = .distantPast
    let languageCycleDebounceInterval: TimeInterval = 0.3 // 300ms debounce
    
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
        
        // Window size: max expanded width (440) + padding, height for compact overlay
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 80),
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
        window?.hasShadow = false // Shadow is handled by SwiftUI
        window?.center()
        window?.orderOut(nil)
        
        // Configurar atalhos globais
        setupGlobalShortcuts()
        
        // Observar mudanças
        setupObservers()
        
        // Mostrar wizard ou ativação se necessário
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.checkFirstLaunch()
        }
    }
    
    // MARK: - First Launch
    
    func checkFirstLaunch() {
        // Verificar licença primeiro
        if !settings.isLicensed && !settings.hasSeenLicensePrompt {
            showLicenseActivation()
            return
        }
        
        // Depois verificar onboarding
        guard !settings.onboardingCompleted || !settings.hasApiKey else { return }
        showWizard()
    }
    
    var licenseWindow: NSWindow?
    
    func showLicenseActivation() {
        settings.hasSeenLicensePrompt = true
        
        let licenseView = LicenseActivationView()
        let hostingView = NSHostingView(rootView: licenseView)
        
        licenseWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 500),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        licenseWindow?.contentView = hostingView
        licenseWindow?.title = "Ativar VibeFlow"
        licenseWindow?.center()
        licenseWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
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
        
        // Idioma atual e favoritos
        let currentLangItem = NSMenuItem(
            title: "Idioma: \(settings.outputLanguage.displayWithFlag)",
            action: nil,
            keyEquivalent: ""
        )
        currentLangItem.isEnabled = false
        menu.addItem(currentLangItem)
        
        // Submenu de idiomas favoritos
        if settings.favoriteLanguages.count > 1 {
            let langMenu = NSMenu()
            for language in settings.favoriteLanguages {
                let item = NSMenuItem(
                    title: language.displayWithFlag,
                    action: #selector(selectLanguage(_:)),
                    keyEquivalent: ""
                )
                item.target = self
                item.representedObject = language
                if settings.outputLanguage == language {
                    item.state = .on
                }
                langMenu.addItem(item)
            }
            langMenu.addItem(NSMenuItem.separator())
            let cycleItem = NSMenuItem(
                title: "Próximo (⌃⌥L)",
                action: #selector(cycleLanguage),
                keyEquivalent: ""
            )
            cycleItem.target = self
            langMenu.addItem(cycleItem)
            
            let langItem = NSMenuItem(title: "Idiomas Favoritos", action: nil, keyEquivalent: "")
            langItem.submenu = langMenu
            menu.addItem(langItem)
        } else {
            let cycleItem = NSMenuItem(
                title: "Mudar Idioma (⌃⌥L)",
                action: #selector(cycleLanguage),
                keyEquivalent: ""
            )
            cycleItem.target = self
            menu.addItem(cycleItem)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // Novos itens
        menu.addItem(NSMenuItem(title: "Histórico", action: #selector(showHistory), keyEquivalent: "y"))
        menu.addItem(NSMenuItem(title: "Snippets", action: #selector(showSnippets), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Estatísticas", action: #selector(showAnalytics), keyEquivalent: ""))
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
    
    @objc func selectLanguage(_ sender: NSMenuItem) {
        guard let language = sender.representedObject as? SpeechLanguage else { return }
        settings.outputLanguage = language
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
        
        // Close existing window if present
        settingsWindow?.close()
        
        let settingsView = ModernSettingsView()
        let hostingView = NSHostingView(rootView: settingsView)
        
        settingsWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 550, height: 500),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        settingsWindow?.contentView = hostingView
        settingsWindow?.title = "VibeFlow - Configurações"
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
    
    var analyticsWindow: NSWindow?
    
    @objc func showAnalytics() {
        if let existingWindow = analyticsWindow, existingWindow.isVisible {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let analyticsView = AnalyticsView()
        let hostingView = NSHostingView(rootView: analyticsView)
        
        analyticsWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 550),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        analyticsWindow?.contentView = hostingView
        analyticsWindow?.title = "VibeFlow - Estatísticas"
        analyticsWindow?.center()
        analyticsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    // MARK: - Global Shortcuts
    
    var localKeyDownMonitor: Any?
    
    func setupGlobalShortcuts() {
        // Cmd+Shift+V - Toggle window (global)
        globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleGlobalKeyEvent(event)
        }
        
        // Local key monitor (works when app is active)
        localKeyDownMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleGlobalKeyEvent(event)
            return event
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
    
    func handleGlobalKeyEvent(_ event: NSEvent) {
        let modifiers = event.modifierFlags
        let keyCode = event.keyCode
        
        // Debug logging
        // print("[KeyEvent] modifiers: \(modifiers.rawValue), keyCode: \(keyCode)")
        
        // Cmd+Shift+V (keyCode 9 = v)
        if modifiers.contains([.command, .shift]) && keyCode == 9 {
            DispatchQueue.main.async { [weak self] in
                self?.toggleWindow()
            }
            return
        }
        
        // Control+Option+L (keyCode 37 = l)
        // Note: Check for control + option specifically
        let hasControl = modifiers.contains(.control)
        let hasOption = modifiers.contains(.option)
        let isLKey = (keyCode == 37) || (keyCode == 32) // 37 = L, 32 might be L on some layouts
        
        if hasControl && hasOption && isLKey {
            DispatchQueue.main.async { [weak self] in
                print("[VibeFlow] Language shortcut detected")
                self?.cycleLanguage()
            }
            return
        }
    }
    
    @objc func cycleLanguage() {
        // Debounce rapid key presses
        let now = Date()
        guard now.timeIntervalSince(lastLanguageCycleTime) >= languageCycleDebounceInterval else {
            print("[VibeFlow] Language cycle debounced")
            return
        }
        lastLanguageCycleTime = now

        let previousLanguage = settings.outputLanguage
        settings.cycleToNextLanguage()
        let newLanguage = settings.outputLanguage

        // Play feedback sound
        sounds.playSuccess()

        // Show notification
        showLanguageNotification(language: newLanguage)

        // Update menu to reflect change
        updateMenu()

        print("[VibeFlow] Language changed: \(previousLanguage.displayName) → \(newLanguage.displayName)")
    }
    
    func showLanguageNotification(language: SpeechLanguage) {
        // Close existing notification window if present
        languageNotificationWindow?.orderOut(nil)
        languageNotificationWindow = nil

        // Create notification window (retained as property)
        let notificationWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 180, height: 60),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        let contentView = LanguageNotificationView(language: language)
        notificationWindow.contentView = NSHostingView(rootView: contentView)
        notificationWindow.level = .floating
        notificationWindow.backgroundColor = .clear
        notificationWindow.isOpaque = false
        notificationWindow.hasShadow = true
        notificationWindow.isReleasedWhenClosed = false

        // Position near the main window or centered
        if let window = window, window.isVisible {
            let windowFrame = window.frame
            let x = windowFrame.midX - 90
            let y = windowFrame.maxY + 20
            notificationWindow.setFrameOrigin(NSPoint(x: x, y: y))
        } else {
            notificationWindow.center()
        }

        // Retain the window
        self.languageNotificationWindow = notificationWindow
        notificationWindow.makeKeyAndOrderFront(nil)

        // Auto-close after 1.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.languageNotificationWindow?.orderOut(nil)
            self?.languageNotificationWindow = nil
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
        
        // Observar ativação de licença para mostrar wizard
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLicenseActivated),
            name: .showWizardAfterActivation,
            object: nil
        )
        
        // Observar mudanças de idioma para atualizar menu
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateMenu),
            name: .languageChanged,
            object: nil
        )
    }
    
    @objc func handleRecordingCancelled() {
        // Fechar janela se não houve fala
        DispatchQueue.main.async { [weak self] in
            self?.window?.orderOut(nil)
        }
    }
    
    @objc func handleLicenseActivated() {
        // Mostrar wizard após ativação da licença
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.checkFirstLaunch()
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
        if let monitor = localKeyDownMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
