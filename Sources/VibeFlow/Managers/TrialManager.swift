import Foundation
import Combine

/// Manages the 7-day Pro trial with device-based anti-abuse.
class TrialManager: ObservableObject {
    static let shared = TrialManager()

    enum TrialState: Equatable {
        case unknown
        case active(daysRemaining: Int)
        case expired
    }

    @Published var trialState: TrialState = .unknown
    @Published var trialTranscriptionsUsed: Int = 0

    static let trialDuration: TimeInterval = 7 * 24 * 60 * 60  // 7 days
    static let trialTranscriptionLimit = 50

    private let defaults = UserDefaults.standard

    private struct Keys {
        static let trialStartedAt = "trial_started_at"
        static let trialEndsAt = "trial_ends_at"
        static let trialDeviceRegistered = "trial_device_registered"
        static let trialTranscriptionsUsed = "trial_transcriptions_used"
    }

    private init() {
        trialTranscriptionsUsed = defaults.integer(forKey: Keys.trialTranscriptionsUsed)
        updateTrialState()
    }

    // MARK: - Public API

    /// Check if trial is currently active (always re-evaluates in real time)
    func isTrialActive() -> Bool {
        updateTrialState()
        if case .active = trialState { return true }
        return false
    }

    /// Force-expire the trial (called when user clicks "Continue with Free").
    /// Persists by setting end date to now so it survives app restarts.
    func forceExpireTrial() {
        let now = Date()
        defaults.set(now.addingTimeInterval(-Self.trialDuration).timeIntervalSince1970, forKey: Keys.trialStartedAt)
        defaults.set(now.addingTimeInterval(-1).timeIntervalSince1970, forKey: Keys.trialEndsAt)
        defaults.set(true, forKey: Keys.trialDeviceRegistered)
        trialState = .expired
        print("[TrialManager] Trial force-expired by user (persisted)")
    }

    /// Days remaining in trial (0 if expired or not started)
    var trialDaysRemaining: Int {
        if case .active(let days) = trialState { return days }
        return 0
    }

    /// Check if this device is eligible for a trial (hasn't used one before)
    func checkTrialEligibility() async -> Bool {
        let deviceId = DeviceIdentifier.deviceId

        // Check server first (prevents clock manipulation + multi-account abuse)
        if let serverResult = await checkDeviceOnServer(deviceId: deviceId) {
            return serverResult
        }

        // Fallback to local check if server is unreachable
        return !defaults.bool(forKey: Keys.trialDeviceRegistered)
    }

    /// Start the trial for this device. Call after account creation.
    func startTrial() async {
        let deviceId = DeviceIdentifier.deviceId

        // Register on server
        await registerDeviceOnServer(deviceId: deviceId)

        // Store locally
        let now = Date()
        let endsAt = now.addingTimeInterval(Self.trialDuration)
        defaults.set(now.timeIntervalSince1970, forKey: Keys.trialStartedAt)
        defaults.set(endsAt.timeIntervalSince1970, forKey: Keys.trialEndsAt)
        defaults.set(true, forKey: Keys.trialDeviceRegistered)
        defaults.set(0, forKey: Keys.trialTranscriptionsUsed)

        await MainActor.run {
            self.trialTranscriptionsUsed = 0
            self.updateTrialState()

            // Reset Whisper counter so user gets fresh 200 after trial ends
            SubscriptionManager.shared.devSetWhisperUsage(0)
        }

        print("[TrialManager] Trial started — ends at \(endsAt), Whisper counter reset")
    }

    /// Auto-start trial for new users right after first signup/login.
    /// Called once after authentication — checks eligibility then starts if device is new.
    func autoStartTrialIfEligible() async {
        // Skip if trial already started or expired on this device
        guard case .unknown = trialState else {
            print("[TrialManager] autoStart skipped — state is \(trialState)")
            return
        }

        let eligible = await checkTrialEligibility()
        guard eligible else {
            print("[TrialManager] autoStart skipped — device already used trial")
            await MainActor.run { trialState = .expired }
            return
        }

        await startTrial()
        print("[TrialManager] autoStart — trial started for new user!")

        // Show welcome message after short delay (so login window closes first)
        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5s
        await MainActor.run {
            NotificationCenter.default.post(name: .showWelcomeTrial, object: nil)
        }
    }

