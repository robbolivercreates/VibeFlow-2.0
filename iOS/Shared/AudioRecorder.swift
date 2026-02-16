import Foundation
import AVFoundation

/// Audio recorder for capturing voice input
final class AudioRecorder: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var audioLevel: Float = 0

    private var audioRecorder: AVAudioRecorder?
    private var levelTimer: Timer?
    private var recordingURL: URL?

    override init() {
        super.init()
    }

    /// Request microphone permission
    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    /// Start recording audio
    func startRecording() throws -> URL {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try audioSession.setActive(true)

        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFilename = documentsPath.appendingPathComponent("vibeflow_recording.m4a")
        recordingURL = audioFilename

        // Delete existing file if present
        try? FileManager.default.removeItem(at: audioFilename)

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
        audioRecorder?.isMeteringEnabled = true
        audioRecorder?.record()

        isRecording = true

        // Start level monitoring
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.updateAudioLevel()
        }

        return audioFilename
    }

    /// Stop recording and return the audio data
    func stopRecording() -> Data? {
        levelTimer?.invalidate()
        levelTimer = nil

        audioRecorder?.stop()
        isRecording = false
        audioLevel = 0

        guard let url = recordingURL else { return nil }

        do {
            let data = try Data(contentsOf: url)
            // Clean up the file
            try? FileManager.default.removeItem(at: url)
            return data
        } catch {
            print("Error reading audio file: \(error)")
            return nil
        }
    }

    /// Cancel recording without saving
    func cancelRecording() {
        levelTimer?.invalidate()
        levelTimer = nil

        audioRecorder?.stop()
        isRecording = false
        audioLevel = 0

        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
        }
    }

    private func updateAudioLevel() {
        guard let recorder = audioRecorder, recorder.isRecording else { return }

        recorder.updateMeters()
        let level = recorder.averagePower(forChannel: 0)

        // Convert dB to linear scale (0-1)
        let minDb: Float = -60
        let normalizedLevel = max(0, (level - minDb) / (-minDb))

        DispatchQueue.main.async {
            self.audioLevel = normalizedLevel
        }
    }
}
