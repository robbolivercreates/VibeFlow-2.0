#!/bin/bash

# VibeFlow Build Script
# Builds the app and creates the .app bundle

set -e

echo "🔨 Building VibeFlow..."

# Build release
swift build -c release

echo "📦 Creating app bundle..."

# Clean previous
rm -rf VibeFlow.app

# Create structure
mkdir -p "VibeFlow.app/Contents/MacOS"
mkdir -p "VibeFlow.app/Contents/Resources"

# Copy binary
cp ".build/release/VibeFlow" "VibeFlow.app/Contents/MacOS/VibeFlow"

# Copy Info.plist
cp "Info.plist" "VibeFlow.app/Contents/Info.plist"

# Copy icon if exists
if [ -f "VibeFlow.icns" ]; then
    cp "VibeFlow.icns" "VibeFlow.app/Contents/Resources/AppIcon.icns"
    echo "✅ Icon added"
fi

echo ""
echo "✅ Build complete!"
echo "📍 App bundle: ./VibeFlow.app"
echo ""
echo "To install, drag VibeFlow.app to /Applications"
