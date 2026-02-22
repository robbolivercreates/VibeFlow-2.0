import Foundation
import Combine
import AppKit

class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    // Eduzz checkout URLs
    static let proMonthlyCheckoutURL = "https://chk.eduzz.com/39ZQ2OYE9E"
    static let proAnnualCheckoutURL = "https://chk.eduzz.com/Z0B57NQ3WA"

    // Free tier limits (Whisper local — 200 transcriptions/month)
    static let whisperMonthlyLimit = 200
    static let freeModes: [TranscriptionMode] = [.text]
    static let freeLanguages: [SpeechLanguage] = [.portuguese, .english]

    // Legacy server-side limit (kept for Supabase gating)
    static let freeMonthlyLimit = 100

    @Published var plan: String = "free"
    @Published var subscriptionStatus: String? = nil
    @Published var freeTranscriptionsUsed: Int = 0
    @Published var freeTranscriptionsResetAt: String? = nil
    @Published var profile: UserProfile? = nil

    // Cloud stats (from Supabase usage_log — same source as dashboard)
    @Published var cloudTotalTranscriptions: Int = 0
    @Published var cloudTotalRecordingSeconds: Double = 0

    // Whisper local usage counter (client-side)
    @Published var whisperTranscriptionsUsed: Int = 0

    // Dev mode: local override that grants full Pro access (easter egg)
    @Published private(set) var devModeActive: Bool = UserDefaults.standard.bool(forKey: "devModeActive")

    // Force Free: dev override that makes isPro return false regardless of actual plan
    @Published private(set) var forceFreeMode: Bool = false

    func activateDevMode() {
        devModeActive = true
        forceFreeMode = false
        UserDefaults.standard.set(true, forKey: "devModeActive")
    }

    func deactivateDevMode() {
        devModeActive = false
        forceFreeMode = false
        UserDefaults.standard.set(false, forKey: "devModeActive")
    }

    func activateForceFree() {
        forceFreeMode = true
        devModeActive = true // keep dev tools visible
        UserDefaults.standard.set(true, forKey: "devModeActive")
    }

    func deactivateForceFree() {
        forceFreeMode = false
    }

    private let defaults = UserDefaults.standard
    private var cancellables = Set<AnyCancellable>()
    private var refreshTimer: Timer?

    private struct WhisperKeys {
        static let transcriptionsUsed = "whisper_transcriptions_used"
        static let resetDate = "whisper_transcriptions_reset_date"
    }

    private init() {
        // Load whisper usage counter
        loadWhisperUsage()

        // Observe auth changes to fetch profile
        AuthManager.shared.$isAuthenticated
            .dropFirst()
            .sink { [weak self] isAuth in
                if isAuth {
                    Task {
                        await self?.fetchProfile()
                        await self?.fetchCloudStats()
                    }
                    self?.startPeriodicRefresh()
                } else {
                    self?.resetToFree()
                    self?.stopPeriodicRefresh()
                }
            }
            .store(in: &cancellables)

        // Fetch on init if already authenticated
        if AuthManager.shared.isAuthenticated {
            Task {
                await fetchProfile()
                await fetchCloudStats()
            }
            startPeriodicRefresh()
        }
    }

    private func startPeriodicRefresh() {
        stopPeriodicRefresh()
        // Refresh profile + stats every 5 minutes to keep in sync with dashboard
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task {
                await self?.fetchProfile()
                await self?.fetchCloudStats()
            }
        }
    }

    private func stopPeriodicRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    // MARK: - Feature Gating

    func canUseMode(_ mode: TranscriptionMode) -> Bool {
        let trial = TrialManager.shared.isTrialActive()
        let result = isPro || trial || Self.freeModes.contains(mode)
        print("[SubscriptionManager] canUseMode(\(mode.rawValue)) → isPro=\(isPro) trial=\(trial) plan=\(plan) → \(result)")
        return result
    }

    func canUseLanguage(_ language: SpeechLanguage) -> Bool {
        let trial = TrialManager.shared.isTrialActive()
        let result = isPro || trial || Self.freeLanguages.contains(language)
        print("[SubscriptionManager] canUseLanguage(\(language.rawValue)) → isPro=\(isPro) trial=\(trial) → \(result)")
        return result
    }

    /// Server-side free limit (Supabase/Gemini path)
    var hasReachedFreeLimit: Bool {
        guard !isPro else { return false }
        return freeTranscriptionsUsed >= Self.freeMonthlyLimit
    }

    /// Client-side Whisper free limit (200/month)
    var hasReachedWhisperLimit: Bool {
        guard !isPro else { return false }
        guard !TrialManager.shared.isTrialActive() else { return false }
        return whisperTranscriptionsUsed >= Self.whisperMonthlyLimit
    }

    var freeTranscriptionsRemaining: Int {
        max(0, Self.freeMonthlyLimit - freeTranscriptionsUsed)
    }

    var whisperTranscriptionsRemaining: Int {
        max(0, Self.whisperMonthlyLimit - whisperTranscriptionsUsed)
    }

    var isPro: Bool {
        if forceFreeMode { return false }
        return devModeActive || plan == "pro"
    }

    // MARK: - Whisper Usage Tracking

    func recordWhisperTranscription() {
        whisperTranscriptionsUsed += 1
        defaults.set(whisperTranscriptionsUsed, forKey: WhisperKeys.transcriptionsUsed)
    }

    // Dev tools: set counters for testing
    func devSetWhisperUsage(_ count: Int) {
        whisperTranscriptionsUsed = count
        defaults.set(count, forKey: WhisperKeys.transcriptionsUsed)
    }

    func devSetFreeUsage(_ count: Int) {
        freeTranscriptionsUsed = count
    }

    // MARK: - Dev Tools: Supabase Mutations

    /// Changes plan in Supabase profiles table (real server-side change)
    func devSetPlanOnSupabase(_ newPlan: String) async -> Bool {
        guard let token = AuthManager.shared.accessToken,
              let userId = AuthManager.shared.userId else { return false }

        let urlString = "\(SupabaseConfig.url)/rest/v1/profiles?id=eq.\(userId)"
        guard let url = URL(string: urlString) else { return false }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")

        let body: [String: Any] = ["plan": newPlan]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { return false }
            print("[DevTools] PATCH plan=\(newPlan) → \(http.statusCode)")
            if http.statusCode == 204 || http.statusCode == 200 {
                await fetchProfile()
                return true
            }
            return false
        } catch {
            print("[DevTools] PATCH plan failed: \(error)")
            return false
        }
    }

    /// Sets free_transcriptions_used in Supabase profiles table
    func devSetFreeUsageOnSupabase(_ count: Int) async -> Bool {
        guard let token = AuthManager.shared.accessToken,
              let userId = AuthManager.shared.userId else { return false }

        let urlString = "\(SupabaseConfig.url)/rest/v1/profiles?id=eq.\(userId)"
        guard let url = URL(string: urlString) else { return false }

        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")

        let body: [String: Any] = ["free_transcriptions_used": count]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { return false }
            print("[DevTools] PATCH free_transcriptions_used=\(count) → \(http.statusCode)")
            if http.statusCode == 204 || http.statusCode == 200 {
                await fetchProfile()
                return true
            }
            return false
        } catch {
            print("[DevTools] PATCH free_transcriptions_used failed: \(error)")
            return false
        }
    }

    private func loadWhisperUsage() {
        // Check if we need to reset (new month)
        let now = Date()
        if let resetDate = defaults.object(forKey: WhisperKeys.resetDate) as? Date {
            let calendar = Calendar.current
            if !calendar.isDate(now, equalTo: resetDate, toGranularity: .month) {
                // New month — reset counter
                defaults.set(0, forKey: WhisperKeys.transcriptionsUsed)
                defaults.set(now, forKey: WhisperKeys.resetDate)
                whisperTranscriptionsUsed = 0
                print("[SubscriptionManager] Whisper counter reset (new month)")
                return
            }
        } else {
            // First time — set reset date
            defaults.set(now, forKey: WhisperKeys.resetDate)
        }
        whisperTranscriptionsUsed = defaults.integer(forKey: WhisperKeys.transcriptionsUsed)
    }

    // MARK: - Profile Fetch

    func fetchProfile() async {
        guard let token = AuthManager.shared.accessToken,
              let userId = AuthManager.shared.userId else { return }

        let urlString = "\(SupabaseConfig.url)/rest/v1/profiles?id=eq.\(userId)&select=*"
        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return }

            let profiles = try JSONDecoder().decode([UserProfile].self, from: data)
            if let profile = profiles.first {
                await MainActor.run {
                    self.profile = profile
                    self.plan = profile.plan
                    self.subscriptionStatus = profile.subscriptionStatus
                    self.freeTranscriptionsUsed = profile.freeTranscriptionsUsed
                    self.freeTranscriptionsResetAt = profile.freeTranscriptionsResetAt
                }
            }
        } catch {
            print("[SubscriptionManager] Failed to fetch profile: \(error)")
        }
    }

    // MARK: - Cloud Stats (from usage_log — same source as dashboard)

    func fetchCloudStats() async {
        guard let token = AuthManager.shared.accessToken,
              let userId = AuthManager.shared.userId else { return }

        let urlString = "\(SupabaseConfig.url)/rest/v1/usage_log?user_id=eq.\(userId)&select=audio_duration_seconds"
        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("count=exact", forHTTPHeaderField: "Prefer")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return }

            // Parse count from Content-Range header: "0-N/total" or "*/total"
            var count = 0
            if let contentRange = httpResponse.value(forHTTPHeaderField: "Content-Range"),
               let slashIndex = contentRange.lastIndex(of: "/"),
               let total = Int(contentRange[contentRange.index(after: slashIndex)...]) {
                count = total
            }

            // Sum audio durations
            struct DurationRow: Codable {
                let audio_duration_seconds: Double?
            }
            let rows = (try? JSONDecoder().decode([DurationRow].self, from: data)) ?? []
            let totalSeconds = rows.compactMap(\.audio_duration_seconds).reduce(0, +)

            await MainActor.run {
                self.cloudTotalTranscriptions = count
                self.cloudTotalRecordingSeconds = totalSeconds
            }
            print("[SubscriptionManager] Cloud stats: \(count) transcriptions, \(Int(totalSeconds))s recording")
        } catch {
            print("[SubscriptionManager] Failed to fetch cloud stats: \(error)")
        }
    }

    // MARK: - Verify Purchase

    func verifyPurchase() async -> VerifyPurchaseResponse? {
        guard let token = AuthManager.shared.accessToken else { return nil }

        let urlString = "\(SupabaseConfig.url)/functions/v1/verify-purchase"
        guard let url = URL(string: urlString) else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = "{}".data(using: .utf8)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return nil }

            let result = try JSONDecoder().decode(VerifyPurchaseResponse.self, from: data)

            // Refresh profile after verification
            await fetchProfile()

            return result
        } catch {
            print("[SubscriptionManager] Verify purchase failed: \(error)")
            return nil
        }
    }

    // MARK: - Upgrade

    func openUpgradeURL(annual: Bool = false) {
        var urlString = annual ? Self.proAnnualCheckoutURL : Self.proMonthlyCheckoutURL

        // Pre-fill email on Eduzz checkout so purchase email matches VoxAiGo account
        if let email = AuthManager.shared.userEmail,
           let encoded = email.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            let name = profile?.email != nil ? "" : "" // Eduzz uses email as identifier
            urlString += "?email=\(encoded)&skip=1"
        }

        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Private

    private func resetToFree() {
        plan = "free"
        subscriptionStatus = nil
        freeTranscriptionsUsed = 0
        freeTranscriptionsResetAt = nil
        profile = nil
        cloudTotalTranscriptions = 0
        cloudTotalRecordingSeconds = 0
    }
}
