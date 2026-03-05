# VibeFlow iOS

Voice-to-text transcription keyboard for iPhone and iPad, powered by Google Gemini AI.

## Features

- **Custom Keyboard Extension**: Use in any app
- **Voice Recording**: Hold mic button to record
- **AI Transcription**: Powered by Gemini 2.0 Flash
- **Multiple Modes**: Code, Text, Email, UX Design
- **Multiple Languages**: Portuguese, English, Spanish, French, German, Italian, Japanese, Chinese
- **Translation**: Optional translation to English

## Project Structure

```
iOS/
├── Shared/                        # Shared code between app and extension
│   ├── TranscriptionMode.swift    # Transcription modes enum
│   ├── SpeechLanguage.swift       # Supported languages
│   ├── SharedSettings.swift       # App Groups settings
│   ├── GeminiService.swift        # Gemini API integration
│   └── AudioRecorder.swift        # Audio recording helper
│
├── VibeFlowApp/                   # Main application
│   ├── Sources/
│   │   ├── VibeFlowApp.swift      # App entry point
│   │   ├── MainView.swift         # Main screen with tabs
│   │   ├── SettingsView.swift     # Settings & API key
│   │   └── OnboardingView.swift   # First-launch setup
│   └── Info.plist
│
└── VibeFlowKeyboard/              # Keyboard Extension
    ├── Sources/
    │   └── KeyboardViewController.swift  # Keyboard UI & logic
    └── Info.plist
```

## Setup Instructions

### 1. Create Xcode Project

1. Open Xcode
2. File > New > Project
3. Select **App** template
4. Configure:
   - Product Name: `VibeFlow`
   - Team: Your Apple Developer account
   - Organization Identifier: `com.yourname` (e.g., `com.vibeflow`)
   - Interface: **SwiftUI**
   - Language: **Swift**

### 2. Add Keyboard Extension Target

1. File > New > Target
2. Select **Custom Keyboard Extension**
3. Name it `VibeFlowKeyboard`
4. Click "Activate" when prompted

### 3. Configure App Groups

**IMPORTANT: This allows the app and keyboard to share settings!**

1. Select the **VibeFlow** target
2. Go to Signing & Capabilities
3. Click "+ Capability"
4. Add **App Groups**
5. Create a group: `group.com.vibeflow.app`
6. Repeat for **VibeFlowKeyboard** target (same group)

### 4. Add Source Files

1. Drag the `Shared/` folder into both targets:
   - Right-click on VibeFlow group > Add Files
   - Select all files in `Shared/`
   - Check both **VibeFlow** and **VibeFlowKeyboard** targets

2. Drag `VibeFlowApp/Sources/` files into VibeFlow target only

3. Replace `KeyboardViewController.swift` in the keyboard target with the one from `VibeFlowKeyboard/Sources/`

### 5. Update App Group ID

In `Shared/SharedSettings.swift`, update the App Group ID to match yours:

```swift
private let appGroupID = "group.com.vibeflow.app"  // Your App Group ID
```

### 6. Configure Info.plist

The provided Info.plist files should work, but verify:

**VibeFlowKeyboard/Info.plist:**
- `RequestsOpenAccess` = `true` (required for mic + network)
- `NSMicrophoneUsageDescription` is set

**VibeFlowApp/Info.plist:**
- `NSMicrophoneUsageDescription` is set

### 7. Build & Run

1. Select **VibeFlow** scheme
2. Select your iPhone/iPad or Simulator
3. Click Run (⌘R)

## Testing on Simulator

> **Note**: Keyboard extensions have limited functionality in Simulator. For best results, test on a real device.

1. Build and run the app
2. Open Settings > General > Keyboard > Keyboards
3. Add New Keyboard > VibeFlow
4. Enable "Allow Full Access"
5. Open any text field
6. Switch to VibeFlow keyboard (globe button)

## Testing on Device

1. Connect iPhone/iPad
2. Select device in Xcode
3. Build and run
4. Follow the setup steps in the app
5. Enable keyboard in Settings

## Troubleshooting

### Keyboard not appearing?
- Make sure keyboard is added in Settings
- Check "Allow Full Access" is enabled
- Restart the app you're trying to use

### Microphone not working?
- "Allow Full Access" must be ON
- Check microphone permissions in Settings

### API errors?
- Verify API key is correct
- Check internet connection
- Try validating key in Settings

### Settings not syncing?
- Verify App Groups are configured on BOTH targets
- App Group IDs must match exactly

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    VibeFlow App                          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐      │
│  │  Onboarding │  │    Home     │  │  Settings   │      │
│  │    View     │  │    View     │  │    View     │      │
│  └─────────────┘  └─────────────┘  └─────────────┘      │
│                           │                              │
│                    ┌──────┴──────┐                      │
│                    │ SharedSettings │ ◄── App Groups    │
│                    └──────┬──────┘                      │
└───────────────────────────┼─────────────────────────────┘
                            │
                    ┌───────┴───────┐
                    │  App Groups   │
                    │ (Shared Data) │
                    └───────┬───────┘
                            │
┌───────────────────────────┼─────────────────────────────┐
│              VibeFlow Keyboard Extension                 │
│                           │                              │
│                    ┌──────┴──────┐                      │
│                    │ SharedSettings │                    │
│                    └──────┬──────┘                      │
│                           │                              │
│  ┌───────────────────────┐│┌───────────────────────┐    │
│  │  KeyboardViewController│││   GeminiService      │    │
│  │  - Mic button         │││   - API calls         │    │
│  │  - Recording          │││   - Transcription     │    │
│  │  - Text insertion     │││                       │    │
│  └───────────────────────┘│└───────────────────────┘    │
└─────────────────────────────────────────────────────────┘
```

## Requirements

- iOS 16.0+
- Xcode 15.0+
- Apple Developer Account (for testing on device)
- Google Gemini API Key (free at aistudio.google.com)

## Get Your API Key

1. Go to [Google AI Studio](https://aistudio.google.com/app/apikey)
2. Sign in with Google account
3. Click "Create API Key"
4. Copy and paste into VibeFlow app

The API is free with generous usage limits!

---

Built with SwiftUI + UIKit | Powered by Google Gemini
