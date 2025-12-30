import SwiftUI

// MARK: - Main Content View (Interface Mínima)
struct ContentView: View {
    @EnvironmentObject var viewModel: VibeFlowViewModel
    @State private var audioLevel: CGFloat = 0.3
    @State private var isHovering = false
    
    var body: some View {
        ZStack {
            // Fundo transparente clicável para fechar
            Color.clear
                .contentShape(Rectangle())
            
            VStack(spacing: 0) {
                Spacer()
                
                // Interface mínima na parte inferior
                MinimalRecordingView(viewModel: viewModel, audioLevel: $audioLevel)
            }
        }
        .frame(width: 280, height: 100)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
        )
        .onAppear {
            startAudioLevelSimulation()
        }
    }
    
    private func startAudioLevelSimulation() {
        Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { _ in
            if viewModel.isRecording {
                withAnimation(.easeInOut(duration: 0.08)) {
                    audioLevel = CGFloat.random(in: 0.3...1.0)
                }
            } else {
                withAnimation(.easeInOut(duration: 0.2)) {
                    audioLevel = 0.3
                }
            }
        }
    }
}

// MARK: - Minimal Recording View
struct MinimalRecordingView: View {
    @ObservedObject var viewModel: VibeFlowViewModel
    @Binding var audioLevel: CGFloat
    
    var body: some View {
        HStack(spacing: 16) {
            // Indicador de modo (pequeno)
            ModeIndicator(mode: viewModel.selectedMode, translateEnabled: viewModel.translateToEnglish)
            
            // Ondas de áudio ou botão
            ZStack {
                if viewModel.isRecording {
                    // Ondas animadas
                    AudioWaveformView(level: audioLevel, color: .red)
                } else if viewModel.isProcessing {
                    // Indicador de processamento
                    ProcessingIndicator()
                } else {
                    // Estado idle - mostrar status
                    IdleStateView(viewModel: viewModel)
                }
            }
            .frame(maxWidth: .infinity)
            
            // Botão de microfone
            MicButton(viewModel: viewModel)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

// MARK: - Mode Indicator
struct ModeIndicator: View {
    let mode: TranscriptionMode
    let translateEnabled: Bool
    
    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: mode.icon)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            if translateEnabled {
                Text("EN")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.blue)
            }
        }
        .frame(width: 30)
    }
}

// MARK: - Audio Waveform
struct AudioWaveformView: View {
    let level: CGFloat
    let color: Color
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<12, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(color.gradient)
                    .frame(width: 4, height: barHeight(for: i))
                    .animation(.easeInOut(duration: 0.1), value: level)
            }
        }
    }
    
    private func barHeight(for index: Int) -> CGFloat {
        let baseHeight: CGFloat = 8
        let maxHeight: CGFloat = 32
        let variation = sin(Double(index) * 0.8 + Double(level) * 10) * 0.5 + 0.5
        return baseHeight + (maxHeight - baseHeight) * level * CGFloat(variation)
    }
}

// MARK: - Processing Indicator
struct ProcessingIndicator: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Color.orange)
                    .frame(width: 8, height: 8)
                    .scaleEffect(isAnimating ? 1.0 : 0.5)
                    .animation(
                        .easeInOut(duration: 0.5)
                        .repeatForever()
                        .delay(Double(i) * 0.15),
                        value: isAnimating
                    )
            }
        }
        .onAppear { isAnimating = true }
    }
}

// MARK: - Idle State View
struct IdleStateView: View {
    @ObservedObject var viewModel: VibeFlowViewModel
    
    var body: some View {
        VStack(spacing: 2) {
            if viewModel.needsAPIKey {
                Text("⚠️ \(L10n.configureAPIKey)")
                    .font(.system(size: 11))
                    .foregroundColor(.orange)
            } else if let error = viewModel.error {
                Text(error)
                    .font(.system(size: 10))
                    .foregroundColor(.red)
                    .lineLimit(1)
            } else {
                Text(viewModel.statusText)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text(L10n.holdToRecord)
                    .font(.system(size: 9))
                    .foregroundColor(.gray.opacity(0.6))
            }
        }
    }
}

// MARK: - Mic Button
struct MicButton: View {
    @ObservedObject var viewModel: VibeFlowViewModel
    
    var body: some View {
        Button(action: {
            viewModel.toggleRecording()
        }) {
            ZStack {
                Circle()
                    .fill(buttonColor.gradient)
                    .frame(width: 44, height: 44)
                    .shadow(color: buttonColor.opacity(0.4), radius: 8, x: 0, y: 4)
                
                Image(systemName: buttonIcon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(viewModel.isProcessing || viewModel.needsAPIKey)
    }
    
    private var buttonColor: Color {
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
