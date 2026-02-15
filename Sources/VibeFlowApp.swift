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
    var viewModel: VibeFlowViewModel?
    var isHoldToTalkActive = false
    var globalKeyMonitor: Any?
    var localKeyMonitor: Any?
    var localKeyDownMonitor: Any?

    // CGEvent tap for reliable global keyboard shortcut detection
    var globalKeyTap: CFMachPort?
    var accessibilityRetryTimer: Timer?

    // Notification windows (retained to prevent memory issues)
    var languageNotificationWindow: NSWindow?
    var modeNotificationWindow: NSWindow?
    var pasteLastNotificationWindow: NSWindow?
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
        
        // Create status item in .regular policy (ONLY mode where it works).
        // .accessory mode and LSUIElement both move status items off-screen on this system.
        AppDelegate.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = AppDelegate.statusItem?.button {
            if let sfImage = NSImage(systemSymbolName: "waveform", accessibilityDescription: "VibeFlow") {
                let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .medium)
                button.image = sfImage.withSymbolConfiguration(config) ?? sfImage
            } else {
                button.image = AppIconGenerator.createMenuBarIcon()
            }
            button.action = #selector(toggleWindow)
            button.target = self
        }
        
        // Hide dock icon by making it transparent (workaround for .accessory breaking status items)
        let transparentIcon = NSImage(size: NSSize(width: 128, height: 128))
        transparentIcon.lockFocus()
        NSColor.clear.set()
        NSRect(x: 0, y: 0, width: 128, height: 128).fill()
        transparentIcon.unlockFocus()
        NSApp.applicationIconImage = transparentIcon
        // Hide the dock tile badge/label
        NSApp.dockTile.showsApplicationBadge = false
        
        // Criar view model
        let viewModel = VibeFlowViewModel()
        self.viewModel = viewModel
        
        // Update menu after viewModel is created
        updateMenu()
        
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.checkFirstLaunch()
        }
    }
    
    /// Creates and configures the menu bar status item
    private func createStatusBarItem() {
        let diag = "/tmp/vibeflow_diag.txt"
        var log = "[\(Date())] createStatusBarItem called\n"
        
        AppDelegate.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        log += "statusItem created: \(AppDelegate.statusItem != nil)\n"
        
        if let button = AppDelegate.statusItem?.button {
            // Use SF Symbol instead of custom drawing to test visibility
            if let sfImage = NSImage(systemSymbolName: "waveform", accessibilityDescription: "VibeFlow") {
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
        wizardWindow?.isReleasedWhenClosed = false
        wizardWindow?.contentView = hostingView
        wizardWindow?.title = "Configurar VibeFlow"
        wizardWindow?.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
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
        let titleItem = NSMenuItem(title: "VibeFlow \(AppVersion.current)", action: nil, keyEquivalent: "")
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

        // Main Window (VibeFlow Central)
        let mainWindowItem = NSMenuItem(title: "Abrir VibeFlow", action: #selector(showMainWindow), keyEquivalent: "")
        mainWindowItem.target = self
        menu.addItem(mainWindowItem)

        menu.addItem(NSMenuItem.separator())

        // Quick access items
        menu.addItem(NSMenuItem(title: "Historico", action: #selector(showHistory), keyEquivalent: "y"))
        menu.addItem(NSMenuItem(title: "Snippets", action: #selector(showSnippets), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Estatísticas", action: #selector(showAnalytics), keyEquivalent: ""))
        let pasteLastItem = NSMenuItem(
            title: "Colar Última Transcrição (⌃⇧V)",
            action: #selector(pasteLastTranscription),
            keyEquivalent: ""
        )
        pasteLastItem.target = self
        menu.addItem(pasteLastItem)
        menu.addItem(NSMenuItem.separator())

        // Settings
        menu.addItem(NSMenuItem(title: L10n.settings, action: #selector(showSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: L10n.quit, action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        AppDelegate.statusItem?.menu = menu
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
        newWindow.title = "VibeFlow"
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
            self?.viewModel?.reloadAPIKey()
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
        newWindow.title = "VibeFlow - Histórico"
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
        newWindow.title = "VibeFlow - Snippets"
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

        // Local keyDown monitor (shortcuts work when VibeFlow window is active)
        localKeyDownMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleGlobalKeyEvent(event)
            return event
        }
    }

    /// Checks if Accessibility permission is granted and prompts user if not.
    /// Also starts a retry timer to recreate CGEvent tap once permission is granted.
    private func checkAccessibilityPermission() {
        var diag = "[VibeFlow \(Date())] checkAccessibilityPermission\n"
        
        let trusted = AXIsProcessTrusted()
        diag += "  AXIsProcessTrusted = \(trusted)\n"
        
        if !trusted {
            // Don't prompt user here — let the Setup Wizard guide them
            diag += "  Accessibility not granted (wizard will guide user)\n"
            
            // Start periodic retry — once permission is granted, recreate the tap
            accessibilityRetryTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] timer in
                if AXIsProcessTrusted() {
                    let msg = "[VibeFlow \(Date())] Accessibility permission granted via retry! Setting up tap...\n"
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
        var diag = "[VibeFlow \(Date())] setupGlobalKeyTap\n"
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
                        appDelegate.appendDiag("[VibeFlow \(Date())] Re-enabled tap after system disabled it\n")
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
    }

    func handleGlobalKeyEvent(_ event: NSEvent) {
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
                print("[VibeFlow] Language shortcut detected!")
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

        let contentView = LanguageNotificationView(language: language)
        let notificationWindow = createHUDWindow(
            contentView: contentView,
            width: 260,
            height: 64
        )

        self.languageNotificationWindow = notificationWindow
        notificationWindow.orderFrontRegardless()

        // Auto-close with fade-out after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.fadeOutAndClose(window: self?.languageNotificationWindow) {
                self?.languageNotificationWindow = nil
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

        print("[VibeFlow] Mode changed: \(previousMode.localizedName) → \(newMode.localizedName)")
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.fadeOutAndClose(window: self?.modeNotificationWindow) {
                self?.modeNotificationWindow = nil
            }
        }
    }

    @objc func pasteLastTranscription() {
        // Debounce rapid key presses
        let now = Date()
        guard now.timeIntervalSince(lastPasteLastTime) >= pasteLastDebounceInterval else {
            print("[VibeFlow] Paste last debounced")
            return
        }
        lastPasteLastTime = now

        // Get and paste the last item
        if let item = history.pasteLastItem() {
            // Play feedback sound
            sounds.playSuccess()

            // Show notification
            showPasteLastNotification(text: item.text, mode: item.mode)

            print("[VibeFlow] Pasted last transcription: \(item.text.prefix(30))...")
        } else {
            // No history - show empty notification
            sounds.playError()
            showNoHistoryNotification()

            print("[VibeFlow] No history to paste")
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.fadeOutAndClose(window: self?.pasteLastNotificationWindow) {
                self?.pasteLastNotificationWindow = nil
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.fadeOutAndClose(window: self?.pasteLastNotificationWindow) {
                self?.pasteLastNotificationWindow = nil
            }
        }
    }

    // MARK: - HUD Window Helpers

    /// Creates a floating HUD notification window, positioned at top-center of screen
    private func createHUDWindow<Content: View>(contentView: Content, width: CGFloat, height: CGFloat) -> NSWindow {
        let notificationWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        notificationWindow.contentView = NSHostingView(rootView: contentView)
        notificationWindow.level = .screenSaver  // Above everything
        notificationWindow.backgroundColor = .clear
        notificationWindow.isOpaque = false
        notificationWindow.hasShadow = false  // Shadow handled by SwiftUI
        notificationWindow.isReleasedWhenClosed = false
        notificationWindow.ignoresMouseEvents = true  // Click-through
        notificationWindow.collectionBehavior = [.canJoinAllSpaces, .stationary]

        // Position at top center of screen (30px below menu bar)
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - width / 2
            let y = screenFrame.maxY - height - 30
            notificationWindow.setFrameOrigin(NSPoint(x: x, y: y))
        }

        return notificationWindow
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
