import SwiftUI
import Combine

// MARK: - Main Content View
struct ContentView: View {
    @EnvironmentObject var viewModel: VibeFlowViewModel
    
    var body: some View {
        RecordingInterface(viewModel: viewModel)
            .frame(width: 320, height: 140)
    }
}

// MARK: - Modern Recording Interface
struct RecordingInterface: View {
    @ObservedObject var viewModel: VibeFlowViewModel
    @State private var showLanguagePicker = false
    
    var body: some View {
        ZStack {
            // Background with material effect
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 8)
            
            VStack(spacing: 0) {
                // Top section: Recording info or Language selector
                if viewModel.isRecording {
                    RecordingInfoBar(viewModel: viewModel)
                        .transition(.move(edge: .top).combined(with: .opacity))
                } else {
                    IdleTopBar(viewModel: viewModel)
                        .transition(.opacity)
                }
                
                Spacer()
                
                // Middle: Status and main action
                HStack(spacing: 16) {
                    // Mode indicator
                    ModeBadge(mode: viewModel.selectedMode)
                    
                    Spacer()
                    
                    // Status
                    StatusDisplay(viewModel: viewModel)
                    
                    Spacer()
                    
                    // Action button
                    RecordButton(viewModel: viewModel)
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Bottom: Waveform
                WaveformSection(viewModel: viewModel)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
            }
            .padding(.vertical, 12)
        }
    }
}

// MARK: - Idle Top Bar
struct IdleTopBar: View {
    @ObservedObject var viewModel: VibeFlowViewModel
    @StateObject private var settings = SettingsManager.shared
    @State private var showLanguageSelector = false
    
    var body: some View {
        HStack {
            // Current language button
            Button(action: { showLanguageSelector = true }) {
                HStack(spacing: 4) {
                    Text(settings.outputLanguage.flag)
                        .font(.system(size: 14))
                    Text(settings.outputLanguage.rawValue.uppercased())
                        .font(.system(size: 10, weight: .medium))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 8))
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.secondary.opacity(0.1))
                )
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            // Quick language switcher (only if multiple favorites)
            if settings.favoriteLanguages.count > 1 {
                HStack(spacing: 4) {
                    ForEach(settings.favoriteLanguages.prefix(3)) { language in
                        Button(action: {
                            settings.outputLanguage = language
                        }) {
                            Text(language.flag)
                                .font(.system(size: 12))
                                .opacity(settings.outputLanguage == language ? 1.0 : 0.4)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .sheet(isPresented: $showLanguageSelector) {
            LanguageSelectorView()
        }
    }
}

// MARK: - Recording Info Bar
struct RecordingInfoBar: View {
    @ObservedObject var viewModel: VibeFlowViewModel
    @StateObject private var settings = SettingsManager.shared
    
    var body: some View {
        HStack(spacing: 12) {
            // Mode badge
            HStack(spacing: 4) {
                Image(systemName: viewModel.selectedMode.icon)
                    .font(.system(size: 10))
                Text(viewModel.selectedMode.shortDescription)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(modeColor)
            .cornerRadius(6)
            
            // Language indicator
            HStack(spacing: 2) {
                Text(settings.outputLanguage.flag)
                    .font(.system(size: 10))
                Text(settings.outputLanguage.rawValue.uppercased())
                    .font(.system(size: 9, weight: .bold))
            }
            .foregroundColor(.blue)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.blue.opacity(0.15))
            .cornerRadius(4)
            
            Spacer()
            
            // Recording timer
            RecordingTimer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
    }
    
    private var modeColor: Color {
        switch viewModel.selectedMode {
        case .code: return Color(red: 0.2, green: 0.6, blue: 1.0)
        case .text: return Color(red: 0.3, green: 0.8, blue: 0.4)
        case .email: return Color(red: 1.0, green: 0.5, blue: 0.2)
        case .uxDesign: return Color(red: 0.8, green: 0.4, blue: 0.9)
        case .command: return Color(red: 0.9, green: 0.3, blue: 0.5)
        }
    }
}

// MARK: - Recording Timer
struct RecordingTimer: View {
    @State private var startTime = Date()
    @State private var elapsed: TimeInterval = 0
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack(spacing: 4) {
            // Recording indicator dot
            RecordingPulseDot()
            
            // Time display
            Text(formattedTime)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundColor(.primary)
                .frame(minWidth: 45, alignment: .trailing)
        }
    }
    
    private var formattedTime: String {
        let seconds = Int(elapsed)
        let tenths = Int((elapsed - Double(seconds)) * 10)
        return String(format: "%d.%d", seconds, tenths)
    }
}

// MARK: - Recording Pulse Dot
struct RecordingPulseDot: View {
    @State private var isPulsing = false
    
    var body: some View {
        Circle()
            .fill(Color.red)
            .frame(width: 6, height: 6)
            .overlay(
                Circle()
                    .fill(Color.red.opacity(0.4))
                    .scaleEffect(isPulsing ? 2.5 : 1.0)
                    .opacity(isPulsing ? 0 : 0.6)
            )
            .animation(.easeOut(duration: 0.8).repeatForever(autoreverses: false), value: isPulsing)
            .onAppear { isPulsing = true }
    }
}

// MARK: - Mode Badge
struct ModeBadge: View {
    let mode: TranscriptionMode
    
    var body: some View {
        Menu {
            ForEach(TranscriptionMode.allCases, id: \.self) { m in
                Button(action: {
                    SettingsManager.shared.selectedMode = m
                    NotificationCenter.default.post(name: .modeChanged, object: m)
                }) {
                    Label(m.localizedName, systemImage: m.icon)
                }
            }
        } label: {
            HStack(spacing: 3) {
                Circle()
                    .fill(modeColor)
                    .frame(width: 6, height: 6)
                Image(systemName: "chevron.down")
                    .font(.system(size: 8))
            }
            .foregroundStyle(.secondary)
            .padding(6)
            .background(
                Circle()
                    .fill(Color.secondary.opacity(0.1))
            )
        }
        .menuStyle(.borderlessButton)
    }
    
    private var modeColor: Color {
        switch mode {
        case .code: return Color(red: 0.2, green: 0.6, blue: 1.0)
        case .text: return Color(red: 0.3, green: 0.8, blue: 0.4)
        case .email: return Color(red: 1.0, green: 0.5, blue: 0.2)
        case .uxDesign: return Color(red: 0.8, green: 0.4, blue: 0.9)
        case .command: return Color(red: 0.9, green: 0.3, blue: 0.5)
        }
    }
}

// MARK: - Status Display
struct StatusDisplay: View {
    @ObservedObject var viewModel: VibeFlowViewModel
    
    var body: some View {
        Group {
            if viewModel.isProcessing {
                ProcessingStatus()
            } else if viewModel.isRecording {
                RecordingStatus()
            } else if viewModel.needsAPIKey {
                Text("API Key necessária")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.orange)
            } else if viewModel.error != nil {
                Text("Erro")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.red)
            } else {
                Text("Segure ⌥⌘")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary.opacity(0.7))
            }
        }
    }
}

