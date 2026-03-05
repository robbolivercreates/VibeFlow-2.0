import AppKit
import SwiftUI

/// Gera o ícone do app programaticamente - Design matte black com barras douradas
class AppIconGenerator {

    // MARK: - Brand Colors

    /// Cores da marca VoxAiGo — Matte Black & Gold
    private static let brandGold = VoxTheme.nsAccent
    private static let brandGoldDark = VoxTheme.nsGoldDark
    private static let brandGoldLight = VoxTheme.nsAccentLight

    // MARK: - App Icon

    /// Cria o ícone principal do VoxAiGo - Fundo preto com barras douradas
    static func createAppIcon(size: CGFloat = 512) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size))

        image.lockFocus()

        // Background — Matte Black
        let rect = NSRect(x: 0, y: 0, width: size, height: size)
        let cornerRadius = size * 0.22
        let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)

        NSColor(red: 0.04, green: 0.04, blue: 0.04, alpha: 1.0).setFill()
        path.fill()

        // Subtle gold border
        let borderPath = NSBezierPath(roundedRect: rect.insetBy(dx: 1, dy: 1), xRadius: cornerRadius - 1, yRadius: cornerRadius - 1)
        borderPath.lineWidth = max(1.5, size * 0.004)
        VoxTheme.nsAccent.withAlphaComponent(0.3).setStroke()
        borderPath.stroke()

        // Subtle inner highlight at top
        let innerGlow = NSGradient(colors: [
            NSColor.white.withAlphaComponent(0.05),
            NSColor.clear
        ])
        let innerRect = rect.insetBy(dx: size * 0.04, dy: size * 0.04)
        let innerPath = NSBezierPath(roundedRect: innerRect, xRadius: cornerRadius * 0.85, yRadius: cornerRadius * 0.85)
        innerGlow?.draw(in: innerPath, angle: 90)

        // Draw gold waveform bars
        drawGoldWaveform(in: rect, size: size)

        image.unlockFocus()

        return image
    }

    /// Desenha barras de onda douradas no centro do ícone
    private static func drawGoldWaveform(in rect: NSRect, size: CGFloat) {
        let centerX = size / 2
        let centerY = size / 2

        // Gold glow shadow behind bars
        let glowColor = VoxTheme.nsAccent.withAlphaComponent(0.2)

        // Wave bars - asymmetric for visual interest
        let barData: [(offset: CGFloat, height: CGFloat)] = [
            (-0.24, 0.18),   // Far left
            (-0.14, 0.38),   // Left
            (-0.04, 0.55),   // Center-left
            (0.06, 0.48),    // Center-right
            (0.16, 0.32),    // Right
            (0.26, 0.15)     // Far right
        ]

        let barWidth = size * 0.065
        let maxHeight = size * 0.50

        for (offset, heightRatio) in barData {
            let barHeight = maxHeight * heightRatio
            let x = centerX + (size * offset) - (barWidth / 2)
            let y = centerY - (barHeight / 2)

            // Gold glow behind bar
            glowColor.setFill()
            let glowRect = NSRect(x: x - 2, y: y - 2, width: barWidth + 4, height: barHeight + 4)
            let glowPath = NSBezierPath(roundedRect: glowRect, xRadius: (barWidth + 4) / 2, yRadius: (barWidth + 4) / 2)
            glowPath.fill()

            // Gold gradient bar
            let barGradient = NSGradient(colors: [
                VoxTheme.nsGoldDark,
                VoxTheme.nsAccent,
                VoxTheme.nsAccentLight
            ])
            let barRect = NSRect(x: x, y: y, width: barWidth, height: barHeight)
            let barPath = NSBezierPath(roundedRect: barRect, xRadius: barWidth / 2, yRadius: barWidth / 2)
            barGradient?.draw(in: barPath, angle: 90)
        }
    }

    // MARK: - Menu Bar Icon

    /// Cria ícone para a barra de menu - Minimalista, estilo Apple
    /// Usa template image para adaptar automaticamente ao modo claro/escuro
    static func createMenuBarIcon() -> NSImage {
        let size: CGFloat = 18
        let image = NSImage(size: NSSize(width: size, height: size))

        image.lockFocus()

        // Simple monochrome waveform that adapts to system appearance
        let color = NSColor.black // Will be tinted by system when isTemplate = true

        color.setFill()

        let centerY = size / 2

        // Elegant wave bars
        let barData: [(offset: CGFloat, height: CGFloat)] = [
            (-5.5, 0.25),
            (-2.5, 0.55),
            (0.5, 0.75),
            (3.5, 0.45),
            (6.5, 0.30)
        ]

        let barWidth: CGFloat = 2.0

        for (offset, heightRatio) in barData {
            let barHeight = (size - 4) * heightRatio
            let x = (size / 2) + offset - (barWidth / 2)
            let y = centerY - (barHeight / 2)

            let barRect = NSRect(x: x, y: y, width: barWidth, height: barHeight)
            let barPath = NSBezierPath(roundedRect: barRect, xRadius: 1, yRadius: 1)
            barPath.fill()
        }

        image.unlockFocus()
        image.isTemplate = true  // Adapta automaticamente ao modo claro/escuro

        return image
    }

    /// Cria ícone colorido para a barra de menu (versao alternativa)
    static func createColoredMenuBarIcon() -> NSImage {
        let size: CGFloat = 18
        let image = NSImage(size: NSSize(width: size, height: size))

        image.lockFocus()

        // Black circle background with gold border
        let bgRect = NSRect(x: 1, y: 1, width: size - 2, height: size - 2)
        NSColor.black.setFill()
        let bgPath = NSBezierPath(ovalIn: bgRect)
        bgPath.fill()

        // Gold border
        VoxTheme.nsAccent.withAlphaComponent(0.4).setStroke()
        bgPath.lineWidth = 0.5
        bgPath.stroke()

        // Gold wave bars
        VoxTheme.nsAccent.setFill()

        let centerY = size / 2

        let barData: [(offset: CGFloat, height: CGFloat)] = [
            (-3.5, 0.30),
            (-1.0, 0.60),
            (1.5, 0.50),
            (4.0, 0.35)
        ]

        let barWidth: CGFloat = 1.8

        for (offset, heightRatio) in barData {
            let barHeight = (size - 6) * heightRatio
            let x = (size / 2) + offset - (barWidth / 2)
            let y = centerY - (barHeight / 2)

            let barRect = NSRect(x: x, y: y, width: barWidth, height: barHeight)
            let barPath = NSBezierPath(roundedRect: barRect, xRadius: 0.9, yRadius: 0.9)
            barPath.fill()
        }

        image.unlockFocus()
        image.isTemplate = false

        return image
    }

    // MARK: - SwiftUI Icon View

    /// Retorna o icone como uma View SwiftUI
    static func iconView(size: CGFloat = 24) -> some View {
        Image(nsImage: createAppIcon(size: size))
            .resizable()
            .aspectRatio(contentMode: .fit)
    }
}
