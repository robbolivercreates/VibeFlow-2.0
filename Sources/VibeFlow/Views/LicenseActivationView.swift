import SwiftUI

/// Tela de ativação de licença
struct LicenseActivationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var licenseKey = ""
    @State private var isActivating = false
    @State private var activationError: String?
    @State private var isActivated = false
    
    private let settings = SettingsManager.shared
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "key.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.orange)
                
                Text("Ativar VibeFlow")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Insira sua license key para ativar o VibeFlow Pro")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Input da key
            VStack(alignment: .leading, spacing: 8) {
                Text("License Key")
                    .font(.headline)
                
                HStack(spacing: 8) {
                    TextField("VIBE-XXXX-XXXX-XXXX", text: $licenseKey)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                        .onChange(of: licenseKey) { _ in
                            activationError = nil
                            licenseKey = formatKey(licenseKey)
                        }
                    
                    Button {
                        pasteFromClipboard()
                    } label: {
                        Image(systemName: "doc.on.clipboard")
                    }
                    .buttonStyle(.borderless)
                    .help("Colar da área de transferência")
                }
                
                if let error = activationError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            
            // Botões
            VStack(spacing: 12) {
                Button {
                    activateLicense()
                } label: {
                    HStack {
                        if isActivating {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text(isActivating ? "Ativando..." : "Ativar")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(licenseKey.count < 19 || isActivating)
                
                Link("Comprar License", destination: URL(string: "https://gumroad.com")!)
                    .font(.callout)
                
                Button("Continuar em modo trial") {
                    dismiss()
                }
                .buttonStyle(.borderless)
                .font(.callout)
                .foregroundStyle(.secondary)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 8) {
                Label("Ativação em 1 dispositivo", systemImage: "desktopcomputer")
                Label("Updates vitalícios", systemImage: "arrow.clockwise")
                Label("Suporte prioritário", systemImage: "envelope")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding()
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(12)
        }
        .padding(30)
        .frame(width: 400)
        .onAppear {
            checkExistingLicense()
        }
    }
    
    private func formatKey(_ input: String) -> String {
        // Remove tudo que não é alfanumérico
        let cleaned = input.uppercased().filter { $0.isLetter || $0.isNumber }
        
        // Limita a 12 caracteres (sem contar VIBE-)
        let limited = String(cleaned.prefix(12))
        
        // Formata como VIBE-XXXX-XXXX-XXXX
        var formatted = "VIBE-"
        for (index, char) in limited.enumerated() {
            if index > 0 && index % 4 == 0 && index < 12 {
                formatted += "-"
            }
            formatted += String(char)
        }
        
        return formatted
    }
    
    private func pasteFromClipboard() {
        let pasteboard = NSPasteboard.general
        if let string = pasteboard.string(forType: .string) {
            licenseKey = formatKey(string)
        }
    }
    
    private func activateLicense() {
        isActivating = true
        activationError = nil
        
        // Simular validação (em produção, chamar API)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isActivating = false
            
            // Validação básica (em produção, validar com servidor)
            if isValidKeyFormat(licenseKey) {
                settings.licenseKey = licenseKey
                settings.isLicensed = true
                isActivated = true
                dismiss()
            } else {
                activationError = "License key inválida. Verifique e tente novamente."
            }
        }
    }
    
    private func isValidKeyFormat(_ key: String) -> Bool {
        // Must be exactly 19 characters: VIBE-XXXX-XXXX-XXXX
        guard key.count == 19 else { return false }
        
        // Chave mestre (sua chave especial) - exact match only
        let masterKey = "VIBE-MASTER-2024-PRO"
        if key == masterKey {
            return true
        }
        
        // Strict format validation: VIBE-XXXX-XXXX-XXXX
        let components = key.split(separator: "-")
        guard components.count == 4,
              components[0] == "VIBE",
              components[1].count == 4,
              components[2].count == 4,
              components[3].count == 4 else {
            return false
        }
        
        // Only alphanumeric characters allowed (excluding confusing ones: 0, O, I, 1)
        let validChars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        for i in 1...3 {
            for char in components[i] {
                if !validChars.contains(char) {
                    return false
                }
            }
        }
        
        return true
    }
    
    private func checkExistingLicense() {
        if settings.isLicensed {
            dismiss()
            // Show wizard after dismissing if needed
            NotificationCenter.default.post(name: .showWizardAfterActivation, object: nil)
        }
    }
}

#Preview {
    LicenseActivationView()
}
