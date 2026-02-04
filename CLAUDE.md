# CLAUDE.md - VibeFlow Development Guide

This document provides essential context for AI assistants working with the VibeFlow codebase.

## Project Overview

**VibeFlow** is a macOS menu-bar application that converts voice input into formatted code and text using Google's Gemini AI. It's a productivity tool for developers that enables voice-to-code transcription.

- **Version:** 2.1.0
- **Platform:** macOS 13.0+ (Ventura and later)
- **Language:** Swift 5.9+
- **Framework:** SwiftUI with AppKit integration
- **Architecture:** MVVM with Singleton Managers

## Quick Commands

```bash
# Build for development
swift build

# Build for release
swift build -c release

# Run the app
./.build/release/VibeFlow

# Create app bundle
./Scripts/build.sh

# Create DMG installer
cd Distribution && ./create_dmg.sh
```

## Codebase Structure

```
VibeFlow/
├── Sources/                          # Main source code
│   ├── VibeFlowApp.swift            # App entry point, AppDelegate, menu bar
│   ├── VibeFlowViewModel.swift      # Main business logic (MVVM ViewModel)
│   ├── ContentView.swift            # Main UI view
│   ├── TranscriptionMode.swift      # Transcription modes enum with prompts
│   ├── AudioRecorder.swift          # Microphone recording logic
│   ├── GeminiService.swift          # Google Gemini API integration
│   ├── ClipboardHelper.swift        # Clipboard operations & auto-paste
│   ├── Localization.swift           # i18n strings (PT/EN)
│   ├── AppIcon.swift                # Menu bar icon generation
│   ├── AppVersion.swift             # Version info constants
│   ├── Config.swift.template        # API key template (copy to Config.swift)
│   │
│   └── VibeFlow/
│       ├── Managers/                # Singleton state managers
│       │   ├── SettingsManager.swift    # UserDefaults persistence
│       │   ├── HistoryManager.swift     # Last 50 transcriptions
│       │   ├── SnippetsManager.swift    # Text expansion shortcuts
│       │   ├── AnalyticsManager.swift   # Usage statistics
│       │   └── SoundManager.swift       # Audio feedback effects
│       │
│       └── Views/                   # SwiftUI views
│           ├── SettingsView.swift       # Settings window
│           ├── HistoryView.swift        # History browser
│           ├── SnippetsView.swift       # Snippet editor
│           ├── AnalyticsView.swift      # Usage statistics view
│           ├── SetupWizardView.swift    # 6-step onboarding
│           └── LicenseActivationView.swift # License key entry
│
├── Distribution/                    # Deployment files
│   ├── generate_keys.py            # License key generator
│   ├── create_dmg.sh               # DMG installer script
│   └── output/                     # Built DMG files
│
├── Scripts/
│   └── build.sh                    # Build & bundle script
│
├── Package.swift                   # Swift Package manifest
├── Info.plist                      # macOS app configuration
└── VibeFlow.icns                   # App icon
```

## Architecture

### MVVM Pattern with Managers

```
User/System Events
        ↓
AppDelegate (Global Shortcuts, Menu Bar)
        ↓
VibeFlowViewModel (Observable)
    ├── AudioRecorder
    ├── GeminiService
    └── ClipboardHelper
        ↓
Managers (Singletons)
    ├── SettingsManager
    ├── HistoryManager
    ├── SnippetsManager
    ├── AnalyticsManager
    └── SoundManager
        ↓
Views (SwiftUI)
```

### Key Design Principles

1. **Single Responsibility** - Each file handles one concern
2. **Observable State** - `@Published` properties for reactive updates
3. **Singleton Managers** - Shared state via `static let shared`
4. **NotificationCenter** - Cross-component communication
5. **Combine** - Reactive data binding with publishers

## Key Files Reference

| File | Purpose | When to Modify |
|------|---------|----------------|
| `VibeFlowApp.swift` | App lifecycle, menu bar, global shortcuts, windows | Adding windows, menus, shortcuts |
| `VibeFlowViewModel.swift` | Core business logic, recording state | Recording workflow, state changes |
| `TranscriptionMode.swift` | Mode definitions, AI prompts | Adding modes, adjusting prompts |
| `GeminiService.swift` | Gemini API integration | API changes, model updates |
| `AudioRecorder.swift` | Microphone recording, audio levels | Audio quality, detection thresholds |
| `SettingsManager.swift` | UserDefaults persistence | Adding new settings |
| `Localization.swift` | UI strings (PT/EN) | Adding text, new languages |

## Coding Conventions

### Naming

- **Classes/Structs/Enums:** PascalCase (`VibeFlowViewModel`, `TranscriptionMode`)
- **Properties/Methods:** camelCase (`isRecording`, `toggleRecording()`)
- **Constants:** PascalCase in dedicated structs (`L10n.ready`, `Keys.apiKey`)
- **Files:** PascalCase matching primary type (`SettingsManager.swift`)

### Swift Style

```swift
// Singleton pattern
class SettingsManager {
    static let shared = SettingsManager()
    private init() {}

    @Published var isLicensed: Bool = false
}

// Observable view model
class VibeFlowViewModel: ObservableObject {
    @Published var isRecording = false
    private var cancellables = Set<AnyCancellable>()
}

// Weak self in closures
DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
    self?.doSomething()
}
```

