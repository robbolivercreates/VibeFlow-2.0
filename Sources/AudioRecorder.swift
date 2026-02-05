import AVFoundation
import AppKit
import Foundation
import Combine
import CoreAudio

/// Represents an audio input device
struct AudioInputDevice: Identifiable, Equatable {
    let id: String
    let name: String
    let isDefault: Bool

    static func == (lhs: AudioInputDevice, rhs: AudioInputDevice) -> Bool {
        lhs.id == rhs.id
    }
}

class AudioRecorder: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var recordingError: String?
    @Published var audioLevel: CGFloat = 0.0
    @Published var availableDevices: [AudioInputDevice] = []
    @Published var selectedDeviceId: String?

    // Speech detection
    private var speechDetected = false
    private var maxAudioLevel: CGFloat = 0.0
    private var recordingStartTime: Date?
    private let minimumRecordingDuration: TimeInterval = 0.5  // Minimum 500ms to filter accidental taps
    private let speechThreshold: CGFloat = 0.02  // Low threshold to accommodate quiet speakers

    private var audioRecorder: AVAudioRecorder?
    private var recordingURL: URL?
    private var levelTimer: Timer?

    override init() {
        super.init()
        refreshDevices()
        loadSelectedDevice()
    }

    /// Refresh the list of available audio input devices
    func refreshDevices() {
        var devices: [AudioInputDevice] = []

        // Get default device
        var defaultDeviceID: AudioDeviceID = 0
        var propertySize = UInt32(MemoryLayout<AudioDeviceID>.size)
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &propertySize,
            &defaultDeviceID
        )

        // Get all devices
        propertyAddress.mSelector = kAudioHardwarePropertyDevices
        AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &propertySize
        )

        let deviceCount = Int(propertySize) / MemoryLayout<AudioDeviceID>.size
        var deviceIDs = [AudioDeviceID](repeating: 0, count: deviceCount)

        AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &propertySize,
            &deviceIDs
        )

        for deviceID in deviceIDs {
            // Check if device has input channels
            var inputChannels: UInt32 = 0
            var channelPropertySize = UInt32(MemoryLayout<UInt32>.size)
            var channelAddress = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyStreamConfiguration,
                mScope: kAudioDevicePropertyScopeInput,
                mElement: kAudioObjectPropertyElementMain
            )

            // Get buffer list size
            AudioObjectGetPropertyDataSize(
                deviceID,
                &channelAddress,
                0,
                nil,
                &channelPropertySize
            )

            if channelPropertySize > 0 {
                let bufferListPointer = UnsafeMutablePointer<AudioBufferList>.allocate(capacity: 1)
                defer { bufferListPointer.deallocate() }

                AudioObjectGetPropertyData(
                    deviceID,
                    &channelAddress,
                    0,
                    nil,
                    &channelPropertySize,
                    bufferListPointer
                )

                let bufferList = bufferListPointer.pointee
                for i in 0..<Int(bufferList.mNumberBuffers) {
                    let buffer = bufferList.mBuffers
                    inputChannels += buffer.mNumberChannels
                }
            }

            // Only include devices with input channels
            if inputChannels > 0 {
                // Get device name
                var namePropertySize = UInt32(MemoryLayout<CFString>.size)
                var nameAddress = AudioObjectPropertyAddress(
                    mSelector: kAudioDevicePropertyDeviceNameCFString,
                    mScope: kAudioObjectPropertyScopeGlobal,
                    mElement: kAudioObjectPropertyElementMain
                )

                var deviceName: CFString = "" as CFString
                AudioObjectGetPropertyData(
                    deviceID,
                    &nameAddress,
                    0,
                    nil,
                    &namePropertySize,
                    &deviceName
                )

                let device = AudioInputDevice(
                    id: String(deviceID),
                    name: deviceName as String,
                    isDefault: deviceID == defaultDeviceID
                )
                devices.append(device)
            }
        }

        DispatchQueue.main.async {
            self.availableDevices = devices
        }
    }

    /// Load selected device from settings
    private func loadSelectedDevice() {
        if let savedDeviceId = UserDefaults.standard.string(forKey: "selected_microphone_id") {
            selectedDeviceId = savedDeviceId
        }
    }

    /// Select a specific microphone
    func selectDevice(_ device: AudioInputDevice) {
        selectedDeviceId = device.id
        UserDefaults.standard.set(device.id, forKey: "selected_microphone_id")
        print("[AudioRecorder] Selected microphone: \(device.name)")
    }

    /// Get currently selected device (or default)
    var currentDevice: AudioInputDevice? {
        if let selectedId = selectedDeviceId,
           let device = availableDevices.first(where: { $0.id == selectedId }) {
            return device
        }
        return availableDevices.first(where: { $0.isDefault }) ?? availableDevices.first
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
        
        // Detect if audio level exceeds speech threshold
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
    
    /// Validates that the recording contains actual speech
    func isRecordingValid() -> Bool {
        let duration = recordingDuration

        // Must meet minimum duration (filters accidental taps)
        guard duration >= minimumRecordingDuration else {
            print("[AudioRecorder] Recording too short: \(String(format: "%.2f", duration))s < \(minimumRecordingDuration)s")
            return false
        }

        // Must have detected audio above speech threshold
        // The threshold (0.02) is very low - typical silence is ~0.005-0.01,
        // so even quiet speech or whispering will exceed it
        let isValid = speechDetected

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
