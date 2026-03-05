# VoxAiGo HUD Reference — Windows Implementation Guide

This document describes every HUD, notification, and overlay in the macOS app,
with exact specs for the Windows (Tauri) team to replicate.

---

## Global HUD Properties

All floating HUD notifications share these characteristics:

| Property | Value |
|---|---|
| Window type | NSPanel (borderless, nonactivatingPanel) |
| Level | `.screenSaver` — above everything, including fullscreen apps |
| Click-through | `ignoresMouseEvents = true` (HUDs don't steal focus) |
| Transparency | Transparent background, shadow handled by content |
| Multi-desktop | Visible on all Spaces and fullscreen apps |
| Position | Horizontally centered, 25% from bottom of screen |
| Auto-close | 2 seconds + 0.3s fade-out |

**Windows equivalent:** Use a borderless, always-on-top, click-through window (e.g., Tauri `set_always_on_top(true)` + `set_ignore_cursor_events(true)`).

---

## 1. Language Notification HUD

**Trigger:** `Ctrl+Shift+L` (cycle language)

| Spec | Value |
|---|---|
| Size | 260 x 64 px |
| Duration | 2s visible + 0.3s fade-out |
| Position | Center-X, 25% from bottom |

**Content layout (horizontal):**
```
[  Flag   ] [ Language Name ]
[  emoji  ] [ code badge    ]
[  48pt   ] [ "Idioma" + checkmark ]
```

**Elements:**
- **Flag emoji** — large (28pt font), inside a colored circle (32x32)
- **Language name** — e.g., "Portugues" (13pt, bold, white)
- **Language code badge** — e.g., "PT" (9pt, bold, inside 30x16 pill, accent color background)
- **"Idioma" label** — (10pt, white 50% opacity) with checkmark.circle.fill (10pt, accent color)

**Color mapping** (accent per language):
- Portuguese: `#4CD964` (green)
- English: `#5AC8FA` (blue)
- Spanish: `#FF9500` (orange)
- French: `#AF52DE` (purple)
- German: `#FF3B30` (red)
- Italian: `#34C759` (green)
- Japanese: `#FF2D55` (pink)
- Chinese: `#FF9500` (orange)
- Korean: `#5856D6` (indigo)
- Others: `#8E8E93` (gray)

**Animation (appear):**
- Spring animation: `response: 0.45, dampingFraction: 0.65`
- Scale: `0.7 -> 1.0`
- Offset Y: `15px down -> 0`
- Opacity: `0 -> 1`

**Animation (dismiss):**
- Ease-in: `0.3s`
- Opacity: `1 -> 0`

**Background:**
- Capsule shape (fully rounded corners)
- `Color.white.opacity(0.08)` fill
- `LinearGradient` overlay border (white 10% -> white 5%, top to bottom)
- 1px border, capsule clip

---

## 2. Mode Notification HUD

**Trigger:** `Ctrl+Shift+M` (cycle mode)

| Spec | Value |
|---|---|
| Size | 240 x 64 px |
| Duration | 2s visible + 0.3s fade-out |
| Position | Center-X, 25% from bottom |

**Content layout (horizontal):**
```
[ Icon    ] [ Mode Name    ]
[ circle  ] [ "Modo" + checkmark ]
```

**Elements:**
- **Mode icon** — SF Symbol (16pt, semibold) inside colored circle (32x32, mode color at 20% opacity)
- **Mode name** — e.g., "Codigo" (13pt, bold, white)
- **"Modo" label** — (10pt, white 50% opacity) with checkmark.circle.fill (10pt, mode color)

**Mode icons and colors:**

| Mode | Icon | Color |
|---|---|---|
| Code | `chevron.left.forwardslash.chevron.right` | `#5AC8FA` (blue) |
| Text | `text.alignleft` | `#8E8E93` (gray) |
| Email | `envelope.fill` | `#FF9500` (orange) |
| UX Design | `paintbrush.pointed.fill` | `#AF52DE` (purple) |
| SQL | `cylinder.fill` | `#FF6B35` (dark orange) |
| Vibe Coder | `wand.and.stars` | `#BF5AF2` (magenta) |
| Summary | `doc.text.magnifyingglass` | `#34C759` (green) |
| Translation | `globe` | `#5856D6` (indigo) |
| Correction | `checkmark.seal.fill` | `#FF2D55` (pink) |
| Technical | `gearshape.2.fill` | `#636366` (dark gray) |
| Creative | `sparkles` | `#FFD60A` (yellow) |
| Meeting | `person.2.fill` | `#30B0C7` (teal) |
| Social | `bubble.left.and.bubble.right.fill` | `#FF375F` (red-pink) |
| Custom | `slider.horizontal.3` | `#8E8E93` (gray) |
| Conversation Reply | `bubble.left.and.text.bubble.right.fill` | `#5856D6` (indigo) |

**Animation:** Same as Language HUD.

---

## 3. Wake Word Notification HUD

**Trigger:** Voice command detected ("Vox, email", "Vox, codigo", etc.)

| Spec | Value |
|---|---|
| Size | 280 x 64 px |
| Duration | 2s visible + 0.3s fade-out |
| Position | Center-X, 25% from bottom |

**Content layout (horizontal):**
```
[ Icon    ] [ "Vox" + checkmark ]
[ circle  ] [ Command label     ]
[  purple ] [ Active badge "ON" ]
```

**Elements:**
- **Icon** — the mode/language icon (16pt, semibold) inside circle (32x32, purple 20% opacity)
- **"Vox"** label — (10pt, medium, white 50% opacity) with checkmark (10pt, purple accent)
- **Command label** — e.g., "Email", "Portugues" (13pt, bold, white)
- **Active badge** — "ON" text with sparkle symbol (9pt, purple background pill)

**Accent color:** `#BF5AF2` (purple) — always purple regardless of mode/language

**Animation:** Same as Language HUD.

---

## 4. Paste Last Notification HUD

**Trigger:** `Ctrl+Shift+V` (paste last transcription)

| Spec | Value |
|---|---|
| Size | 280 x 64 px |
| Duration | 2s visible + 0.3s fade-out |
| Position | Center-X, 25% from bottom |

**Content layout (horizontal):**
```
[ Clipboard ] [ "Colado" + checkmark ]
[   icon    ] [ First 30 chars...    ]
```

**Elements:**
- **Clipboard icon** — `doc.on.clipboard.fill` (16pt) inside circle (32x32, mode color at 20% opacity)
- **"Colado"** label — (10pt, medium, white 50% opacity) with checkmark (10pt, mode color)
- **Text preview** — first 30 characters of pasted text (11pt, white 70% opacity, truncated)

**Animation:** Same as Language HUD.

---

## 5. No History Notification HUD

**Trigger:** `Ctrl+Shift+V` when history is empty

| Spec | Value |
|---|---|
| Size | 260 x 64 px |
| Duration | 2s visible + 0.3s fade-out |
| Position | Center-X, 25% from bottom |

**Content layout (horizontal):**
```
[ Empty   ] [ "Historico vazio"           ]
[  tray   ] [ "Nenhuma transcricao salva" ]
```

**Elements:**
- **Icon** — `tray` (16pt) inside circle (32x32, gray 20% opacity)
- **Title** — "Historico vazio" (13pt, bold, white)
- **Subtitle** — "Nenhuma transcricao salva" (10pt, white 50% opacity)

**Animation:** Same as Language HUD.

---

## 6. Recording HUD (Main Window / ContentView)

**Trigger:** Hold `Option+Command` (macOS) / configured shortcut

| Spec | Value |
|---|---|
| Size | 500 x 100 px |
| Duration | Visible while keys held + auto-close after transcription |
| Position | Center-X, 25% from bottom |
| Click-through | NO (user can interact) |

**States:**

### 6a. Idle / Ready State
```
[ Mode icon + name ] [ Waveform area (flat line) ] [ Language flag ]
```
- Shows current mode icon, name, and selected language
- Waveform is flat/silent

### 6b. Recording State
```
[ Pulsing mic ] [ Live waveform ] [ Timer ]
```
- Mic icon pulses red
- Real-time audio waveform visualization (bars react to voice volume)
- Duration counter

### 6c. Processing State
```
[ Spinner ] [ "Processing..." ] [ Mode name ]
```
- Spinning progress indicator
- Shows which mode is processing

### 6d. Complete State
- Window auto-closes after paste
- Optional: brief success indicator before closing

**Window properties:**
- NSPanel + borderless + fullSizeContentView + nonactivatingPanel
- `.screenSaver` level
- NOT click-through (user can interact with it)
- Stays visible when app loses focus
- Visible on all Spaces

**Background:**
- Semi-transparent dark capsule
- Same styling as HUD notifications

---

## 7. Conversation Reply HUD

**Trigger:** `Ctrl+Shift+R` with text selected in another app

| Spec | Value |
|---|---|
| Base size | 460 x 64-200 px (dynamic) |
| Duration | Up to 30 seconds (timeout with visual countdown) |
| Position | Center-X, 25% from bottom |
| Click-through | NO (has dismiss button) |

**States and sizes:**

### 7a. Translating State (460 x 64 px)
```
[ Globe icon (blue) ] [ "Reading message..." ] [ Spinner ]
```

### 7b. Ready State (460 x 200 px)
```
[ Source lang badge -> Target lang badge ]  [ X button ]
[ Translated text (scrollable, max 220px height) ]
[ "Hold Option+Cmd to reply in [language]"       ]
[ Countdown progress bar                          ]
```
- Language badges: colored pills with flag + language code
- Dismiss button (X) in top-right corner
- Visual countdown bar (progress shrinks over 30s)

### 7c. Recording State (460 x 80 px)
```
[ Pulsing red mic ] [ "Replying in [language]..." ] [ Sound wave ]
```
- Mic circle pulses: shadow 8-12pt, scale 1.0-1.08
- Live SoundWaveView with real-time audio levels

### 7d. Processing State (460 x 64 px)
```
[ Sparkles icon (rotating 360deg) ] [ "Translating your reply..." ] [ Spinner ]
```
- Sparkles icon rotates continuously (2.5s per rotation, linear)

**Animation (appear):**
- Ease-out: `0.28s`
- Opacity: `0 -> 1`
- Offset Y: `-20px -> 0` (slides up from below)

**Animation (dismiss):**
- Ease-in: `0.22s`
- Opacity: `1 -> 0`
- Offset Y: `0 -> +12px` (slides down)

**Animation (resize between states):**
- Ease-in-out: `0.22s`
- Smooth frame animation

**Border styling by state:**
- Recording: red border with glow effect
- Processing: purple accent border
- Default: white subtle border (white 8% opacity)

---

## 8. Modal Windows (User-Dismissible)

These are larger modal panels that require user interaction to close.

### Common properties:
| Property | Value |
|---|---|
| Style | Titled + closable + nonactivatingPanel |
| Level | `.screenSaver` |
| Position | Center of screen |
| Background | App default (not transparent) |
| Activation | App activates when shown (comes to front) |

### 8a. Welcome Trial Modal
- **Trigger:** First signup (auto-start trial)
- **Size:** 420 x 560 px
- **Content:** Welcome message, trial benefits list, CTA button

### 8b. Trial Expired Modal
- **Trigger:** Trial expires (shown once via UserDefaults flag)
- **Size:** 440 x 620 px
- **Content:** Expiry message, what's lost, upgrade CTA, "Continue without AI" dismiss

### 8c. Monthly Limit Modal
- **Trigger:** Free user reaches 75 Whisper transcriptions/month
- **Size:** 440 x 560 px
- **Content:** Limit reached message, usage stats, upgrade CTA

### 8d. Upgrade Reminder Modal (Soft Nudge)
- **Trigger:** Every 25 Whisper transcriptions (free tier)
- **Size:** 420 x 520 px
- **Content:** Gentle upgrade suggestion, benefits list, dismiss option

### 8e. Contextual Upgrade Modal
- **Trigger:** Free user tries Pro-locked feature (mode, language, wake word)
- **Size:** 420 x 520 px
- **Content:** Shows which feature was attempted, what Pro unlocks

---

## 9. Toast Notifications

**Purpose:** Subtle feedback for app events (copy success, errors, etc.)

| Spec | Value |
|---|---|
| Position | Top of screen, stacked vertically (8px spacing) |
| Duration | Success: 2s, Error: 3s, Warning: 2.5s |
| Width | Auto (fits content) |

**Types and colors:**
| Type | Icon | Color |
|---|---|---|
| Success | `checkmark.circle.fill` | Green |
| Error | `xmark.circle.fill` | Red |
| Info | `info.circle.fill` | White |
| Warning | `exclamationmark.triangle.fill` | Orange |

**Animation (appear):**
- Spring: `response: 0.3, dampingFraction: 0.7`
- Slides in from top + fades in

**Animation (dismiss):**
- Ease-out: `0.2s`
- Slides up + fades out

---

## Positioning Reference

```
+------------------------------------------+
|                                          |
|          [Toast notifications]           |  <- Top of screen
|                                          |
|                                          |
|                                          |
|                                          |
|          [Modal windows]                 |  <- Center of screen
|                                          |
|                                          |
|                                          |
|     [Recording HUD / Notifications]     |  <- 25% from bottom
|                                          |
+------------------------------------------+
```

**Exact Y position formula:**
```
y = screen.visibleFrame.minY + (screen.visibleFrame.height * 0.25)
x = screen.visibleFrame.midX - (windowWidth / 2)
```

---

## Dev Tools: HUD Preview

In the macOS app, activate Dev Mode (tap version 5x, enter "voxdev") to access:

1. **"Preview HUDs"** section with a **"Congelar" toggle** — freezes HUDs for 30 seconds instead of 2s
2. **Individual buttons:** Idioma, Modo, Vox, Colar, Sem hist., Gravacao
3. Each button shows the corresponding HUD with sample data
4. Take screenshots while HUDs are frozen on screen

---

## Background Styling (Shared)

All floating HUDs use this background:
```css
/* Capsule container */
background: rgba(255, 255, 255, 0.08);
border-radius: 9999px; /* full capsule */
border: 1px solid;
border-image: linear-gradient(to bottom, rgba(255,255,255,0.10), rgba(255,255,255,0.05));
padding: 24px horizontal, 16px vertical;
```

The overall app uses a dark theme. All HUD text is white with varying opacity levels.

---

*Document generated: 2026-03-01*
*macOS source: VoxAiGo 3.0.0*
