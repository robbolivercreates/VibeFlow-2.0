import Foundation
import AVFoundation
import AppKit

/// Gerencia efeitos sonoros do app
class SoundManager: ObservableObject {
    static let shared = SoundManager()
    
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    private let settings = SettingsManager.shared
    
    // Sons embutidos (criados programaticamente)
    enum Sound: String, CaseIterable {
        case startRecording = "start"
        case stopRecording = "stop"
        case success = "success"
        case error = "error"
        
        var fileName: String {
            return self.rawValue
        }
    }
    
    private init() {
        setupSounds()
    }
    
    private func setupSounds() {
        // Criar sons sintetizados simples
        for sound in Sound.allCases {
            if let player = createSyntheticSound(for: sound) {
                audioPlayers[sound.rawValue] = player
            }
        }
    }
    
    private func createSyntheticSound(for sound: Sound) -> AVAudioPlayer? {
        // Criar áudio sintetizado simples
        let sampleRate: Double = 44100
        let duration: Double
        let frequency: Double
        
        switch sound {
        case .startRecording:
            duration = 0.15
            frequency = 800
        case .stopRecording:
            duration = 0.1
            frequency = 600
        case .success:
            duration = 0.2
            frequency = 1200
        case .error:
            duration = 0.3
            frequency = 300
        }
        
        let numSamples = Int(sampleRate * duration)
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format!, frameCapacity: AVAudioFrameCount(numSamples)) else {
            return nil
        }
        
        buffer.frameLength = AVAudioFrameCount(numSamples)
        
        let data = buffer.floatChannelData![0]
        for i in 0..<numSamples {
            let t = Double(i) / sampleRate
            let envelope = exp(-t * 10) // Decaimento exponencial
            data[i] = Float(sin(2 * .pi * frequency * t) * envelope * 0.3)
        }
        
        let player = AVAudioPlayer()
        // Não podemos usar init com buffer diretamente, então salvamos em arquivo temporário
        return nil // Placeholder - vamos usar sistema de áudio diferente
    }
    
    func play(_ sound: Sound) {
        guard settings.enableSounds else { return }
        
        // Usar NSSound para sons simples do sistema
        switch sound {
        case .startRecording:
            NSSound(named: "Pop")?.play()
        case .stopRecording:
            NSSound(named: "Funk")?.play()
        case .success:
            NSSound(named: "Glass")?.play()
        case .error:
            NSSound(named: "Basso")?.play()
        }
    }
    
    func playStart() {
        play(.startRecording)
    }
    
    func playStop() {
        play(.stopRecording)
    }
    
    func playSuccess() {
        play(.success)
    }
    
    func playError() {
        play(.error)
    }
}
