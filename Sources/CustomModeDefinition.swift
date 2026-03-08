import Foundation
import SwiftUI

/// Definição de um modo customizado criado pelo usuário
struct CustomModeDefinition: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var prompt: String
    var icon: String       // SF Symbol name
    var colorHex: String   // Hex color string
    var createdAt: Date

    init(name: String = "Novo Modo", prompt: String = "",
         icon: String = "slider.horizontal.3", colorHex: String = "#999999") {
        self.id = UUID()
        self.name = name
        self.prompt = prompt
        self.icon = icon
        self.colorHex = colorHex
        self.createdAt = Date()
    }

    /// Resolve a SwiftUI Color from the hex string
    var color: Color {
        Color(hex: colorHex) ?? Color.gray
    }
}

// MARK: - Color hex helper

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        guard hexSanitized.count == 6,
              let rgb = UInt64(hexSanitized, radix: 16) else { return nil }

        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
}

/// Categorias para organização visual dos modos
enum ModeCategory: String, CaseIterable {
    case writing = "Escrita"
    case productivity = "Produtividade"
    case development = "Desenvolvimento"
    case social = "Social"
    case custom = "Meus Modos"

    var icon: String {
        switch self {
        case .writing:       return "pencil.line"
        case .productivity:  return "checklist"
        case .development:   return "laptopcomputer"
        case .social:        return "shareplay"
        case .custom:        return "slider.horizontal.3"
        }
    }

    /// Modos built-in que pertencem a esta categoria
    static func modes(for category: ModeCategory) -> [TranscriptionMode] {
        switch category {
        case .writing:       return [.text, .chat, .email, .creative]
        case .productivity:  return [.summary, .meeting, .translation]
        case .development:   return [.code, .vibeCoder, .uxDesign]
        case .social:        return [.social]
        case .custom:        return [.custom]
        }
    }
}
