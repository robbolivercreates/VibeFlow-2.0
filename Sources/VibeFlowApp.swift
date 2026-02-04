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
    var mainAppWindow: NSWindow?  // New main window with sidebar navigation
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

        // Window size: max expanded width (460) + padding, height for compact overlay
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 100),
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
        window?.hasShadow = false // Clean look, no window shadow
        window?.ignoresMouseEvents = false
        centerWindow()
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
        // Verificar onboarding (pular license)
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
            contentRect: NSRect(x: 0, y: 0, width: 680, height: 580),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        wizardWindow?.contentView = hostingView
        wizardWindow?.title = "Configurar VibeFlow"
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

        // Microphone selection submenu
        let micMenu = NSMenu()
        if let recorder = viewModel?.audioRecorder {
            recorder.refreshDevices()
            let devices = recorder.availableDevices
            let currentDevice = recorder.currentDevice

            if devices.isEmpty {
                let noMicItem = NSMenuItem(title: "Nenhum microfone encontrado", action: nil, keyEquivalent: "")
                noMicItem.isEnabled = false
                micMenu.addItem(noMicItem)
            } else {
                for device in devices {
                    let item = NSMenuItem(
                        title: device.name + (device.isDefault ? " (Padrão)" : ""),
                        action: #selector(selectMicrophone(_:)),
                        keyEquivalent: ""
                    )
                    item.target = self
                    item.representedObject = device
                    if device.id == currentDevice?.id {
                        item.state = .on
                    }
                    micMenu.addItem(item)
                }
            }
        }
        let micItem = NSMenuItem(title: "Microfone", action: nil, keyEquivalent: "")
        micItem.submenu = micMenu
        menu.addItem(micItem)

        menu.addItem(NSMenuItem.separator())

        // Main Window (VibeFlow Central)
        let mainWindowItem = NSMenuItem(title: "Abrir VibeFlow", action: #selector(showMainWindow), keyEquivalent: "")
        mainWindowItem.target = self
        menu.addItem(mainWindowItem)

        menu.addItem(NSMenuItem.separator())

        // Quick access items
        menu.addItem(NSMenuItem(title: "Historico", action: #selector(showHistory), keyEquivalent: "y"))
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
    
    @objc func selectLanguage(_ sender: NSMenuItem) {
        guard let language = sender.representedObject as? SpeechLanguage else { return }
        settings.outputLanguage = language
        updateMenu()
    }

    @objc func selectMicrophone(_ sender: NSMenuItem) {
        guard let device = sender.representedObject as? AudioInputDevice else { return }
        viewModel?.audioRecorder.selectDevice(device)
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
            // Center horizontally
            let x = screenRect.midX - windowRect.width / 2
            // Position in lower portion of screen (25% from bottom)
            let y = screenRect.minY + (screenRect.height * 0.25)
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }
    }
    
    // MARK: - Settings
    
    @objc func showSettings() {
        showMainWindow()
    }

    @objc func showMainWindow() {
        if let existingWindow = mainAppWindow, existingWindow.isVisible {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        // Close existing window if present
        mainAppWindow?.close()

        let mainView = MainWindowView()
        let hostingView = NSHostingView(rootView: mainView)

        mainAppWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        mainAppWindow?.contentView = hostingView
        mainAppWindow?.title = "VibeFlow"
        mainAppWindow?.minSize = NSSize(width: 720, height: 520)
        mainAppWindow?.center()
        mainAppWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: mainAppWindow,
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

        // Get key character
        let keyChar = keyCodeToChar(keyCode)

        // Debug logging (uncomment to debug)
        // print("[KeyEvent] modifiers: \(modifiers.rawValue), keyCode: \(keyCode), char: \(keyChar)")

        // Toggle window shortcut (default: ⌘⇧V)
        if matchesShortcut(settings.shortcutToggleKey, modifiers: modifiers, keyChar: keyChar) {
            DispatchQueue.main.async { [weak self] in
                self?.toggleWindow()
            }
            return
        }

        // Language cycle shortcut (default: ⌃⌥L)
        if matchesShortcut(settings.cycleLanguageShortcut, modifiers: modifiers, keyChar: keyChar) {
            DispatchQueue.main.async { [weak self] in
                print("[VibeFlow] Language shortcut detected")
                self?.cycleLanguage()
            }
            return
        }
    }

    /// Convert key code to character
    private func keyCodeToChar(_ keyCode: UInt16) -> String {
        let keyMap: [UInt16: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
            8: "C", 9: "V", 10: "B", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
            16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6", 23: "5",
            24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0", 30: "]", 31: "O",
            32: "U", 33: "[", 34: "I", 35: "P", 37: "L", 38: "J", 39: "'", 40: "K",
            41: ";", 42: "\\", 43: ",", 44: "/", 45: "N", 46: "M", 47: "."
        ]
        return keyMap[keyCode] ?? ""
    }

    /// Check if event matches shortcut string
    private func matchesShortcut(_ shortcut: String, modifiers: NSEvent.ModifierFlags, keyChar: String) -> Bool {
        // Parse expected modifiers from shortcut string
        let expectControl = shortcut.contains("⌃")
        let expectOption = shortcut.contains("⌥")
        let expectShift = shortcut.contains("⇧")
        let expectCommand = shortcut.contains("⌘")

        // Check modifiers match
        let hasControl = modifiers.contains(.control)
        let hasOption = modifiers.contains(.option)
        let hasShift = modifiers.contains(.shift)
        let hasCommand = modifiers.contains(.command)

        guard expectControl == hasControl,
              expectOption == hasOption,
              expectShift == hasShift,
              expectCommand == hasCommand else {
            return false
        }

        // Extract key from shortcut (last character that's not a modifier)
        let modifierChars = Set(["⌃", "⌥", "⇧", "⌘"])
        let expectedKey = shortcut.filter { !modifierChars.contains(String($0)) }.uppercased()

        return keyChar.uppercased() == expectedKey
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
        // Parse the record shortcut to get required modifiers
        let recordShortcut = settings.shortcutRecordKey
        let requireControl = recordShortcut.contains("⌃")
        let requireOption = recordShortcut.contains("⌥")
        let requireShift = recordShortcut.contains("⇧")
        let requireCommand = recordShortcut.contains("⌘")

        // Check if required modifiers are pressed
        let hasControl = event.modifierFlags.contains(.control)
        let hasOption = event.modifierFlags.contains(.option)
        let hasShift = event.modifierFlags.contains(.shift)
        let hasCommand = event.modifierFlags.contains(.command)

        let shortcutPressed = (requireControl == hasControl) &&
                              (requireOption == hasOption) &&
                              (requireShift == hasShift) &&
                              (requireCommand == hasCommand) &&
                              (requireControl || requireOption || requireShift || requireCommand)

        if shortcutPressed && !isHoldToTalkActive {
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
            
        } else if !shortcutPressed && isHoldToTalkActive {
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

        // Observar pedido para mostrar historico (from HomeView)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(showHistory),
            name: NSNotification.Name("showHistory"),
            object: nil
        )

        // Observar pedido para abrir Setup Wizard (from Settings)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(resetAndShowWizard),
            name: .openSetupWizard,
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

        // Fechar janela automaticamente se habilitado
        if settings.enableAutoClose {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.window?.orderOut(nil)
            }
        }
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
