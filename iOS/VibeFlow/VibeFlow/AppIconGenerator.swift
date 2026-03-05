import UIKit

/// Generates the VibeFlow app icon programmatically
class AppIconGenerator {

    // MARK: - Brand Colors

    private static let brandPurple = UIColor(red: 0.42, green: 0.35, blue: 0.85, alpha: 1.0)
    private static let brandOrange = UIColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0)
    private static let brandOrangeDark = UIColor(red: 0.9, green: 0.45, blue: 0.1, alpha: 1.0)

    // MARK: - App Icon

    /// Creates the main VibeFlow app icon - Orange theme to match the app
    static func createAppIcon(size: CGFloat = 1024) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))

        return renderer.image { context in
            let ctx = context.cgContext
            let rect = CGRect(x: 0, y: 0, width: size, height: size)

            // Background gradient - Orange tones
            let colors = [
                UIColor(red: 1.0, green: 0.55, blue: 0.15, alpha: 1.0).cgColor,  // Bright orange
                UIColor(red: 0.95, green: 0.45, blue: 0.1, alpha: 1.0).cgColor,  // Deep orange
                UIColor(red: 1.0, green: 0.5, blue: 0.2, alpha: 1.0).cgColor     // Orange
            ]

            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: [0, 0.5, 1])!

            // Rounded rectangle background (iOS style)
            let cornerRadius = size * 0.22
            let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
            ctx.addPath(path.cgPath)
            ctx.clip()

            // Draw gradient
            ctx.drawLinearGradient(gradient,
                                   start: CGPoint(x: 0, y: size),
                                   end: CGPoint(x: size, y: 0),
                                   options: [])

            // Reset clip
            ctx.resetClip()

            // Draw the waveform logo
            drawWaveformLogo(in: rect, size: size, context: ctx)
        }
    }

    /// Draws the waveform logo (sound bars)
    private static func drawWaveformLogo(in rect: CGRect, size: CGFloat, context: CGContext) {
        let centerX = size / 2
        let centerY = size / 2

        // Wave bars - asymmetric for visual interest
        let barData: [(offset: CGFloat, height: CGFloat)] = [
            (-0.24, 0.20),   // Far left
            (-0.14, 0.42),   // Left
            (-0.04, 0.60),   // Center-left (tallest)
            (0.06, 0.50),    // Center-right
            (0.16, 0.35),    // Right
            (0.26, 0.18)     // Far right
        ]

        let barWidth = size * 0.07
        let maxHeight = size * 0.52

        for (offset, heightRatio) in barData {
            let barHeight = maxHeight * heightRatio
            let x = centerX + (size * offset) - (barWidth / 2)
            let y = centerY - (barHeight / 2)

            // Shadow
            let shadowRect = CGRect(x: x + 3, y: y - 3, width: barWidth, height: barHeight)
            let shadowPath = UIBezierPath(roundedRect: shadowRect, cornerRadius: barWidth / 2)
            UIColor.black.withAlphaComponent(0.2).setFill()
            shadowPath.fill()

            // White bar
            let barRect = CGRect(x: x, y: y, width: barWidth, height: barHeight)
            let barPath = UIBezierPath(roundedRect: barRect, cornerRadius: barWidth / 2)
            UIColor.white.setFill()
            barPath.fill()
        }

        // Add microphone icon below the bars
        drawMicrophoneHint(centerX: centerX, centerY: centerY, size: size)
    }

    /// Draws a subtle microphone shape below the waveform
    private static func drawMicrophoneHint(centerX: CGFloat, centerY: CGFloat, size: CGFloat) {
        // Small mic icon at bottom
        let micWidth = size * 0.08
        let micHeight = size * 0.12
        let micX = centerX - micWidth / 2
        let micY = centerY - size * 0.35

        // Mic body
        let micRect = CGRect(x: micX, y: micY, width: micWidth, height: micHeight)
        let micPath = UIBezierPath(roundedRect: micRect, cornerRadius: micWidth / 2)
        UIColor.white.withAlphaComponent(0.3).setFill()
        micPath.fill()

        // Mic stand
        let standPath = UIBezierPath()
        standPath.move(to: CGPoint(x: centerX, y: micY))
        standPath.addLine(to: CGPoint(x: centerX, y: micY - size * 0.05))

        // Mic arc
        let arcY = micY - size * 0.02
        let arcPath = UIBezierPath(arcCenter: CGPoint(x: centerX, y: arcY),
                                    radius: micWidth * 0.8,
                                    startAngle: 0,
                                    endAngle: .pi,
                                    clockwise: false)

        UIColor.white.withAlphaComponent(0.2).setStroke()
        standPath.lineWidth = size * 0.015
        standPath.stroke()

        arcPath.lineWidth = size * 0.015
        arcPath.stroke()
    }

    // MARK: - Save Icon

    /// Saves the app icon to the specified URL
    static func saveIcon(to url: URL, size: CGFloat = 1024) throws {
        let icon = createAppIcon(size: size)
        guard let data = icon.pngData() else {
            throw NSError(domain: "AppIconGenerator", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create PNG data"])
        }
        try data.write(to: url)
    }

    /// Saves the app icon to the Documents directory and returns the path
    static func saveIconToDocuments() -> URL? {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }

        let iconURL = documentsPath.appendingPathComponent("AppIcon.png")

        do {
            try saveIcon(to: iconURL)
            print("✅ Icon saved to: \(iconURL.path)")
            return iconURL
        } catch {
            print("❌ Failed to save icon: \(error)")
            return nil
        }
    }
}

// MARK: - SwiftUI Preview

import SwiftUI

struct AppIconPreview: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(uiImage: AppIconGenerator.createAppIcon(size: 200))
                .clipShape(RoundedRectangle(cornerRadius: 44))
                .shadow(radius: 10)

            Text("VibeFlow")
                .font(.title2.bold())

            Button("Save Icon to Files") {
                if let url = AppIconGenerator.saveIconToDocuments() {
                    print("Saved to: \(url)")
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
        }
        .padding()
    }
}

#Preview {
    AppIconPreview()
}
