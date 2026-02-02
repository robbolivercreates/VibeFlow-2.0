import SwiftUI

// MARK: - Main Content View
struct ContentView: View {
    @EnvironmentObject var viewModel: VibeFlowViewModel
    
    var body: some View {
        RecordingInterface(viewModel: viewModel)
            .frame(width: 300, height: 110)
    }
}

// MARK: - Modern Recording Interface
struct RecordingInterface: View {
    @ObservedObject var viewModel: VibeFlowViewModel
    
    var body: some View {
        ZStack {
            // Fundo blur sem bordas
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.08), radius: 32, x: 0, y: 12)
            
            // Conteúdo
            VStack(spacing: 6) {
                // Top: Info (modo + idioma) quando gravando, ou só status
                if viewModel.isRecording {
                    RecordingInfoView(viewModel: viewModel)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // Status e botão
                HStack(spacing: 12) {
                    // Indicador de modo
                    ModeIndicator(mode: viewModel.selectedMode)
                    
                    Spacer(minLength: 4)
                    
                    // Status central
                    StatusView(viewModel: viewModel)
                    
                    Spacer(minLength: 4)
                    
                    // Botão de ação
                    ActionButton(viewModel: viewModel)
                }
                .padding(.horizontal, 16)
                
                // Waveform
                WaveformView(level: viewModel.isRecording ? viewModel.audioLevel : 0.02)
                    .frame(height: 26)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 4)
            }
            .padding(.vertical, 10)
        }
    }
}

// MARK: - Recording Info View (mostra modo e idioma durante gravação)
struct RecordingInfoView: View {
    @ObservedObject var viewModel: VibeFlowViewModel
    
