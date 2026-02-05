import SwiftUI
import Combine

// MARK: - Color Constants
private enum VoiceColors {
    static let accent = Color(red: 0.4, green: 0.4, blue: 1.0) // Indigo
    static let accentGlow = Color(red: 0.4, green: 0.4, blue: 1.0).opacity(0.3)
    static let speechActive = Color(red: 0.95, green: 0.25, blue: 0.25) // Red for active speech
    static let speechActiveGlow = Color(red: 0.95, green: 0.25, blue: 0.25).opacity(0.3)
    static let processing = Color(red: 0.6, green: 0.4, blue: 1.0) // Purple
    static let background = Color.black.opacity(0.75)
    static let backgroundIdle = Color.black.opacity(0.6)
    static let border = Color.white.opacity(0.1)
    static let textPrimary = Color.white.opacity(0.9)
    static let textSecondary = Color.white.opacity(0.5)

    // Language colors (elegant, no emoji)
    static func languageColor(for code: String) -> Color {
        switch code.lowercased() {
        case "pt": return Color(red: 0.0, green: 0.53, blue: 0.35) // Emerald
        case "en": return Color(red: 0.15, green: 0.39, blue: 0.92) // Royal Blue
        case "es": return Color(red: 0.92, green: 0.35, blue: 0.05) // Orange
        case "fr": return Color(red: 0.23, green: 0.51, blue: 0.96) // French Blue
        case "de": return Color(red: 0.79, green: 0.54, blue: 0.02) // Gold
        case "it": return Color(red: 0.13, green: 0.55, blue: 0.13) // Italian Green
        case "ja": return Color(red: 0.86, green: 0.15, blue: 0.15) // Red
        case "ko": return Color(red: 0.0, green: 0.47, blue: 0.75) // Korean Blue
        case "zh": return Color(red: 0.86, green: 0.08, blue: 0.24) // Chinese Red
        case "ru": return Color(red: 0.0, green: 0.24, blue: 0.55) // Russian Blue
        default: return Color(red: 0.4, green: 0.4, blue: 0.6) // Default purple-ish
        }
    }

    // Mode colors
    static func modeColor(for mode: TranscriptionMode) -> Color {
        switch mode {
        case .code: return Color(red: 0.2, green: 0.6, blue: 1.0)
        case .text: return Color(red: 0.3, green: 0.75, blue: 0.45)
        case .email: return Color(red: 1.0, green: 0.55, blue: 0.2)
        case .uxDesign: return Color(red: 0.75, green: 0.4, blue: 0.9)
        case .command: return Color(red: 0.95, green: 0.75, blue: 0.2)
        }
    }
}

// MARK: - Main Content View
struct ContentView: View {
    @EnvironmentObject var viewModel: VibeFlowViewModel

    var body: some View {
        GeometryReader { geometry in
            ModernVoiceOverlay(viewModel: viewModel)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
    }
}

// MARK: - Modern Voice Overlay
struct ModernVoiceOverlay: View {
    @ObservedObject var viewModel: VibeFlowViewModel
    @StateObject private var settings = SettingsManager.shared

    // Animation states
    @State private var isExpanded = false
    @State private var showContent = false
    @State private var glowOpacity: CGFloat = 0
    @State private var micPulse = false

    private var currentState: OverlayState {
        if viewModel.isProcessing {
            return .processing
        } else if viewModel.isRecording {
            return .listening
        } else {
            return .idle
        }
    }

    /// Whether the audio level indicates active speech (for visual feedback)
    private var isSpeechActive: Bool {
        currentState == .listening && viewModel.audioLevel > 0.05
    }

