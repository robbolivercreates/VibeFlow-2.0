import SwiftUI
import Combine

// MARK: - Color Constants
private enum VoiceColors {
    static let accent = Color.white  // White for idle waveform/mic
    static let accentGlow = Color.white.opacity(0.3)
    static let speechActive = Color(red: 0.95, green: 0.25, blue: 0.25) // Red for active speech
    static let speechActiveGlow = Color(red: 0.95, green: 0.25, blue: 0.25).opacity(0.3)
    static let processing = VoxTheme.accent  // Gold for processing state
    static let transform = Color(red: 0.65, green: 0.45, blue: 1.0) // Purple for transform mode
    static let background = Color.black.opacity(0.75)
    static let backgroundIdle = Color.black.opacity(0.6)
    static let border = Color.white.opacity(0.1)
    static let textPrimary = Color.white.opacity(0.9)
    static let textSecondary = Color.white.opacity(0.5)

    // Language color — unified gold for all
    static func languageColor(for code: String) -> Color {
        return VoxTheme.accent
    }

    // Mode color — unified gold for all
    static func modeColor(for mode: TranscriptionMode) -> Color {
        return VoxTheme.accent
    }
}

// MARK: - Main Content View
struct ContentView: View {
    @EnvironmentObject var viewModel: VoxAiGoViewModel

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
    @ObservedObject var viewModel: VoxAiGoViewModel
    @StateObject private var settings = SettingsManager.shared

    // Animation states
    @State private var isExpanded = false
    @State private var showContent = false
    @State private var glowOpacity: CGFloat = 0
    @State private var micPulse = false

