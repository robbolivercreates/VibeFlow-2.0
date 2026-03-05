# VoxAiGo — Complete Reference Guide

Complete documentation of VoxAiGo's behavior: plans, notifications, prompts,
recording flow, silence handling, and upgrade triggers.

---

## Table of Contents

1. [Plans & Pricing](#1-plans--pricing)
2. [Recording Flow: Press to Paste](#2-recording-flow-press-to-paste)
3. [State Timing & Transitions](#3-state-timing--transitions)
4. [Silence & Error Handling](#4-silence--error-handling)
5. [Visual Differences: Free vs Pro](#5-visual-differences-free-vs-pro)
6. [Sound Wave Visualization](#6-sound-wave-visualization)
7. [Upgrade Prompts & Triggers](#7-upgrade-prompts--triggers)
8. [Feature Gating (What's Locked)](#8-feature-gating-whats-locked)
9. [Transcription Modes & Prompts](#9-transcription-modes--prompts)
10. [Notification System & Sounds](#10-notification-system--sounds)
11. [Data Synchronization](#11-data-synchronization)
12. [Plan Transitions (Pro ↔ Free)](#12-plan-transitions-pro--free)
13. [Anti-Abuse & Security](#13-anti-abuse--security)

---

## 1. Plans & Pricing

### Free (Gratis)
| Spec | Value |
|---|---|
| Engine | Whisper local (offline, on-device) |
| Monthly limit | 75 transcriptions/month (resets automatically) |
| Modes | Text only (1 of 15) |
| Languages | Portuguese + English only (2 of 30) |
| AI features | None — raw transcription only |
| Wake word | Disabled |
| Cost | R$0 |

### Trial (7-day, ONE TIME per device)
| Spec | Value |
|---|---|
| Engine | Gemini 2.5 Flash (cloud via Supabase) |
| Limit | 50 transcriptions OR 7 days (whichever comes first) |
| Modes | All 15 AI modes |
| Languages | All 30 languages |
| Wake word | Enabled |
| Cost | Free |
| Device lock | SHA256 hardware fingerprint — prevents multi-account abuse |

### Pro
| Spec | Value |
|---|---|
| Engine | Gemini 2.5 Flash (cloud via Supabase) |
| Limit | Unlimited |
| Modes | All 15 AI modes |
| Languages | All 30 languages |
| Wake word | Enabled |
| Monthly | R$29,90/month |
| Annual | R$268,80/year (R$22,40/month — 25% discount) |
| Server check | Must validate online every 48 hours |

### Summary Table

| Feature | Free | Trial | Pro |
|---|---|---|---|
| Engine | Whisper local | Gemini cloud | Gemini cloud |
| Limit | 75/month | 50 total (7 days) | Unlimited |
| Modes | Text (1) | All 15 | All 15 |
| Languages | PT + EN (2) | All 30 | All 30 |
| Wake word | No | Yes | Yes |
| AI formatting | No | Yes | Yes |

---

## 2. Recording Flow: Press to Paste

### Complete Timeline (Hold-to-Talk)

```
USER HOLDS Option+Command
│
├─ 1. Sound: "Pop" (start feedback)
├─ 2. Save previous foreground app (for paste-back)
├─ 3. Show recording HUD (lower 25% of screen)
├─ 4. Start microphone recording (M4A, 44.1kHz, mono)
├─ 5. Audio level monitoring begins (every 30ms)
│     └─ If level > 0.02 → speechDetected = true (sticky)
│     └─ Waveform animates in real-time
│
│  [USER IS SPEAKING...]
│
USER RELEASES Option+Command
│
├─ 6. Sound: "Funk" (stop feedback)
├─ 7. Stop recording
├─ 8. VALIDATE recording:
│     ├─ Duration >= 0.5 seconds? (filters accidental taps)
│     └─ speechDetected == true? (audio ever exceeded threshold)
│
├── IF INVALID (silence or too short):
│   ├─ HUD closes immediately
│   ├─ No sound, no error
│   └─ DONE — nothing happens
│
├── IF VALID:
│   ├─ 9. HUD shows "Processing..."
│   ├─ 10. Select transcription service:
│   │      ├─ Pro/Trial → Supabase (Gemini cloud)
│   │      ├─ Free → Whisper local
│   │      └─ BYOK → Direct Gemini API
│   │
│   ├─ 11. Transcribe audio with selected service
│   ├─ 12. Check for wake word command:
│   │      ├─ "Vox, email" → switch mode, show HUD, NO PASTE
│   │      ├─ "Vox, inglês" → switch language, show HUD, NO PASTE
│   │      └─ Normal text → continue to paste
│   │
│   ├─ 13. Expand snippets (text shortcuts)
│   ├─ 14. Copy text to clipboard
│   ├─ 15. Auto-paste to previous app (key simulation)
│   ├─ 16. Sound: "Glass" (success)
│   ├─ 17. HUD shows "Pasted!" for 2 seconds
│   ├─ 18. Save to history
│   └─ 19. HUD closes
│
DONE — text appears where user was typing
```

### State Machine

```
  IDLE ──[⌥⌘ pressed]──► RECORDING ──[⌥⌘ released]──► VALIDATE
                              │                            │
                              │                       ┌────┴────┐
                              │                    INVALID    VALID
                              │                       │         │
                              │                    CLOSE     PROCESSING
                              │                    (silent)     │
                              │                           ┌────┴────┐
                              │                        ERROR    SUCCESS
                              │                           │         │
                              │                        SHOW ERR   PASTE
                              │                        (3 sec)   "Pasted!"
                              │                           │      (2 sec)
                              │                           └────┬────┘
                              │                                │
                              └────────────────────────────── IDLE
```

---

## 3. State Timing & Transitions

### Exact Duration of Each State

| State | Text Shown (Free) | Text Shown (Pro/Trial) | Duration | Next State |
|---|---|---|---|---|
| **Idle** | "Segure ⌥⌘" | "Segure ⌥⌘" | Until user presses shortcut | Listening |
| **Listening** | "Ouvindo..." | "Vox ouvindo..." | While user holds keys | Validate |
| **Processing** | "Processando..." | "Vox processando..." | 0.5-2s (Whisper) / 2-5s (Gemini) | Pasted or Error |
| **Pasted** | "Colado!" | "Colado!" | Exactly 2 seconds | Ready |
| **Error** | Error message | Error message | Exactly 3 seconds | HUD closes |
| **Ready** | "Pronto" | "Pronto" | 0.5s then HUD closes | Idle |

### Complete Timeline Example (Pro User)

```
T+0.00s   User presses ⌥⌘
          → Sound: "Pop"
          → HUD appears: "Vox ouvindo..." (gold text, golden glow)
          → Waveform animates at 440Hz

T+2.50s   User releases ⌥⌘
          → Sound: "Funk"
          → Validate: duration OK, speech detected
          → HUD shows: "Vox processando..." (spinning sparkle icon)
          → Waveform slows to 220Hz

T+2.50-5.50s  API call to Gemini (2-5 seconds typical)

T+5.50s   Transcription returns
          → Text copied to clipboard
          → Auto-pasted to previous app
          → Sound: "Glass"
          → HUD shows: "✓ Colado!" (green checkmark)

T+7.50s   Status resets to "Pronto" (2 seconds after pasted)

T+8.00s   HUD closes (0.5s extra grace period)
```

### Processing Duration by Engine

| Engine | Typical Latency | Why |
|---|---|---|
| Whisper local (Free) | 0.5-2 seconds | On-device Neural Engine, no network |
| Gemini via Supabase (Pro/Trial) | 2-5 seconds | Network upload + Gemini processing + response |
| Gemini BYOK | 2-5 seconds | Direct API, similar to Supabase |

### Debounce Intervals (Prevents Double-Tap)

| Shortcut | Debounce | Purpose |
|---|---|---|
| ⌃⇧L (Language cycle) | 300ms | Prevents accidental double-switch |
| ⌃⇧M (Mode cycle) | 300ms | Same |
| ⌃⇧V (Paste last) | 500ms | Prevents double-paste |
| ⌃⇇R (Conversation Reply) | 500ms | Same |

### HUD Auto-Close Delays

| Event | Delay Before Close |
|---|---|
| Transcription success | 2s "Pasted" + 0.5s grace = **2.5s total** |
| Error (any) | **3 seconds** (error message visible) |
| Silence (no speech) | **Immediate** (no delay, silent close) |
| Too short (<0.5s) | **Immediate** (no delay, silent close) |
| Notification HUDs (Language/Mode/Wake Word/Paste) | **2 seconds** + 0.3s fade-out |
| Notification HUDs (Dev freeze mode) | **30 seconds** + 0.3s fade-out |

### Animation Durations

| Animation | Duration | Easing |
|---|---|---|
| HUD notification fade-out | 0.3s | ease-in |
| HUD notification appear (spring) | 0.45s | spring (damping 0.65) |
| Conversation Reply slide-in | 0.28s | ease-out |
| Conversation Reply dismiss | 0.22s | ease-in |
| Conversation Reply resize | 0.22s | ease-in-out |
| Recording HUD expand (idle→listening) | 0.4s | spring |
| Mic glow breathing pulse | 1.2s | ease-in-out (infinite) |
| Processing sparkle rotation | 2.0s | linear (infinite) |
| Waveform spring response | 0.15s | spring (damping 0.5) |
| Speech color transition (white→red) | 0.3s | ease-in-out |

---

## 4. Silence & Error Handling

### Silence Detection

| Parameter | Value | Purpose |
|---|---|---|
| Speech threshold | 0.02 (normalized 0-1) | Very sensitive — catches whispers |
| Min. recording duration | 0.5 seconds | Filters accidental tap-and-release |
| Level update interval | 30ms | Smooth, responsive waveform |
| Smoothing factor | 0.4 | Fast reaction to voice changes |

**How it works:**
- Audio level is measured continuously during recording
- If level EVER exceeds 0.02 → `speechDetected = true` (never resets during that recording)
- When user releases the shortcut, both checks run:
  - Was recording >= 0.5 seconds?
  - Was speech detected?
- If BOTH fail → recording is silently discarded, HUD closes, nothing happens
- There is NO automatic timeout — app waits for user to release the shortcut

### Error Scenarios

| Scenario | What Happens | HUD Behavior |
|---|---|---|
| User pressed but didn't speak | `speechDetected = false` | Closes silently (no error, no sound) |
| Recording too short (<0.5s) | `isRecordingValid() = false` | Closes silently |
| Microphone permission denied | Error message shown | Shows error 3 seconds, then closes |
| Network error (Pro/Trial) | API call fails | Shows error 3 seconds, then closes |
| Whisper model not ready | Transcription blocked | Shows loading state |
| Empty transcription result | No text returned | Shows "No text detected" error |
| Free monthly limit reached (75) | Recording blocked before starting | Shows Monthly Limit modal |
| Trial limit reached (50) | Trial expires | Shows Trial Expired modal |
| Online validation expired (>48h) | Recording blocked | Shows "Internet required" error |
| Pro-only mode selected by free user | Recording blocked | Shows Upgrade modal |

### Fallback Mechanism
- If Supabase API fails AND user has a BYOK API key → automatically falls back to direct Gemini
- Prevents losing the transcription on network issues

---

## 5. Visual Differences: Free vs Pro

The recording HUD looks DIFFERENT depending on the user's plan. The key variable
is `isVoxActive` which is `true` for Pro/Trial users and `false` for Free users.

### Quick Comparison Table

| Visual Element | Free User | Pro/Trial User |
|---|---|---|
| **Listening text** | "Ouvindo..." (white) | **"Vox ouvindo..."** (gold) |
| **Processing text** | "Processando..." (white) | **"Vox processando..."** (gold) |
| **Microphone glow** | No glow circle | **Golden glow circle (40px, breathing pulse 1.2s)** |
| **Container border** | White border (1px, subtle) | **Gold gradient border (1.5px, glowing)** |
| **Container shadow** | None | **Gold shadow (12px blur, 0.2 opacity)** |
| **Waveform color (quiet)** | White/gold | White/gold |
| **Waveform color (speaking)** | White/gold (no change) | **RED (0.95, 0.25, 0.25)** |
| **Processing icon** | Gold sparkle (spinning) | Gold sparkle (spinning) |
| **Success text** | "✓ Colado!" (green) | "✓ Colado!" (green) |

### The Golden Glow (Pro/Trial Only)

When a Pro/Trial user is recording, three golden effects activate simultaneously:

**1. Microphone Glow Circle (40px diameter)**
```
Color: VoxTheme.accent (gold, #FFD700)
Size: 40x40 px circle behind mic icon
Shadow: two layers:
  - Inner: gold at 50% opacity, 10px blur
  - Outer: gold at 25% opacity, 20px blur
Animation: breathing pulse (ease-in-out, 1.2s, infinite)
  - Quiet: opacity 0.8
  - Speaking: opacity 0.5 (pulsing)
  - Idle: opacity 0.4 (very subtle)
```

**2. Container Border Glow**
```
Pro:  Gold gradient (top-left 40% opacity → bottom-right 10% opacity), 1.5px
Free: White gradient (top 15% opacity → bottom 2% opacity), 1px
```

**3. Container Shadow**
```
Pro:  Gold shadow, 12px blur radius, 20% opacity (golden aura around HUD)
Free: No shadow (transparent)
```

### "Vox Ouvindo" vs "Ouvindo"

| Language | Free Text | Pro Text |
|---|---|---|
| Portuguese | "Ouvindo..." | "Vox ouvindo..." |
| English | "Listening..." | "Vox listening..." |
| Spanish | "Escuchando..." | "Vox escuchando..." |

The Pro text uses **gold color** (`VoxTheme.accent`).
The Free text uses **white** (90% opacity).

This visual distinction makes it immediately clear whether the user is getting
AI-powered transcription (Gemini) or basic local transcription (Whisper).

### HUD Size by State

| State | Width | Height |
|---|---|---|
| Idle | 200px | 56px |
| Listening | 440px | 56px |
| Processing | 220px | 56px |

The HUD animates smoothly between sizes with a 0.4s spring animation.

---

## 6. Sound Wave Visualization

### How the Waveform Works

The waveform uses two layered organic sine waves that react to the microphone audio level in real-time.

**Architecture:**
```
┌─ Background wave (90x36px, blurred, softer)
└─ Foreground wave (80x28px, sharp, prominent)
```

### Wave Shape Algorithm

Each wave is a **sinusoidal curve** with:

```
Amplitude = minAmplitude + (maxAmplitude - minAmplitude) × audioLevel × 1.5
Where:
  minAmplitude = 2px (even when silent — subtle idle motion)
  maxAmplitude = height/2 = 14px (at peak voice)
  audioLevel = 0.0 to 1.0 (from microphone)

Shape: sin(x × π × frequency + phase) × amplitude × taper
Where:
  taper = bell curve (sin(x × π)) — softens edges
  frequency = 1.5Hz (background) / 2.0Hz (foreground)
  phase = random when speaking, 0 when quiet
```

### Color Behavior

| Condition | Color | When |
|---|---|---|
| Quiet (level ≤ 0.05) | White/gold | Always, both Free and Pro |
| Speaking (level > 0.05) — FREE | White/gold (no change) | Free users don't get red |
| Speaking (level > 0.05) — PRO | **RED (#F24040)** | Pro/Trial users see red waves |

The speech visual threshold (0.05) is higher than the detection threshold (0.02),
so waves stay white briefly before turning red.

### Animation Parameters

```
Wave response:     0.15s spring (damping 0.5) — fast, snappy reaction to voice
Color transition:  0.3s ease-in-out — smooth white→red change
Background wave:   2px blur for soft, ethereal effect
Foreground wave:   no blur, crisp lines
```

### Waveform Frequency by State

| State | Frequency | Visual Effect |
|---|---|---|
| Listening | 440Hz | Active, responsive waves |
| Processing | 220Hz | Slower, calmer waves (AI thinking) |
| Idle | Hidden | Waveform not visible |

### Visual Reference

```
Silent (Free or Pro):
   ──────~~~~~──────     White, minimal movement

Speaking (Free):
   ──~~╱╲╱╲╱╲~~──       White, same color, bigger amplitude

Speaking (Pro):
   ──~~╱╲╱╲╱╲~~──       RED waves, golden glow around mic
   ✨ golden border ✨    Gold container border + shadow
```

---

## 7. Upgrade Prompts & Triggers

### A. Welcome Trial Modal (420x560 px)

**When:** Immediately after first account creation (1.5s delay)
**Trigger:** `TrialManager.autoStartTrialIfEligible()` → posts `.showWelcomeTrial`
**Shows once:** Yes — only on first signup
**Content:** Welcome message, trial benefits (7 days, 50 transcriptions, all modes), pricing preview
**User action:** Dismiss to start trial

### B. Soft Upgrade Reminder (420x520 px)

**When:** Every 15 free Whisper transcriptions (at 15, 30, 45, 60)
**Trigger:** `whisperTranscriptionsUsed % 15 == 0` (only for free users, not during trial)
**Blocks recording:** NO — soft nudge, dismissible
**Content:** Progress bar "Used X of 75", pricing toggle (monthly/annual), dismiss button
**Notification:** `.showUpgradeReminder`

### C. Monthly Limit Modal (440x560 px)

**When:** Free user reaches 75 Whisper transcriptions in a month
**Trigger:** `subscription.hasReachedWhisperLimit` check before recording starts
**Blocks recording:** YES — cannot record until next month or upgrade
**Content:** Limit reached message, usage stats, two options: wait for reset OR upgrade
**Notification:** `.showMonthlyLimit`

### D. Trial Expired Modal (440x620 px)

**When:** Trial ends (7 days elapsed OR 50 transcriptions used)
**Trigger:** On app launch, checked by `checkTrialExpiredOnLaunch()` (2s after launch)
**Shows once:** Yes — tracked by UserDefaults flag `trial_expired_shown`
**Content:** What's lost (AI modes, languages, wake word), upgrade CTA, "Continue without AI" dismiss
**Auto-downgrade:** Forces mode to Text, language to Portuguese, disables wake word
**Notification:** `.showTrialExpired`

### E. Contextual Upgrade Modal (420x520 px)

**When:** Free user tries a Pro-only feature:
- Selects a locked mode from menu bar (any mode except Text)
- Selects a locked language from menu bar (any language except PT/EN)
- Tries to use wake word command
**Blocks action:** YES — feature doesn't activate
**Content:** Shows exactly which feature was attempted, what Pro unlocks
**Notification:** `.showUpgradePrompt` or `.wakeWordProLocked`

### Timeline of a Free User's Journey

```
Signup
  │
  ├─ [Immediately] Welcome Trial modal (7 days start)
  │
  │  TRIAL PERIOD (7 days or 50 transcriptions)
  │  ├─ All 15 modes, 30 languages, wake word, AI
  │  └─ Counter: 1/50, 2/50, ..., 50/50
  │
  ├─ [Trial expires] Trial Expired modal (shown once)
  │   └─ Forced downgrade: Text mode, PT+EN, no wake word
  │
  │  FREE PERIOD (75 Whisper/month, Text only)
  │  ├─ Transcription 15 → Soft reminder (dismissible)
  │  ├─ Transcription 30 → Soft reminder
  │  ├─ Transcription 45 → Soft reminder
  │  ├─ Transcription 60 → Soft reminder
  │  ├─ Transcription 75 → BLOCKED — Monthly Limit modal
  │  └─ [Next month] Counter resets to 0
  │
  │  At any time:
  │  ├─ Click locked mode → Contextual Upgrade modal
  │  ├─ Click locked language → Contextual Upgrade modal
  │  └─ Try wake word → Wake Word Pro Locked modal
  │
  └─ [Upgrade to Pro] → Unlimited, all features
```

---

## 8. Feature Gating (What's Locked)

### Mode Gating

```
canUseMode(mode) = isPro || isTrialActive || mode == .text
```

- Free users: ONLY Text mode
- Menu bar shows lock icon (◆) next to Pro-only modes
- Clicking a locked mode → Contextual Upgrade modal (doesn't switch)

### Language Gating

```
canUseLanguage(language) = isPro || isTrialActive || language ∈ [.portuguese, .english]
```

- Free users: ONLY Portuguese and English
- Menu bar shows lock icon next to Pro-only languages
- Clicking a locked language → Contextual Upgrade modal

### Wake Word Gating

- Free/expired users: wake word is auto-disabled in `enforceFreeTierDefaults()`
- If a free user somehow triggers a wake word → shows upgrade modal
- Re-enabled automatically when trial starts or Pro activates

### Online Validation (Pro/Trial)

- Must connect to Supabase server at least every 48 hours
- If 48h pass without validation → `needsOnlineValidation = true`
- Recording is blocked until online check succeeds
- Grace period prevents intermittent network issues from blocking users

---

## 9. Transcription Modes & Prompts

All modes share these universal rules applied to EVERY transcription:

### Universal Speech Cleanup (applied to all modes)
- **English fillers removed:** "uh", "um", "ah", "er", "hmm", "hm", "huh", "eh"
- **Portuguese fillers removed:** "e...", "entao", "tipo", "ne", "assim", "bem", "ahn", "ee"
- **Verbal pauses removed:** "so...", "well...", "like...", "you know..."
- **False starts resolved:** "I want to- I need to" → "I need to"
- **Repetitions collapsed:** "the the" → "the"
- **Stutters cleaned:** "c-can you" → "can you"
- **Self-corrections:** Uses LAST correction ("X, no wait, Y" → "Y")

### Universal Wake Word Passthrough (HIGHEST PRIORITY)
If audio starts with "Vox" (or variant) → return EXACTLY as spoken.
No translation, no formatting, no cleanup. Overrides ALL other rules.

---

### Mode 1: Text
| Spec | Value |
|---|---|
| Icon | `text.alignleft` |
| Temperature | 0.3 |
| Max tokens | 2048 |
| Plan | Free + Pro |

**What it does:** Clean, well-formatted text transcription. Fixes grammar, punctuation, removes fillers.

**Input:** "um, tipo, eu queria escrever uma mensagem para o Joao, sabe, sobre aquela reuniao, ne, de amanha"
**Output:** "Eu gostaria de escrever uma mensagem para o Joao sobre a reuniao de amanha."

---

### Mode 2: Chat
| Spec | Value |
|---|---|
| Icon | `bubble.fill` |
| Temperature | 0.4 |
| Max tokens | 2048 |
| Plan | Free + Pro |

**What it does:** Quick, casual messages for WhatsApp/Slack. Keeps informal tone, only removes disfluencies.

**Input:** "oi Maria, sabe, tipo, voce consegue vir amanha?"
**Output:** "Oi Maria, voce consegue vir amanha?"

---

### Mode 3: Code
| Spec | Value |
|---|---|
| Icon | `chevron.left.forwardslash.chevron.right` |
| Temperature | 0.1 (very deterministic) |
| Max tokens | 4096 |
| Plan | Free + Pro |

**What it does:** Converts natural language descriptions into code. Returns ONLY code, no explanations, no markdown.

**Input:** "funcao em Swift que retorna o quadrado de um numero"
**Output:** `func square(_ number: Int) -> Int { return number * number }`

**Rules:** Uses mentioned language or defaults to Swift. Follows conventions. No comments unless complex logic.

---

### Mode 4: Vibe Coder
| Spec | Value |
|---|---|
| Icon | `wand.and.stars` |
| Temperature | 0.3 |
| Max tokens | 1024 |
| Plan | Free + Pro |

**What it does:** Extracts the essence of your speech into a clean, concise prompt for AI coding tools (Claude, Cursor, Copilot). Saves tokens.

**Input:** "eu queria, tipo, uma funcao que, sabe, ordena um array em ordem crescente"
**Output:** "Funcao que ordena um array em ordem crescente"

**Critical rules:**
- Question → stays as question (NEVER becomes imperative)
- Instruction → concise instruction
- Observation → clean observation
- Preserves ALL technical terms

---

### Mode 5: Email
| Spec | Value |
|---|---|
| Icon | `envelope.fill` |
| Temperature | 0.2 |
| Max tokens | 2048 |
| Plan | Free + Pro |

**What it does:** Formats speech as a professional, well-structured email with proper greeting, paragraphs, and sign-off.

**Input:** "email para o Joao, ola, gostaria de confirmar a reuniao de amanha as duas da tarde"
**Output:**
```
Ola Joao,

Gostaria de confirmar a reuniao de amanha as 14h.

Abracos
```

---

### Mode 6: Formal
| Spec | Value |
|---|---|
| Icon | `building.2.fill` |
| Temperature | 0.2 |
| Max tokens | 2048 |
| Plan | Free + Pro |

**What it does:** Transforms casual speech into formal, corporate-ready text. Replaces colloquialisms with formal equivalents.

**Input:** "tipo, a gente ta precisando melhorar a comunicacao com os clientes"
**Output:** "E necessario aprimorar a comunicacao com os clientes."

**Rules:** "a gente" → "nos", "pra" → "para", "ta" → "esta". Uses formal connectives.

---

### Mode 7: Social
| Spec | Value |
|---|---|
| Icon | `megaphone.fill` |
| Temperature | 0.5 (creative) |
| Max tokens | 2048 |
| Plan | Free + Pro |

**What it does:** Creates engaging social media posts using IMC framework (Impact, Method, Call). For Instagram/LinkedIn.

**Input:** "eu queria falar sobre como economizar tempo com voz"
**Output:**
```
Quanto tempo voce gasta digitando? 🎙️

Com VoxAiGo, voce transcreve codigo, emails e textos por voz.
Resultado? Menos digitacao, mais produtividade.

E voce, ja testou? ✨
```

**Rules:** Max 2 emojis. No hashtags. Strong opening hook.

---

### Mode 8: X/Tweet
| Spec | Value |
|---|---|
| Icon | `at` |
| Temperature | 0.5 |
| Max tokens | 512 (strict — 280 chars) |
| Plan | Free + Pro |

**What it does:** Creates tweets optimized for X/Twitter. Max 280 characters. Punchy, direct.

**Input:** "voce ja tentou escrever codigo so com a voz?"
**Output:** "Escrever codigo falando e mais rapido que digitando 🎙️"

**Rules:** Max 1 emoji or none. No hashtags. 280 character hard limit.

---

### Mode 9: Summary
| Spec | Value |
|---|---|
| Icon | `doc.text` |
| Temperature | 0.3 |
| Max tokens | 2048 |
| Plan | Free + Pro |

**What it does:** Summarizes speech to 20-30% of original content. Prioritizes decisions, numbers, dates, actions.

**Input:** "Entao, hoje tivemos uma reuniao com o cliente sobre o projeto novo, e ele gostou da proposta, e vamos comecar no proximo mes, e o orcamento foi aprovado, tipo, cinquenta mil reais"
**Output:**
```
Cliente aprovou proposta do novo projeto.
Inicio: proximo mes
Orcamento: R$50.000
```

---

### Mode 10: Topics
| Spec | Value |
|---|---|
| Icon | `list.bullet` |
| Temperature | 0.2 |
| Max tokens | 2048 |
| Plan | Free + Pro |

**What it does:** Organizes speech into clean bullet point lists with automatic grouping.

**Input:** "entao, primeira coisa, preciso comprar leite, pao, e ovos, e tambem preciso fazer a limpeza, limpar o quarto e a cozinha"
**Output:**
```
• Compras
  ◦ Leite
  ◦ Pao
  ◦ Ovos
• Limpeza
  ◦ Quarto
  ◦ Cozinha
```

---

### Mode 11: Meeting
| Spec | Value |
|---|---|
| Icon | `person.3.fill` |
| Temperature | 0.3 |
| Max tokens | 2048 |
| Plan | Free + Pro |

**What it does:** Structures speech as professional meeting minutes with participants, topics, decisions, and action items.

**Input:** "Reuniao com Joao e Maria sobre o projeto. Decidimos fazer o MVP em duas semanas. Eu vou criar o backend, Joao faz o frontend, Maria coordena."
**Output:**
```
PARTICIPANTES: Joao, Maria

ASSUNTOS DISCUTIDOS:
• Projeto MVP

DECISOES:
• Entregar MVP em 2 semanas

ACOES / PROXIMOS PASSOS:
• Criar backend — Responsavel: [Voce]
• Frontend — Responsavel: Joao
• Coordenacao — Responsavel: Maria
```

---

### Mode 12: UX Design
| Spec | Value |
|---|---|
| Icon | `paintbrush.pointed` |
| Temperature | 0.5 |
| Max tokens | 2048 |
| Plan | Free + Pro |

**What it does:** Formats speech as UX documentation — screens, components, user flows, design specs.

**Input:** "Tela de login com campo de email, senha, um botao azul de login, e um link para recuperar senha"
**Output:**
```
Tela de Login

Componentes:
• Campo de email
• Campo de senha
• Button "Login" (azul)
• Link "Recuperar senha"

Fluxo:
1. Usuario insere email
2. Usuario insere senha
3. Click no Button "Login"
```

---

### Mode 13: Translation
| Spec | Value |
|---|---|
| Icon | `bubble.left.and.bubble.right.fill` |
| Temperature | 0.2 (low — accuracy matters) |
| Max tokens | 4096 |
| Plan | Free + Pro |

**What it does:** Auto-detects input language and translates to the selected output language. Returns ONLY the translation.

**Input (Portuguese):** "Ola, como voce esta? Tudo bem com voce?"
**Output (English):** "Hello, how are you? Is everything okay with you?"

**Note:** Triggered via UI only — not available as a wake word command.

---

### Mode 14: Creative
| Spec | Value |
|---|---|
| Icon | `paintpalette.fill` |
| Temperature | 0.7 (high creativity) |
| Max tokens | 2048 |
| Plan | Free + Pro |

**What it does:** Transforms speech into creative, narrative text with rich language and storytelling elements.

**Input:** "A reuniao foi legal, tinham varias pessoas, discutimos o projeto novo"
**Output:** "A reuniao transcorreu em um clima de entusiasmo. Diversas vozes se uniram na discussao sobre o projeto que promete transformar nossa abordagem..."

---

### Mode 15: Custom
| Spec | Value |
|---|---|
| Icon | `slider.horizontal.3` |
| Temperature | 0.4 |
| Max tokens | 2048 |
| Plan | Free + Pro |

**What it does:** User defines their own prompt in Settings. The AI follows those custom instructions.

**Example custom prompt:** "Format as a haiku"
**Input:** "The sun rises over the mountains in the morning"
**Output:**
```
Sol na montanha
Raios dourados brilham
Novo dia nasce
```

---

### Mode Temperature Reference

| Temperature | Modes | Behavior |
|---|---|---|
| 0.1 | Code | Most deterministic, exact output |
| 0.2 | Email, Formal, Topics, Translation | Professional precision |
| 0.3 | Text, Summary, Vibe Coder, Meeting | Balanced |
| 0.4 | Chat, Custom | Natural variation |
| 0.5 | Social, UX Design, X/Tweet | Creative freedom |
| 0.7 | Creative | Maximum variation for storytelling |

---

## 10. Notification System & Sounds

### Sound Effects

| Event | Sound | When |
|---|---|---|
| Start recording | Pop | User holds Option+Command |
| Stop recording | Funk | User releases keys |
| Transcription success | Glass | After paste completes |
| Error/blocked | Basso | Auth required, limit reached |
| Wake word command | Glass | Mode or language switched |
| Language cycle (⌃⇧L) | Glass | Language changed |
| Mode cycle (⌃⇧M) | Glass | Mode changed |
| Paste last (⌃⇧V) | Glass (or Basso) | Success or empty history |

**Master control:** `SettingsManager.enableSounds` — if false, all sounds are muted.

### NotificationCenter Events (26 total)

| # | Event | Trigger | Action |
|---|---|---|---|
| 1 | `.modeChanged` | Mode selected | Refresh menu bar |
| 2 | `.languageChanged` | Language selected | Refresh menu bar |
| 3 | `.transcriptionComplete` | Transcription done | Save history, play sound, close HUD |
| 4 | `.recordingCancelled` | No speech / blocked | Close HUD (delayed if error) |
| 5 | `.authStateChanged` | Login / logout | Update menu; close all windows on logout |
| 6 | `.subscriptionChanged` | Plan change / sync | Update menu bar counter |
| 7 | `.offlineModeChanged` | Offline toggle | Update menu |
| 8 | `.wakeWordCommand` | Voice command detected | Show wake word HUD (2s) |
| 9 | `.wakeWordProLocked` | Free user tries wake word | Show upgrade modal |
| 10 | `.showWelcomeTrial` | Trial started | Show Welcome Trial modal |
| 11 | `.showTrialExpired` | Trial expired (app launch) | Show Trial Expired modal |
| 12 | `.showUpgradePrompt` | Generic upgrade trigger | Show upgrade modal |
| 13 | `.showUpgradeReminder` | Every 15 Whisper transcriptions | Show soft reminder |
| 14 | `.showMonthlyLimit` | 75 free transcriptions reached | Show monthly limit modal |
| 15 | `.openSetupWizard` | User resets wizard | Show setup wizard |
| 16 | `.conversationReplyTimedOut` | 25s countdown expires | Dismiss conversation HUD |
| 17-22 | `.devPreview*` | Dev tools buttons | Show individual HUDs for screenshots |

### Menu Bar Real-Time Counter

The menu bar updates after EVERY transcription:

```
Pro:           (no indicator — just email)
Trial active:  "— Pro Trial: 5d (18/50)"
Free:          "— Gratis: 23/75"
Free (limit):  "— Gratis: limite atingido"
```

---

## 11. Data Synchronization

### How Usage Data Syncs Between App and Supabase

The app uses a **multi-layer sync system** to keep usage data accurate and tamper-resistant.

#### Sync Triggers

| Trigger | What Syncs | Direction |
|---|---|---|
| App launch (auth completes) | Profile + Whisper counter + Cloud stats | Server → App |
| Every 5 minutes (periodic timer) | Profile + Whisper counter + Cloud stats | Bidirectional |
| After EACH transcription | Whisper counter (background, non-blocking) | App → Server |
| Dev Tools plan change | Profile + counter | App → Server → App |
| User clicks "Verify Purchase" | Subscription status | Server → App |

#### Profile Fetch (`fetchProfile()`)

On every sync cycle, the app fetches from Supabase `profiles` table:
- `plan` (free / pro)
- `subscription_status` (active / inactive / cancelled / expired)
- `free_transcriptions_used` (server-side counter)
- `free_transcriptions_reset_at` (next reset date)

After receiving the profile:
1. Marks online validation as successful (resets 48h grace period)
2. Calls `enforceFreeTierDefaults()` — auto-downgrades features if not Pro
3. Posts `.subscriptionChanged` notification — menu bar updates immediately

#### Whisper Counter Bidirectional Sync

The free Whisper transcription counter uses a **MAX(local, server)** strategy
to prevent reinstall exploits:

```
localCount  = UserDefaults counter (on device)
serverCount = profiles.free_transcriptions_used (on Supabase)
syncedCount = MAX(localCount, serverCount)
```

| Scenario | Action | Why |
|---|---|---|
| Server > Local | Pull server count down to local | User synced from another device or reinstalled |
| Local > Server | PATCH server with local count | User transcribed offline |
| Equal | No-op | Already in sync |

This runs after every `fetchProfile()` and after each Whisper transcription.

#### Cloud Stats (Dashboard Data)

Every 5 minutes, the app also fetches from `usage_log` table:
- **Total transcriptions** (all time) — parsed from Content-Range header
- **Total recording seconds** — summed from `audio_duration_seconds` column

These are stored in `@Published cloudTotalTranscriptions` and `cloudTotalRecordingSeconds`
for display in the Account view.

### What the User Sees (Settings / Account / Menu Bar)

#### Menu Bar Counter (real-time)

Updates instantly after EVERY transcription via `.subscriptionChanged` notification:

```
Pro user:            robson@email.com
Trial active:        robson@email.com — Pro Trial: 5d (18/50)
Free user:           robson@email.com — Grátis: 23/75
Free (limit hit):    robson@email.com — Grátis: limite atingido
```

#### Account View (Settings → Account)

For Free/Trial users, shows a "Usage This Month" section:

**Trial users see:**
- "Trial Pro" badge
- Days remaining: "5 dias restantes"
- Progress bar: 18/50 transcriptions used
- Visual progress: ████████░░░░░░░ 36%

**Free users see:**
- Whisper transcriptions used: "23 / 75"
- Progress bar with visual fill
- Remaining count: "52 transcrições restantes"
- If limit reached: warning message in red

**Pro users:** No usage section shown (unlimited).

#### Dev Tools Status Panel

In Dev Mode (tap version 5x, enter "voxdev"), detailed sync status:

```
isPro (effective):    YES / NO
Trial:               active (5d, 18/50) / expired
Online Validation:   OK (2h 15m ago, 45h left) / EXPIRED
Free tx used:        23/75
Trial tx used:       18/50
```

---

## 12. Plan Transitions (Pro ↔ Free)

### Free → Pro (User Purchases)

Three activation paths ensure no purchase is ever lost:

**Path A: Webhook Activation (instant, most common)**
1. User completes checkout on Eduzz
2. Eduzz sends webhook to `/webhook-eduzz` edge function
3. Edge function creates subscription row in `subscriptions` table
4. Updates `profiles`: `plan = 'pro'`, `subscription_status = 'active'`
5. Next `fetchProfile()` (within 5 minutes) → app unlocks Pro features

**Path B: Pending Purchase (user bought before signing up)**
1. User completes checkout but doesn't have an account yet
2. Webhook saves to `pending_purchases` table with status `'pending'`
3. When user later signs up with the same email → auto-activates
4. Pending purchase marked as `'claimed'`

**Path C: Manual Verification (fallback)**
1. User clicks "Verify Purchase" in Settings
2. App calls `/verify-purchase` edge function
3. Edge function queries Eduzz API for active sales
4. If found → creates subscription and upgrades profile
5. If not on Eduzz → checks `pending_purchases` table

### Pro → Free (Subscription Expires)

Two safety nets ensure no user keeps Pro access after expiring:

**Layer 1: Webhook-Driven Downgrade (real-time)**
1. Eduzz sends cancellation/refund/expiration webhook (status 4, 6, or 7)
2. `/webhook-eduzz` edge function:
   - Marks subscription as `'cancelled'` or `'expired'`
   - Sets profile: `plan = 'free'`, `subscription_status = 'cancelled'`
   - Resets `free_transcriptions_used = 0` (fresh start on free tier)
   - Sets `free_transcriptions_reset_at = now + 30 days`

**Layer 2: pg_cron Safety Net (every 6 hours)**
1. Cron job `downgrade-expired-subscriptions` runs at `0 */6 * * *`
2. Finds Pro users where subscription is missing, expired, or cancelled
3. Downgrades profile: `plan = 'free'`, `subscription_status = 'expired'`
4. Catches any webhooks that failed or were delayed

### Client-Side Enforcement (`enforceFreeTierDefaults()`)

When the app detects the user is no longer Pro (and trial is not active):

1. **Mode auto-downgrade:** If using a Pro-only mode (Code, Email, etc.) → switches to Text
2. **Language auto-downgrade:** If using a Pro-only language → switches to Portuguese
3. **Wake word auto-disable:** If enabled → sets to false

This runs after every `fetchProfile()`, ensuring the UI always reflects the real plan.

### Trial → Free Transition

Three ways a trial can end:

| Trigger | When | What Happens |
|---|---|---|
| 7 days elapsed | `trialEndsAt < now` | `isTrialActive()` returns false |
| 50 transcriptions used | `trialTranscriptionsUsed >= 50` | `hasReachedTrialLimit = true` |
| User clicks "Continue without AI" | Manual dismissal | `forceExpireTrial()` persists expiration |

After trial expires:
- Trial Expired modal shown once (tracked by UserDefaults flag)
- `enforceFreeTierDefaults()` runs on next profile fetch
- User reverts to Free tier (75 Whisper/month, Text only, PT+EN)

### Monthly Counter Reset (3 layers)

**Layer 1: Client-side (app launch)**
- On launch, checks if current month ≠ last reset month
- If new month → resets `whisperTranscriptionsUsed = 0`
- Clock manipulation protection: refuses reset if `now < lastOnlineValidation`

**Layer 2: Client-side (runtime)**
- `checkWhisperMonthlyReset()` runs every time limit is checked
- Allows month boundary crossing without app restart

**Layer 3: Server-side (pg_cron)**
- Runs 1st of month at 00:00 UTC
- Resets ALL free users:
  - `free_transcriptions_used = 0`
  - `monthly_text_transcription_count = 0`
  - `free_transcriptions_reset_at = 1st of next month`

### Transition Summary Table

| Transition | Trigger | Supabase Changes | App Changes | Speed |
|---|---|---|---|---|
| Free → Pro | Eduzz purchase webhook | `plan='pro'`, subscription created | Features unlock on next sync | Real-time |
| Free → Pro | Manual verify | Edge function checks Eduzz API | Features unlock immediately | On demand |
| Pro → Free | Eduzz cancellation webhook | `plan='free'`, subscription cancelled | `enforceFreeTierDefaults()` | Real-time |
| Pro → Free | Expiry (pg_cron) | `plan='free'`, subscription expired | `enforceFreeTierDefaults()` | Up to 6h |
| Trial → Free | 7 days or 50 tx | Trial dates expired (local) | `enforceFreeTierDefaults()` | Immediate |
| Trial → Free | User dismisses | `forceExpireTrial()` locally | Features locked immediately | Immediate |

---

## 13. Anti-Abuse & Security

| Protection | Method | Details |
|---|---|---|
| Whisper counter tamper | Hash with salt `"v0x41g0_wh15p3r"` | Detects UserDefaults manipulation; restores previous value if hash mismatch |
| Trial counter tamper | Hash with salt `"v0x41g0_tr14l"` | Detects trial count manipulation; same hash-based integrity check |
| Device fingerprint | SHA256(serial + model + salt) via IOKit | Same device = same ID; survives reinstalls; prevents multi-account trial abuse |
| Clock manipulation | Compare device clock vs. last server validation | Refuses monthly reset if `now < lastOnlineValidation`; treats negative elapsed time as expired |
| Online validation | 48-hour grace period | Pro/Trial must sync with Supabase every 48h; blocks recording if expired |
| Bidirectional sync | MAX(local, server) counter strategy | Prevents reinstall counter reset; always takes the higher count |
| Monthly reset (3 layers) | Client (launch) + Client (runtime) + Server (pg_cron) | Triple redundancy ensures counter always resets correctly |
| pg_cron downgrade | Every 6 hours, checks for expired Pro subscriptions | Safety net for failed webhooks; auto-downgrades to free |
| Pending purchase system | `pending_purchases` table with claim tracking | Prevents double-claiming; marks purchases as `'claimed'` after activation |
| Server-side limit check | `/transcribe` edge function returns HTTP 429 | Even if client counter is bypassed, server enforces the 75/month limit |

---

*Document generated: 2026-03-01*
*Source: VoxAiGo 3.0.0 (macOS)*
