import UIKit
import AVFoundation

class KeyboardViewController: UIInputViewController {

    // MARK: - Properties

    private let settings = SharedSettings.shared
    private var audioRecorder: AVAudioRecorder?
    private var recordingURL: URL?
    private var levelTimer: Timer?
    private var isRecording = false

    // MARK: - UI Elements

    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemBackground
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var topBar: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.secondarySystemBackground
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var modeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var languageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var micButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false

        var config = UIButton.Configuration.filled()
        config.cornerStyle = .capsule
        config.baseBackgroundColor = .systemOrange
        config.baseForegroundColor = .white
        config.image = UIImage(systemName: "mic.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30))

        button.configuration = config
        return button
    }()

    private lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.text = "Hold to record"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var waveformView: WaveformView = {
        let view = WaveformView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()

    private lazy var globeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "globe"), for: .normal)
        button.tintColor = .label
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(handleInputModeList(from:with:)), for: .allTouchEvents)
        return button
    }()

    private lazy var deleteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "delete.left"), for: .normal)
        button.tintColor = .label
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(deletePressed), for: .touchUpInside)

        // Add long press for continuous delete
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(deleteLongPressed(_:)))
        longPress.minimumPressDuration = 0.3
        button.addGestureRecognizer(longPress)

        return button
    }()

    private lazy var returnButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "return"), for: .normal)
        button.tintColor = .label
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(returnPressed), for: .touchUpInside)
        return button
    }()

    private lazy var spaceButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("space", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16)
        button.tintColor = .label
        button.backgroundColor = .secondarySystemBackground
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(spacePressed), for: .touchUpInside)
        return button
    }()

    private var deleteTimer: Timer?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupMicButton()
        updateModeDisplay()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateModeDisplay()
    }

    // MARK: - Setup

    private func setupUI() {
        view.addSubview(containerView)

        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.topAnchor.constraint(equalTo: view.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            containerView.heightAnchor.constraint(equalToConstant: 260)
        ])

        // Top bar with mode and language
        containerView.addSubview(topBar)
        topBar.addSubview(modeLabel)
        topBar.addSubview(languageLabel)

        NSLayoutConstraint.activate([
            topBar.topAnchor.constraint(equalTo: containerView.topAnchor),
            topBar.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            topBar.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            topBar.heightAnchor.constraint(equalToConstant: 36),

            modeLabel.leadingAnchor.constraint(equalTo: topBar.leadingAnchor, constant: 16),
            modeLabel.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),

            languageLabel.trailingAnchor.constraint(equalTo: topBar.trailingAnchor, constant: -16),
            languageLabel.centerYAnchor.constraint(equalTo: topBar.centerYAnchor)
        ])

        // Mic button (center)
        containerView.addSubview(micButton)
        containerView.addSubview(statusLabel)
        containerView.addSubview(waveformView)

        NSLayoutConstraint.activate([
            micButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            micButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor, constant: -20),
            micButton.widthAnchor.constraint(equalToConstant: 80),
            micButton.heightAnchor.constraint(equalToConstant: 80),

            statusLabel.topAnchor.constraint(equalTo: micButton.bottomAnchor, constant: 12),
            statusLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),

            waveformView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            waveformView.centerYAnchor.constraint(equalTo: micButton.centerYAnchor),
            waveformView.widthAnchor.constraint(equalToConstant: 200),
            waveformView.heightAnchor.constraint(equalToConstant: 60)
        ])

        // Bottom row: Globe, Space, Delete, Return
        containerView.addSubview(globeButton)
        containerView.addSubview(spaceButton)
        containerView.addSubview(deleteButton)
        containerView.addSubview(returnButton)

        NSLayoutConstraint.activate([
            globeButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            globeButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8),
            globeButton.widthAnchor.constraint(equalToConstant: 44),
            globeButton.heightAnchor.constraint(equalToConstant: 44),

            spaceButton.leadingAnchor.constraint(equalTo: globeButton.trailingAnchor, constant: 8),
            spaceButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8),
            spaceButton.heightAnchor.constraint(equalToConstant: 44),

            deleteButton.leadingAnchor.constraint(equalTo: spaceButton.trailingAnchor, constant: 8),
            deleteButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8),
            deleteButton.widthAnchor.constraint(equalToConstant: 44),
            deleteButton.heightAnchor.constraint(equalToConstant: 44),

            returnButton.leadingAnchor.constraint(equalTo: deleteButton.trailingAnchor, constant: 8),
            returnButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            returnButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8),
            returnButton.widthAnchor.constraint(equalToConstant: 44),
            returnButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func setupMicButton() {
        // Touch down - start recording
        micButton.addTarget(self, action: #selector(micButtonDown), for: .touchDown)

        // Touch up - stop recording and transcribe
        micButton.addTarget(self, action: #selector(micButtonUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }

    private func updateModeDisplay() {
        let mode = settings.selectedMode
        let language = settings.selectedLanguage

        modeLabel.text = "\(modeIcon(for: mode)) \(mode.displayName)"
        languageLabel.text = language.flag
    }

    private func modeIcon(for mode: TranscriptionMode) -> String {
        switch mode {
        case .code: return "</>"
        case .text: return "T"
        case .email: return "@"
        case .uxDesign: return "UX"
        }
    }

    // MARK: - Recording

    @objc private func micButtonDown() {
        guard settings.hasApiKey else {
            statusLabel.text = "Add API key in app"
            statusLabel.textColor = .systemRed
            return
        }

        startRecording()
    }

    @objc private func micButtonUp() {
        guard isRecording else { return }
        stopRecordingAndTranscribe()
    }

    private func startRecording() {
        // Haptic feedback
        if settings.hapticFeedback {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }

        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try audioSession.setActive(true)

            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioFilename = documentsPath.appendingPathComponent("keyboard_recording.m4a")
            recordingURL = audioFilename

            // Delete existing file
            try? FileManager.default.removeItem(at: audioFilename)

            let recordSettings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: recordSettings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()

            isRecording = true

            // Update UI
            statusLabel.text = "Recording..."
            statusLabel.textColor = .systemRed

            var config = micButton.configuration
            config?.baseBackgroundColor = .systemRed
            config?.image = UIImage(systemName: "waveform", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30))
            micButton.configuration = config

            // Show waveform if enabled
            if settings.showWaveform {
                micButton.isHidden = true
                waveformView.isHidden = false
                waveformView.startAnimating()
            }

            // Start level monitoring
            levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
                self?.updateAudioLevel()
            }

        } catch {
            statusLabel.text = "Mic error: \(error.localizedDescription)"
            statusLabel.textColor = .systemRed
        }
    }

    private func stopRecordingAndTranscribe() {
        levelTimer?.invalidate()
        levelTimer = nil

        audioRecorder?.stop()
        isRecording = false

        // Reset UI
        statusLabel.text = "Processing..."
        statusLabel.textColor = .systemOrange

        var config = micButton.configuration
        config?.baseBackgroundColor = .systemGray
        config?.image = UIImage(systemName: "hourglass", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30))
        micButton.configuration = config

        // Hide waveform
        waveformView.stopAnimating()
        waveformView.isHidden = true
        micButton.isHidden = false

        guard let url = recordingURL else {
            resetUI()
            return
        }

        // Read audio data
        guard let audioData = try? Data(contentsOf: url) else {
            statusLabel.text = "Failed to read audio"
            statusLabel.textColor = .systemRed
            resetUI()
            return
        }

        // Clean up file
        try? FileManager.default.removeItem(at: url)

        // Transcribe
        Task {
            do {
                let text = try await GeminiService.shared.transcribe(
                    audioData: audioData,
                    mode: settings.selectedMode,
                    language: settings.selectedLanguage,
                    translateToEnglish: settings.translateToEnglish
                )

                await MainActor.run {
                    // Insert the transcribed text
                    self.textDocumentProxy.insertText(text)

                    // Success feedback
                    if settings.hapticFeedback {
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                    }

                    self.statusLabel.text = "Done!"
                    self.statusLabel.textColor = .systemGreen

                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.resetUI()
                    }
                }
            } catch {
                await MainActor.run {
                    if settings.hapticFeedback {
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.error)
                    }

                    self.statusLabel.text = error.localizedDescription
                    self.statusLabel.textColor = .systemRed

                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.resetUI()
                    }
                }
            }
        }
    }

    private func resetUI() {
        statusLabel.text = "Hold to record"
        statusLabel.textColor = .secondaryLabel

        var config = micButton.configuration
        config?.baseBackgroundColor = .systemOrange
        config?.image = UIImage(systemName: "mic.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 30))
        micButton.configuration = config

        updateModeDisplay()
    }

    private func updateAudioLevel() {
        guard let recorder = audioRecorder, recorder.isRecording else { return }

        recorder.updateMeters()
        let level = recorder.averagePower(forChannel: 0)

        // Normalize level
        let normalizedLevel = max(0, (level + 60) / 60)
        waveformView.updateLevel(CGFloat(normalizedLevel))
    }

    // MARK: - Button Actions

    @objc private func deletePressed() {
        textDocumentProxy.deleteBackward()
        if settings.hapticFeedback {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
    }

    @objc private func deleteLongPressed(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            deleteTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                self?.textDocumentProxy.deleteBackward()
            }
        case .ended, .cancelled:
            deleteTimer?.invalidate()
            deleteTimer = nil
        default:
            break
        }
    }

    @objc private func returnPressed() {
        textDocumentProxy.insertText("\n")
    }

    @objc private func spacePressed() {
        textDocumentProxy.insertText(" ")
    }
}