    // Processing stage feedback
    @State private var processingStage: Int = 0
    @State private var processingTimer: Timer?
    @State private var showStagedFeedback = false

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
                // Start staged feedback after 2s delay
                processingStage = 0
                showStagedFeedback = false
                processingTimer?.invalidate()
                processingTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
                    DispatchQueue.main.async {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showStagedFeedback = true
                        }
                        // Then cycle through stages every 2.5s
                        processingTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { _ in
                            DispatchQueue.main.async {
                                withAnimation(.easeInOut(duration: 0.35)) {
                                    processingStage = min(processingStage + 1, 3)
                                }
                            }
                        }
                    }
                }
            } else {
                // Reset staged feedback
                processingTimer?.invalidate()
                processingTimer = nil
                showStagedFeedback = false
                processingStage = 0
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
        .padding(.horizontal, isExpanded ? 22 : 18)
        .padding(.vertical, 14)
        .frame(
            width: containerWidth,
            height: containerHeight
        )
        .background(
            Capsule()
                .fill(Color(white: 0.12, opacity: 0.85))
        )
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(
                    LinearGradient(
                        colors: settings.isVoxActive && currentState == .listening
                            ? [VoxTheme.accent.opacity(0.4), VoxTheme.accent.opacity(0.1)]
                            : [Color.white.opacity(0.15), Color.white.opacity(0.02)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: settings.isVoxActive && currentState == .listening ? 1.5 : 1
                )
        )
        .shadow(
            color: settings.isVoxActive && currentState == .listening
                ? VoxTheme.accent.opacity(0.2) : Color.clear,
            radius: 12
        )
        .animation(.spring(response: 0.45, dampingFraction: 0.75, blendDuration: 0.1), value: isExpanded)
        .animation(.spring(response: 0.45, dampingFraction: 0.75, blendDuration: 0.1), value: currentState)
    }

    private var containerWidth: CGFloat {
        switch currentState {
        case .idle:
            // Wider when showing favorite mode pills
            return settings.favoriteModes.isEmpty ? 200 : 280
        case .listening:
            return 440
        case .processing:
            return showStagedFeedback ? 300 : 220
        }
    }

    private var containerHeight: CGFloat {
        return 56
    }

    // MARK: - Left Section (Mic + Waves)
    private var leftSection: some View {
        HStack(spacing: 10) {
            // Microphone icon (transform visuals only during processing)
            ZStack {
                // Vox AI glow — golden neon effect when AI engine is active
                if settings.isVoxActive {
                    Circle()
                        .fill(VoxTheme.accent.opacity(0.1))
                        .frame(width: 40, height: 40)
                        .shadow(color: VoxTheme.accent.opacity(0.5), radius: 10)
                        .shadow(color: VoxTheme.accent.opacity(0.25), radius: 20)
                        .opacity(currentState == .idle ? 0.4 : (micPulse ? 0.5 : 0.8))
                        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: currentState == .listening)
                }

                if currentState == .listening && isSpeechActive {
                    // Speaking: red circle with pulse
                    Circle()
                        .fill(VoiceColors.speechActive)
                        .frame(width: 32, height: 32)
                        .opacity(micPulse ? 0.6 : 1.0)

                    Circle()
                        .fill(VoiceColors.speechActive)
                        .frame(width: 28, height: 28)
                        .opacity(micPulse ? 0.7 : 1.0)
                } else if currentState != .processing {
                    // Idle or listening-quiet: white dot behind gold mic
                    Circle()
                        .fill(Color.white)
                        .frame(width: 28, height: 28)
                }

                Image(systemName: micIcon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(
                        currentState == .listening && isSpeechActive
                            ? .white  // White mic on red circle
                            : (currentState == .processing
                                ? (viewModel.isTransformMode ? VoiceColors.transform : VoiceColors.processing)
                                : VoxTheme.accent)  // Gold mic
                    )
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
            return viewModel.isTransformMode ? "wand.and.stars" : "sparkles"
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
            if viewModel.statusText == L10n.pasted {
                // Show success state briefly after paste (prevents "Segure" flash)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.green)
                Text(L10n.pasted)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.green)
            } else if let error = viewModel.error, !error.isEmpty {
                // Show error state
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.orange)
                Text(error)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.orange)
                    .lineLimit(1)
            } else if !settings.favoriteModes.isEmpty {
                // Favorite mode pills — click to switch mode
                HStack(spacing: 5) {
                    ForEach(settings.favoriteModes, id: \.self) { mode in
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                settings.selectedMode = mode
                            }
                        }) {
                            HStack(spacing: 3) {
                                Image(systemName: mode.icon)
                                    .font(.system(size: 8, weight: .semibold))
                                Text(mode.localizedName)
                                    .font(.system(size: 9, weight: .semibold))
                            }
                            .foregroundColor(mode == settings.selectedMode ? .white : VoiceColors.textSecondary)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(mode == settings.selectedMode
                                          ? VoxTheme.accent
                                          : Color.white.opacity(0.08))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(mode == settings.selectedMode
                                            ? VoxTheme.accent.opacity(0.6)
                                            : Color.white.opacity(0.06), lineWidth: 0.5)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            } else {
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
    }

    private var listeningContent: some View {
        Text(settings.isVoxActive ? L10n.voxListening : L10n.listening)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(settings.isVoxActive ? VoiceColors.processing : VoiceColors.textPrimary)
            .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    private var processingContent: some View {
        HStack(spacing: 8) {
            // Spinning sparkle
            Image(systemName: processingStageIcon)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(viewModel.isTransformMode ? VoiceColors.transform : VoiceColors.processing)
                .rotationEffect(.degrees(viewModel.isProcessing ? 360 : 0))
                .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: viewModel.isProcessing)

            Text(processingStageText)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(viewModel.isTransformMode ? VoiceColors.transform : VoiceColors.processing)
                .id("stage_\(processingStage)_\(showStagedFeedback)")
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .bottom)),
                    removal: .opacity.combined(with: .move(edge: .top))
                ))
        }
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }

    /// Current processing stage text
    private var processingStageText: String {
        if viewModel.isTransformMode { return L10n.transforming }
        guard showStagedFeedback else {
            return settings.isVoxActive ? L10n.voxProcessing : L10n.processing
        }
        switch processingStage {
        case 0: return "Agente Vox Ativado"
        case 1: return "Buscando Informações..."
        case 2: return "Analisando Dados..."
        default: return "Sintetizando Resultados..."
        }
    }

    /// Icon changes with stage for visual variety
    private var processingStageIcon: String {
        if viewModel.isTransformMode { return "wand.and.stars" }
        guard showStagedFeedback else { return "sparkles" }
        switch processingStage {
        case 0: return "sparkles"
        case 1: return "magnifyingglass"
        case 2: return "brain.head.profile"
        default: return "text.badge.checkmark"
        }
    }

    // MARK: - Right Section (Language + Mode)
    private var rightSection: some View {
        HStack(spacing: 8) {
            // Offline badge
            if settings.offlineMode {
                Text("OFFLINE")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundColor(.orange)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.orange.opacity(0.15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                            )
                    )
            }

            // Language indicator (elegant, no emoji)
            LanguagePill(language: settings.outputLanguage)

            // Mode indicator — show Transform pill when in transform mode
            if viewModel.isTransformMode {
                TransformPill()
            } else {
                ModePill(mode: settings.offlineMode ? .text : viewModel.selectedMode)
            }
        }
    }
}

