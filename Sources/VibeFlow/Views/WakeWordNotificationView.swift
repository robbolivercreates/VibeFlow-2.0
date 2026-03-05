import SwiftUI

/// Floating HUD shown when a wake word command changes mode or language.
/// Matches the style of `LanguageNotificationView`.
struct WakeWordNotificationView: View {
    let label: String
    let icon: String

    private let accent = Color(hue: 0.75, saturation: 0.6, brightness: 0.95)  // purple

    var body: some View {
        HUDNotificationContainer {
            HStack(spacing: 14) {
                // Icon circle
                ZStack {
                    Circle()
                        .fill(accent.opacity(0.2))
                        .frame(width: 36, height: 36)

                    Circle()
                        .stroke(accent.opacity(0.4), lineWidth: 1.5)
                        .frame(width: 36, height: 36)

                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(accent)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text("Vox")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.white.opacity(0.5))

                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(accent)
                    }

                    Text(label)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }

                Spacer(minLength: 4)

                // "Active" badge
                Text("✦")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(accent.opacity(0.15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(accent.opacity(0.3), lineWidth: 1)
                            )
                    )
            }
            .padding(.horizontal, 16)
        }
    }
}

#Preview {
    WakeWordNotificationView(label: "Vibe Coder", icon: "chevron.left.forwardslash.chevron.right")
        .frame(width: 280, height: 64)
}
