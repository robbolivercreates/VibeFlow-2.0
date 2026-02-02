import AVFoundation
import AppKit
import Foundation
import Combine

class AudioRecorder: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var recordingError: String?
    @Published var audioLevel: CGFloat = 0.0
    
    // Detecção de fala - MAIS PERMISSIVA
    private var speechDetected = false
    private var maxAudioLevel: CGFloat = 0.0
    private var recordingStartTime: Date?
    private let minimumRecordingDuration: TimeInterval = 0.3  // Reduzido para 300ms
    private let speechThreshold: CGFloat = 0.05  // Reduzido para detectar mais fácil
    
    private var audioRecorder: AVAudioRecorder?
    private var recordingURL: URL?
    private var levelTimer: Timer?
    
    override init() {
        super.init()
    }
    
    var hasSpeechDetected: Bool {
        speechDetected
    }
    
    var recordingDuration: TimeInterval {
        guard let startTime = recordingStartTime else { return 0 }
        return Date().timeIntervalSince(startTime)
    }
    
    func startRecording() {
        // Resetar estado
        speechDetected = false
        maxAudioLevel = 0.0
        recordingStartTime = nil
        audioLevel = 0.0
        
        // Solicitar permissão de microfone (macOS)
        AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    self?.performRecording()
                } else {
                    self?.recordingError = "Permissão de microfone negada"
                }
            }
        }
    }
    
    private func performRecording() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFilename = documentsPath.appendingPathComponent("recording_\(Date().timeIntervalSince1970).m4a")
        recordingURL = audioFilename
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            isRecording = true
            recordingStartTime = Date()
            recordingError = nil
            
            startLevelTimer()
            
        } catch {
            recordingError = "Erro ao iniciar gravação: \(error.localizedDescription)"
            isRecording = false
        }
    }
    
    private func startLevelTimer() {
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { [weak self] _ in
            self?.updateAudioLevel()
        }
    }
    
    private func updateAudioLevel() {
        guard let recorder = audioRecorder, isRecording else { return }
        
        recorder.updateMeters()
        
        // Converter dB para escala 0-1
        let db = recorder.averagePower(forChannel: 0)
        let level = pow(10, db / 20)
        let normalizedLevel = CGFloat(min(max(level, 0), 1))
        
        // Detectar se houve fala (threshold mais baixo)
        if normalizedLevel > speechThreshold {
            speechDetected = true
        }
        
        maxAudioLevel = max(maxAudioLevel, normalizedLevel)
        
        // Smoothing mais rápido para resposta mais ágil
        let smoothingFactor: CGFloat = 0.4
        let smoothedLevel = (audioLevel * (1 - smoothingFactor)) + (normalizedLevel * smoothingFactor)
        
        DispatchQueue.main.async {
            self.audioLevel = smoothedLevel
        }
    }
    
    private func stopLevelTimer() {
        levelTimer?.invalidate()
        levelTimer = nil
    }
    
    func stopRecording() -> URL? {
        stopLevelTimer()
        audioRecorder?.stop()
        isRecording = false
        audioLevel = 0.0
        return recordingURL
    }
    
    func getRecordingData() -> Data? {
        guard let url = recordingURL else { return nil }
        return try? Data(contentsOf: url)
    }
    
    /// Verifica se a gravação é válida - MAIS PERMISSIVA
    func isRecordingValid() -> Bool {
        let duration = recordingDuration
        
        // Sempre válido se gravou por pelo menos 300ms
        // Não exige mais detecção de fala (muitos usuários falam baixo)
        let isValid = duration >= minimumRecordingDuration
        
        print("[AudioRecorder] Duration: \(String(format: "%.2f", duration))s, Speech: \(speechDetected), Max: \(String(format: "%.3f", maxAudioLevel)), Valid: \(isValid)")
        
        return isValid
    }
}

extension AudioRecorder: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            recordingError = "Gravação não foi concluída com sucesso"
            isRecording = false
        }
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        recordingError = "Erro na gravação: \(error?.localizedDescription ?? "Erro desconhecido")"
        isRecording = false
    }
}
