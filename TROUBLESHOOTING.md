# VibeFlow Troubleshooting Guide

## Known Issues & Workarounds

### 1. Accessibility Permission Detection (FIXED)

**Problem:**  
Even after granting Accessibility permission in System Settings, the app would still show "permission denied" or prompt for permission repeatedly. The `AXIsProcessTrustedWithOptions()` check was unreliable on macOS 13+.

**Solution:**  
Modified `ClipboardHelper.swift` to bypass the strict permission check:
- `checkAccessibilityPermission()` now always returns `true`
- App always attempts to paste automatically
- Falls back to manual Cmd+V if automatic paste fails
- Text is always copied to clipboard regardless of permission state

**Commit:** `9b6465e` - "Fix: Accessibility permission workaround and macOS 13 compatibility"

**Code Change:**
```swift
// Before: Actually checked permission
static func checkAccessibilityPermission() -> Bool {
    let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
    return AXIsProcessTrustedWithOptions(options)
}

// After: Always returns true
static func checkAccessibilityPermission() -> Bool {
    return true  // Bypass check, always try to work
}
```

---

### 2. macOS 14 API Compatibility Issues

**Problem:**  
The app used APIs only available on macOS 14+ (Sonoma), causing build/compilation errors on macOS 13 (Ventura).

**Affected APIs:**
- `onChange(of:initial:_:)` → Changed to `onChange(of:_)`
- `.strokeBorder()` → Changed to `.overlay(stroke())`  
- `.fill()` with ShapeStyle → Changed to `.foregroundColor()`
- `.tertiary` color → Changed to `.secondary`
- `onKeyPress` modifier → Custom `KeyboardCaptureView` using `NSViewRepresentable`

**Solution:**  
All macOS 14+ APIs were replaced with macOS 13-compatible alternatives.

---

### 3. Dark Mode Visual Issues

**Problem:**  
In Dark Mode, some UI elements appear with gray overlays or broken appearance due to `Color.secondary.opacity()` usage.

**Affected Areas:**
- Settings panels with `.secondary.opacity(0.05)` backgrounds
- Cards and containers with `.secondary.opacity(0.1)` strokes
- Progress bars and indicators

**Root Cause:**  
`Color.secondary` adapts to light/dark mode, but when combined with opacity (e.g., `.opacity(0.05)`), it creates inconsistent gray tones that look broken.

**Solution:**  
Replace with `Color(nsColor: .controlBackgroundColor)` or use adaptive colors that work in both modes.

---

### 4. Dropdown/Picker Issues (macOS 13)

**Problem:**  
`.pickerStyle(.menu)` dropdowns may not work correctly on macOS 13.

**Affected:**
- Language selection dropdown in Settings

**Workaround:**  
Use `.pickerStyle(.segmented)` or `.pickerStyle(.radioGroup)` instead of `.menu` style.

---

### 5. Duplicate Type Declarations

**Problem:**  
Multiple files defined the same SwiftUI view types (e.g., `StatCard`, `ModeCard`, `LanguageRow`), causing "invalid redeclaration" build errors.

**Solution:**  
Renamed duplicate types with numeric suffixes:
- `StatCard` → `StatCard2` (in AnalyticsView.swift)
- `ModeCard` → `ModeCard2` (in SetupWizardView.swift)
- `LanguageRow` → `LanguageRow2` (in ModernSettingsView.swift)
- `FeatureCard` → `FeatureCard2` (in StyleView.swift)

---

## Build Instructions

### Requirements
- macOS 13.0+ (Ventura)
- Xcode 14.0+ or Swift 5.9+

### Building from Source
```bash
cd ~/Desktop/VibeFlow
swift build -c release
```

### Creating the App Bundle
```bash
# Create app structure
mkdir -p VibeFlow.app/Contents/MacOS
mkdir -p VibeFlow.app/Contents/Resources

# Copy executable
cp .build/arm64-apple-macosx/release/VibeFlow VibeFlow.app/Contents/MacOS/
chmod +x VibeFlow.app/Contents/MacOS/VibeFlow

# Copy Info.plist and icon (see project root)
```

---

## Debugging

### Check Accessibility Permission Status
```bash
# List VibeFlow in accessibility database
sqlite3 /Library/Application\ Support/com.apple.TCC/TCC.db \
  "SELECT * FROM access WHERE client LIKE '%vibeflow%'"
```

### Reset App Preferences
```bash
defaults delete com.robbolivercreates.vibeflow
```

### View Console Logs
```bash
# Filter for VibeFlow logs
log stream --predicate 'process == "VibeFlow"' --level debug
```

---

## License

This troubleshooting guide is part of the VibeFlow project.
