#!/usr/bin/env swift

import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// Generate VibeFlow App Icon (1024x1024)
func createAppIcon() -> CGImage? {
    let size: CGFloat = 1024
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    
    guard let context = CGContext(
        data: nil,
        width: Int(size),
        height: Int(size),
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { return nil }
    
    // Flip context for correct orientation
    context.translateBy(x: 0, y: size)
    context.scaleBy(x: 1, y: -1)
    
    // Background gradient - Orange
    let colors = [
        CGColor(red: 1.0, green: 0.55, blue: 0.15, alpha: 1.0),
        CGColor(red: 0.95, green: 0.4, blue: 0.1, alpha: 1.0)
    ]
    
    guard let gradient = CGGradient(
        colorsSpace: colorSpace,
        colors: colors as CFArray,
        locations: [0, 1]
    ) else { return nil }
    
    // Draw rounded rect background
    let rect = CGRect(x: 0, y: 0, width: size, height: size)
    let cornerRadius = size * 0.22
    let path = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
    
    context.addPath(path)
    context.clip()
    context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: size, y: size), options: [])
    
    // Draw waveform bars
    let centerX = size / 2
    let centerY = size / 2
    
    let barData: [(offset: CGFloat, height: CGFloat)] = [
        (-0.24, 0.20),
        (-0.14, 0.42),
        (-0.04, 0.60),
        (0.06, 0.50),
        (0.16, 0.35),
        (0.26, 0.18)
    ]
    
    let barWidth = size * 0.07
    let maxHeight = size * 0.52
    
    context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
    
    for (offset, heightRatio) in barData {
        let barHeight = maxHeight * heightRatio
        let x = centerX + (size * offset) - (barWidth / 2)
        let y = centerY - (barHeight / 2)
        
        let barRect = CGRect(x: x, y: y, width: barWidth, height: barHeight)
        let barPath = CGPath(roundedRect: barRect, cornerWidth: barWidth/2, cornerHeight: barWidth/2, transform: nil)
        context.addPath(barPath)
        context.fillPath()
    }
    
    return context.makeImage()
}

// Main
print("🎨 Generating VibeFlow App Icon...")

guard let image = createAppIcon() else {
    print("❌ Failed to create icon")
    exit(1)
}

// Save to file
let outputPath = "./iOS/VibeFlow/VibeFlow/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
let url = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent(outputPath)

// Create directory if needed
try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)

guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
    print("❌ Failed to create image destination")
    exit(1)
}

CGImageDestinationAddImage(destination, image, nil)

if CGImageDestinationFinalize(destination) {
    print("✅ Icon saved to: \(outputPath)")
} else {
    print("❌ Failed to save icon")
    exit(1)
}
