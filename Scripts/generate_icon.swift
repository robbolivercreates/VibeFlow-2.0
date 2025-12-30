#!/usr/bin/env swift

import AppKit
import Foundation

/// Gera o ícone do VibeFlow em múltiplas resoluções
func createAppIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    
    image.lockFocus()
    
    // Background gradient (roxo/azul vibrante)
    let gradient = NSGradient(colors: [
        NSColor(red: 0.45, green: 0.20, blue: 0.85, alpha: 1.0),  // Purple
        NSColor(red: 0.25, green: 0.45, blue: 0.95, alpha: 1.0),  // Blue
        NSColor(red: 0.30, green: 0.70, blue: 0.95, alpha: 1.0)   // Cyan
    ])
    
    // Rounded rectangle background
    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    let cornerRadius = size * 0.22
    let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
    gradient?.draw(in: path, angle: -45)
    
    // Subtle inner shadow/glow
    let innerRect = rect.insetBy(dx: size * 0.02, dy: size * 0.02)
    let innerPath = NSBezierPath(roundedRect: innerRect, xRadius: cornerRadius * 0.9, yRadius: cornerRadius * 0.9)
    NSColor.white.withAlphaComponent(0.1).setStroke()
    innerPath.lineWidth = size * 0.01
    innerPath.stroke()
    
    // Draw waveform bars
    let waveColor = NSColor.white
    waveColor.setFill()
    
    let centerY = size / 2
    let barWidth = size * 0.07
    let barSpacing = size * 0.10
    let heights: [CGFloat] = [0.18, 0.38, 0.58, 0.48, 0.68, 0.42, 0.22]
    let totalWidth = CGFloat(heights.count - 1) * barSpacing + barWidth
    let startX = (size - totalWidth) / 2
    
    for (index, heightRatio) in heights.enumerated() {
        let barHeight = size * heightRatio
        let x = startX + CGFloat(index) * barSpacing
        let y = centerY - barHeight / 2
        
        let barRect = NSRect(x: x, y: y, width: barWidth, height: barHeight)
        let barPath = NSBezierPath(roundedRect: barRect, xRadius: barWidth / 2, yRadius: barWidth / 2)
        
        // Add subtle shadow to bars
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.3)
        shadow.shadowOffset = NSSize(width: 0, height: -size * 0.01)
        shadow.shadowBlurRadius = size * 0.02
        shadow.set()
        
        barPath.fill()
    }
    
    image.unlockFocus()
    
    return image
}

func generateIconSet() {
    let sizes: [(size: Int, scale: Int, name: String)] = [
        (16, 1, "icon_16x16"),
        (16, 2, "icon_16x16@2x"),
        (32, 1, "icon_32x32"),
        (32, 2, "icon_32x32@2x"),
        (128, 1, "icon_128x128"),
        (128, 2, "icon_128x128@2x"),
        (256, 1, "icon_256x256"),
        (256, 2, "icon_256x256@2x"),
        (512, 1, "icon_512x512"),
        (512, 2, "icon_512x512@2x")
    ]
    
    let iconsetPath = FileManager.default.currentDirectoryPath + "/VibeFlow.iconset"
    
    // Criar pasta iconset
    try? FileManager.default.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)
    
    for config in sizes {
        let pixelSize = CGFloat(config.size * config.scale)
        let image = createAppIcon(size: pixelSize)
        
        // Converter para PNG
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            print("Erro ao criar \(config.name)")
            continue
        }
        
        let filePath = iconsetPath + "/\(config.name).png"
        do {
            try pngData.write(to: URL(fileURLWithPath: filePath))
            print("✓ Criado: \(config.name).png (\(Int(pixelSize))x\(Int(pixelSize)))")
        } catch {
            print("Erro ao salvar \(config.name): \(error)")
        }
    }
    
    print("\n📁 Iconset criado em: \(iconsetPath)")
    print("\n🔧 Para converter para .icns, execute:")
    print("   iconutil -c icns VibeFlow.iconset")
}

// Executar
generateIconSet()
