import SwiftUI

/// Animação de ondas estilo Siri - fluida e moderna
struct SiriWaveformView: View {
    let audioLevel: CGFloat
    let primaryColor: Color
    
    @State private var phase: CGFloat = 0
    @State private var secondaryPhase: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Onda principal (mais externa)
            WaveformShape(
                amplitude: audioLevel * 25,
                frequency: 2.5,
                phase: phase
            )
            .stroke(
                primaryColor.opacity(0.3 + audioLevel * 0.4),
                lineWidth: 2 + audioLevel * 2
            )
            
            // Onda secundária (meio)
            WaveformShape(
                amplitude: audioLevel * 18,
                frequency: 3.0,
                phase: secondaryPhase
            )
            .stroke(
                primaryColor.opacity(0.5 + audioLevel * 0.3),
                lineWidth: 2.5 + audioLevel * 1.5
            )
            
            // Onda central (mais intensa)
            WaveformShape(
                amplitude: audioLevel * 12,
                frequency: 3.5,
                phase: -phase * 0.7
            )
            .stroke(
                primaryColor.opacity(0.7 + audioLevel * 0.3),
                lineWidth: 3 + audioLevel
            )
            
            // Linha central brilhante
            WaveformShape(
                amplitude: audioLevel * 6,
                frequency: 4.0,
                phase: phase * 1.3
            )
            .stroke(
                primaryColor,
                lineWidth: 1.5 + audioLevel * 2
            )
            
            // Partículas de brilho
            if audioLevel > 0.3 {
                GlowParticles(audioLevel: audioLevel, color: primaryColor)
            }
        }
        .frame(height: 50)
        .onAppear {
            // Animação contínua das ondas
            withAnimation(.linear(duration: 0.1).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
            withAnimation(.linear(duration: 0.15).repeatForever(autoreverses: false)) {
                secondaryPhase = .pi * 2
            }
        }
    }
}

/// Shape customizado para ondas sinusoidais
struct WaveformShape: Shape {
    let amplitude: CGFloat
    let frequency: CGFloat
    let phase: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let width = rect.width
        let height = rect.height
        let midY = height / 2
        
        path.move(to: CGPoint(x: 0, y: midY))
        
        for x in stride(from: 0, to: width, by: 1) {
            let normalizedX = x / width
            
            // Onda principal
            let sine = sin(normalizedX * .pi * frequency * 2 + phase)
            
            // Harmônicos para forma mais orgânica
            let harmonic1 = sin(normalizedX * .pi * frequency * 4 + phase * 1.5) * 0.3
            let harmonic2 = sin(normalizedX * .pi * frequency * 6 + phase * 0.8) * 0.15
            
            // Envelope para suavizar as bordas
            let envelope = sin(normalizedX * .pi)
            
            let y = midY + (sine + harmonic1 + harmonic2) * amplitude * envelope
            
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        return path
    }
}

/// Partículas de brilho que flutuam
struct GlowParticles: View {
    let audioLevel: CGFloat
    let color: Color
    
    var body: some View {
        TimelineView(.animation(minimumInterval: 0.05, paused: false)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                
                for i in 0..<5 {
                    let offset = Double(i) * 1.2
                    let x = size.width * 0.5 + sin(time * 2 + offset) * 30 * audioLevel
                    let y = size.height * 0.5 + cos(time * 1.5 + offset) * 10 * audioLevel
                    let particleSize = 3 + audioLevel * 4
                    
                    let rect = CGRect(
                        x: x - particleSize/2,
                        y: y - particleSize/2,
                        width: particleSize,
                        height: particleSize
                    )
                    
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(color.opacity(0.6 + audioLevel * 0.4))
                    )
                }
            }
        }
    }
}

/// Visualização de barras estilo equalizador circular
struct CircularBarsVisualizer: View {
    let audioLevel: CGFloat
    let color: Color
    