// MARK: - Waveform View

class WaveformView: UIView {
    private var bars: [UIView] = []
    private var displayLink: CADisplayLink?
    private var currentLevel: CGFloat = 0
    private var targetLevel: CGFloat = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupBars()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupBars()
    }

    private func setupBars() {
        let barCount = 7
        let barWidth: CGFloat = 6
        let spacing: CGFloat = 8

        for i in 0..<barCount {
            let bar = UIView()
            bar.backgroundColor = .systemOrange
            bar.layer.cornerRadius = barWidth / 2
            addSubview(bar)

            let xOffset = CGFloat(i) * (barWidth + spacing)
            bar.frame = CGRect(x: xOffset, y: 20, width: barWidth, height: 20)
            bars.append(bar)
        }
    }

    func startAnimating() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateAnimation))
        displayLink?.add(to: .main, forMode: .common)
    }

    func stopAnimating() {
        displayLink?.invalidate()
        displayLink = nil

        // Reset bars
        for bar in bars {
            bar.frame.size.height = 20
            bar.frame.origin.y = 20
        }
    }

    func updateLevel(_ level: CGFloat) {
        targetLevel = level
    }

    @objc private func updateAnimation() {
        currentLevel = currentLevel * 0.8 + targetLevel * 0.2

        let maxHeight: CGFloat = 50
        let minHeight: CGFloat = 10

        for (index, bar) in bars.enumerated() {
            let variation = CGFloat(index % 3) * 0.1
            let height = minHeight + (maxHeight - minHeight) * (currentLevel + variation)

            UIView.animate(withDuration: 0.05) {
                bar.frame.size.height = height
                bar.frame.origin.y = (60 - height) / 2
            }
        }
    }
}