    var body: some View {
        ZStack {
            // Subtle glow behind (only when active)
            if currentState == .listening {
                Ellipse()
                    .fill(isSpeechActive ? VoiceColors.speechActiveGlow : VoiceColors.accentGlow)
                    .frame(width: 350, height: 80)
                    .blur(radius: 40)
                    .opacity(glowOpacity)
                    .animation(.easeInOut(duration: 0.2), value: isSpeechActive)
            }

            // Main container
            mainContainer
        }
        .onChange(of: viewModel.isRecording) { isRecording in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                isExpanded = isRecording
            }
            withAnimation(.easeOut(duration: 0.3).delay(0.1)) {
                showContent = isRecording
            }
            withAnimation(.easeInOut(duration: 0.5)) {
                glowOpacity = isRecording ? 0.5 : 0
            }
            if !isRecording {
                micPulse = false
            }
        }
        .onChange(of: viewModel.isProcessing) { isProcessing in
            if isProcessing {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded = false
                }
            }
        }
    }

    private var mainContainer: some View {
        HStack(spacing: 0) {
            // Left: Microphone icon with waves
            leftSection

            // Divider (only when expanded)
            if isExpanded && currentState == .listening {
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 1, height: 28)
                    .padding(.horizontal, 8)
                    .transition(.opacity.combined(with: .scale(scale: 0.5)))
            }

            // Center: Content (status, transcript)
            centerSection

            // Right: Language + Mode (only when listening)
            if showContent && currentState == .listening {
                rightSection
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
        }
        .padding(.horizontal, isExpanded ? 20 : 16)
        .padding(.vertical, 12)
        .frame(
            width: containerWidth,
            height: containerHeight
        )
        .background(
            // Clean dark background with no glassmorphism artifacts
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.12, green: 0.12, blue: 0.15),
                            Color(red: 0.08, green: 0.08, blue: 0.10)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .animation(.spring(response: 0.45, dampingFraction: 0.78), value: isExpanded)
        .animation(.spring(response: 0.45, dampingFraction: 0.78), value: currentState)
    }

    private var containerWidth: CGFloat {
        switch currentState {
        case .idle:
            return 200
        case .listening:
            return 440
        case .processing:
            return 220
        }
    }

    private var containerHeight: CGFloat {
        return 56
    }

    // MARK: - Left Section (Mic + Waves)
    private var leftSection: some View {
        HStack(spacing: 10) {
            // Microphone icon
            ZStack {
                // Glow circle when active
                if currentState == .listening {
                    Circle()
                        .fill(isSpeechActive ? VoiceColors.speechActive : VoiceColors.accent)
                        .frame(width: 32, height: 32)
                        .shadow(color: (isSpeechActive ? VoiceColors.speechActive : VoiceColors.accent).opacity(0.4), radius: 8)
                        .opacity(micPulse ? 0.6 : 1.0)
                }

                Circle()
                    .fill(currentState == .listening
                          ? (isSpeechActive ? VoiceColors.speechActive : VoiceColors.accent)
                          : Color.clear)
                    .frame(width: 28, height: 28)
                    .opacity(micPulse ? 0.7 : 1.0)

                Image(systemName: micIcon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(currentState == .listening ? .white : VoiceColors.textSecondary)
            }
            .animation(.easeInOut(duration: 0.2), value: isSpeechActive)
            .onChange(of: isSpeechActive) { active in
                if active {
                    // Start pulsing when speech detected
                    withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
                        micPulse = true
                    }
                } else {
                    // Stop pulsing when quiet
                    withAnimation(.easeInOut(duration: 0.2)) {
                        micPulse = false
                    }
                }
            }

            // Sound wave bars (only when listening)
            if currentState == .listening {
                SoundWaveView(audioLevel: viewModel.audioLevel)
                    .transition(.opacity.combined(with: .scale(scale: 0.8, anchor: .leading)))
            }
        }
    }

    private var micIcon: String {
        switch currentState {
        case .processing:
            return "sparkles"
        default:
            return "mic.fill"
        }
    }

    // MARK: - Center Section (Status)
    private var centerSection: some View {
        Group {
            switch currentState {
            case .idle:
                idleContent
            case .listening:
                listeningContent
            case .processing:
                processingContent
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var idleContent: some View {
        HStack(spacing: 6) {
            Text("Segure")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(VoiceColors.textSecondary)

            // Keyboard shortcut badge
            HStack(spacing: 2) {
                Text("⌥")
                Text("⌘")
            }
            .font(.system(size: 11, weight: .medium, design: .rounded))
            .foregroundColor(VoiceColors.textPrimary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
        }
    }

    private var listeningContent: some View {
        Text("Ouvindo...")
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(VoiceColors.textPrimary)
            .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    private var processingContent: some View {
        HStack(spacing: 8) {
            // Spinning sparkle
            Image(systemName: "sparkles")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(VoiceColors.processing)
                .rotationEffect(.degrees(viewModel.isProcessing ? 360 : 0))
                .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: viewModel.isProcessing)

            Text("Processando...")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(VoiceColors.processing)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }

    // MARK: - Right Section (Language + Mode)
    private var rightSection: some View {
        HStack(spacing: 8) {
            // Language indicator (elegant, no emoji)
            LanguagePill(language: settings.outputLanguage)

            // Mode indicator
            ModePill(mode: viewModel.selectedMode)
        }
    }
}

// MARK: - Overlay State
private enum OverlayState {
    case idle
    case listening
    case processing
}

// MARK: - Sound Wave View
struct SoundWaveView: View {
    let audioLevel: CGFloat

    private let barCount = 6

    /// Audio level threshold for visual speech detection feedback
    private let speechVisualThreshold: CGFloat = 0.05

    private var isSpeechActive: Bool {
        audioLevel > speechVisualThreshold
    }

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<barCount, id: \.self) { index in
                SoundWaveBar(
                    index: index,
                    audioLevel: audioLevel,
                    isSpeechActive: isSpeechActive,
                    totalBars: barCount
                )
            }
        }
        .frame(width: 50, height: 20)
    }
}

// MARK: - Sound Wave Bar
struct SoundWaveBar: View {
    let index: Int
    let audioLevel: CGFloat
    let isSpeechActive: Bool
    let totalBars: Int

    private var barColor: Color {
        isSpeechActive ? VoiceColors.speechActive : VoiceColors.accent
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 1.5)
            .fill(barColor.opacity(0.8 + Double(audioLevel) * 0.2))
            .frame(width: 3, height: barHeight)
            .animation(
                .easeInOut(duration: 0.15)
                .delay(Double(index) * 0.05),
                value: audioLevel
            )
            .animation(.easeInOut(duration: 0.2), value: isSpeechActive)
    }

    private var barHeight: CGFloat {
        let minHeight: CGFloat = 4
        let maxHeight: CGFloat = 18

        // Create wave pattern based on index
        let centerOffset = abs(CGFloat(index) - CGFloat(totalBars - 1) / 2)
        let positionMultiplier = 1.0 - (centerOffset / CGFloat(totalBars) * 0.5)

        // Apply audio level with some variation per bar
        let variation = sin(Double(index) * 1.2) * 0.3 + 0.7
        let effectiveLevel = max(audioLevel, 0.1) * CGFloat(variation) * positionMultiplier

        let height = minHeight + (maxHeight - minHeight) * effectiveLevel
        return min(max(height, minHeight), maxHeight)
    }
}

