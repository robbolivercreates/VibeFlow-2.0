# VoxAiGo Windows — Status de Paridade com macOS

> Atualizado: 2026-02-25 (sessão final)

## Projeto
- **Localização:** `/Users/robsonoliveira/Library/Mobile Documents/com~apple~CloudDocs/VideoCode2026/VoxAiGo-Windows/voxaigo-windows/`
- **Stack:** Tauri 2.0 (Rust) + React 18 + TypeScript + Tailwind CSS
- **Design System:** `src/theme.ts` — gold accent #D4AF37, bg #0A0A0A, surface #141414
- **TypeScript:** Compila com 0 erros (`npx tsc --noEmit`)

---

## PARIDADE COMPLETA — Funcionalidade (macOS ↔ Windows)

### Managers (TypeScript — src/managers/)
| Manager | macOS Equivalente | Status |
|---------|------------------|--------|
| `supabase.ts` | SupabaseService.swift + AuthManager.swift | DONE |
| `subscription.ts` | SubscriptionManager.swift | DONE (+ 48h grace + anti-tampering hash) |
| `settings.ts` | SettingsManager.swift | DONE |
| `history.ts` | HistoryManager.swift | DONE |
| `analytics.ts` | AnalyticsManager.swift | DONE (7 levels, 20 achievements) |
| `snippets.ts` | SnippetsManager.swift | DONE |
| `sounds.ts` | SoundManager.swift | DONE |
| `conversationReply.ts` | ConversationReplyManager.swift | DONE (state machine + 25s countdown) |
| `writingStyle.ts` | WritingStyleManager.swift | DONE (5 samples/mode, style prompt gen) |
| `localModeFormatter.ts` | LocalModeFormatter.swift | DONE (15 mode formatters + speech cleanup) |

### Views (React TSX — src/windows/)
| View | macOS Equivalente | Status |
|------|------------------|--------|
| `HUD.tsx` | ContentView.swift | DONE (capsule, waveform, golden glow, transform pill, offline badge) |
| `MainWindow.tsx` | MainWindowView.swift | DONE (6 sidebar sections + Dev Tools easter egg) |
| `Settings.tsx` | SettingsView.swift | DONE (8 tabs) |
| `History.tsx` | HistoryView.swift | DONE |
| `Login.tsx` | LoginView.swift | DONE (3-view: Sign In/Up/Reset + Google OAuth) |
| `Upgrade.tsx` | UpgradeModalView.swift | DONE (gold theme, correct pricing) |
| `SetupWizard.tsx` | SetupWizardView.swift | DONE (6 steps) |
| `TrialModals.tsx` | TrialViews.swift | DONE (4 modals: Welcome/Expired/Limit/Reminder) |
| `NotificationHUD.tsx` | LanguageNotificationView.swift | DONE (4 types, spring animation, 2s dismiss) |
| `ConversationReply.tsx` | ConversationReplyView.swift | DONE (4 states, countdown bar, language badges) |

### Rust Backend (src-tauri/src/)
| Module | macOS Equivalente | Status |
|--------|------------------|--------|
| `audio.rs` | AudioRecorder.swift | DONE (WASAPI recording + metering) |
| `shortcuts.rs` | AppDelegate shortcuts | DONE (Ctrl+Space hold-to-talk + 5 more) |
| `clipboard.rs` | ClipboardHelper.swift | DONE (auto-paste via enigo) |
| `device.rs` | DeviceIdentifier.swift | DONE (WMI SHA256 fingerprint) |
| `whisper.rs` | WhisperEngine.swift | DONE (whisper-rs offline) |
| `modes.rs` | TranscriptionMode.swift | DONE (15 modes) |
| `commands.rs` | Window management | DONE (18 commands including conversation-reply) |
| `lib.rs` | App entry + tray | DONE (tray menu, deep link handler) |

### Feature Parity Matrix
| Feature | macOS | Windows | Notes |
|---------|-------|---------|-------|
| Hold-to-talk | ⌥⌘ | Ctrl+Space | Platform-appropriate |
| Wake word detection | ✅ | ✅ | Same aliases, cycle, set mode/lang |
| Offline Whisper | ✅ | ✅ | whisper-rs (Windows) vs WhisperKit (macOS) |
| LocalModeFormatter | ✅ | ✅ | 15 mode formatters + speech cleanup |
| Writing style learning | ✅ | ✅ | 5 samples/mode, prompt injection |
| 48h grace period | ✅ | ✅ | Offline validation window |
| Anti-tampering hash | ✅ | ✅ | FNV-1a hash on whisper/trial counters |
| Dev Mode easter egg | ✅ | ✅ | Tap 5x → "voxdev" → Free/Trial/Pro |
| Dev Tools server sync | ✅ | ✅ | PATCH subscriptions table directly |
| Conversation Reply | ✅ | ✅ | 4-state HUD + 25s countdown |
| Transform mode | ✅ | ✅ | Purple gradient pill on HUD |
| Golden glow (AI active) | ✅ | ✅ | Gold box-shadow when Pro recording |
| Offline badge | ✅ | ✅ | Orange "OFFLINE" pill on HUD |
| Trial modals (4) | ✅ | ✅ | Welcome, Expired, Limit, Reminder |
| Notification HUDs (4) | ✅ | ✅ | Language, Mode, Paste, No History |
| Setup wizard (6 steps) | ✅ | ✅ | Interactive onboarding |
| Snippet expansion | ✅ | ✅ | :abbreviation: patterns |
| Analytics + achievements | ✅ | ✅ | 7 levels, 20 achievements |
| Feature gating | ✅ | ✅ | Free/Trial/Pro plan checks |
| Google OAuth | ✅ | ✅ | voxaigo://auth/callback |
| Magic Link auth | ✅ | ✅ | Via Supabase |
| System tray | ✅ | ✅ | Dynamic menu with plan status |
| Auto-paste | ✅ | ✅ | Ctrl+V simulation |
| History (50 items) | ✅ | ✅ | With search/copy/delete |

