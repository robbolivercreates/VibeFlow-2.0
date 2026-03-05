#!/bin/bash
set -e

# ============================================================================
# VoxAiGo — Build, Sign, Notarize & Create DMG
# ============================================================================
#
# Usage:
#   ./build-dmg.sh              — Build DMG (ad-hoc signed, no notarization)
#   ./build-dmg.sh --sign       — Build DMG with Developer ID signing
#   ./build-dmg.sh --notarize   — Build DMG, sign + notarize with Apple
#
# Prerequisites for --sign / --notarize:
#   1. "Developer ID Application" certificate in Keychain
#      → Create at: https://developer.apple.com/account/resources/certificates/add
#      → Choose "Developer ID Application" → download & install .cer
#   2. For --notarize, create an app-specific password:
#      → https://appleid.apple.com → Security → App-Specific Passwords
#      → Store it in Keychain:
#        xcrun notarytool store-credentials "VoxAiGo-Notary" \
#          --apple-id "robsonboliver@hotmail.com" \
#          --team-id "Z72H43BA3X" \
#          --password "<app-specific-password>"
# ============================================================================

APP_NAME="VoxAiGo"
BUNDLE_ID="com.voxaigo.app"
VERSION="3.0.0"
TEAM_ID="Z72H43BA3X"
APPLE_ID="robsonboliver@hotmail.com"
SIGNING_IDENTITY="Developer ID Application: Robson Oliveira (${TEAM_ID})"
NOTARY_PROFILE="VoxAiGo-Notary"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/.build/release"
TIMESTAMP="$(date +%d-%m-%Y-%H%M)"
# Use /tmp to avoid iCloud Drive extended attributes that break codesign
DIST_DIR="/tmp/VoxAiGo-dist"
APP_BUNDLE="${DIST_DIR}/${APP_NAME}.app"
DMG_NAME="${APP_NAME}-${VERSION}-${TIMESTAMP}.dmg"
DMG_PATH="${DIST_DIR}/${DMG_NAME}"

# Parse flags
DO_SIGN=false
DO_NOTARIZE=false
for arg in "$@"; do
    case $arg in
        --sign) DO_SIGN=true ;;
        --notarize) DO_SIGN=true; DO_NOTARIZE=true ;;
        --no-sign) DO_SIGN=false ;;
    esac
done

# Auto-detect Developer ID certificate (sign by default if available)
if [ "$DO_SIGN" = false ] && security find-identity -v -p codesigning 2>/dev/null | grep -q "Developer ID Application"; then
    echo "🔐 Auto-detected Developer ID certificate — signing enabled"
    DO_SIGN=true
fi

echo "╔══════════════════════════════════════════════════════╗"
echo "║  🎙️ VoxAiGo Build System                            ║"
echo "╠══════════════════════════════════════════════════════╣"
echo "║  Version:     ${VERSION}                              ║"
echo "║  Signing:     $([ "$DO_SIGN" = true ] && echo "✅ Developer ID" || echo "⚪ Ad-hoc")                       ║"
echo "║  Notarize:    $([ "$DO_NOTARIZE" = true ] && echo "✅ Yes" || echo "⚪ No")                              ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""

# ── Step 1: Clean & Build ────────────────────────────────────────────────
echo "🔨 Step 1/6: Building release binary..."
cd "${SCRIPT_DIR}"
swift build -c release 2>&1
echo "   ✅ Build complete"

# ── Step 2: Assemble .app Bundle ─────────────────────────────────────────
echo ""
echo "📦 Step 2/6: Assembling ${APP_NAME}.app bundle..."

rm -rf "${DIST_DIR}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

# Copy binary
cp "${BUILD_DIR}/${APP_NAME}" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"

# Copy icon
if [ -f "${SCRIPT_DIR}/VoxAiGo.icns" ]; then
    cp "${SCRIPT_DIR}/VoxAiGo.icns" "${APP_BUNDLE}/Contents/Resources/AppIcon.icns"
    echo "   ✅ Icon embedded"
elif [ -f "${SCRIPT_DIR}/VibeFlow.icns" ]; then
    cp "${SCRIPT_DIR}/VibeFlow.icns" "${APP_BUNDLE}/Contents/Resources/AppIcon.icns"
    echo "   ✅ Icon embedded (using VibeFlow.icns)"
else
    echo "   ⚠️  No .icns found — app will use generic icon"
fi

# Create Info.plist
cat > "${APP_BUNDLE}/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSUIElement</key>
    <false/>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSMicrophoneUsageDescription</key>
    <string>VoxAiGo precisa do microfone para transcrever sua voz em texto.</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSAppleEventsUsageDescription</key>
    <string>VoxAiGo precisa simular teclas para colar código automaticamente no editor ativo.</string>
    <key>NSSupportsAutomaticTermination</key>
    <false/>
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleURLName</key>
            <string>com.voxaigo.app</string>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>voxaigo</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
PLIST

# Copy Whisper model (if present)
WHISPER_MODEL_DIR="${SCRIPT_DIR}/Models/whisper-small"
if [ -d "${WHISPER_MODEL_DIR}" ]; then
    cp -R "${WHISPER_MODEL_DIR}" "${APP_BUNDLE}/Contents/Resources/whisper-small"
    echo "   ✅ Whisper model embedded (~250MB)"
