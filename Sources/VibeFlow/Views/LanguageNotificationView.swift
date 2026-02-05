import SwiftUI

/// View flutuante para mostrar mudança de idioma
struct LanguageNotificationView: View {
    let language: SpeechLanguage
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
            
            HStack(spacing: 8) {
                Text(language.flag)
                    .font(.system(size: 24))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(language.displayName)
                        .font(.system(size: 13, weight: .semibold))
                    
                    Text("Idioma de saída")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .frame(width: 180, height: 60)
    }
}

/// View flutuante para mostrar mudança de modo
struct ModeNotificationView: View {
    let mode: TranscriptionMode

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)

            HStack(spacing: 8) {
                Image(systemName: mode.icon)
                    .font(.system(size: 20))
                    .foregroundStyle(mode.color)

                VStack(alignment: .leading, spacing: 2) {
                    Text(mode.localizedName)
                        .font(.system(size: 13, weight: .semibold))

                    Text("Modo de transcrição")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .frame(width: 200, height: 60)
    }
}

#Preview {
    LanguageNotificationView(language: .portuguese)
        .padding()
        .background(Color.gray.opacity(0.2))
}