### Routes (14 total)
```
/                  → HUD (default)
/hud               → HUD (recording overlay)
/settings          → Settings (8-tab panel)
/main              → MainWindow (6-section sidebar hub)
/history           → History (50 items)
/login             → Login (3-view auth)
/upgrade           → Upgrade (paywall)
/wizard            → SetupWizard (6 steps)
/welcome-trial     → WelcomeTrialModal
/trial-expired     → TrialExpiredModal
/monthly-limit     → MonthlyLimitModal
/upgrade-reminder  → UpgradeReminderModal
/notification      → NotificationHUD (4 types)
/conversation-reply → ConversationReply (4-state HUD)
```

### Rust Commands Registered (18)
- Audio: `start_recording`, `stop_recording`, `get_audio_devices`, `get_audio_level`, `has_speech_detected`
- Clipboard: `save_previous_window`, `paste_to_previous_window`, `get_selected_text`
- Device: `get_device_id`
- Modes: `get_transcription_modes`
- Whisper: `check_whisper_model_status`, `download_whisper_model`, `delete_whisper_model`, `transcribe_offline`
- Windows: `show_hud`, `hide_hud`, `show_settings`, `show_main_window`, `show_history`, `show_login`, `show_upgrade`, `show_wizard`, `show_welcome_trial`, `show_trial_expired`, `show_monthly_limit`, `show_upgrade_reminder`, `show_notification_hud`, `show_conversation_reply`
- System: `update_tray_menu`, `open_url`

---

## Platform Differences (Intentional — Not Bugs)

| Aspect | macOS | Windows | Reason |
|--------|-------|---------|--------|
| Hold-to-talk key | ⌥⌘ (Option+Command) | Ctrl+Space | Platform convention |
| Cycle language | ⌃⇧L | Alt+L | Platform convention |
| Cycle mode | ⌃⇧M | Alt+M | Platform convention |
| Paste last | ⌃⇧V | Alt+P | Platform convention |
| Conversation reply | ⌃⇧R | Alt+R | Platform convention |
| UI Framework | SwiftUI native | React + Tailwind in WebView | Tauri architecture |
| Audio engine | AVFoundation | WASAPI (cpal crate) | OS audio API |
| Offline ASR | WhisperKit (CoreML) | whisper-rs (whisper.cpp) | Platform-specific ML |
| Window management | NSPanel/NSWindow | Tauri WebviewWindow | Framework |
| Persistence | UserDefaults | tauri-plugin-store (JSON) | Framework |
| Code signing | Apple Developer ID | Windows EV Certificate | Platform |

---

## Files Created/Modified (This Session)

### New Files
- `src/managers/conversationReply.ts` — State machine for Conversation Reply
- `src/managers/writingStyle.ts` — Writing Style Learning Manager
- `src/managers/localModeFormatter.ts` — 15 mode formatters for offline use
- `src/windows/ConversationReply.tsx` — Dedicated Conversation Reply HUD

### Modified Files
- `src/App.tsx` — Added `/conversation-reply` route
- `src/managers/subscription.ts` — Added 48h grace period + anti-tampering hash + recordWhisperTranscription/recordTrialTranscription
- `src/managers/supabase.ts` — Added `text_to_translate` and `detected_language/code` to interfaces; **BUG FIX (2026-03-01):** `isPro` check now accepts `"pro_monthly"` and `"pro_annual"` (not just `"pro"`) — was causing Pro users to be treated as free
- `src/windows/HUD.tsx` — Added golden glow, transform pill, offline badge, LocalModeFormatter + WritingStyle integration
- `src/windows/MainWindow.tsx` — Added Dev Mode easter egg + DevToolsSection
- `src-tauri/src/commands.rs` — Added `show_conversation_reply` command
- `src-tauri/src/lib.rs` — Registered `show_conversation_reply` in invoke_handler