// MARK: - Language Pill (Elegant, No Emoji)
struct LanguagePill: View {
    let language: SpeechLanguage

    private var languageCode: String {
        language.rawValue.uppercased()
    }

    private var accentColor: Color {
        VoiceColors.languageColor(for: language.rawValue)
    }

    var body: some View {
        Text(languageCode)
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundColor(accentColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
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

// MARK: - Mode Pill
struct ModePill: View {
    let mode: TranscriptionMode

    private var modeColor: Color {
        VoiceColors.modeColor(for: mode)
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: mode.icon)
                .font(.system(size: 9, weight: .semibold))

            Text(mode.shortDescription)
                .font(.system(size: 10, weight: .semibold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(modeColor)
                .shadow(color: modeColor.opacity(0.4), radius: 4, y: 2)
        )
    }
}

// MARK: - Language Selector (Sheet)
struct LanguageSelectorView3: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var settings = SettingsManager.shared

    var body: some View {
        VStack(spacing: 16) {
            Text("Selecionar Idioma")
                .font(.headline)

            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                    ForEach(SpeechLanguage.allCases) { language in
                        Button(action: {
                            settings.outputLanguage = language
                            dismiss()
                        }) {
                            HStack(spacing: 6) {
                                Text(language.rawValue.uppercased())
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                Text(language.displayName)
                                    .font(.system(size: 11))
                                    .lineLimit(1)
                            }
                            .foregroundColor(settings.outputLanguage == language ? .white : .primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(settings.outputLanguage == language
                                          ? VoiceColors.languageColor(for: language.rawValue)
                                          : Color(nsColor: .controlBackgroundColor))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }

            Button("Fechar") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(width: 400, height: 350)
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.8)
            .ignoresSafeArea()

        ContentView()
            .environmentObject(VibeFlowViewModel())
    }
}
