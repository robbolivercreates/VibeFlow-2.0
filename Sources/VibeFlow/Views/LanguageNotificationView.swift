import SwiftUI

// MARK: - Animated HUD Notification Base

/// Reusable animated HUD container for shortcut feedback notifications
struct HUDNotificationContainer<Content: View>: View {
    let content: Content
    @State private var isVisible = false
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                Capsule()
                    .fill(VoxTheme.surface.opacity(0.85))
            )
            .overlay(
                Capsule()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.15),
                                Color.white.opacity(0.02)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .clipShape(Capsule())
            .scaleEffect(isVisible ? 1.0 : 0.7, anchor: .center)
            .offset(y: isVisible ? 0 : 15)
            .opacity(isVisible ? 1.0 : 0.0)
            .onAppear {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.65, blendDuration: 0.1)) {
                    isVisible = true
                }
            }
    }
}

/// View flutuante para mostrar mudança de idioma
struct LanguageNotificationView: View {
    let language: SpeechLanguage
    
    private var accentColor: Color {
        languageColor(for: language.rawValue)
    }
    
    var body: some View {
        HUDNotificationContainer {
            HStack(spacing: 14) {
                // Animated checkmark circle
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.2))
                        .frame(width: 36, height: 36)
                    
                    Circle()
                        .stroke(accentColor.opacity(0.4), lineWidth: 1.5)
                        .frame(width: 36, height: 36)
                    
                    Text(language.flag)
                        .font(.system(size: 18))
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text("Idioma")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.5))
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(accentColor)
                    }
                    
                    Text(language.displayName)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                }
                
                Spacer(minLength: 4)
                
                // Language code badge
                Text(language.rawValue.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(accentColor.opacity(0.15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(accentColor.opacity(0.3), lineWidth: 1)
                            )
                    )
            }
        }
        .frame(width: 260, height: 64)
    }
    
    private func languageColor(for code: String) -> Color {
        switch code.lowercased() {
        case "pt": return Color(red: 0.0, green: 0.53, blue: 0.35)
        case "en": return Color(red: 0.15, green: 0.39, blue: 0.92)
        case "es": return Color(red: 0.92, green: 0.35, blue: 0.05)
        case "fr": return Color(red: 0.23, green: 0.51, blue: 0.96)
        case "de": return Color(red: 0.79, green: 0.54, blue: 0.02)
        case "it": return Color(red: 0.13, green: 0.55, blue: 0.13)
        case "ja": return Color(red: 0.86, green: 0.15, blue: 0.15)
        case "ko": return Color(red: 0.0, green: 0.47, blue: 0.75)
        case "zh": return Color(red: 0.86, green: 0.08, blue: 0.24)
        case "ru": return Color(red: 0.0, green: 0.24, blue: 0.55)
        default: return Color(red: 0.4, green: 0.4, blue: 0.6)
        }
    }
}

/// View flutuante para mostrar mudança de modo
struct ModeNotificationView: View {
    let mode: TranscriptionMode

    private var modeColor: Color { mode.color }

    var body: some View {
        HUDNotificationContainer {
            HStack(spacing: 14) {
                // Mode icon with accented background
                ZStack {
                    Circle()
                        .fill(modeColor.opacity(0.2))
                        .frame(width: 36, height: 36)

                    Circle()
                        .stroke(modeColor.opacity(0.4), lineWidth: 1.5)
                        .frame(width: 36, height: 36)

                    Image(systemName: mode.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(modeColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text("Modo")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.5))
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(modeColor)
                    }

                    Text(mode.localizedName)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                }
                
                Spacer(minLength: 0)
            }
        }
        .frame(width: 240, height: 64)
    }
}

/// View flutuante para mostrar que a última transcrição foi colada
struct PasteLastNotificationView: View {
    let text: String
    let mode: TranscriptionMode

    private var modeColor: Color { mode.color }

    var body: some View {
        HUDNotificationContainer {
            HStack(spacing: 14) {
                // Clipboard icon
                ZStack {
                    Circle()
                        .fill(VoxTheme.accent.opacity(0.2))
                        .frame(width: 36, height: 36)

                    Circle()
                        .stroke(VoxTheme.accent.opacity(0.4), lineWidth: 1.5)
                        .frame(width: 36, height: 36)

                    Image(systemName: "doc.on.clipboard.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(VoxTheme.accent)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text("Colado")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.5))
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(VoxTheme.accent)
                    }

                    Text(text.prefix(30) + (text.count > 30 ? "…" : ""))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
                
                Spacer(minLength: 0)
            }
        }
        .frame(width: 280, height: 64)
    }
}

/// View flutuante para mostrar que não há histórico
struct NoHistoryNotificationView: View {
    var body: some View {
        HUDNotificationContainer {
            HStack(spacing: 14) {
                // Empty tray icon
                ZStack {
                    Circle()
                        .fill(VoxTheme.accent.opacity(0.2))
                        .frame(width: 36, height: 36)

                    Circle()
                        .stroke(VoxTheme.accent.opacity(0.4), lineWidth: 1.5)
                        .frame(width: 36, height: 36)

                    Image(systemName: "tray")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(VoxTheme.accent)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Histórico vazio")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)

                    Text("Nenhuma transcrição salva")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.white.opacity(0.5))
                }
                
                Spacer(minLength: 0)
            }
        }
        .frame(width: 260, height: 64)
    }
}

#Preview {
    VStack(spacing: 20) {
        LanguageNotificationView(language: .portuguese)
        ModeNotificationView(mode: .code)
        PasteLastNotificationView(text: "Hello world, this is a test transcription", mode: .text)
        NoHistoryNotificationView()
    }
    .padding(40)
    .background(Color.gray.opacity(0.3))
}
