import SwiftUI
import AppKit
import Carbon

/// Gerenciador de atalhos globais configuráveis
class ShortcutManager: ObservableObject {
    static let shared = ShortcutManager()
    
    // MARK: - Shortcut Definitions
    enum ShortcutType: String, CaseIterable, Identifiable {
        case toggleWindow = "toggle_window"
        case recordHold = "record_hold"
        case showSettings = "show_settings"
        case showHistory = "show_history"
        case showSnippets = "show_snippets"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .toggleWindow: return "Mostrar/Esconder"
            case .recordHold: return "Gravar (segurar)"
            case .showSettings: return "Configurações"
            case .showHistory: return "Histórico"
            case .showSnippets: return "Snippets"
            }
        }
        
        var icon: String {
            switch self {
            case .toggleWindow: return "eye"
            case .recordHold: return "mic.fill"
            case .showSettings: return "gear"
            case .showHistory: return "clock.arrow.circlepath"
            case .showSnippets: return "text.quote"
            }
        }
        
        var defaultShortcut: Shortcut {
            switch self {
            case .toggleWindow:
                return Shortcut(key: .v, modifiers: [.command, .shift])
            case .recordHold:
                return Shortcut(key: .option, modifiers: [.command], isHold: true)
            case .showSettings:
                return Shortcut(key: .comma, modifiers: [.command])
            case .showHistory:
                return Shortcut(key: .y, modifiers: [.command])
            case .showSnippets:
                return Shortcut(key: .s, modifiers: [.command, .shift])
            }
        }
    }
    
    // MARK: - Shortcut Model
    struct Shortcut: Codable, Equatable {
        let key: Key
        let modifiers: [Modifier]
        let isHold: Bool
        
        init(key: Key, modifiers: [Modifier], isHold: Bool = false) {
            self.key = key
            self.modifiers = modifiers
            self.isHold = isHold
        }
        
        var displayString: String {
            if isHold {
                return modifiers.map { $0.display }.joined(separator: "") + " (segure)"
            }
            return modifiers.map { $0.display }.joined(separator: "") + key.display
        }
    }
    
    enum Key: String, Codable, CaseIterable {
        case a, b, c, d, e, f, g, h, i, j, k, l, m
        case n, o, p, q, r, s, t, u, v, w, x, y, z
        case zero = "0", one = "1", two = "2", three = "3", four = "4"
        case five = "5", six = "6", seven = "7", eight = "8", nine = "9"
        case space, tab, escape, enter, delete
        case up, down, left, right
        case f1, f2, f3, f4, f5, f6, f7, f8, f9, f10, f11, f12
        case option, control, command, shift
        
        var display: String {
            switch self {
            case .space: return "␣"
            case .tab: return "⇥"
            case .escape: return "⎋"
            case .enter: return "↩"
            case .delete: return "⌫"
            case .up: return "↑"
            case .down: return "↓"
            case .left: return "←"
            case .right: return "→"
            case .option: return "⌥"
            case .control: return "⌃"
            case .command: return "⌘"
            case .shift: return "⇧"
            default: return rawValue.uppercased()
            }
        }
        
        var keyCode: UInt16? {
            switch self {
            case .a: return 0
            case .s: return 1
            case .d: return 2
            case .f: return 3
            case .h: return 4
            case .g: return 5
            case .z: return 6
            case .x: return 7
            case .c: return 8
            case .v: return 9
            case .b: return 11
            case .q: return 12
            case .w: return 13
            case .e: return 14
            case .r: return 15
            case .y: return 16
            case .t: return 17
            case .one: return 18
            case .two: return 19
            case .three: return 20
            case .four: return 21
            case .six: return 22
            case .five: return 23
            case .equal: return 24
            case .nine: return 25
            case .seven: return 26
            case .minus: return 27
            case .eight: return 28
            case .zero: return 29
            case .rightBracket: return 30
            case .o: return 31
            case .u: return 32
            case .leftBracket: return 33
            case .i: return 34
            case .p: return 35
            case .return: return 36
            case .l: return 37
            case .j: return 38
            case .quote: return 39
            case .k: return 40
            case .semicolon: return 41
            case .backslash: return 42
            case .comma: return 43
            case .slash: return 44
            case .n: return 45
            case .m: return 46
            case .period: return 47
            case .tab: return 48
            case .space: return 49
            case .delete: return 51
            case .escape: return 53
            case .command: return 55
            case .shift: return 56
            case .capsLock: return 57
            case .option: return 58
            case .control: return 59
            case .f17: return 64
            case .padPeriod: return 65
            case .padAsterisk: return 67
            case .padPlus: return 69
            case .padClear: return 71
            case .padSlash: return 75
            case .padEnter: return 76
            case .padMinus: return 78
            case .f18: return 79
            case .f19: return 80
            case .padEquals: return 81
            case .padZero: return 82
            case .padOne: return 83
            case .padTwo: return 84
            case .padThree: return 85
            case .padFour: return 86
            case .padFive: return 87
            case .padSix: return 88
            case .padSeven: return 89
            case .f20: return 90
            case .padEight: return 91
            case .padNine: return 92
            case .f5: return 96
            case .f6: return 97
            case .f7: return 98
            case .f3: return 99
            case .f8: return 100
            case .f9: return 101
            case .f10: return 109
            case .f11: return 103
            case .f12: return 111
            case .help: return 114
            case .home: return 115
            case .pageUp: return 116
            case .f4: return 118
            case .end: return 119
            case .f2: return 120
            case .pageDown: return 121
            case .f1: return 122
            case .left: return 123
            case .right: return 124
            case .down: return 125
            case .up: return 126
            default: return nil
            }
        }
    }
    
    enum Modifier: String, Codable, CaseIterable {
        case command, option, control, shift, function
        
        var display: String {
            switch self {
            case .command: return "⌘"
            case .option: return "⌥"
            case .control: return "⌃"
            case .shift: return "⇧"
            case .function: return "Fn"
            }
        }
        
        var eventMask: NSEvent.ModifierFlags {
            switch self {
            case .command: return .command
            case .option: return .option
            case .control: return .control
            case .shift: return .shift
            case .function: return .function
            }
        }
    }
    
    // MARK: - Properties
    @Published var shortcuts: [ShortcutType: Shortcut] = [:]
    
    private var globalMonitors: [Any] = []
    private var localMonitors: [Any] = []
    private var actionHandlers: [ShortcutType: () -> Void] = [:]
    
    private let defaults = UserDefaults.standard
    private let prefix = "shortcut_"
    
    private init() {
        loadShortcuts()
    }
    
    // MARK: - Loading & Saving
    
    private func loadShortcuts() {
        for type in ShortcutType.allCases {
            if let data = defaults.data(forKey: prefix + type.rawValue),
               let shortcut = try? JSONDecoder().decode(Shortcut.self, from: data) {
                shortcuts[type] = shortcut
            } else {
                shortcuts[type] = type.defaultShortcut
            }
        }
    }
    
    func saveShortcut(_ type: ShortcutType, shortcut: Shortcut) {
        shortcuts[type] = shortcut
        if let data = try? JSONEncoder().encode(shortcut) {
            defaults.set(data, forKey: prefix + type.rawValue)
        }
    }
    
    func resetToDefaults() {
        for type in ShortcutType.allCases {
            shortcuts[type] = type.defaultShortcut
            if let data = try? JSONEncoder().encode(type.defaultShortcut) {
                defaults.set(data, forKey: prefix + type.rawValue)
            }
        }
    }
    
    // MARK: - Action Registration
    
    func registerAction(for type: ShortcutType, action: @escaping () -> Void) {
        actionHandlers[type] = action
    }
    
    // MARK: - Monitoring
    
    func startMonitoring() {
        stopMonitoring()
        
        // Monitor global para atalhos de tecla
        let globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
        }
        if let monitor = globalMonitor {
            globalMonitors.append(monitor)
        }
        
        // Monitor para hold-to-talk (flags changed)
        let flagsMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event)
        }
        if let monitor = flagsMonitor {
            globalMonitors.append(monitor)
        }
        
        // Monitor local também (quando app está ativo)
        let localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
            return event
        }
        if let monitor = localMonitor {
            localMonitors.append(monitor)
        }
        
        let localFlagsMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handleFlagsChanged(event)
            return event
        }
        if let monitor = localFlagsMonitor {
            localMonitors.append(monitor)
        }
    }
    
    func stopMonitoring() {
        globalMonitors.forEach { NSEvent.removeMonitor($0) }
        localMonitors.forEach { NSEvent.removeMonitor($0) }
        globalMonitors.removeAll()
        localMonitors.removeAll()
    }
    
    // MARK: - Event Handling
    
    private func handleKeyEvent(_ event: NSEvent) {
        guard !event.isARepeat else { return }
        
        for (type, shortcut) in shortcuts {
            guard !shortcut.isHold else { continue }
            
            if matches(event, shortcut: shortcut) {
                actionHandlers[type]?()
                break
            }
        }
    }
    
    private func handleFlagsChanged(_ event: NSEvent) {
        // Handle hold-to-talk
        if let recordShortcut = shortcuts[.recordHold], recordShortcut.isHold {
            let requiredRawValues = recordShortcut.modifiers.map { $0.eventMask.rawValue }
            let currentRawValue = event.modifierFlags.intersection([.command, .option, .control, .shift]).rawValue
            
            let isPressed = requiredRawValues.allSatisfy { (currentRawValue & $0) == $0 }
            
            if isPressed {
                actionHandlers[.recordHold]?()
            }
        }
    }
    
    private func matches(_ event: NSEvent, shortcut: Shortcut) -> Bool {
        guard let keyCode = shortcut.key.keyCode,
              event.keyCode == keyCode else {
            return false
        }
        
        let requiredModifiers = shortcut.modifiers.map { $0.eventMask }
        let currentModifiers = event.modifierFlags.intersection([.command, .option, .control, .shift])
        
        return requiredModifiers.allSatisfy { currentModifiers.contains($0) }
    }
    
    // MARK: - Convenience
    
    func shortcut(for type: ShortcutType) -> Shortcut? {
        shortcuts[type]
    }
    
    func displayString(for type: ShortcutType) -> String {
        shortcuts[type]?.displayString ?? type.defaultShortcut.displayString
    }
}

