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

    // Online validation: tracks when the app last successfully validated with server
    @Published var lastOnlineValidation: Date? = nil
    @Published var needsOnlineValidation: Bool = false

    // Dev mode: session-only override — NOT persisted in UserDefaults.
    // Requires easter egg password each app launch to prevent `defaults write` bypass.
    @Published private(set) var devModeActive: Bool = false

    // Force Free: dev override that makes isPro return false regardless of actual plan
    @Published private(set) var forceFreeMode: Bool = false

    func activateDevMode() {
        devModeActive = true
        forceFreeMode = false
        // NOT persisted — session only
    }

    func deactivateDevMode() {
        devModeActive = false
        forceFreeMode = false
    }

    func activateForceFree() {
        forceFreeMode = true
        devModeActive = true // keep dev tools visible
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
        static let integrityHash = "wtu_h"  // tamper detection hash
        static let lastOnlineValidation = "last_online_validation"  // Date of last server check
        static let pendingSyncCount = "whisper_pending_sync"  // Offline transcriptions not yet synced
    }

    /// Grace period: how long the app works without an online validation (48 hours)
    static let onlineValidationGracePeriod: TimeInterval = 48 * 3600

    // Anti-tamper: simple hash to detect UserDefaults manipulation of the counter
    private static let hashSalt = "v0x41g0_wh15p3r"

    private func whisperIntegrityHash(for count: Int) -> String {
        let input = "\(Self.hashSalt)_\(count)"
        // Simple hash: sum of character values × prime
        var hash: UInt64 = 0
        for char in input.utf8 {
            hash = hash &* 31 &+ UInt64(char)
        }
        return String(hash, radix: 36)
    }

    private func verifyWhisperIntegrity() {
        let stored = defaults.integer(forKey: WhisperKeys.transcriptionsUsed)
        let storedHash = defaults.string(forKey: WhisperKeys.integrityHash) ?? ""
        let expected = whisperIntegrityHash(for: stored)

        if storedHash != expected && stored < whisperTranscriptionsUsed {
            // Counter was tampered (reduced) — restore previous known value
            print("[SubscriptionManager] ⚠️ Whisper counter tampered! stored=\(stored) expected=\(whisperTranscriptionsUsed)")
            defaults.set(whisperTranscriptionsUsed, forKey: WhisperKeys.transcriptionsUsed)
            defaults.set(whisperIntegrityHash(for: whisperTranscriptionsUsed), forKey: WhisperKeys.integrityHash)
        } else {
            whisperTranscriptionsUsed = stored
        }
    }

    private func saveWhisperCount(_ count: Int) {
        defaults.set(count, forKey: WhisperKeys.transcriptionsUsed)
        defaults.set(whisperIntegrityHash(for: count), forKey: WhisperKeys.integrityHash)
    }

    private init() {
        // Load whisper usage counter
        loadWhisperUsage()

        // Load last online validation timestamp
        lastOnlineValidation = defaults.object(forKey: WhisperKeys.lastOnlineValidation) as? Date
        checkOnlineValidationStatus()

        // Observe auth changes to fetch profile
        AuthManager.shared.$isAuthenticated
            .dropFirst()
            .sink { [weak self] isAuth in
                if isAuth {
                    Task {
                        await self?.fetchProfile()
                        await self?.syncWhisperUsageToServer()
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
                await syncWhisperUsageToServer()
                await fetchCloudStats()
            }
            startPeriodicRefresh()
        }
    }

    private func startPeriodicRefresh() {
        stopPeriodicRefresh()
        // Refresh profile + sync usage + stats every 5 minutes
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task {
                await self?.fetchProfile()
                await self?.syncWhisperUsageToServer()
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

    /// Client-side Whisper free limit (200/month).
    /// Re-checks monthly reset on every access to handle month boundaries without restart.
    var hasReachedWhisperLimit: Bool {
        guard !isPro else { return false }
        guard !TrialManager.shared.isTrialActive() else { return false }
        checkWhisperMonthlyReset()
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
        if devModeActive { return true }
        // Must have plan=pro AND active subscription status
        return plan == "pro" && subscriptionStatus == "active"
    }

    // MARK: - Whisper Usage Tracking

    /// How often to show a soft upgrade reminder (every N Whisper transcriptions)
    static let upgradeReminderInterval = 25

    func recordWhisperTranscription() {
        verifyWhisperIntegrity()  // Detect tampering before incrementing
        whisperTranscriptionsUsed += 1
        saveWhisperCount(whisperTranscriptionsUsed)

        // Background sync to server (best-effort, non-blocking)
        Task {
            await syncWhisperUsageToServer()
        }

        // Show soft upgrade reminder every N transcriptions for free users
        if !isPro,
           !TrialManager.shared.isTrialActive(),
           whisperTranscriptionsUsed > 0,
           whisperTranscriptionsUsed % Self.upgradeReminderInterval == 0,
           whisperTranscriptionsUsed < Self.whisperMonthlyLimit {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                NotificationCenter.default.post(name: .showUpgradeReminder, object: nil)
            }
            print("[SubscriptionManager] Upgrade reminder at \(self.whisperTranscriptionsUsed) transcriptions")
        }
    }

    // Dev tools: set counters for testing (includes integrity hash)
    func devSetWhisperUsage(_ count: Int) {
        whisperTranscriptionsUsed = count
        saveWhisperCount(count)
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

    /// Checks if a new month started and resets Whisper counter if so.
    /// Called on every limit check to handle month boundaries without app restart.
    private func checkWhisperMonthlyReset() {
        let now = Date()
        if let resetDate = defaults.object(forKey: WhisperKeys.resetDate) as? Date {
            let calendar = Calendar.current
            if !calendar.isDate(now, equalTo: resetDate, toGranularity: .month) {
                whisperTranscriptionsUsed = 0
                saveWhisperCount(0)
                defaults.set(now, forKey: WhisperKeys.resetDate)
                print("[SubscriptionManager] Whisper counter auto-reset (new month detected)")
            }
        }
    }

    private func loadWhisperUsage() {
        // Check if we need to reset (new month)
        let now = Date()
        if let resetDate = defaults.object(forKey: WhisperKeys.resetDate) as? Date {
            let calendar = Calendar.current
            if !calendar.isDate(now, equalTo: resetDate, toGranularity: .month) {
                // New month — reset counter
                whisperTranscriptionsUsed = 0
                saveWhisperCount(0)
                defaults.set(now, forKey: WhisperKeys.resetDate)
                print("[SubscriptionManager] Whisper counter reset (new month)")
                return
            }
        } else {
            // First time — set reset date
            defaults.set(now, forKey: WhisperKeys.resetDate)
        }

        // Load and verify integrity
        let stored = defaults.integer(forKey: WhisperKeys.transcriptionsUsed)
        let storedHash = defaults.string(forKey: WhisperKeys.integrityHash) ?? ""
        let expected = whisperIntegrityHash(for: stored)

        if !storedHash.isEmpty && storedHash != expected {
            // Tampered — keep at 0 for first launch, otherwise flag
            print("[SubscriptionManager] ⚠️ Whisper counter integrity check failed on load")
            whisperTranscriptionsUsed = stored  // Accept but log
        } else {
            whisperTranscriptionsUsed = stored
        }

        // Ensure hash exists (migration for existing users)
        if storedHash.isEmpty {
            saveWhisperCount(stored)
        }
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

                    // Mark successful online validation
                    self.markOnlineValidation()
                }
            }
        } catch {
            print("[SubscriptionManager] Failed to fetch profile: \(error)")
        }
    }

    // MARK: - Online Validation Enforcement

    /// Records that the app successfully validated with server right now
    private func markOnlineValidation() {
        let now = Date()
        lastOnlineValidation = now
        needsOnlineValidation = false
        defaults.set(now, forKey: WhisperKeys.lastOnlineValidation)
        print("[SubscriptionManager] Online validation marked at \(now)")
    }

    /// Checks if the app has validated online within the grace period (48h).
    /// If not, sets needsOnlineValidation = true which blocks transcription.
    func checkOnlineValidationStatus() {
        guard AuthManager.shared.isAuthenticated else {
            needsOnlineValidation = false
            return
        }

        guard let lastValidation = lastOnlineValidation else {
            // Never validated — needs online check
            needsOnlineValidation = true
            print("[SubscriptionManager] No previous online validation found — requires connection")
            return
        }

        let elapsed = Date().timeIntervalSince(lastValidation)
        if elapsed > Self.onlineValidationGracePeriod {
            needsOnlineValidation = true
            print("[SubscriptionManager] Online validation expired (\(Int(elapsed / 3600))h ago) — requires connection")
        } else {
            needsOnlineValidation = false
            let remaining = Self.onlineValidationGracePeriod - elapsed
            print("[SubscriptionManager] Online validation OK (\(Int(remaining / 3600))h remaining)")
        }
    }

    // MARK: - Whisper Usage Sync (bidirectional)

    /// Syncs local Whisper usage count to the server (profiles.free_transcriptions_used).
    /// Takes the MAX of local and server count to prevent reset exploits.
    func syncWhisperUsageToServer() async {
        guard let token = AuthManager.shared.accessToken,
              let userId = AuthManager.shared.userId else { return }

        // Use the higher of local vs server count (prevents reinstall reset exploit)
        let localCount = await MainActor.run { whisperTranscriptionsUsed }
        let serverCount = await MainActor.run { freeTranscriptionsUsed }
        let syncedCount = max(localCount, serverCount)

        // Update local if server was higher
        if serverCount > localCount {
            await MainActor.run {
                self.whisperTranscriptionsUsed = serverCount
                self.saveWhisperCount(serverCount)
            }
            print("[SubscriptionManager] Whisper sync: server had higher count (\(serverCount) > \(localCount)), updated local")
        }

        // Update server if local was higher
        if localCount > serverCount {
            let urlString = "\(SupabaseConfig.url)/rest/v1/profiles?id=eq.\(userId)"
            guard let url = URL(string: urlString) else { return }

            var request = URLRequest(url: url)
            request.httpMethod = "PATCH"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("return=minimal", forHTTPHeaderField: "Prefer")

            let body: [String: Any] = ["free_transcriptions_used": localCount]
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)

            do {
                let (_, response) = try await URLSession.shared.data(for: request)
                if let http = response as? HTTPURLResponse, (200...204).contains(http.statusCode) {
                    print("[SubscriptionManager] Whisper sync: pushed local count (\(localCount)) to server")
                }
            } catch {
                print("[SubscriptionManager] Whisper sync failed: \(error)")
            }
        }

        if localCount == serverCount {
            print("[SubscriptionManager] Whisper sync: counts match (\(syncedCount))")
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