else
    echo "   ⚠️  Whisper model not found at Models/whisper-small/"
    echo "      App will download model on first launch (requires internet)"
fi

echo "   ✅ .app bundle assembled"

# ── Step 3: Code Signing ─────────────────────────────────────────────────
echo ""
if [ "$DO_SIGN" = true ]; then
    echo "🔐 Step 3/6: Signing with Developer ID..."

    # Strip extended attributes (resource forks, Finder info) that break codesign
    xattr -cr "${APP_BUNDLE}"

    # Check if the certificate exists
    if ! security find-identity -v -p codesigning | grep -q "Developer ID Application"; then
        echo "   ❌ ERROR: 'Developer ID Application' certificate not found!"
        echo ""
        echo "   To create one:"
        echo "   1. Go to https://developer.apple.com/account/resources/certificates/add"
        echo "   2. Select 'Developer ID Application'"
        echo "   3. Follow the steps to create a CSR and download the certificate"
        echo "   4. Double-click the .cer file to install it in Keychain"
        echo "   5. Run this script again with --sign"
        echo ""
        echo "   Falling back to ad-hoc signing..."
        DO_SIGN=false
        DO_NOTARIZE=false
        codesign --force --deep --sign - "${APP_BUNDLE}"
        echo "   ✅ Ad-hoc signed"
    else
        codesign --force --deep --options runtime \
            --sign "${SIGNING_IDENTITY}" \
            --entitlements /dev/stdin "${APP_BUNDLE}" << ENTITLEMENTS
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.device.audio-input</key>
    <true/>
    <key>com.apple.security.automation.apple-events</key>
    <true/>
</dict>
</plist>
ENTITLEMENTS
        echo "   ✅ Signed with Developer ID"

        # Verify
        codesign --verify --deep --strict "${APP_BUNDLE}" 2>&1
        echo "   ✅ Signature verified"
    fi
else
    echo "⚪ Step 3/6: Skipping code signing (use --sign to enable)"
    codesign --force --deep --sign - "${APP_BUNDLE}"
    echo "   ✅ Ad-hoc signed"
fi

# ── Step 4: Create DMG ───────────────────────────────────────────────────
echo ""
echo "💿 Step 4/6: Creating DMG..."

DMG_TEMP="${DIST_DIR}/dmg-staging"
rm -rf "${DMG_TEMP}"
mkdir -p "${DMG_TEMP}"

# Copy .app to staging
cp -R "${APP_BUNDLE}" "${DMG_TEMP}/"

# Create Applications symlink (for drag-to-install)
ln -s /Applications "${DMG_TEMP}/Applications"

# Remove old DMG if exists
rm -f "${DMG_PATH}"

# Create DMG
hdiutil create -volname "${APP_NAME}" \
    -srcfolder "${DMG_TEMP}" \
    -ov -format UDZO \
    "${DMG_PATH}" 2>&1 | grep -v "^$"

# Clean up staging
rm -rf "${DMG_TEMP}"

echo "   ✅ DMG created: ${DMG_PATH}"

# ── Step 5: Sign DMG ─────────────────────────────────────────────────────
echo ""
if [ "$DO_SIGN" = true ]; then
    echo "🔐 Step 5/6: Signing DMG..."
    codesign --force --sign "${SIGNING_IDENTITY}" "${DMG_PATH}"
    echo "   ✅ DMG signed"
else
    echo "⚪ Step 5/6: Skipping DMG signing"
fi

# ── Step 6: Notarize ─────────────────────────────────────────────────────
echo ""
if [ "$DO_NOTARIZE" = true ]; then
    echo "📤 Step 6/6: Submitting to Apple for notarization..."
    echo "   (this may take 2-10 minutes)"

    xcrun notarytool submit "${DMG_PATH}" \
        --keychain-profile "${NOTARY_PROFILE}" \
        --wait 2>&1

    echo ""
    echo "📌 Stapling notarization ticket..."
    xcrun stapler staple "${DMG_PATH}"
    echo "   ✅ Notarized and stapled!"
else
    echo "⚪ Step 6/6: Skipping notarization (use --notarize to enable)"
fi

# ── Done! ────────────────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║  ✅ Build Complete!                                  ║"
echo "╠══════════════════════════════════════════════════════╣"
echo "║                                                      ║"
echo "║  📦 App:  dist/${APP_NAME}.app                       ║"
echo "║  💿 DMG:  dist/${DMG_NAME}                    ║"
echo "║                                                      ║"
if [ "$DO_NOTARIZE" = true ]; then
echo "║  🔐 Signed + Notarized — ready to distribute!       ║"
elif [ "$DO_SIGN" = true ]; then
echo "║  🔐 Signed — notarize with --notarize flag          ║"
else
echo "║  ⚠️  Not signed — users will need to right-click     ║"
echo "║     → Open to bypass Gatekeeper warning              ║"
fi
echo "║                                                      ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""
echo "📂 Open dist folder:"
echo "   open ${DIST_DIR}"