    @State private var barHeights: [CGFloat] = Array(repeating: 0.3, count: 12)
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<12, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [
                                color.opacity(0.4),
                                color,
                                color.opacity(0.4)
                            ],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 4, height: barHeight(for: index))
                    .animation(.spring(response: 0.1, dampingFraction: 0.5), value: audioLevel)
            }
        }
        .frame(height: 40)
    }
    
    private func barHeight(for index: Int) -> CGFloat {
        let centerIndex = 5.5
        let distanceFromCenter = abs(CGFloat(index) - centerIndex)
        let positionFactor = 1.0 - (distanceFromCenter / 6.0) * 0.3
        
        // Adicionar variação baseada no índice
        let phase = Double(index) * 0.5
        let variation = CGFloat(sin(phase + Double(audioLevel) * 3) * 0.2 + 0.8)
        
        let baseHeight: CGFloat = 6
        let maxHeight: CGFloat = 36
        
        return baseHeight + (maxHeight - baseHeight) * audioLevel * positionFactor * variation
    }
}

/// Visualização de ondas concentricas pulsantes
struct PulsingRingsView: View {
    let audioLevel: CGFloat
    let color: Color
    
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 0.6
    
    var body: some View {
        ZStack {
            // Anel externo
            Circle()
                .stroke(color.opacity(opacity), lineWidth: 2)
                .frame(width: 50 + audioLevel * 30, height: 50 + audioLevel * 30)
                .scaleEffect(scale)
            
            // Anel médio
            Circle()
                .stroke(color.opacity(opacity * 0.7), lineWidth: 2)
                .frame(width: 35 + audioLevel * 20, height: 35 + audioLevel * 20)
                .scaleEffect(scale * 0.85)
            
            // Anel interno
            Circle()
                .stroke(color.opacity(opacity * 0.5), lineWidth: 2)
                .frame(width: 20 + audioLevel * 10, height: 20 + audioLevel * 10)
                .scaleEffect(scale * 0.7)
            
            // Centro brilhante
            Circle()
                .fill(color.opacity(0.3 + audioLevel * 0.5))
                .frame(width: 12 + audioLevel * 8, height: 12 + audioLevel * 8)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                scale = 1.0 + audioLevel * 0.3
                opacity = 0.3 + Double(audioLevel) * 0.4
            }
        }
    }
}

/// View principal que combina todas as visualizações
struct ModernWaveformView: View {
    let audioLevel: CGFloat
    let isRecording: Bool
    
    var primaryColor: Color {
        if audioLevel < 0.3 {
            return .green
        } else if audioLevel < 0.7 {
            return .orange
        } else {
            return .red
        }
    }
    
    var body: some View {
        ZStack {
            // Fundo sutil
            RoundedRectangle(cornerRadius: 8)
                .fill(primaryColor.opacity(0.05))
                .frame(height: 60)
            
            if isRecording {
                // Anéis pulsantes no fundo
                PulsingRingsView(audioLevel: audioLevel, color: primaryColor)
                    .opacity(0.4)
                
                // Ondas estilo Siri
                SiriWaveformView(audioLevel: audioLevel, primaryColor: primaryColor)
                    .padding(.horizontal, 8)
                
                // Indicador de nível numérico (opcional, para debug)
                // Text(String(format: "%.0f%%", audioLevel * 100))
                //    .font(.caption2)
                //    .foregroundColor(primaryColor)
                //    .offset(x: 60, y: -20)
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.easeInOut(duration: 0.1), value: audioLevel)
    }
}

// MARK: - Preview

struct SiriWaveformView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 40) {
            // Baixo volume
            ModernWaveformView(audioLevel: 0.2, isRecording: true)
                .frame(width: 200)
            
            // Médio volume
            ModernWaveformView(audioLevel: 0.5, isRecording: true)
                .frame(width: 200)
            
            // Alto volume
            ModernWaveformView(audioLevel: 0.9, isRecording: true)
                .frame(width: 200)
        }
        .padding()
        .background(Color.black)
    }
}