    /// Increment trial transcription counter and refresh state
    func recordTrialTranscription() {
        trialTranscriptionsUsed += 1
        defaults.set(trialTranscriptionsUsed, forKey: Keys.trialTranscriptionsUsed)
        updateTrialState()  // Re-evaluate so isTrialActive() reflects limit
    }

    /// Whether trial has hit the transcription limit
    var hasReachedTrialLimit: Bool {
        trialTranscriptionsUsed >= Self.trialTranscriptionLimit
    }

    // MARK: - Dev Tools

    /// Reset all trial state — simulate a brand-new device (dev only)
    func devResetTrial() {
        defaults.removeObject(forKey: Keys.trialStartedAt)
        defaults.removeObject(forKey: Keys.trialEndsAt)
        defaults.removeObject(forKey: Keys.trialDeviceRegistered)
        defaults.removeObject(forKey: Keys.trialTranscriptionsUsed)
        trialTranscriptionsUsed = 0
        trialState = .unknown
        print("[TrialManager] DEV: Trial fully reset — state=unknown")
    }

    /// Simulate trial expired — sets trial as registered but ended
    func devExpireTrial() {
        let past = Date().addingTimeInterval(-1)  // 1 second ago
        defaults.set(past.addingTimeInterval(-Self.trialDuration).timeIntervalSince1970, forKey: Keys.trialStartedAt)
        defaults.set(past.timeIntervalSince1970, forKey: Keys.trialEndsAt)
        defaults.set(true, forKey: Keys.trialDeviceRegistered)
        trialTranscriptionsUsed = defaults.integer(forKey: Keys.trialTranscriptionsUsed)
        updateTrialState()
        print("[TrialManager] DEV: Trial force-expired — state=\(trialState)")
    }

    // MARK: - State Management

    private func updateTrialState() {
        let endsAtTimestamp = defaults.double(forKey: Keys.trialEndsAt)
        guard endsAtTimestamp > 0 else {
            // No trial started — check if device was registered (used trial before)
            if defaults.bool(forKey: Keys.trialDeviceRegistered) {
                trialState = .expired
            } else {
                trialState = .unknown
            }
            return
        }

        let endsAt = Date(timeIntervalSince1970: endsAtTimestamp)
        let now = Date()

        if now < endsAt && !hasReachedTrialLimit {
            let remaining = Calendar.current.dateComponents([.day], from: now, to: endsAt).day ?? 0
            trialState = .active(daysRemaining: max(1, remaining))
        } else {
            trialState = .expired
        }
    }

    // MARK: - Server Communication

    private func checkDeviceOnServer(deviceId: String) async -> Bool? {
        guard let token = AuthManager.shared.accessToken else { return nil }

        let urlString = "\(SupabaseConfig.url)/rest/v1/device_trials?device_id=eq.\(deviceId)&select=id"
        guard let url = URL(string: urlString) else { return nil }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return nil
            }
            // If array is empty, device hasn't used trial → eligible
            let results = try JSONDecoder().decode([[String: String]].self, from: data)
            return results.isEmpty
        } catch {
            print("[TrialManager] Server check failed: \(error.localizedDescription)")
            return nil  // Fallback to local
        }
    }

    private func registerDeviceOnServer(deviceId: String) async {
        guard let token = AuthManager.shared.accessToken,
              let userId = AuthManager.shared.userId else { return }

        let urlString = "\(SupabaseConfig.url)/rest/v1/device_trials"
        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")

        let body: [String: Any] = [
            "device_id": deviceId,
            "user_id": userId,
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                print("[TrialManager] Device registered — status \(httpResponse.statusCode)")
            }
        } catch {
            print("[TrialManager] Failed to register device: \(error.localizedDescription)")
        }
    }
}
