import UIKit
import AVFoundation

class KeyboardViewController: UIInputViewController {

    private var micButton: UIButton!
    private var statusLabel: UILabel!
    private var isRecording = false
    private var audioRecorder: AVAudioRecorder?
    private var recordingURL: URL?
    private let settings = SharedSettings.shared

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        // Mic button only
        micButton = UIButton(type: .system)
        micButton.backgroundColor = .systemOrange
        micButton.setTitle("🎤", for: .normal)
        micButton.titleLabel?.font = .systemFont(ofSize: 40)
        micButton.layer.cornerRadius = 45
        micButton.clipsToBounds = true
        micButton.isUserInteractionEnabled = true
        micButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(micButton)

        // Add tap action for feedback
        micButton.addTarget(self, action: #selector(micTapped), for: .touchUpInside)

        // Add touch down/up for hold recording
        micButton.addTarget(self, action: #selector(micTouchDown), for: .touchDown)
        micButton.addTarget(self, action: #selector(micTouchUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])

        // Status label
        statusLabel = UILabel()
        statusLabel.text = settings.hasApiKey ? "Tap & hold to record" : "Add API key in app"
        statusLabel.textColor = settings.hasApiKey ? .secondaryLabel : .systemRed
        statusLabel.font = .systemFont(ofSize: 13)
        statusLabel.textAlignment = .center
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statusLabel)

        // Constraints
        NSLayoutConstraint.activate([
            micButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            micButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -10),
            micButton.widthAnchor.constraint(equalToConstant: 90),
            micButton.heightAnchor.constraint(equalToConstant: 90),

            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.topAnchor.constraint(equalTo: micButton.bottomAnchor, constant: 12),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Set height
        let heightConstraint = view.heightAnchor.constraint(equalToConstant: 220)
        heightConstraint.priority = .defaultHigh
        heightConstraint.isActive = true
    }

    @objc func micTapped() {
        // Visual feedback on tap
        UIView.animate(withDuration: 0.1, animations: {
            self.micButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.micButton.transform = .identity
            }
        }
    }

    @objc func micTouchDown() {
        // Start recording when finger touches button
        startRecording()
    }

    @objc func micTouchUp() {
        // Stop recording when finger lifts
        stopAndTranscribe()
    }

    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            startRecording()
        } else if gesture.state == .ended || gesture.state == .cancelled {
            stopAndTranscribe()
        }
    }

    private func startRecording() {
        guard settings.hasApiKey else {
            statusLabel.text = "Add API key in app"
            statusLabel.textColor = .systemRed
            return
        }

        AVAudioApplication.requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    self?.beginRecording()
                } else {
                    self?.statusLabel.text = "Enable Full Access"
                    self?.statusLabel.textColor = .systemRed
                }
            }
        }
    }

    private func beginRecording() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)

            let url = FileManager.default.temporaryDirectory.appendingPathComponent("rec.m4a")
            try? FileManager.default.removeItem(at: url)
            recordingURL = url

            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.record()
            isRecording = true

            micButton.backgroundColor = .systemRed
            micButton.setTitle("⏺", for: .normal)
            statusLabel.text = "Recording..."
            statusLabel.textColor = .systemRed

        } catch {
            statusLabel.text = "Mic error"
            statusLabel.textColor = .systemRed
        }
    }

    private func stopAndTranscribe() {
        guard isRecording else { return }

        audioRecorder?.stop()
        isRecording = false

        micButton.backgroundColor = .systemOrange
        micButton.setTitle("🎤", for: .normal)

        guard let url = recordingURL, let data = try? Data(contentsOf: url) else {
            statusLabel.text = "Hold to record"
            statusLabel.textColor = .secondaryLabel
            return
        }

        try? FileManager.default.removeItem(at: url)

        statusLabel.text = "Processing..."
        statusLabel.textColor = .systemBlue

        Task {
            do {
                let text = try await GeminiService.shared.transcribe(
                    audioData: data,
                    mode: settings.selectedMode,
                    language: settings.selectedLanguage,
                    translateToEnglish: settings.translateToEnglish
                )

                await MainActor.run {
                    textDocumentProxy.insertText(text)
                    statusLabel.text = "✓ Done"
                    statusLabel.textColor = .systemGreen

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                        self?.statusLabel.text = "Hold to record"
                        self?.statusLabel.textColor = .secondaryLabel
                    }
                }
            } catch {
                await MainActor.run {
                    statusLabel.text = "Error"
                    statusLabel.textColor = .systemRed

                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                        self?.statusLabel.text = "Hold to record"
                        self?.statusLabel.textColor = .secondaryLabel
                    }
                }
            }
        }
    }
}