// MARK: - Additional Key Cases
extension ShortcutManager.Key {
    static let equal = Self(rawValue: "equal")!
    static let minus = Self(rawValue: "minus")!
    static let leftBracket = Self(rawValue: "leftBracket")!
    static let rightBracket = Self(rawValue: "rightBracket")!
    static let quote = Self(rawValue: "quote")!
    static let semicolon = Self(rawValue: "semicolon")!
    static let backslash = Self(rawValue: "backslash")!
    static let comma = Self(rawValue: "comma")!
    static let period = Self(rawValue: "period")!
    static let slash = Self(rawValue: "slash")!
    static let `return` = Self(rawValue: "return")!
    static let capsLock = Self(rawValue: "capsLock")!
    static let padPeriod = Self(rawValue: "padPeriod")!
    static let padAsterisk = Self(rawValue: "padAsterisk")!
    static let padPlus = Self(rawValue: "padPlus")!
    static let padClear = Self(rawValue: "padClear")!
    static let padSlash = Self(rawValue: "padSlash")!
    static let padEnter = Self(rawValue: "padEnter")!
    static let padMinus = Self(rawValue: "padMinus")!
    static let padEquals = Self(rawValue: "padEquals")!
    static let padZero = Self(rawValue: "padZero")!
    static let padOne = Self(rawValue: "padOne")!
    static let padTwo = Self(rawValue: "padTwo")!
    static let padThree = Self(rawValue: "padThree")!
    static let padFour = Self(rawValue: "padFour")!
    static let padFive = Self(rawValue: "padFive")!
    static let padSix = Self(rawValue: "padSix")!
    static let padSeven = Self(rawValue: "padSeven")!
    static let padEight = Self(rawValue: "padEight")!
    static let padNine = Self(rawValue: "padNine")!
    static let f17 = Self(rawValue: "f17")!
    static let f18 = Self(rawValue: "f18")!
    static let f19 = Self(rawValue: "f19")!
    static let f20 = Self(rawValue: "f20")!
    static let help = Self(rawValue: "help")!
    static let home = Self(rawValue: "home")!
    static let pageUp = Self(rawValue: "pageUp")!
    static let end = Self(rawValue: "end")!
    static let pageDown = Self(rawValue: "pageDown")!
}
