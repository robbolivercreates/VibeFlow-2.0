# VibeFlow 🎤✨

A native macOS voice-to-code/text app powered by Google Gemini AI. Speak naturally and get perfectly formatted code or text pasted directly into your editor.

![macOS](https://img.shields.io/badge/macOS-13.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

- 🎙️ **Voice Recording** - Hold ⌥⌘ (Option+Command) to record
- 🤖 **AI-Powered** - Uses Google Gemini 2.0 Flash for transcription and formatting
- 📝 **Multiple Modes**:
  - **Code** - Transforms speech into code
  - **Text** - Clean, formatted text transcription
  - **UX Design** - Structured UI/UX documentation
- 🌍 **Bilingual** - Interface in English or Portuguese
- 🔄 **Translation** - Speak in Portuguese, get output in English
- ✨ **Text Clarity** - Removes filler words, organizes sentences
- 📋 **Auto-Paste** - Automatically pastes result into active app
- 🖥️ **Menu Bar App** - Minimal, non-intrusive interface

## Screenshots

| Recording | Processing | Ready |
|-----------|------------|-------|
| 🔴 Red waves | 🟡 Orange dots | 🟢 Green mic |

## Installation

### Option 1: Build from Source

1. **Clone the repository**
   ```bash
   git clone https://github.com/YOUR_USERNAME/VibeFlow.git
   cd VibeFlow
   ```

2. **Configure API Key**
   ```bash
   cp Sources/Config.swift.template Sources/Config.swift
   # Edit Config.swift and add your Gemini API key
   ```

3. **Build**
   ```bash
   swift build -c release
   ```

4. **Create App Bundle**
   ```bash
   ./Scripts/build.sh
   ```

5. **Install**
   - Drag `VibeFlow.app` to `/Applications`
   - Grant Accessibility permissions when prompted

### Option 2: Download Release

Download the latest `.app` from [Releases](https://github.com/YOUR_USERNAME/VibeFlow/releases).

## Getting a Gemini API Key

1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Click "Create API Key"
3. Copy the key
4. Paste in VibeFlow Settings (right-click menu bar icon → Settings)

## Usage

1. **Activate**: Press ⌘⇧V or click the menu bar icon
2. **Record**: Hold ⌥⌘ (Option+Command) and speak
3. **Release**: Let go to process and auto-paste

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| ⌘⇧V | Show/Hide window |
| ⌥⌘ (hold) | Record while held |

## Configuration

Right-click the menu bar icon → **Settings**:

- **Mode** - Code / Text / UX Design
- **Language** - Interface language (EN/PT)
- **Translate** - Output in English even when speaking Portuguese
- **Clarity** - Remove filler words and organize text

## Development

### Requirements

- macOS 13.0+
- Swift 5.9+
- Xcode 15+ (optional, for IDE)

### Project Structure

```
VibeFlow/
├── Sources/
│   ├── VibeFlowApp.swift      # App entry point, menu bar
│   ├── ContentView.swift       # Main UI
│   ├── SettingsView.swift      # Settings window
│   ├── AudioRecorder.swift     # Microphone recording
│   ├── GeminiService.swift     # Gemini API integration
│   ├── ClipboardHelper.swift   # Copy & paste automation
│   ├── TranscriptionMode.swift # Mode definitions
│   ├── Localization.swift      # i18n strings
│   ├── AppIcon.swift           # Programmatic icon
│   └── Config.swift            # API key (not in git)
├── Scripts/
│   ├── build.sh                # Build script
│   └── generate_icon.swift     # Icon generator
├── Package.swift               # Dependencies
└── Info.plist                  # App metadata
```

### Building

```bash
# Debug build
swift build

# Release build
swift build -c release

# Run
swift run
```

### Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Roadmap

- [ ] Custom keyboard shortcuts
- [ ] Multiple language support for transcription
- [ ] Audio feedback (sounds)
- [ ] History of transcriptions
- [ ] Custom prompts per mode
- [ ] Whisper integration (offline mode)

## Troubleshooting

### Auto-paste not working

1. Go to **System Settings → Privacy & Security → Accessibility**
2. Add VibeFlow to the list
3. Toggle it off and on again

### No audio recording

1. Go to **System Settings → Privacy & Security → Microphone**
2. Ensure VibeFlow has permission

## License

MIT License - see [LICENSE](LICENSE) for details.

## Acknowledgments

- [Google Gemini](https://ai.google.dev/) - AI API
- [Swift](https://swift.org/) - Programming language
- Inspired by [Whisper Flow](https://github.com/...) and voice coding tools

---

Made with ❤️ for developers who prefer talking over typing.