// MARK: - Overlay State
private enum OverlayState {
    case idle
    case listening
    case processing
}

// MARK: - Organic Sound Wave View
struct SoundWaveView: View {
    let audioLevel: CGFloat

    /// Audio level threshold for visual speech detection feedback
    private let speechVisualThreshold: CGFloat = 0.05

    private var isSpeechActive: Bool {
        audioLevel > speechVisualThreshold
    }

    var body: some View {
        ZStack {
            // Background ambient wave (wider, softer)
            OrganicWaveShape(level: audioLevel, frequency: 1.5, phase: isSpeechActive ? .random(in: 0...2) : 0)
                .fill(
                    LinearGradient(
                        colors: [
                            (isSpeechActive ? VoiceColors.speechActive : VoiceColors.accent).opacity(0.4),
                            Color.clear
                        ],
                        startPoint: .center,
                        endPoint: .trailing
                    )
                )
                .frame(width: 90, height: 36)
                .blur(radius: 2)

            // Foreground sharp wave
            OrganicWaveShape(level: audioLevel, frequency: 2.0, phase: isSpeechActive ? .random(in: 0...4) : 0)
                .fill(
                    LinearGradient(
                        colors: [
                            isSpeechActive ? VoiceColors.speechActive : VoiceColors.accent,
                            (isSpeechActive ? VoiceColors.speechActive : VoiceColors.accent).opacity(0.6)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 80, height: 28)
        }
        .animation(.spring(response: 0.15, dampingFraction: 0.5, blendDuration: 0.1), value: audioLevel)
        .animation(.easeInOut(duration: 0.3), value: isSpeechActive)
    }
}

// MARK: - Organic Wave Shape
struct OrganicWaveShape: Shape {
    var level: CGFloat
    var frequency: CGFloat
    var phase: CGFloat

    var animatableData: AnimatablePair<CGFloat, AnimatablePair<CGFloat, CGFloat>> {
        get { AnimatablePair(level, AnimatablePair(frequency, phase)) }
        set {
            level = newValue.first
            frequency = newValue.second.first
            phase = newValue.second.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let midY = rect.height / 2
        
        let minAmplitude: CGFloat = 2.0
        let maxAmplitude = rect.height / 2
        
        // Effective amplitude based on audio level
        let amplitude = minAmplitude + (maxAmplitude - minAmplitude) * max(0, min(level * 1.5, 1.0))
        
        path.move(to: CGPoint(x: 0, y: midY))
        
        // Draw top curve
        for x in stride(from: 0, through: width, by: 1) {
            let relativeX = x / width
            // Bell curve to taper edges
            let taper = sin(relativeX * .pi)
            
            let yOffset = sin((relativeX * .pi * frequency) + phase) * amplitude * taper
            path.addLine(to: CGPoint(x: x, y: midY - yOffset))
        }
        
        // Draw bottom curve (mirrored usually, but add slight phase shift for organic feel)
        for x in stride(from: width, through: 0, by: -1) {
            let relativeX = x / width
            let taper = sin(relativeX * .pi)
            
            let yOffset = sin((relativeX * .pi * frequency) + phase + 0.5) * amplitude * taper
            path.addLine(to: CGPoint(x: x, y: midY + yOffset))
        }
        
        path.closeSubpath()
        return path
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

            Text(mode.localizedName)
                .font(.system(size: 10, weight: .semibold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(modeColor)
        )
    }
}
// MARK: - Transform Pill
struct TransformPill: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "wand.and.stars")
                .font(.system(size: 9, weight: .semibold))

            Text("Transform")
                .font(.system(size: 10, weight: .semibold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(
                        colors: [VoiceColors.transform, VoxTheme.accent],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
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
                                          : VoxTheme.surface)
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
            .environmentObject(VoxAiGoViewModel())
    }
}
