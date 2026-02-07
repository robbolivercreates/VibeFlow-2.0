import SwiftUI

/// Sistema de notificações/toast sutis para o VibeFlow
enum ToastType {
    case success
    case error
    case info
    case warning
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .success: return .green
        case .error: return .red
        case .info: return .blue
        case .warning: return .orange
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .success: return Color.green.opacity(0.15)
        case .error: return Color.red.opacity(0.15)
        case .info: return Color.blue.opacity(0.15)
        case .warning: return Color.orange.opacity(0.15)
        }
    }
}

struct Toast: Identifiable {
    let id = UUID()
    let message: String
    let type: ToastType
    let duration: TimeInterval
}

/// ViewModel para gerenciar toasts
class ToastManager: ObservableObject {
    static let shared = ToastManager()
    
    @Published var toasts: [Toast] = []
    
    private init() {}
    
    func show(_ message: String, type: ToastType = .info, duration: TimeInterval = 2.0) {
        let toast = Toast(message: message, type: type, duration: duration)
        
        DispatchQueue.main.async {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                self.toasts.append(toast)
            }
        }
        
        // Auto-remove
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            self.remove(toast)
        }
    }
    
    func success(_ message: String, duration: TimeInterval = 2.0) {
        show(message, type: .success, duration: duration)
    }
    
    func error(_ message: String, duration: TimeInterval = 3.0) {
        show(message, type: .error, duration: duration)
    }
    
    func info(_ message: String, duration: TimeInterval = 2.0) {
        show(message, type: .info, duration: duration)
    }
    
    func warning(_ message: String, duration: TimeInterval = 2.5) {
        show(message, type: .warning, duration: duration)
    }
    
    func remove(_ toast: Toast) {
        DispatchQueue.main.async {
            withAnimation(.easeOut(duration: 0.2)) {
                self.toasts.removeAll { $0.id == toast.id }
            }
        }
    }
}

/// View de Toast individual
struct ToastView: View {
    let toast: Toast
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: toast.type.icon)
                .foregroundColor(toast.type.color)
                .font(.system(size: 16, weight: .semibold))
            
            Text(toast.message)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)
            
            Spacer(minLength: 8)
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(toast.type.backgroundColor)
                )
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(toast.type.color.opacity(0.2), lineWidth: 1)
        )
    }
}

/// Container de Toasts que pode ser adicionado a qualquer view
struct ToastContainer: View {
    @StateObject private var manager = ToastManager.shared
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(manager.toasts) { toast in
                ToastView(toast: toast) {
                    manager.remove(toast)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.top, 8)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .allowsHitTesting(!manager.toasts.isEmpty)
    }
}

// MARK: - Preview
#Preview {
    VStack {
        ToastView(toast: Toast(message: "Texto copiado!", type: .success, duration: 2)) {}
        ToastView(toast: Toast(message: "Erro ao processar", type: .error, duration: 2)) {}
        ToastView(toast: Toast(message: "Processando áudio...", type: .info, duration: 2)) {}
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}
