---
description: How to sign, notarize, and staple a macOS DMG for distribution
---

# macOS App — Sign, Notarize & Staple DMG

## Prerequisites

### 1. Apple Developer Account
- Paid Apple Developer Program membership ($99/year)
- Account at https://developer.apple.com

### 2. Developer ID Certificate
Create at https://developer.apple.com/account/resources/certificates/add:
1. Select **"Developer ID Application"**
2. Create a CSR from Keychain Access (Keychain Access → Certificate Assistant → Request a Certificate From a Certificate Authority)
3. Upload the CSR, download the `.cer` file
4. Double-click to install in Keychain

Verify it's installed:
```bash
security find-identity -v -p codesigning | grep "Developer ID"
```

### 3. App-Specific Password (for notarization)
1. Go to https://appleid.apple.com → Security → App-Specific Passwords
2. Generate a new password (e.g., name it "Notarization")
3. Save it — you'll need it once

### 4. Store Credentials in Keychain
```bash
xcrun notarytool store-credentials "YOUR-APP-Notary" \
  --apple-id "your@email.com" \
  --team-id "YOUR_TEAM_ID" \
  --password "xxxx-xxxx-xxxx-xxxx"
```
> Your Team ID is the 10-character alphanumeric code from your Apple Developer account.

---

## Step-by-Step Process

### Step 1: Build your app
```bash
swift build -c release
```

### Step 2: Create .app bundle
```bash
APP_NAME="YourApp"
DIST_DIR="/tmp/${APP_NAME}-dist"
APP_BUNDLE="${DIST_DIR}/${APP_NAME}.app"

mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

# Copy binary
cp .build/release/${APP_NAME} "${APP_BUNDLE}/Contents/MacOS/"

# Copy icon (if you have one)
cp YourApp.icns "${APP_BUNDLE}/Contents/Resources/AppIcon.icns"

# Create Info.plist (customize as needed)
cat > "${APP_BUNDLE}/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>YourApp</string>
    <key>CFBundleIdentifier</key>
    <string>com.yourcompany.yourapp</string>
    <key>CFBundleName</key>
    <string>YourApp</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF
```

### Step 3: Code sign the .app
```bash
SIGNING_IDENTITY="Developer ID Application: Your Name (TEAM_ID)"

# Remove extended attributes (important!)
xattr -cr "${APP_BUNDLE}"

# Sign with hardened runtime
codesign --force --deep --options runtime \
  --sign "${SIGNING_IDENTITY}" \
  "${APP_BUNDLE}"

# Verify signature
codesign --verify --deep --strict "${APP_BUNDLE}"
```

> **Note:** If your app needs microphone, camera, etc., add `--entitlements entitlements.plist` to the codesign command.

### Step 4: Create DMG
```bash
DMG_STAGING="/tmp/${APP_NAME}-dmg-staging"
DMG_PATH="${DIST_DIR}/${APP_NAME}-1.0.dmg"

mkdir -p "${DMG_STAGING}"
cp -R "${APP_BUNDLE}" "${DMG_STAGING}/"
ln -s /Applications "${DMG_STAGING}/Applications"

hdiutil create -volname "${APP_NAME}" \
  -srcfolder "${DMG_STAGING}" \
  -ov -format UDZO \
  "${DMG_PATH}"

rm -rf "${DMG_STAGING}"
```

### Step 5: Sign the DMG
```bash
codesign --force --sign "${SIGNING_IDENTITY}" "${DMG_PATH}"
```

### Step 6: Notarize (submit to Apple)
```bash
xcrun notarytool submit "${DMG_PATH}" \
  --keychain-profile "YOUR-APP-Notary" \
  --wait
```
> This uploads to Apple and waits for approval (usually 2-10 minutes).

### Step 7: Staple
```bash
xcrun stapler staple "${DMG_PATH}"
```
> This embeds Apple's approval ticket into the DMG so it works offline.

---

## Useful Commands

| Command | Purpose |
|---------|---------|
| `xcrun notarytool history --keychain-profile "X"` | List all submissions |
| `xcrun notarytool info <ID> --keychain-profile "X"` | Check a specific submission |
| `xcrun notarytool log <ID> --keychain-profile "X"` | View detailed notarization log |
| `spctl -a -vv YourApp.app` | Verify Gatekeeper will allow the app |
| `stapler validate YourApp.dmg` | Verify staple is attached |

## VibeFlow-Specific Values
- **Team ID:** `Z72H43BA3X`
- **Apple ID:** `robsonboliver@hotmail.com`
- **Keychain Profile:** `VibeFlow-Notary`
- **Signing Identity:** `Developer ID Application: Robson Oliveira (Z72H43BA3X)`