### Access Control

- Default to `private` for properties and methods
- Use `@Published` for observable state
- Use `static let shared` for singletons
- Use `private init()` to enforce singleton pattern

### Error Handling

- Custom error enums (e.g., `GeminiError`)
- Swift async/await for API calls
- `Task { }` blocks for background work
- `DispatchQueue.main.async` for UI updates

## Common Development Tasks

### Adding a New Setting

1. Add key to `SettingsManager.swift`:
```swift
// In Keys enum
static let newSetting = "new_setting_key"

// Add @Published property
@Published var newSetting: Bool = false

// Initialize in init()
newSetting = defaults.bool(forKey: Keys.newSetting)
```

2. Add UI in `SettingsView.swift`

### Adding a New Transcription Mode

1. Edit `TranscriptionMode.swift`:
```swift
enum TranscriptionMode: String, CaseIterable {
    case code = "Codigo"
    case text = "Texto"
    case email = "Email"
    case uxDesign = "UX Design"
    case newMode = "New Mode"  // Add case

    // Add properties: icon, color, temperature, systemPrompt
}
```

2. Add color mapping in `ContentView.swift` and `HistoryView.swift`

### Adding a New View/Window

1. Create view in `Sources/VibeFlow/Views/NewView.swift`
2. Add window property in `AppDelegate`:
```swift
var newWindow: NSWindow?
```
3. Add show function:
```swift
func showNewWindow() {
    if newWindow == nil {
        newWindow = NSWindow(...)
    }
    newWindow?.makeKeyAndOrderFront(nil)
}
```
4. Add menu item in `updateMenu()`

### Adding Localized Strings

Edit `Localization.swift`:
```swift
static var newString: String {
    switch currentLanguage {
    case .portuguese: return "Texto em Portugues"
    case .english: return "Text in English"
    }
}
```

## Global Shortcuts

Defined in `VibeFlowApp.swift`:

| Shortcut | Action | Handler |
|----------|--------|---------|
| `Option+Command` (hold) | Hold-to-talk recording | `handleFlagsChanged()` |
| `Cmd+Shift+V` | Toggle main window | `handleKeyPress()` |
| `Cmd+,` | Open Settings | `handleKeyPress()` |
| `Cmd+Y` | Open History | `handleKeyPress()` |

## Data Flow

### Recording Workflow

```
1. User holds Option+Command
2. AppDelegate.handleFlagsChanged() detects
3. SoundManager plays "start" sound
4. VibeFlowViewModel.toggleRecording()
5. AudioRecorder.startRecording()
6. Real-time audio level updates waveform
7. User releases keys
8. AudioRecorder.stopRecording()
9. GeminiService.transcribeAudio()
10. ClipboardHelper.copyAndPaste()
11. HistoryManager.add() + AnalyticsManager.record()
```

### NotificationCenter Events

```swift
.modeChanged              // Transcription mode changed
.transcriptionComplete    // Transcription finished
.recordingCancelled       // Cancelled (no speech detected)
.showWizardAfterActivation // Show wizard after license activation
.shortcutChanged          // Keyboard shortcut changed
```

## Dependencies

**Swift Package Manager (Package.swift):**
- `GoogleGenerativeAI` (v0.5.0+) - Google Gemini API SDK

**System Frameworks:**
- SwiftUI, AppKit, Combine
- AVFoundation (audio)
- ApplicationServices (accessibility)
- Carbon (key events)

## Configuration

### API Key Setup

1. Copy `Sources/Config.swift.template` to `Sources/Config.swift`
2. Add your Gemini API key
3. `Config.swift` is gitignored

### Required Permissions (Info.plist)

- Microphone access
- Accessibility (for auto-paste simulation)
- AppleEvents (for automation)

## License System

**Key Format:** `VIBE-XXXX-XXXX-XXXX`
- Characters: A-Z (excluding O, I) + 2-9 (excluding 0, 1)
- Master key: `VIBE-MASTER-2024-PRO`

**Validation:**
- Local format validation (currently)
- Future: Server-side validation

## Testing Approach

This project currently has no automated tests. When adding features:
1. Test manually on macOS 13+
2. Verify all transcription modes
3. Test with/without API key
4. Check accessibility permissions
5. Verify auto-paste functionality

## Things to Avoid

1. **Never commit `Config.swift`** - Contains API keys
2. **Never use force unwrapping** - Use optional binding
3. **Avoid blocking main thread** - Use async/await or DispatchQueue
4. **Don't forget weak self** - Prevent retain cycles in closures
5. **Don't hardcode strings** - Use `Localization.swift`
6. **Avoid direct UserDefaults** - Use `SettingsManager`

## Build Outputs

```
.build/release/VibeFlow           # Compiled binary
VibeFlow.app/                     # App bundle (after build.sh)
Distribution/output/*.dmg         # Installer (after create_dmg.sh)
```

## Useful Resources

- [Google AI Studio](https://aistudio.google.com/) - Get API keys
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Gemini API Docs](https://ai.google.dev/docs)

## Version History

- **2.1.0** (Current) - Email mode, Setup Wizard, History, Snippets, Sound effects
- **2.0.0** - Dynamic temperature, UI refresh
- **1.0.0** - Initial release

---

**Last Updated:** 2026-02-04
**Maintained by:** AI Assistant based on codebase analysis
