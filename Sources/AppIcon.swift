import AppKit
import SwiftUI

/// Gera o ícone do app programaticamente
class AppIconGenerator {
    
    /// Cria o ícone do VibeFlow
    static func createAppIcon(size: CGFloat = 512) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size))
        
        image.lockFocus()
        
        // Background gradient (roxo/azul vibrante)
        let gradient = NSGradient(colors: [
            NSColor(red: 0.4, green: 0.2, blue: 0.8, alpha: 1.0),  // Purple
            NSColor(red: 0.2, green: 0.4, blue: 0.9, alpha: 1.0),  // Blue
            NSColor(red: 0.3, green: 0.7, blue: 0.9, alpha: 1.0)   // Cyan
        ])
        
        // Rounded rectangle background
        let rect = NSRect(x: 0, y: 0, width: size, height: size)
        let cornerRadius = size * 0.22
        let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
        gradient?.draw(in: path, angle: -45)
        
        // Draw waveform
        let waveColor = NSColor.white
        waveColor.setStroke()
        waveColor.setFill()
        
        let centerY = size / 2
        let waveWidth = size * 0.6
        let startX = (size - waveWidth) / 2
        let barWidth = size * 0.06
        let barSpacing = size * 0.09
        let heights: [CGFloat] = [0.15, 0.35, 0.55, 0.45, 0.65, 0.40, 0.20]
        
        for (index, heightRatio) in heights.enumerated() {
            let barHeight = size * heightRatio
            let x = startX + CGFloat(index) * barSpacing
            let y = centerY - barHeight / 2
            
            let barRect = NSRect(x: x, y: y, width: barWidth, height: barHeight)
            let barPath = NSBezierPath(roundedRect: barRect, xRadius: barWidth / 2, yRadius: barWidth / 2)
            barPath.fill()
        }
        
        image.unlockFocus()
        
        return image
    }
    
    /// Cria ícone para a barra de menu
    static func createMenuBarIcon() -> NSImage {
        let size: CGFloat = 18
        let image = NSImage(size: NSSize(width: size, height: size))
        
        image.lockFocus()
        
        let waveColor = NSColor.labelColor
        waveColor.setFill()
        
        let centerY = size / 2
        let barWidth: CGFloat = 2
        let barSpacing: CGFloat = 3
        let heights: [CGFloat] = [0.3, 0.6, 0.9, 0.5, 0.7]
        let totalWidth = CGFloat(heights.count) * barSpacing
        let startX = (size - totalWidth) / 2
        
        for (index, heightRatio) in heights.enumerated() {
            let barHeight = size * heightRatio * 0.8
            let x = startX + CGFloat(index) * barSpacing
            let y = centerY - barHeight / 2
            
            let barRect = NSRect(x: x, y: y, width: barWidth, height: barHeight)
            let barPath = NSBezierPath(roundedRect: barRect, xRadius: 1, yRadius: 1)
            barPath.fill()
        }
        
        image.unlockFocus()
        image.isTemplate = true
        
        return image
    }
}
