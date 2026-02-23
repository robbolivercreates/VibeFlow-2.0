import SwiftUI
import AppKit
import Combine

// Entry point is main.swift — using AppKit lifecycle directly
// (SwiftUI @main lifecycle was causing NSStatusItem to not appear)

class AppDelegate: NSObject, NSApplicationDelegate {
    static var shared: AppDelegate?
    static var statusItem: NSStatusItem?
    var window: NSWindow?
    var settingsWindow: NSWindow?
    var mainAppWindow: NSWindow?  // New main window with sidebar navigation
    var historyWindow: NSWindow?
    var snippetsWindow: NSWindow?
    var wizardWindow: NSWindow?
    var loginOnboardingWindow: NSWindow?
    var viewModel: VoxAiGoViewModel?
    var isHoldToTalkActive = false
    var isWizardActive = false
    var globalKeyMonitor: Any?
    var localKeyMonitor: Any?
    var localKeyDownMonitor: Any?

    // CGEvent tap for reliable global keyboard shortcut detection
    var globalKeyTap: CFMachPort?
    var accessibilityRetryTimer: Timer?

    // Conversation Reply HUD (retained, interactive, stays until dismissed or timeout)
    var conversationReplyWindow: NSWindow?
    var lastConversationReplyTime: Date = .distantPast
    let conversationReplyDebounceInterval: TimeInterval = 0.5

    // Notification windows (retained to prevent memory issues)
    var languageNotificationWindow: NSWindow?
    var modeNotificationWindow: NSWindow?
    var pasteLastNotificationWindow: NSWindow?
    var wakeWordNotificationWindow: NSWindow?
    var lastLanguageCycleTime: Date = .distantPast
    var lastModeCycleTime: Date = .distantPast
    var lastPasteLastTime: Date = .distantPast
    let languageCycleDebounceInterval: TimeInterval = 0.3 // 300ms debounce
    let modeCycleDebounceInterval: TimeInterval = 0.3
    let pasteLastDebounceInterval: TimeInterval = 0.5
    
    // Managers
    let settings = SettingsManager.shared
    let sounds = SoundManager.shared
    let history = HistoryManager.shared
    let snippets = SnippetsManager.shared
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self

        // Force dark mode globally — ensures all system controls match the matte black theme
        NSApp.appearance = NSAppearance(named: .darkAqua)

