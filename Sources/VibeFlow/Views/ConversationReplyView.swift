import SwiftUI

// MARK: - Conversation Reply HUD
// Floats above all windows. 4 states: translating → ready → recording → processing.
// Activated by ⌃⇧R with text selected. Reply with ⌥⌘ (existing shortcut).

struct ConversationReplyView: View {
    @ObservedObject var manager: ConversationReplyManager
    @ObservedObject var viewModel: VoxAiGoViewModel

    // Local animation state for processing sparkle rotation
    @State private var processingRotation: Double = 0
    // Pulsing animation for recording mic
    @State private var recordingPulse: Bool = false

    var body: some View {
        ZStack {
            // Subtle glow behind in recording state
            if case .recording = manager.state {
                Ellipse()
                    .fill(Color(red: 0.95, green: 0.25, blue: 0.25).opacity(0.15))
                    .frame(width: 300, height: 50)
                    .blur(radius: 30)
                    .allowsHitTesting(false)
            }

            mainCard

            // Hidden escape button to close HUD anytime
            Button(action: {
                manager.dismiss()
                NotificationCenter.default.post(name: .conversationReplyTimedOut, object: nil)
            }) {
                EmptyView()
            }
            .keyboardShortcut(.cancelAction)
            .opacity(0)
        }
    }

    // MARK: - Main Card

    private var mainCard: some View {
        Group {
            switch manager.state {
            case .idle:
                EmptyView()
            case .translating:
                translatingContent
            case .ready(let context):
                readyContent(context)
            case .recording:
                recordingContent
            case .processing:
                processingContent
            }
        }
        .frame(width: 440)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color(white: 0.08, opacity: 0.95))
        )
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.35), .clear, borderColor],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
    }

    // MARK: - Backgrounds & Borders

    private var borderColor: Color {
        switch manager.state {
        case .recording:
            return Color(red: 0.95, green: 0.25, blue: 0.25).opacity(0.5)
        case .processing:
            return VoxTheme.accent.opacity(0.5)
        default:
            return Color.white.opacity(0.15)
        }
    }

    // Used as animation value (Equatable proxy)
    private var borderColorKey: Int {
        switch manager.state {
        case .recording: return 1
        case .processing: return 2
        default: return 0
        }
    }

    // MARK: - State: Translating

    private var translatingContent: some View {
        HStack(spacing: 14) {
            Image(systemName: "globe")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(VoxTheme.accent)

            Text("Reading message...")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color.white.opacity(0.85))

            Spacer()

            ProgressView()
                .scaleEffect(0.8)
                .tint(Color.white.opacity(0.5))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }

    // MARK: - State: Ready

    private func readyContent(_ context: ConversationContext) -> some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Header: from → to + dismiss ──────────────────────────────
            HStack(spacing: 10) {
                languageBadge(
                    name: context.fromLanguageName,
                    code: context.fromLanguageCode,
                    color: Color(red: 0.95, green: 0.45, blue: 0.35)
                )

                Image(systemName: "arrow.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color.white.opacity(0.35))

                languageBadge(
                    name: context.toLanguageName,
                    code: nil,
                    color: Color(red: 0.35, green: 0.88, blue: 0.58)
                )

                Spacer()

                dismissButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            // ── Translated text (scrollable for long content) ─────────
            ScrollView {
                Text(context.translation)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(Color.white.opacity(0.95))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 220)
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 14)

            // ── Separator ────────────────────────────────────────────────
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)

            // ── CTA ──────────────────────────────────────────────────────
            HStack(spacing: 6) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Color.white.opacity(0.4))

                Text("Hold")
                    .font(.system(size: 13))
                    .foregroundColor(Color.white.opacity(0.5))

                shortcutBadge

                Text("to reply in \(context.fromLanguageName)")
                    .font(.system(size: 13))
                    .foregroundColor(Color.white.opacity(0.5))

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

            // ── Countdown bar ────────────────────────────────────────────
            countdownBar
        }
    }

    // MARK: - State: Recording

    private var recordingContent: some View {
        HStack(spacing: 16) {
            // Pulsing mic circle
            ZStack {
                Circle()
                    .fill(Color(red: 0.95, green: 0.25, blue: 0.25))
                    .frame(width: 36, height: 36)
                    .shadow(
                        color: Color(red: 0.95, green: 0.25, blue: 0.25).opacity(0.5),
                        radius: recordingPulse ? 12 : 7
                    )
                    .scaleEffect(recordingPulse ? 1.08 : 1.0)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: recordingPulse)

                Image(systemName: "mic.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            .onAppear { recordingPulse = true }
            .onDisappear { recordingPulse = false }

            VStack(alignment: .leading, spacing: 4) {
                Text("Replying in \(manager.detectedLanguageName)...")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color.white.opacity(0.95))

                SoundWaveView(audioLevel: viewModel.audioLevel)
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }

    // MARK: - State: Processing

    private var processingContent: some View {
        HStack(spacing: 14) {
            Image(systemName: "sparkles")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(VoxTheme.accent)
                .rotationEffect(.degrees(processingRotation))
                .onAppear {
                    withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                        processingRotation = 360
                    }
                }

            Text("Translating your reply...")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color.white.opacity(0.85))

            Spacer()

            ProgressView()
                .scaleEffect(0.8)
                .tint(Color.white.opacity(0.5))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }

    // MARK: - Reusable Components

    private func languageBadge(name: String, code: String?, color: Color) -> some View {
        HStack(spacing: 4) {
            if let code = code {
                Text(code.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(color)
            }
            Text(name)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(color.opacity(0.95))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(color.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(color.opacity(0.28), lineWidth: 1)
                )
        )
    }

    private var shortcutBadge: some View {
        HStack(spacing: 1) {
            Text("⌥")
            Text("⌘")
        }
        .font(.system(size: 12, weight: .medium, design: .rounded))
        .foregroundColor(Color.white.opacity(0.9))
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }

    private var dismissButton: some View {
        Button(action: {
            manager.dismiss()
            NotificationCenter.default.post(name: .conversationReplyTimedOut, object: nil)
        }) {
            Image(systemName: "xmark")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(Color.white.opacity(0.4))
                .frame(width: 26, height: 26)
                .background(Circle().fill(Color.white.opacity(0.08)))
        }
        .buttonStyle(.plain)
    }

    private var countdownBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.white.opacity(0.05))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .cornerRadius(1)

                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                VoxTheme.accent,
                                VoxTheme.accentLight
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * manager.timeoutProgress, height: 3)
                    .cornerRadius(1.5)
                    .animation(.linear(duration: 0.08), value: manager.timeoutProgress)
            }
        }
        .frame(height: 3)
    }
}

// MARK: - Preview

#Preview("Ready") {
    let manager = ConversationReplyManager.shared
    let viewModel = VoxAiGoViewModel()

    ConversationReplyView(manager: manager, viewModel: viewModel)
        .frame(width: 440, height: 260)
        .background(Color.black.opacity(0.6))
        .onAppear {
            manager.showReady(ConversationContext(
                originalText: "金曜日までにレポートを送ってもらえますか？",
                translation: "Can you send me the report by Friday?",
                fromLanguageName: "Japanese",
                fromLanguageCode: "JA",
                toLanguageName: "English"
            ))
        }
}

#Preview("Recording") {
    let manager = ConversationReplyManager.shared
    let viewModel = VoxAiGoViewModel()

    ConversationReplyView(manager: manager, viewModel: viewModel)
        .frame(width: 440, height: 140)
        .background(Color.black.opacity(0.6))
        .onAppear {
            manager.beginRecordingReply()
        }
}