    var body: some View {
        HStack(spacing: 8) {
            // Badge do modo
            HStack(spacing: 3) {
                Image(systemName: viewModel.selectedMode.icon)
                    .font(.system(size: 8))
                Text(viewModel.selectedMode.shortDescription)
                    .font(.system(size: 9, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(modeColor)
            .cornerRadius(4)
            
            // Indicador de idioma (se tradução ativada)
            if viewModel.translateToEnglish {
                HStack(spacing: 2) {
                    Image(systemName: "globe")
                        .font(.system(size: 7))
                    Text("EN")
                        .font(.system(size: 8, weight: .bold))
                }
                .foregroundColor(.blue)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(Color.blue.opacity(0.15))
                .cornerRadius(4)
            }
            
            Spacer()
            
            // Timer de gravação
            RecordingTimer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
    }
    
    private var modeColor: Color {
        switch viewModel.selectedMode {
        case .code: return Color(red: 0.2, green: 0.6, blue: 1.0)
        case .text: return Color(red: 0.3, green: 0.8, blue: 0.4)
        case .email: return Color(red: 1.0, green: 0.5, blue: 0.2)  // Laranja
        case .uxDesign: return Color(red: 0.8, green: 0.4, blue: 0.9)
        }
    }
}

// MARK: - Recording Timer
struct RecordingTimer: View {
    @State private var startTime = Date()
    @State private var elapsed: TimeInterval = 0
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        Text(formattedTime)
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .foregroundColor(.secondary.opacity(0.7))
            .onReceive(timer) { _ in
                elapsed = Date().timeIntervalSince(startTime)
            }
    }
    
    private var formattedTime: String {
        let seconds = Int(elapsed)
        let tenths = Int((elapsed - Double(seconds)) * 10)
        return "\(seconds).\(tenths)s"
    }
}

// MARK: - Mode Indicator
struct ModeIndicator: View {
    let mode: TranscriptionMode
    
    var body: some View {
        Circle()
            .fill(modeColor)
            .frame(width: 8, height: 8)
    }
    
    private var modeColor: Color {
        switch mode {
        case .code: return Color(red: 0.2, green: 0.6, blue: 1.0)
        case .text: return Color(red: 0.3, green: 0.8, blue: 0.4)
        case .email: return Color(red: 1.0, green: 0.5, blue: 0.2)
        case .uxDesign: return Color(red: 0.8, green: 0.4, blue: 0.9)
        }
    }
}

// MARK: - Status View
struct StatusView: View {
    @ObservedObject var viewModel: VibeFlowViewModel
    
    var body: some View {
        Group {
            if viewModel.isProcessing {
                HStack(spacing: 6) {
                    ProgressView()
                        .scaleEffect(0.6)
                        .tint(.orange)
                    Text("Processando")
                        .foregroundColor(.orange)
                }
            } else if viewModel.isRecording {
                HStack(spacing: 5) {
                    PulsingDot()
                    Text("Gravando")
                        .foregroundColor(.primary)
                }
            } else if viewModel.needsAPIKey {
                Text("API Key necessária")
                    .foregroundColor(.orange.opacity(0.8))
            } else if viewModel.error != nil {
                Text("Erro")
                    .foregroundColor(.red.opacity(0.8))
            } else {
                Text("Segure ⌥⌘")
                    .foregroundColor(.secondary.opacity(0.6))
            }
        }
        .font(.system(size: 12, weight: .medium, design: .rounded))
    }
}

// MARK: - Pulsing Dot
struct PulsingDot: View {
    @State private var isPulsing = false
    
    var body: some View {
        Circle()
            .fill(Color.red)
            .frame(width: 6, height: 6)
            .scaleEffect(isPulsing ? 1.2 : 0.9)
            .opacity(isPulsing ? 1.0 : 0.6)
            .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: isPulsing)
            .onAppear { isPulsing = true }
    }
}

// MARK: - Action Button
struct ActionButton: View {
    @ObservedObject var viewModel: VibeFlowViewModel
    
    var body: some View {
        Button(action: {
            viewModel.toggleRecording()
        }) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: buttonColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                
                Image(systemName: buttonIcon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(viewModel.isProcessing || viewModel.needsAPIKey)
    }
    
    private var buttonColors: [Color] {
        if viewModel.isProcessing {
            return [Color.orange, Color.orange.opacity(0.8)]
        } else if viewModel.isRecording {
            return [Color.red, Color.red.opacity(0.8)]
        } else {
            return [Color.green, Color.green.opacity(0.8)]
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

// MARK: - Waveform View
struct WaveformView: View {
    let level: CGFloat
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<16, id: \.self) { i in
                WaveBar(index: i, level: level)
            }
        }
    }
}

struct WaveBar: View {
    let index: Int
    let level: CGFloat
    
    private var barHeight: CGFloat {
        let centerIndex = 7.5
        let distanceFromCenter = abs(CGFloat(index) - centerIndex)
        let positionFactor = max(0, 1.0 - (distanceFromCenter / 8.0))
        
        let baseHeight: CGFloat = 2
        let maxHeight: CGFloat = 24
        
        let effectiveLevel = max(level, 0.015)
        
        let wavePhase = Double(index) * 0.6
        let wave = sin(wavePhase + Double(effectiveLevel) * 8) * 0.5 + 0.7
        
        let height = baseHeight + (maxHeight - baseHeight) * effectiveLevel * CGFloat(wave) * positionFactor
        
        return min(max(height, baseHeight), maxHeight)
    }
    
    private var barColor: Color {
        let intensity = min(max(level, 0), 1)
        return Color(
            red: 1.0,
            green: 0.3 - (intensity * 0.2),
            blue: 0.3 - (intensity * 0.1)
        )
        .opacity(0.3 + (intensity * 0.7))
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(barColor)
            .frame(width: 4, height: barHeight)
            .animation(.easeOut(duration: 0.04), value: level)
    }
}

#Preview {
    ContentView()
        .environmentObject(VibeFlowViewModel())
        .padding()
        .background(Color.gray.opacity(0.2))
}
