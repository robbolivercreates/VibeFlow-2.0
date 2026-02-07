import SwiftUI
import AppKit
import Combine

/// Gerenciador de auto-hide inteligente para a janela flutuante
/// Esconde a janela automaticamente após período de inatividade
class AutoHideManager: ObservableObject {
    static let shared = AutoHideManager()
    
    // MARK: - Configuration
    @Published var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: "autoHideEnabled")
            if isEnabled {
                startMonitoring()
            } else {
                stopMonitoring()
            }
        }
    }
    
    @Published var delay: TimeInterval {
        didSet {
            UserDefaults.standard.set(delay, forKey: "autoHideDelay")
        }
    }
    
    // MARK: - Private Properties
    private var inactivityTimer: Timer?
    private var mouseMonitor: Any?
    private var keyboardMonitor: Any?
    private var lastActivityTime: Date = Date()
    private var window: NSWindow?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Init
    private init() {
        self.isEnabled = UserDefaults.standard.object(forKey: "autoHideEnabled") as? Bool ?? true
        self.delay = UserDefaults.standard.object(forKey: "autoHideDelay") as? TimeInterval ?? 5.0
    }
    
    // MARK: - Window Registration
    
    func register(window: NSWindow) {
        self.window = window
        
        // Observar quando a janela é mostrada
        NotificationCenter.default.publisher(for: NSWindow.didBecomeKeyNotification, object: window)
            .sink { [weak self] _ in
                self?.onWindowShown()
            }
            .store(in: &cancellables)
        
        // Observar quando a janela perde foco
        NotificationCenter.default.publisher(for: NSWindow.didResignKeyNotification, object: window)
            .sink { [weak self] _ in
                self?.onWindowHidden()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Monitoring
    
    private func startMonitoring() {
        guard isEnabled else { return }
        
        stopMonitoring()
        
        // Monitor de movimento do mouse
        mouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged]) { [weak self] _ in
            self?.recordActivity()
        }
        
        // Monitor de teclado
        keyboardMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] _ in
            self?.recordActivity()
        }
        
        // Iniciar timer
        resetTimer()
    }
    
    private func stopMonitoring() {
        inactivityTimer?.invalidate()
        inactivityTimer = nil
        
        if let monitor = mouseMonitor {
            NSEvent.removeMonitor(monitor)
            mouseMonitor = nil
        }
        
        if let monitor = keyboardMonitor {
            NSEvent.removeMonitor(monitor)
            keyboardMonitor = nil
        }
    }
    
    // MARK: - Activity Tracking
    
    private func recordActivity() {
        lastActivityTime = Date()
        resetTimer()
    }
    
    private func resetTimer() {
        inactivityTimer?.invalidate()
        
        guard isEnabled, window?.isVisible == true else { return }
        
        inactivityTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.hideWindow()
        }
    }
    
    private func hideWindow() {
        guard let window = window, window.isVisible else { return }
        
        // Verificar se o mouse está sobre a janela
        let mouseLocation = NSEvent.mouseLocation
        let windowFrame = window.frame
        
        if windowFrame.contains(mouseLocation) {
            // Mouse está sobre a janela, resetar timer
            resetTimer()
            return
        }
        
        // Esconder janela com animação suave
        DispatchQueue.main.async {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.2
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                window.animator().alphaValue = 0
            } completionHandler: {
                window.orderOut(nil)
                window.alphaValue = 1
            }
        }
    }
    
    // MARK: - Event Handlers
    
    private func onWindowShown() {
        guard isEnabled else { return }
        lastActivityTime = Date()
        startMonitoring()
    }
    
    private func onWindowHidden() {
        stopMonitoring()
    }
    
    // MARK: - Public Methods
    
    func pause() {
        inactivityTimer?.invalidate()
    }
    
    func resume() {
        guard isEnabled else { return }
        resetTimer()
    }
    
    func reset() {
        recordActivity()
    }
}

// MARK: - View Extension

extension View {
    /// Aplica auto-hide à janela que contém esta view
    func autoHide(enabled: Bool = true) -> some View {
        self.onAppear {
            if let window = NSApp.keyWindow {
                AutoHideManager.shared.register(window: window)
            }
        }
    }
}

// MARK: - Settings View Extension

extension SettingsView {
}