        // Create status item in .regular policy (ONLY mode where it works).
        // .accessory mode and LSUIElement both move status items off-screen on this system.
        AppDelegate.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = AppDelegate.statusItem?.button {
            if let sfImage = NSImage(systemSymbolName: "waveform", accessibilityDescription: "VoxAiGo") {
                let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .medium)
                button.image = sfImage.withSymbolConfiguration(config) ?? sfImage
            } else {
                button.image = AppIconGenerator.createMenuBarIcon()
            }
            button.action = #selector(toggleWindow)
            button.target = self
        }
        
        // Hide dock icon: switch to .accessory AFTER status item is created
        // (creating status item in .regular ensures it appears on-screen correctly)
        DispatchQueue.main.async {
            NSApp.setActivationPolicy(.accessory)
        }
        
        // Criar view model
        let viewModel = VoxAiGoViewModel()
        self.viewModel = viewModel

        // Initialize WhisperEngine in background (loads model for offline transcription)
        Task {
            await WhisperEngine.shared.setup()
        }

        // Update menu after viewModel is created
        updateMenu()
        
        // Criar janela flutuante
        let contentView = ContentView()
            .environmentObject(viewModel)

        // NSPanel + nonactivatingPanel: floats above maximized/fullscreen apps without stealing focus
        window = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 100),
            styleMask: [.borderless, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        window?.contentView = NSHostingView(rootView: contentView)
        window?.isReleasedWhenClosed = false
        window?.level = .screenSaver  // Above everything including maximized apps
        window?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window?.backgroundColor = .clear
        window?.isOpaque = false
        window?.hasShadow = false // Clean look, no window shadow
        window?.ignoresMouseEvents = false
        (window as? NSPanel)?.hidesOnDeactivate = false  // Stay visible when app loses focus
        centerWindow()
        window?.orderOut(nil)
        
        // Configurar atalhos globais
        setupGlobalShortcuts()
        
        // Observar mudanças
        setupObservers()
        
        // Mostrar wizard ou ativação se necessário
        // Delay reduzido: 0.3s suficiente para app inicializar sem deixar menu acessível
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.checkFirstLaunch()
        }

        // Check if trial just expired → show downgrade message once
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.checkTrialExpiredOnLaunch()
        }
    }
    
    // MARK: - URL Scheme Handler (OAuth callback)

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            if url.scheme == "voxaigo" {
                AuthManager.shared.handleOAuthCallback(url: url)
            }
        }
    }

    /// Creates and configures the menu bar status item
    private func createStatusBarItem() {
        let diag = "/tmp/voxaigo_diag.txt"
        var log = "[\(Date())] createStatusBarItem called\n"
        
        AppDelegate.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        log += "statusItem created: \(AppDelegate.statusItem != nil)\n"
        
        if let button = AppDelegate.statusItem?.button {
            // Use SF Symbol instead of custom drawing to test visibility
            if let sfImage = NSImage(systemSymbolName: "waveform", accessibilityDescription: "VoxAiGo") {
                let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .medium)
                let configured = sfImage.withSymbolConfiguration(config) ?? sfImage
                button.image = configured
                log += "SF Symbol set, image size: \(configured.size)\n"
            } else {
                // Fallback: use title text if SF Symbol not available
                button.title = "🎵"
                log += "SF Symbol unavailable, using emoji title\n"
            }
            button.action = #selector(toggleWindow)
            button.target = self
            log += "button configured\n"
        } else {
            log += "ERROR: button is nil\n"
        }
        
        // Assign the menu
        updateMenu()
        
        log += "menu assigned: \(AppDelegate.statusItem?.menu != nil)\n"
        log += "button visible: \(AppDelegate.statusItem?.button?.window != nil)\n"
        log += "isVisible: \(AppDelegate.statusItem?.isVisible ?? false)\n"
        log += "button window frame: \(AppDelegate.statusItem?.button?.window?.frame ?? .zero)\n"
        try? log.write(toFile: diag, atomically: true, encoding: .utf8)
        
        // Safety check: verify status item is still alive after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            var check = "\n[\(Date())] 3s check:\n"
            check += "statusItem still exists: \(AppDelegate.statusItem != nil)\n"
            check += "button exists: \(AppDelegate.statusItem?.button != nil)\n"
            check += "button window: \(AppDelegate.statusItem?.button?.window != nil)\n"
            check += "button window frame: \(AppDelegate.statusItem?.button?.window?.frame ?? .zero)\n"
            check += "isVisible: \(AppDelegate.statusItem?.isVisible ?? false)\n"
            check += "delegate alive: \(AppDelegate.shared != nil)\n"
            check += "button title: \(AppDelegate.statusItem?.button?.title ?? "nil")\n"
            check += "button image: \(AppDelegate.statusItem?.button?.image?.size ?? .zero)\n"
            if let existing = try? String(contentsOfFile: diag, encoding: .utf8) {
                try? (existing + check).write(toFile: diag, atomically: true, encoding: .utf8)
            }
        }
    }
    
    // MARK: - First Launch
    
    func checkFirstLaunch() {
        if !AuthManager.shared.isAuthenticated {
            // Not logged in: show blocking login window first
            showLoginOnboarding()
        } else if !settings.onboardingCompleted {
            // Already authenticated (returning user after reinstall) — skip wizard.
            // onboardingCompleted resets with UserDefaults on fresh install, but if
            // the user is already logged in they've already been onboarded before.
            // Wizard is only shown to new users via showLoginOnboarding() callback.
            settings.onboardingCompleted = true
        }
        // else: normal launch — everything is set up
    }

    func showLoginOnboarding() {
        loginOnboardingWindow?.close()
        loginOnboardingWindow = nil

        let loginView = LoginOnboardingWrapper {
            DispatchQueue.main.async { [weak self] in
                self?.loginOnboardingWindow?.close()
                self?.loginOnboardingWindow = nil
                if !(self?.settings.onboardingCompleted ?? true) {
                    self?.showWizard()
                }
            }
        }

        let win = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 580),
            styleMask: [.titled, .miniaturizable],  // NO .closable — login is required
            backing: .buffered,
            defer: false
        )
        win.isReleasedWhenClosed = false
        win.contentView = NSHostingView(rootView: loginView)
        win.title = "Bem-vindo ao VoxAiGo"
        win.collectionBehavior = [.moveToActiveSpace]
        win.center()
        loginOnboardingWindow = win
        win.makeKeyAndOrderFront(nil)
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
            contentRect: NSRect(x: 0, y: 0, width: 680, height: 580),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        wizardWindow?.isReleasedWhenClosed = false
        wizardWindow?.contentView = hostingView
        wizardWindow?.title = "Configurar VoxAiGo"
        wizardWindow?.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        wizardWindow?.center()
        wizardWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        isWizardActive = true
        
        // Observar fechamento
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: wizardWindow,
            queue: .main
        ) { [weak self] _ in
            self?.isWizardActive = false
            self?.viewModel?.reloadSettings()
        }
    }
    
    // MARK: - Menu
    
    @objc func showLoginOnboardingFromMenu() {
        showLoginOnboarding()
    }

    @objc func updateMenu() {
        let menu = NSMenu()

        // Título
        let titleItem = NSMenuItem(title: "VoxAiGo \(AppVersion.current)", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)

        // Offline indicator
        if settings.offlineMode {
            let offlineItem = NSMenuItem(title: "✈️ Modo Offline — transcrição simplificada", action: nil, keyEquivalent: "")
            offlineItem.isEnabled = false
            menu.addItem(offlineItem)
        }

        // Se não autenticado: menu mínimo — apenas Login e Sair
        if !AuthManager.shared.isAuthenticated {
            menu.addItem(NSMenuItem.separator())
            let loginItem = NSMenuItem(title: "Fazer Login...", action: #selector(showLoginOnboardingFromMenu), keyEquivalent: "")
            loginItem.target = self
            menu.addItem(loginItem)
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: L10n.quit, action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
            AppDelegate.statusItem?.menu = menu
            return
        }

        // Account info + plan status indicator
        if AuthManager.shared.isAuthenticated {
            let sub = SubscriptionManager.shared
            let trial = TrialManager.shared
            let email = AuthManager.shared.userEmail ?? ""

            let planLabel: String
            if sub.isPro {
                // Pro: no usage indicator — just the email
                planLabel = ""
            } else if trial.isTrialActive() {
                let days = trial.trialDaysRemaining
                let used = trial.trialTranscriptionsUsed
                planLabel = " — Pro Trial: \(days)d (\(used)/50)"
            } else if sub.hasReachedWhisperLimit {
                planLabel = " — Grátis: limite atingido"
            } else {
                planLabel = " — Grátis: \(sub.whisperTranscriptionsUsed)/\(SubscriptionManager.whisperMonthlyLimit)"
            }

            let accountItem = NSMenuItem(title: "\(email)\(planLabel)", action: nil, keyEquivalent: "")
            accountItem.isEnabled = false
            menu.addItem(accountItem)
        }

        menu.addItem(NSMenuItem.separator())
        
        // Ações principais
        menu.addItem(NSMenuItem(title: L10n.showHide, action: #selector(toggleWindow), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        
        // Modos
        let isFreeTier = !SubscriptionManager.shared.isPro && !TrialManager.shared.isTrialActive()
        let modesMenu = NSMenu()
        for mode in TranscriptionMode.allCases {
            let isProMode = !SubscriptionManager.freeModes.contains(mode)
            let isLocked = isFreeTier && isProMode
            let title = isLocked ? "◆ \(mode.localizedName)" : mode.localizedName
            let action = isLocked ? #selector(showUpgradeForMode(_:)) : #selector(selectMode(_:))
            let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
            item.target = self
            item.representedObject = mode
            if settings.selectedMode == mode {
                item.state = .on
            }
            if isLocked {
                // Dim the title to signal it's unavailable
                let attrs: [NSAttributedString.Key: Any] = [
                    .foregroundColor: NSColor.secondaryLabelColor,
                    .font: NSFont.systemFont(ofSize: 13)
                ]
                item.attributedTitle = NSAttributedString(string: title, attributes: attrs)
            }
            modesMenu.addItem(item)
        }
        modesMenu.addItem(NSMenuItem.separator())
        let cycleModeItem = NSMenuItem(
            title: "Próximo (⌃⇧M)",
            action: #selector(cycleMode),
            keyEquivalent: ""
        )
        cycleModeItem.target = self
        modesMenu.addItem(cycleModeItem)
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
                let isProLang = !SubscriptionManager.freeLanguages.contains(language)
                let isLockedLang = isFreeTier && isProLang
                let langTitle = isLockedLang ? "🔒 \(language.displayWithFlag)" : language.displayWithFlag
                let langAction = isLockedLang ? #selector(showUpgradeForLanguage(_:)) : #selector(selectLanguage(_:))
                let item = NSMenuItem(
                    title: langTitle,
                    action: langAction,
                    keyEquivalent: ""
                )
                item.target = self
                item.representedObject = language
                if settings.outputLanguage == language {
                    item.state = .on
                }
                if isLockedLang {
                    let attrs: [NSAttributedString.Key: Any] = [
                        .foregroundColor: NSColor.secondaryLabelColor,
                        .font: NSFont.systemFont(ofSize: 13)
                    ]
                    item.attributedTitle = NSAttributedString(string: langTitle, attributes: attrs)
                }
                langMenu.addItem(item)
            }
            langMenu.addItem(NSMenuItem.separator())
            let cycleItem = NSMenuItem(
                title: "Próximo (⌃⇧L)",
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
                title: "Mudar Idioma (⌃⇧L)",
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

        // Main Window (VoxAiGo Central)
        let mainWindowItem = NSMenuItem(title: "Abrir VoxAiGo", action: #selector(showMainWindow), keyEquivalent: "")
        mainWindowItem.target = self
        menu.addItem(mainWindowItem)

        menu.addItem(NSMenuItem.separator())

        // Offline toggle: show when Pro, dev mode, OR when offline is already active
        // (must always be able to turn it OFF regardless of plan state)
        if SubscriptionManager.shared.isPro || SubscriptionManager.shared.devModeActive || settings.offlineMode {
            let offlineToggle = NSMenuItem(
                title: settings.offlineMode ? "✈️ Modo Offline (ativo)" : "Modo Offline",
                action: #selector(toggleOfflineMode),
                keyEquivalent: ""
            )
            offlineToggle.target = self
            offlineToggle.state = settings.offlineMode ? .on : .off
            menu.addItem(offlineToggle)
            menu.addItem(NSMenuItem.separator())
        }

        // Quick access items
        menu.addItem(NSMenuItem(title: "Historico", action: #selector(showHistory), keyEquivalent: "y"))
        menu.addItem(NSMenuItem(title: "Snippets", action: #selector(showSnippets), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Estatísticas", action: #selector(openDashboard), keyEquivalent: ""))
        let pasteLastItem = NSMenuItem(
            title: "Colar Última Transcrição (⌃⇧V)",
            action: #selector(pasteLastTranscription),
            keyEquivalent: ""
        )
        pasteLastItem.target = self
        menu.addItem(pasteLastItem)
        menu.addItem(NSMenuItem.separator())

        // Settings & Support
        menu.addItem(NSMenuItem(title: L10n.settings, action: #selector(showSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "Suporte", action: #selector(openSupport), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: L10n.quit, action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        AppDelegate.statusItem?.menu = menu
    }
    
    @objc func selectMode(_ sender: NSMenuItem) {
        guard let mode = sender.representedObject as? TranscriptionMode else { return }
        let isFreeTier = !SubscriptionManager.shared.isPro && !TrialManager.shared.isTrialActive()
        if isFreeTier && !SubscriptionManager.freeModes.contains(mode) {
            showContextualUpgrade(context: .mode(mode))
            return
        }
        settings.selectedMode = mode
        viewModel?.updateMode(mode)
        updateMenu()
    }

    @objc func showUpgradeForMode(_ sender: NSMenuItem) {
        guard let mode = sender.representedObject as? TranscriptionMode else { return }
        showContextualUpgrade(context: .mode(mode))
    }

    @objc func showUpgradeForLanguage(_ sender: NSMenuItem) {
        guard let language = sender.representedObject as? SpeechLanguage else { return }
        showContextualUpgrade(context: .language(language))
    }
    
    @objc func selectLanguage(_ sender: NSMenuItem) {
        guard let language = sender.representedObject as? SpeechLanguage else { return }
        let isFreeTier = !SubscriptionManager.shared.isPro && !TrialManager.shared.isTrialActive()
        if isFreeTier && !SubscriptionManager.freeLanguages.contains(language) {
            showContextualUpgrade(context: .language(language))
            return
        }
        settings.outputLanguage = language
        updateMenu()
    }

    // MARK: - Contextual Upgrade Window

    /// Shows a floating upgrade modal for a specific Pro feature
    func showContextualUpgrade(context: UpgradeContext) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // Reuse existing window if present
            self.upgradeWindow?.close()
            self.upgradeWindow = nil

            var isPresented = true
            let binding = Binding(get: { isPresented }, set: { val in
                isPresented = val
                if !val {
                    self.upgradeWindow?.close()
                    self.upgradeWindow = nil
                }
            })

            let upgradeView = UpgradeModalView(isPresented: binding, context: context)
            let hostingView = NSHostingView(rootView: upgradeView)

            let window = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 420, height: 520),
                styleMask: [.titled, .closable, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            window.contentView = hostingView
            window.title = "Upgrade para Pro"
            window.isReleasedWhenClosed = false
            window.hidesOnDeactivate = false
            window.center()
            window.level = .screenSaver
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)

            self.upgradeWindow = window
        }
    }

    @objc func toggleOfflineMode() {
        settings.offlineMode.toggle()
        if settings.offlineMode {
            // Auto-switch to Text mode if current mode is Pro-only
            if !SubscriptionManager.freeModes.contains(settings.selectedMode) {
                settings.selectedMode = .text
                viewModel?.updateMode(.text)
            }
            // Immediately validate subscription when offline mode is enabled.
            // If internet is available, this catches any expiry before the first offline recording.
            Task { await SubscriptionManager.shared.fetchProfile() }
        }
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
        // Block access to main window if not authenticated
        guard AuthManager.shared.isAuthenticated else {
            showLoginOnboarding()
            return
        }

        // If window exists, just show it
        if let existingWindow = mainAppWindow {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        // Create new window
        let mainView = MainWindowView()
        let hostingView = NSHostingView(rootView: mainView)

        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        newWindow.contentView = hostingView
        newWindow.title = "VoxAiGo"
        newWindow.minSize = NSSize(width: 720, height: 520)
        newWindow.isReleasedWhenClosed = false
        newWindow.center()
        mainAppWindow = newWindow

        // Observe close to clean up reference (prevents crash and reappear)
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: newWindow,
            queue: .main
        ) { [weak self] notification in
            self?.viewModel?.reloadSettings()
            self?.mainAppWindow = nil
        }

        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    // MARK: - History
    
    @objc func showHistory() {
        if let existingWindow = historyWindow {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let historyView = HistoryView()
        let hostingView = NSHostingView(rootView: historyView)

        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 500),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        newWindow.contentView = hostingView
        newWindow.title = "VoxAiGo - Histórico"
        newWindow.isReleasedWhenClosed = false
        newWindow.center()
        historyWindow = newWindow

        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: newWindow,
            queue: .main
        ) { [weak self] _ in
            self?.historyWindow = nil
        }

        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Snippets

    @objc func showSnippets() {
        if let existingWindow = snippetsWindow {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let snippetsView = SnippetsView()
        let hostingView = NSHostingView(rootView: snippetsView)

        let newWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 450),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        newWindow.contentView = hostingView
        newWindow.title = "VoxAiGo - Snippets"
        newWindow.isReleasedWhenClosed = false
        newWindow.center()
        snippetsWindow = newWindow

        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: newWindow,
            queue: .main
        ) { [weak self] _ in
            self?.snippetsWindow = nil
        }

        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func openDashboard() {
        if let url = URL(string: "https://www.voxaigo.com/dashboard") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc func openSupport() {
        if let url = URL(string: "https://www.voxaigo.com/suporte") {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Global Shortcuts
    
    
    func setupGlobalShortcuts() {
        // Check Accessibility permissions and prompt if needed
        checkAccessibilityPermission()

        // Global key event tap for keyboard shortcuts (CGEvent tap is more reliable
        // than NSEvent.addGlobalMonitorForEvents for .keyDown in accessory apps)
        setupGlobalKeyTap()

        // Hold-to-Talk: Option + Command (flagsChanged monitors)
        NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            guard let self = self else { return }
            self.handleFlagsChanged(event)
        }

        // Local flagsChanged monitor (when app is active)
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            guard let self = self else { return event }
            self.handleFlagsChanged(event)
            return event
        }

        // Local keyDown monitor (shortcuts work when VoxAiGo window is active)
        // Returns nil for matched shortcuts to consume the event and prevent macOS "bonk" sound
        localKeyDownMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }
            if self.localKeyEventMatchesShortcut(event) {
                self.handleGlobalKeyEvent(event)
                return nil  // Consume event — prevents macOS error sound
            }
            self.handleGlobalKeyEvent(event)
            return event
        }
    }

    /// Checks if Accessibility permission is granted and prompts user if not.
    /// Also starts a retry timer to recreate CGEvent tap once permission is granted.
    private func checkAccessibilityPermission() {
        var diag = "[VoxAiGo \(Date())] checkAccessibilityPermission\n"
        
        let trusted = AXIsProcessTrusted()
        diag += "  AXIsProcessTrusted = \(trusted)\n"
        
        if !trusted {
            // Don't prompt user here — let the Setup Wizard guide them
            diag += "  Accessibility not granted (wizard will guide user)\n"
            
            // Start periodic retry — once permission is granted, recreate the tap
            accessibilityRetryTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] timer in
                if AXIsProcessTrusted() {
                    let msg = "[VoxAiGo \(Date())] Accessibility permission granted via retry! Setting up tap...\n"
                    self?.appendDiag(msg)
                    timer.invalidate()
                    self?.accessibilityRetryTimer = nil
                    self?.setupGlobalKeyTap()
                }
            }
        }
        
        appendDiag(diag)
    }
    
    /// Append diagnostic message to /tmp/vf_shortcuts.txt
    private func appendDiag(_ message: String) {
        let path = "/tmp/vf_shortcuts.txt"
        if let handle = FileHandle(forWritingAtPath: path) {
            handle.seekToEndOfFile()
            handle.write(message.data(using: .utf8)!)
            handle.closeFile()
        } else {
            try? message.write(toFile: path, atomically: true, encoding: .utf8)
        }
    }

    /// Sets up a CGEvent tap for global keyboard shortcut detection.
    /// CGEvent taps work at a lower level than NSEvent monitors and reliably
    /// detect key presses even when the app is a background accessory app.
    func setupGlobalKeyTap() {
        var diag = "[VoxAiGo \(Date())] setupGlobalKeyTap\n"
        diag += "  AXIsProcessTrusted = \(AXIsProcessTrusted())\n"
        
        // If we already have a working tap, skip
        if let existingTap = globalKeyTap {
            let enabled = CGEvent.tapIsEnabled(tap: existingTap)
            diag += "  Already have CGEvent tap, enabled=\(enabled), skipping\n"
            appendDiag(diag)
            return
        }
        
        let eventMask = CGEventMask(1 << CGEventType.keyDown.rawValue)

        let refcon = Unmanaged.passUnretained(self).toOpaque()
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: eventMask,
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else { return Unmanaged.passUnretained(event) }
                let appDelegate = Unmanaged<AppDelegate>.fromOpaque(refcon).takeUnretainedValue()

                if type == .keyDown {
                    let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
                    let flags = event.flags
                    appDelegate.handleCGKeyEvent(keyCode: keyCode, flags: flags)
                }

                // Re-enable tap if macOS disables it (e.g., callback took too long)
                if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                    if let tap = appDelegate.globalKeyTap {
                        CGEvent.tapEnable(tap: tap, enable: true)
                        appDelegate.appendDiag("[VoxAiGo \(Date())] Re-enabled tap after system disabled it\n")
                    }
                }

                return Unmanaged.passUnretained(event)
            },
            userInfo: refcon
        ) else {
            diag += "  ❌ CGEvent.tapCreate FAILED\n"
            diag += "  Falling back to NSEvent global keyDown monitor\n"
            appendDiag(diag)
            
            // Fallback: use NSEvent global monitor
            if globalKeyMonitor == nil {
                globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
                    self?.handleGlobalKeyEvent(event)
                }
            }
            return
        }

        // Remove fallback global monitor if tap succeeded (avoid duplicate handling)
        if let monitor = globalKeyMonitor {
            NSEvent.removeMonitor(monitor)
            globalKeyMonitor = nil
        }

        // Stop retry timer if it's running
        accessibilityRetryTimer?.invalidate()
        accessibilityRetryTimer = nil

        self.globalKeyTap = tap
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        
        diag += "  ✅ CGEvent tap CREATED and ENABLED successfully!\n"
        diag += "  Tap is enabled: \(CGEvent.tapIsEnabled(tap: tap))\n"
        appendDiag(diag)
    }

    /// Handle key events from the CGEvent tap (works globally)
    func handleCGKeyEvent(keyCode: UInt16, flags: CGEventFlags) {
        // Yield to ShortcutEditor when it is actively capturing a new key combo
        guard !ShortcutEditor.isCapturing else { return }

        let keyChar = keyCodeToChar(keyCode)

        // Convert CGEventFlags to NSEvent.ModifierFlags for matchesShortcut
        var modifiers = NSEvent.ModifierFlags()
        if flags.contains(.maskControl) { modifiers.insert(.control) }
        if flags.contains(.maskAlternate) { modifiers.insert(.option) }
        if flags.contains(.maskShift) { modifiers.insert(.shift) }
        if flags.contains(.maskCommand) { modifiers.insert(.command) }

        // Toggle window shortcut (default: ⌘⇧V)
        if matchesShortcut(settings.shortcutToggleKey, modifiers: modifiers, keyChar: keyChar) {
            DispatchQueue.main.async { [weak self] in
                self?.toggleWindow()
            }
            return
        }

        // Language cycle shortcut (default: ⌃⇧L)
        if matchesShortcut(settings.cycleLanguageShortcut, modifiers: modifiers, keyChar: keyChar) {
            DispatchQueue.main.async { [weak self] in
                self?.cycleLanguage()
            }
            return
        }

        // Mode cycle shortcut (default: ⌃⇧M)
        if matchesShortcut(settings.cycleModeShortcut, modifiers: modifiers, keyChar: keyChar) {
            DispatchQueue.main.async { [weak self] in
                self?.cycleMode()
            }
            return
        }

        // Paste last transcription shortcut (default: ⌃⇧V)
        if matchesShortcut(settings.pasteLastShortcut, modifiers: modifiers, keyChar: keyChar) {
            DispatchQueue.main.async { [weak self] in
                self?.pasteLastTranscription()
            }
            return
        }

        // Conversation Reply shortcut (default: ⌃⇧R)
        if matchesShortcut(settings.conversationReplyShortcut, modifiers: modifiers, keyChar: keyChar) {
            appendDiag("[VoxAiGo \(Date())] CGEvent matched conversation reply shortcut (\(settings.conversationReplyShortcut))\n")
            DispatchQueue.main.async { [weak self] in
                self?.activateConversationReply()
            }
            return
        }
    }

    func handleGlobalKeyEvent(_ event: NSEvent) {
        // Yield to ShortcutEditor when it is actively capturing a new key combo
        guard !ShortcutEditor.isCapturing else { return }

        // Strip device-dependent bits for reliable matching
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let keyCode = event.keyCode

        // Get key character from keyCode (layout-independent)
        let keyChar = keyCodeToChar(keyCode)

        // Debug logging
        print("[KeyEvent] keyCode: \(keyCode), char: '\(keyChar)', modifiers: ctrl=\(modifiers.contains(.control)) opt=\(modifiers.contains(.option)) shift=\(modifiers.contains(.shift)) cmd=\(modifiers.contains(.command))")

        // Toggle window shortcut (default: ⌘⇧V)
        if matchesShortcut(settings.shortcutToggleKey, modifiers: modifiers, keyChar: keyChar) {
            DispatchQueue.main.async { [weak self] in
                self?.toggleWindow()
            }
            return
        }

        // Language cycle shortcut (default: ⌃⇧L)
        if matchesShortcut(settings.cycleLanguageShortcut, modifiers: modifiers, keyChar: keyChar) {
            DispatchQueue.main.async { [weak self] in
                print("[VoxAiGo] Language shortcut detected!")
                self?.cycleLanguage()
            }
            return
        }

        // Mode cycle shortcut (default: ⌃⇧M)
        if matchesShortcut(settings.cycleModeShortcut, modifiers: modifiers, keyChar: keyChar) {
            DispatchQueue.main.async { [weak self] in
                self?.cycleMode()
            }
            return
        }

        // Paste last transcription shortcut (default: ⌃⇧V)
        if matchesShortcut(settings.pasteLastShortcut, modifiers: modifiers, keyChar: keyChar) {
            DispatchQueue.main.async { [weak self] in
                self?.pasteLastTranscription()
            }
            return
        }

        // Conversation Reply shortcut (default: ⌃⇧R)
        if matchesShortcut(settings.conversationReplyShortcut, modifiers: modifiers, keyChar: keyChar) {
            DispatchQueue.main.async { [weak self] in
                self?.activateConversationReply()
            }
            return
        }
    }

    /// Returns true if the NSEvent matches any of our registered shortcuts.
    /// Used by the local keyDown monitor to decide whether to consume the event.
    private func localKeyEventMatchesShortcut(_ event: NSEvent) -> Bool {
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let keyChar = keyCodeToChar(event.keyCode)

        let shortcuts = [
            settings.shortcutToggleKey,
            settings.cycleLanguageShortcut,
            settings.cycleModeShortcut,
            settings.pasteLastShortcut,
            settings.conversationReplyShortcut
        ]
        return shortcuts.contains { matchesShortcut($0, modifiers: modifiers, keyChar: keyChar) }
    }

    /// Convert key code to character (macOS virtual key codes, layout-independent)
    private func keyCodeToChar(_ keyCode: UInt16) -> String {
        let keyMap: [UInt16: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
            8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
            16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6", 23: "5",
            24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0", 30: "]", 31: "O",
            32: "U", 33: "[", 34: "I", 35: "P", 36: "RETURN", 37: "L", 38: "J",
            39: "'", 40: "K", 41: ";", 42: "\\", 43: ",", 44: "/", 45: "N", 46: "M",
            47: ".", 48: "TAB", 49: "SPACE", 50: "`", 51: "DELETE"
        ]
        return keyMap[keyCode] ?? ""
    }

    /// Check if event matches shortcut string like "⌃⇧L" or "⌘⇧V"
    private func matchesShortcut(_ shortcut: String, modifiers: NSEvent.ModifierFlags, keyChar: String) -> Bool {
        // Parse expected modifiers from shortcut string
        let expectControl = shortcut.contains("⌃")
        let expectOption = shortcut.contains("⌥")
        let expectShift = shortcut.contains("⇧")
        let expectCommand = shortcut.contains("⌘")

        // Check modifiers match (using already-masked flags)
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

        // Extract key letter from shortcut (everything that's not a modifier symbol)
        let modifierChars: Set<Character> = ["⌃", "⌥", "⇧", "⌘"]
        let expectedKey = String(shortcut.filter { !modifierChars.contains($0) }).uppercased()

        return !expectedKey.isEmpty && keyChar.uppercased() == expectedKey
    }
    
    @objc func cycleLanguage() {
        // Debounce rapid key presses
        let now = Date()
        guard now.timeIntervalSince(lastLanguageCycleTime) >= languageCycleDebounceInterval else {
            print("[VoxAiGo] Language cycle debounced")
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

        print("[VoxAiGo] Language changed: \(previousLanguage.displayName) → \(newLanguage.displayName)")
    }
    
    func showLanguageNotification(language: SpeechLanguage) {
        // Close existing notification window if present
        languageNotificationWindow?.orderOut(nil)
        languageNotificationWindow = nil

        let contentView = LanguageNotificationView(language: language)
        let notificationWindow = createHUDWindow(
            contentView: contentView,
            width: 260,
            height: 64
        )

        self.languageNotificationWindow = notificationWindow
        notificationWindow.orderFrontRegardless()

        // Auto-close with fade-out after 2 seconds
        // Capture the specific window instance to avoid race conditions with rapid switching
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self, weak notificationWindow] in
            guard let self = self, let window = notificationWindow else { return }
            // Only dismiss if this is still the current notification window
            if self.languageNotificationWindow === window {
                self.fadeOutAndClose(window: window) {
                    if self.languageNotificationWindow === window {
                        self.languageNotificationWindow = nil
                    }
                }
            } else {
                // This window was already replaced — force close it
                window.orderOut(nil)
            }
        }
    }

    func showWakeWordNotification(label: String, icon: String) {
        wakeWordNotificationWindow?.orderOut(nil)
        wakeWordNotificationWindow = nil

        // Audio feedback
        sounds.playSuccess()

        let contentView = WakeWordNotificationView(label: label, icon: icon)
        let notificationWindow = createHUDWindow(
            contentView: contentView,
            width: 280,
            height: 64
        )

        self.wakeWordNotificationWindow = notificationWindow
        notificationWindow.orderFrontRegardless()

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self, weak notificationWindow] in
            guard let self = self, let window = notificationWindow else { return }
            if self.wakeWordNotificationWindow === window {
                self.fadeOutAndClose(window: window) {
                    if self.wakeWordNotificationWindow === window {
                        self.wakeWordNotificationWindow = nil
                    }
                }
            } else {
                window.orderOut(nil)
            }
        }
    }

    @objc func cycleMode() {
        // Debounce rapid key presses
        let now = Date()
        guard now.timeIntervalSince(lastModeCycleTime) >= modeCycleDebounceInterval else {
            return
        }
        lastModeCycleTime = now

        let previousMode = settings.selectedMode
        settings.cycleToNextMode()
        let newMode = settings.selectedMode

        // Update ViewModel
        viewModel?.updateMode(newMode)

        // Play feedback sound
        sounds.playSuccess()

        // Show notification
        showModeNotification(mode: newMode)

        // Update menu to reflect change
        updateMenu()

        print("[VoxAiGo] Mode changed: \(previousMode.localizedName) → \(newMode.localizedName)")
    }

    func showModeNotification(mode: TranscriptionMode) {
        // Close existing notification window if present
        modeNotificationWindow?.orderOut(nil)
        modeNotificationWindow = nil

        let contentView = ModeNotificationView(mode: mode)
        let notificationWindow = createHUDWindow(
            contentView: contentView,
            width: 240,
            height: 64
        )

        self.modeNotificationWindow = notificationWindow
        notificationWindow.orderFrontRegardless()

        // Auto-close with fade-out after 2 seconds
        // Capture the specific window instance to avoid race conditions with rapid switching
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self, weak notificationWindow] in
            guard let self = self, let window = notificationWindow else { return }
            // Only dismiss if this is still the current notification window
            if self.modeNotificationWindow === window {
                self.fadeOutAndClose(window: window) {
                    if self.modeNotificationWindow === window {
                        self.modeNotificationWindow = nil
                    }
                }
            } else {
                // This window was already replaced — force close it
                window.orderOut(nil)
            }
        }
    }

    @objc func pasteLastTranscription() {
        // Debounce rapid key presses
        let now = Date()
        guard now.timeIntervalSince(lastPasteLastTime) >= pasteLastDebounceInterval else {
            print("[VoxAiGo] Paste last debounced")
            return
        }
        lastPasteLastTime = now

        // Get and paste the last item
        if let item = history.pasteLastItem() {
            // Play feedback sound
            sounds.playSuccess()

            // Show notification
            showPasteLastNotification(text: item.text, mode: item.mode)

            print("[VoxAiGo] Pasted last transcription: \(item.text.prefix(30))...")
        } else {
            // No history - show empty notification
            sounds.playError()
            showNoHistoryNotification()

            print("[VoxAiGo] No history to paste")
        }
    }

    func showPasteLastNotification(text: String, mode: TranscriptionMode) {
        // Close existing notification window if present
        pasteLastNotificationWindow?.orderOut(nil)
        pasteLastNotificationWindow = nil

        let contentView = PasteLastNotificationView(text: text, mode: mode)
        let notificationWindow = createHUDWindow(
            contentView: contentView,
            width: 280,
            height: 64
        )

        self.pasteLastNotificationWindow = notificationWindow
        notificationWindow.orderFrontRegardless()

        // Auto-close with fade-out after 2 seconds
        // Capture the specific window instance to avoid race conditions with rapid switching
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self, weak notificationWindow] in
            guard let self = self, let window = notificationWindow else { return }
            if self.pasteLastNotificationWindow === window {
                self.fadeOutAndClose(window: window) {
                    if self.pasteLastNotificationWindow === window {
                        self.pasteLastNotificationWindow = nil
                    }
                }
            } else {
                window.orderOut(nil)
            }
        }
    }

    func showNoHistoryNotification() {
        // Close existing notification window if present
        pasteLastNotificationWindow?.orderOut(nil)
        pasteLastNotificationWindow = nil

        let contentView = NoHistoryNotificationView()
        let notificationWindow = createHUDWindow(
            contentView: contentView,
            width: 260,
            height: 64
        )

        self.pasteLastNotificationWindow = notificationWindow
        notificationWindow.orderFrontRegardless()

        // Auto-close with fade-out after 2 seconds
        // Capture the specific window instance to avoid race conditions with rapid switching
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self, weak notificationWindow] in
            guard let self = self, let window = notificationWindow else { return }
            if self.pasteLastNotificationWindow === window {
                self.fadeOutAndClose(window: window) {
                    if self.pasteLastNotificationWindow === window {
                        self.pasteLastNotificationWindow = nil
                    }
                }
            } else {
                window.orderOut(nil)
            }
        }
    }

    // MARK: - HUD Window Helpers

    /// Creates a floating HUD notification panel, positioned at lower-center of screen.
    /// Uses NSPanel + nonactivatingPanel so it floats above maximized/fullscreen apps
    /// without stealing focus — the macOS-native approach for overlay HUDs.
    private func createHUDWindow<Content: View>(contentView: Content, width: CGFloat, height: CGFloat) -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.contentView = NSHostingView(rootView: contentView)
        panel.level = .screenSaver  // Above everything
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false  // Shadow handled by SwiftUI
        panel.isReleasedWhenClosed = false
        panel.ignoresMouseEvents = true  // Click-through
        panel.hidesOnDeactivate = false  // Stay visible when app loses focus
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

        // Position in lower portion of screen (25% from bottom) exactly like recording HUD
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - width / 2
            let y = screenFrame.minY + (screenFrame.height * 0.25)
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        return panel
    }

    /// Fade out a window then close it
    private func fadeOutAndClose(window: NSWindow?, completion: @escaping () -> Void) {
        guard let window = window else {
            completion()
            return
        }

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            window.animator().alphaValue = 0
        }, completionHandler: {
            window.orderOut(nil)
            window.alphaValue = 1  // Reset alpha for reuse
            completion()
        })
    }

    func handleFlagsChanged(_ event: NSEvent) {
        // Parse the record shortcut to get required modifiers
        let recordShortcut = settings.shortcutRecordKey
        let requireControl = recordShortcut.contains("⌃")
        let requireOption = recordShortcut.contains("⌥")
        let requireShift = recordShortcut.contains("⇧")
        let requireCommand = recordShortcut.contains("⌘")

        // Check if required modifiers are pressed (mask device-dependent bits)
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let hasControl = flags.contains(.control)
        let hasOption = flags.contains(.option)
        let hasShift = flags.contains(.shift)
        let hasCommand = flags.contains(.command)

        let shortcutPressed = (requireControl == hasControl) &&
                              (requireOption == hasOption) &&
                              (requireShift == hasShift) &&
                              (requireCommand == hasCommand) &&
                              (requireControl || requireOption || requireShift || requireCommand)

        if shortcutPressed && !isHoldToTalkActive {
            // Block recording if user is not authenticated (and no BYOK key)
            guard AuthManager.shared.isAuthenticated || settings.hasByokKey else {
                sounds.playError()
                DispatchQueue.main.async { [weak self] in
                    self?.showMainWindow()
                }
                return
            }

            // Iniciar gravação
            isHoldToTalkActive = true

            // ── Conversation Reply path ──────────────────────────────────
            // If the conversation HUD is showing and waiting for a reply,
            // intercept ⌥⌘ to record a translation reply instead of normal transcription.
            if case .ready = ConversationReplyManager.shared.state {
                sounds.playStart()
                ClipboardHelper.savePreviousApp()

                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    let targetLanguage = ConversationReplyManager.shared.detectedLanguageName

                    ConversationReplyManager.shared.beginRecordingReply()
                    self.resizeConversationWindow(forRecording: true)

                    // Start recording WITHOUT showing the normal floating window
                    self.viewModel?.isConversationReplyMode = true
                    self.viewModel?.conversationReplyTargetLanguage = targetLanguage
                    if !(self.viewModel?.isRecording ?? false) {
                        self.viewModel?.toggleRecording()
                    }
                }
                return
            }

            // ── Normal recording path ────────────────────────────────────
            // Som de início
            sounds.playStart()

            // Salvar app anterior
            ClipboardHelper.savePreviousApp()


            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }

                // NSPanel + nonactivatingPanel floats above maximized apps without stealing focus
                if !(self.window?.isVisible ?? false) {
                    self.centerWindow()
                    self.window?.orderFrontRegardless()
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

        // Atualizar menu quando auth muda (login/logout)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateMenu),
            name: .authStateChanged,
            object: nil
        )

        // Atualizar menu quando offline mode muda
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateMenu),
            name: .offlineModeChanged,
            object: nil
        )

        // Handle wake word commands (mode or language switch via voice)
        NotificationCenter.default.addObserver(
            forName: .wakeWordCommand,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let info = notification.userInfo,
                  let label = info["label"] as? String,
                  let icon = info["icon"] as? String else { return }
            self?.showWakeWordNotification(label: label, icon: icon)
        }

        // Mostrar login quando usuário faz logout
        NotificationCenter.default.addObserver(
            forName: .authStateChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            if !AuthManager.shared.isAuthenticated {
                // Close all active windows when logging out to prevent UI bugs or crashes
                self?.mainAppWindow?.close()
                self?.mainAppWindow = nil
                self?.settingsWindow?.close()
                self?.settingsWindow = nil
                self?.historyWindow?.close()
                self?.historyWindow = nil
                self?.snippetsWindow?.close()
                self?.snippetsWindow = nil
                self?.window?.orderOut(nil)
                
                self?.showLoginOnboarding()
            }
        }

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

        // Conversation Reply: dismiss HUD on timeout or explicit dismiss
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleConversationReplyTimedOut),
            name: .conversationReplyTimedOut,
            object: nil
        )

        // Show upgrade prompt when free limit is reached
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleShowUpgradePrompt),
            name: .showUpgradePrompt,
            object: nil
        )

        // Show welcome trial after signup
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleShowWelcomeTrial),
            name: .showWelcomeTrial,
            object: nil
        )

        // Show trial expired / downgrade message
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleShowTrialExpired),
            name: .showTrialExpired,
            object: nil
        )

        // Show monthly limit locked (200 Whisper exhausted)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleShowMonthlyLimit),
            name: .showMonthlyLimit,
            object: nil
        )

        // Show soft upgrade reminder (every 25 Whisper transcriptions)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleShowUpgradeReminder),
            name: .showUpgradeReminder,
            object: nil
        )
    }

    var upgradeWindow: NSWindow?

    @objc func handleShowUpgradePrompt() {
        showContextualUpgrade(context: .generic)
    }

    var welcomeTrialWindow: NSWindow?
    var trialExpiredWindow: NSWindow?
    var monthlyLimitWindow: NSWindow?

    @objc func handleShowWelcomeTrial() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.welcomeTrialWindow?.close()
            self.welcomeTrialWindow = nil

            var isPresented = true
            let binding = Binding(get: { isPresented }, set: { val in
                isPresented = val
                if !val {
                    self.welcomeTrialWindow?.close()
                    self.welcomeTrialWindow = nil
                }
            })

            let view = WelcomeTrialView(isPresented: binding)
            let hostingView = NSHostingView(rootView: view)

            let window = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 420, height: 560),
                styleMask: [.titled, .closable, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            window.contentView = hostingView
            window.title = L10n.welcomeTrialTitle
            window.isReleasedWhenClosed = false
            window.hidesOnDeactivate = false
            window.center()
            window.level = .screenSaver
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)

            self.welcomeTrialWindow = window
        }
    }

    @objc func handleShowTrialExpired() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.trialExpiredWindow?.close()
            self.trialExpiredWindow = nil

            var isPresented = true
            let binding = Binding(get: { isPresented }, set: { val in
                isPresented = val
                if !val {
                    self.trialExpiredWindow?.close()
                    self.trialExpiredWindow = nil
                }
            })

            let view = TrialExpiredView(isPresented: binding)
            let hostingView = NSHostingView(rootView: view)

            let window = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 440, height: 620),
                styleMask: [.titled, .closable, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            window.contentView = hostingView
            window.title = L10n.trialExpiredTitle
            window.isReleasedWhenClosed = false
            window.hidesOnDeactivate = false
            window.center()
            window.level = .screenSaver
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)

            self.trialExpiredWindow = window
        }
    }

    @objc func handleShowMonthlyLimit() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.monthlyLimitWindow?.close()
            self.monthlyLimitWindow = nil

            var isPresented = true
            let binding = Binding(get: { isPresented }, set: { val in
                isPresented = val
                if !val {
                    self.monthlyLimitWindow?.close()
                    self.monthlyLimitWindow = nil
                }
            })

            let view = MonthlyLimitView(isPresented: binding)
            let hostingView = NSHostingView(rootView: view)

            let window = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 440, height: 560),
                styleMask: [.titled, .closable, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            window.contentView = hostingView
            window.title = L10n.monthlyLimitTitle
            window.isReleasedWhenClosed = false
            window.hidesOnDeactivate = false
            window.center()
            window.level = .screenSaver
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)

            self.monthlyLimitWindow = window
        }
    }

    var upgradeReminderWindow: NSWindow?

    @objc func handleShowUpgradeReminder() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.upgradeReminderWindow?.close()
            self.upgradeReminderWindow = nil

            var isPresented = true
            let binding = Binding(get: { isPresented }, set: { val in
                isPresented = val
                if !val {
                    self.upgradeReminderWindow?.close()
                    self.upgradeReminderWindow = nil
                }
            })

            let view = UpgradeReminderView(isPresented: binding)
            let hostingView = NSHostingView(rootView: view)

            let window = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 420, height: 520),
                styleMask: [.titled, .closable, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            window.contentView = hostingView
            window.title = L10n.upgradeReminderTitle
            window.isReleasedWhenClosed = false
            window.hidesOnDeactivate = false
            window.center()
            window.level = .screenSaver
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)

            self.upgradeReminderWindow = window
        }
    }

    /// Check on launch if the trial just expired and show downgrade message once
    func checkTrialExpiredOnLaunch() {
        let trial = TrialManager.shared
        guard case .expired = trial.trialState else { return }

        // Only show once per expiry — use a flag
        let key = "trial_expired_shown"
        guard !UserDefaults.standard.bool(forKey: key) else { return }

        // Don't show if user is already Pro (purchased after trial)
        guard !SubscriptionManager.shared.isPro else { return }

        UserDefaults.standard.set(true, forKey: key)
        NotificationCenter.default.post(name: .showTrialExpired, object: nil)
    }

    @objc func handleRecordingCancelled() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            // If there is an error or mic-denied message, keep HUD open briefly so user can read it
            let hasError = self.viewModel?.error != nil
            let hasMicError = self.viewModel?.audioRecorder.recordingError != nil
            if hasError || hasMicError {
                // Show the mic error in the viewModel so ContentView renders it
                if let micErr = self.viewModel?.audioRecorder.recordingError {
                    self.viewModel?.error = micErr
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                    self?.viewModel?.error = nil
                    self?.window?.orderOut(nil)
                }
            } else {
                self.window?.orderOut(nil)
            }
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
    
    // MARK: - Conversation Reply

    /// Called when ⌃⇧R is pressed. Reads selected text, translates it, shows the HUD.
    @objc func activateConversationReply() {
        appendDiag("[VoxAiGo \(Date())] activateConversationReply() called\n")

        // Check if feature is enabled
        guard SettingsManager.shared.enableConversationReply else {
            appendDiag("  ❌ enableConversationReply is false\n")
            return
        }

        // Debounce
        let now = Date()
        guard now.timeIntervalSince(lastConversationReplyTime) >= conversationReplyDebounceInterval else {
            appendDiag("  ❌ debounced\n")
            return
        }
        lastConversationReplyTime = now

        // If already active: dismiss
        if ConversationReplyManager.shared.isActive {
            appendDiag("  Already active → dismissing\n")
            ConversationReplyManager.shared.dismiss()
            dismissConversationReplyHUD()
            return
        }

        // Read selected text BEFORE showing the HUD (clipboard trick needs app focus on source)
        let selectedText = ClipboardHelper.getSelectedText()
        appendDiag("  getSelectedText returned: \(selectedText == nil ? "nil" : "'\(selectedText!.prefix(50))'") (\(selectedText?.count ?? 0) chars)\n")

        guard let selectedText = selectedText, !selectedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            sounds.playError()
            appendDiag("  ❌ No text selected\n")
            return
        }

        guard AuthManager.shared.isAuthenticated || settings.hasByokKey else {
            sounds.playError()
            appendDiag("  ❌ Not authenticated\n")
            showMainWindow()
            return
        }
        appendDiag("  ✅ Starting translation for text: '\(selectedText.prefix(50))'\n")

        sounds.playStart()
        ConversationReplyManager.shared.beginTranslating()
        showConversationReplyHUD()

        let targetLanguage = settings.outputLanguage

        Task {
            do {
                let translation: String
                let fromLanguageName: String
                let fromLanguageCode: String

                if AuthManager.shared.isAuthenticated {
                    // Supabase auth — routes through edge function, no client-side key needed
                    (translation, fromLanguageName, fromLanguageCode) = try await SupabaseService.detectAndTranslate(
                        text: selectedText,
                        targetLanguage: targetLanguage
                    )
                } else if settings.hasByokKey {
                    // BYOK — direct Gemini call
                    (translation, fromLanguageName, fromLanguageCode) = try await GeminiService.detectAndTranslate(
                        text: selectedText,
                        targetLanguage: targetLanguage,
                        apiKey: settings.byokApiKey
                    )
                } else {
                    throw NSError(
                        domain: "ConversationReply",
                        code: 3,
                        userInfo: [NSLocalizedDescriptionKey: "Please log in to use Conversation Reply."]
                    )
                }

                let context = ConversationContext(
                    originalText: selectedText,
                    translation: translation,
                    fromLanguageName: fromLanguageName,
                    fromLanguageCode: fromLanguageCode,
                    toLanguageName: targetLanguage.displayName
                )

                await MainActor.run {
                    ConversationReplyManager.shared.showReady(context)
                    self.resizeConversationWindow(forRecording: false)
                }

            } catch {
                await MainActor.run {
                    self.appendDiag("[VoxAiGo \(Date())] Conversation Reply translation ERROR: \(error.localizedDescription)\n")
                    ConversationReplyManager.shared.dismiss()
                    self.dismissConversationReplyHUD()
                }
            }
        }
    }

    /// Shows the Conversation Reply HUD window with slide-in animation.
    private func showConversationReplyHUD() {
        guard let viewModel = viewModel else { return }

        let manager = ConversationReplyManager.shared
        let contentView = ConversationReplyView(manager: manager, viewModel: viewModel)

        // Reuse window if exists
        if let existing = conversationReplyWindow {
            existing.contentView = NSHostingView(rootView: contentView)
            existing.orderFrontRegardless()
            return
        }

        let width: CGFloat = 460
        let height: CGFloat = 64   // Start small (translating state)

        let window = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        window.contentView = NSHostingView(rootView: contentView)
        window.level = .screenSaver
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.isReleasedWhenClosed = false
        window.ignoresMouseEvents = false     // Needs clicks for the X button
        window.hidesOnDeactivate = false      // Stay visible when app loses focus
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - width / 2
            // Same vertical position as the speech HUD (25% from bottom)
            let y = screenFrame.minY + (screenFrame.height * 0.25)
            window.setFrameOrigin(NSPoint(x: x, y: y - 20))  // Start 20pt below, slides up
        }

        conversationReplyWindow = window

        // Slide in + fade in
        window.alphaValue = 0
        window.orderFrontRegardless()

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.28
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().alphaValue = 1
            if let screen = NSScreen.main {
                let screenFrame = screen.visibleFrame
                let x = screenFrame.midX - width / 2
                let y = screenFrame.minY + (screenFrame.height * 0.25)
                window.animator().setFrameOrigin(NSPoint(x: x, y: y))
            }
        }
    }

    /// Resizes the Conversation Reply HUD for recording (compact) or ready (expanded) state.
    func resizeConversationWindow(forRecording: Bool) {
        guard let window = conversationReplyWindow,
              let screen = NSScreen.main else { return }

        let width: CGFloat = 460
        let height: CGFloat = forRecording ? 80 : 200
        let screenFrame = screen.visibleFrame
        let x = screenFrame.midX - width / 2
        // Keep same vertical anchor as speech HUD (25% from bottom)
        let y = screenFrame.minY + (screenFrame.height * 0.25)

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.22
            ctx.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().setFrame(NSRect(x: x, y: y, width: width, height: height), display: true)
        }
    }

    /// Dismisses the Conversation Reply HUD with a slide-out + fade animation.
    private func dismissConversationReplyHUD() {
        guard let window = conversationReplyWindow else { return }

        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.22
            ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
            window.animator().alphaValue = 0
            let frame = window.frame
            window.animator().setFrameOrigin(NSPoint(x: frame.origin.x, y: frame.origin.y + 12))
        }, completionHandler: { [weak self] in
            window.orderOut(nil)
            window.alphaValue = 1
            self?.conversationReplyWindow = nil
        })
    }

    @objc func handleConversationReplyTimedOut() {
        dismissConversationReplyHUD()
    }

    deinit {
        if let tap = globalKeyTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
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
