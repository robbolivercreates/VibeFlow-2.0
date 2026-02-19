#!/bin/bash

# VoxAiGo Build Script
# Builds the app and creates the .app bundle

set -e

echo "🔨 Building VoxAiGo..."

# Build release
swift build -c release

echo "📦 Creating app bundle..."

# Clean previous
rm -rf VoxAiGo.app

# Create structure
mkdir -p "VoxAiGo.app/Contents/MacOS"
mkdir -p "VoxAiGo.app/Contents/Resources"

# Copy binary
cp ".build/release/VoxAiGo" "VoxAiGo.app/Contents/MacOS/VoxAiGo"

# Copy Info.plist
cp "Info.plist" "VoxAiGo.app/Contents/Info.plist"

# Copy icon if exists
if [ -f "VoxAiGo.icns" ]; then
    cp "VoxAiGo.icns" "VoxAiGo.app/Contents/Resources/AppIcon.icns"
    echo "✅ Icon added"
elif [ -f "VibeFlow.icns" ]; then
    cp "VibeFlow.icns" "VoxAiGo.app/Contents/Resources/AppIcon.icns"
    echo "✅ Icon added (using VibeFlow.icns)"
fi

echo ""
echo "✅ Build complete!"
echo "📍 App bundle: ./VoxAiGo.app"
echo ""
echo "To install, drag VoxAiGo.app to /Applications"