// MARK: - Recording Status
struct RecordingStatus: View {
    var body: some View {
        HStack(spacing: 6) {
            Text("Gravando...")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Processing Status
struct ProcessingStatus: View {
    var body: some View {
        HStack(spacing: 6) {
            ProgressView()
                .scaleEffect(0.7)
                .tint(.orange)
            
            Text("Processando")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.orange)
        }
    }
}

// MARK: - Record Button
struct RecordButton: View {
    @ObservedObject var viewModel: VibeFlowViewModel
    
    var body: some View {
        Button(action: {
            viewModel.toggleRecording()
        }) {
            ZStack {
                // Outer glow when recording
                if viewModel.isRecording {
                    Circle()
                        .fill(Color.red.opacity(0.2))
                        .frame(width: 44, height: 44)
                        .scaleEffect(1.2)
                }
                
                // Main button
                Circle()
                    .fill(buttonBackground)
                    .frame(width: 38, height: 38)
                    .shadow(color: buttonShadowColor.opacity(0.3), radius: 8, x: 0, y: 3)
                
                // Icon
                Image(systemName: buttonIcon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(viewModel.isProcessing || viewModel.needsAPIKey)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isRecording)
    }
    
    private var buttonBackground: Color {
        if viewModel.isProcessing {
            return Color.orange
        } else if viewModel.isRecording {
            return Color.red
        } else {
            return Color.green
        }
    }
    
    private var buttonShadowColor: Color {
        if viewModel.isProcessing {
            return .orange
        } else if viewModel.isRecording {
            return .red
        } else {
            return .green
        }
    }
    
    private var buttonIcon: String {
        if viewModel.isProcessing {
            return "ellipsis"
        } else if viewModel.isRecording {
            return "stop.fill"
        } else {
            return "mic.fill"
        }
    }
}

// MARK: - Waveform Section
struct WaveformSection: View {
    @ObservedObject var viewModel: VibeFlowViewModel
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<20, id: \.self) { i in
                WaveformBar(
                    index: i,
                    level: viewModel.isRecording ? viewModel.audioLevel : 0.02,
                    isRecording: viewModel.isRecording
                )
            }
        }
        .frame(height: 28)
    }
}

// MARK: - Waveform Bar
struct WaveformBar: View {
    let index: Int
    let level: CGFloat
    let isRecording: Bool
    @State private var randomOffset: CGFloat = 0
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(barColor)
            .frame(width: 3, height: barHeight)
            .animation(.easeOut(duration: 0.05), value: level)
            .onAppear {
                randomOffset = CGFloat.random(in: 0...1)
            }
    }
    
    private var barHeight: CGFloat {
        let centerIndex = 9.5
        let distanceFromCenter = abs(CGFloat(index) - centerIndex)
        let positionFactor = max(0, 1.0 - (distanceFromCenter / 10.0))
        
        let baseHeight: CGFloat = 3
        let maxHeight: CGFloat = 26
        
        let effectiveLevel = max(level, 0.01)
        
        // Add some wave variation based on index
        let wavePhase = Double(index) * 0.5 + Double(randomOffset) * 2
        let wave = sin(wavePhase + Double(effectiveLevel) * 6) * 0.5 + 0.7
        
        let height = baseHeight + (maxHeight - baseHeight) * effectiveLevel * CGFloat(wave) * positionFactor
        
        return min(max(height, baseHeight), maxHeight)
    }
    
    private var barColor: Color {
        if !isRecording {
            return Color.secondary.opacity(0.15)
        }
        
        let intensity = min(max(level, 0), 1)
        return Color(
            red: 0.3 + (intensity * 0.4),
            green: 0.6 - (intensity * 0.2),
            blue: 1.0 - (intensity * 0.3)
        )
        .opacity(0.4 + (intensity * 0.6))
    }
}

#Preview {
    ContentView()
        .environmentObject(VibeFlowViewModel())
        .padding()
        .background(Color.gray.opacity(0.2))
}
