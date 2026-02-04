import AppKit
import SwiftUI

/// Gera o ícone do app programaticamente - Design minimalista inspirado na Apple
class AppIconGenerator {

    // MARK: - Brand Colors

    /// Cores da marca VibeFlow
    private static let brandPurple = NSColor(red: 0.42, green: 0.35, blue: 0.85, alpha: 1.0)
    private static let brandIndigo = NSColor(red: 0.35, green: 0.30, blue: 0.75, alpha: 1.0)
    private static let brandViolet = NSColor(red: 0.55, green: 0.40, blue: 0.90, alpha: 1.0)

    // MARK: - App Icon

    /// Cria o ícone principal do VibeFlow - Design minimalista e elegante
    static func createAppIcon(size: CGFloat = 512) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size))

        image.lockFocus()

        // Background gradient - Tons de roxo/indigo suaves
        let gradient = NSGradient(colors: [
            NSColor(red: 0.38, green: 0.32, blue: 0.82, alpha: 1.0),  // Deep purple
            NSColor(red: 0.50, green: 0.38, blue: 0.88, alpha: 1.0),  // Violet
            NSColor(red: 0.45, green: 0.35, blue: 0.85, alpha: 1.0)   // Purple
        ])

        // Rounded rectangle background (Apple style)
        let rect = NSRect(x: 0, y: 0, width: size, height: size)
        let cornerRadius = size * 0.22
        let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
        gradient?.draw(in: path, angle: -45)

        // Subtle inner glow
        let innerGlow = NSGradient(colors: [
            NSColor.white.withAlphaComponent(0.15),
            NSColor.clear
        ])
        let innerRect = rect.insetBy(dx: size * 0.02, dy: size * 0.02)
        let innerPath = NSBezierPath(roundedRect: innerRect, xRadius: cornerRadius * 0.9, yRadius: cornerRadius * 0.9)
        innerGlow?.draw(in: innerPath, angle: 90)

        // Draw elegant "V" letterform with integrated waveform
        drawElegantLogo(in: rect, size: size)

        image.unlockFocus()

        return image
    }

    /// Desenha o logo elegante - "V" estilizado com ondas integradas
    private static func drawElegantLogo(in rect: NSRect, size: CGFloat) {
        let centerX = size / 2
        let centerY = size / 2

        // Draw stylized sound waves emanating from center
        let waveColor = NSColor.white
        let shadowColor = NSColor.black.withAlphaComponent(0.15)

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

            // Shadow
            shadowColor.setFill()
            let shadowRect = NSRect(x: x + 2, y: y - 2, width: barWidth, height: barHeight)
            let shadowPath = NSBezierPath(roundedRect: shadowRect, xRadius: barWidth / 2, yRadius: barWidth / 2)
            shadowPath.fill()

            // Bar with subtle gradient
            let barGradient = NSGradient(colors: [
                NSColor.white,
                NSColor.white.withAlphaComponent(0.9)
            ])
            let barRect = NSRect(x: x, y: y, width: barWidth, height: barHeight)
            let barPath = NSBezierPath(roundedRect: barRect, xRadius: barWidth / 2, yRadius: barWidth / 2)
            barGradient?.draw(in: barPath, angle: 90)
        }

        // Optional: Add subtle "V" shape overlay (very subtle)
        let vPath = NSBezierPath()
        let vWidth = size * 0.35
        let vHeight = size * 0.25
        let vTop = centerY + vHeight * 0.3
        let vBottom = centerY - vHeight * 0.7
        let vLeft = centerX - vWidth / 2
        let vRight = centerX + vWidth / 2
        let vCenter = centerX

        vPath.move(to: NSPoint(x: vLeft, y: vTop))
        vPath.line(to: NSPoint(x: vCenter, y: vBottom))
        vPath.line(to: NSPoint(x: vRight, y: vTop))

        vPath.lineWidth = size * 0.025
        vPath.lineCapStyle = .round
        vPath.lineJoinStyle = .round
        NSColor.white.withAlphaComponent(0.08).setStroke()
        vPath.stroke()
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

        // Subtle purple circle background
        let bgColor = NSColor(red: 0.45, green: 0.38, blue: 0.85, alpha: 1.0)
        bgColor.setFill()

        let bgRect = NSRect(x: 1, y: 1, width: size - 2, height: size - 2)
        let bgPath = NSBezierPath(ovalIn: bgRect)
        bgPath.fill()

        // White wave bars
        NSColor.white.setFill()

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
