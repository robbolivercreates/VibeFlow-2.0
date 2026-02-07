import SwiftUI

/// Preview flutuante para visualização detalhada de itens do histórico
struct FloatingPreviewView: View {
    let text: String
    let mode: TranscriptionMode
    let onClose: () -> Void
    
    @State private var isCopied = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: mode.icon)
                        .foregroundColor(modeColor)
                    
                    Text(mode.localizedName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("\(text.count) caracteres")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.secondary.opacity(0.05))
            
            Divider()
            
            // Content
            ScrollView {
                Text(text)
                    .font(.system(size: 14, design: .monospaced))
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .textSelection(.enabled)
            }
            
            Divider()
            
            // Footer com ações
            HStack(spacing: 12) {
                Button {
                    copyToClipboard()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                        Text(isCopied ? "Copiado!" : "Copiar")
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                
                Button {
                    onClose()
                } label: {
                    Text("Fechar")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Spacer()
                
                // Atalhos hint
                HStack(spacing: 8) {
                    ShortcutHint(key: "⌘", label: "Copiar")
                    ShortcutHint(key: "Esc", label: "Fechar")
                }
            }
            .padding(12)
        }
        .frame(minWidth: 300, idealWidth: 400, maxWidth: .infinity,
               minHeight: 200, idealHeight: 300, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            setupKeyboardShortcuts()
        }
    }
    
    private var modeColor: Color {
        switch mode {
        case .code: return .blue
        case .text: return .green
        case .email: return .orange
        case .uxDesign: return .purple
        case .command: return .yellow
        }
    }
    
    private func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        withAnimation {
            isCopied = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                isCopied = false
            }
        }
    }
    
    private func setupKeyboardShortcuts() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // Cmd+C para copiar
            if event.modifierFlags.contains(.command) && event.keyCode == 8 {
                self.copyToClipboard()
                return nil
            }
            // Esc para fechar
            if event.keyCode == 53 {
                self.onClose()
                return nil
            }
            return event
        }
    }
}

/// Hint visual de atalhos de teclado
struct ShortcutHint: View {
    let key: String
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Text(key)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.15))
                .cornerRadius(3)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    FloatingPreviewView(
        text: "func exemplo() {\n    print(\"Hello World\")\n    return true\n}",
        mode: .code,
        onClose: {}
    )
    .frame(width: 400, height: 300)
}
