import Foundation
import Combine
import AppKit

class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    // Eduzz checkout URLs
    static let proMonthlyCheckoutURL = "https://chk.eduzz.com/39ZQ2OYE9E"
    static let proAnnualCheckoutURL = "https://chk.eduzz.com/Z0B57NQ3WA"

    // Free tier limits
    static let freeMonthlyLimit = 100
    static let freeModes: [TranscriptionMode] = [.text, .chat]
    static let freeLanguages: [SpeechLanguage] = [.portuguese, .english]

    @Published var plan: String = "free"
    @Published var subscriptionStatus: String? = nil
    @Published var freeTranscriptionsUsed: Int = 0
    @Published var freeTranscriptionsResetAt: String? = nil
    @Published var profile: UserProfile? = nil

    // Dev mode: local override that grants full Pro access (easter egg)
    @Published private(set) var devModeActive: Bool = UserDefaults.standard.bool(forKey: "devModeActive")

    func activateDevMode() {
        devModeActive = true
        UserDefaults.standard.set(true, forKey: "devModeActive")
    }

    private var cancellables = Set<AnyCancellable>()
    private var refreshTimer: Timer?

    private init() {
        // Observe auth changes to fetch profile
        AuthManager.shared.$isAuthenticated
            .dropFirst()
            .sink { [weak self] isAuth in
                if isAuth {
                    Task { await self?.fetchProfile() }
                    self?.startPeriodicRefresh()
                } else {
                    self?.resetToFree()
                    self?.stopPeriodicRefresh()
                }
            }
            .store(in: &cancellables)

        // Fetch on init if already authenticated
        if AuthManager.shared.isAuthenticated {
            Task { await fetchProfile() }
            startPeriodicRefresh()
        }
    }

    private func startPeriodicRefresh() {
        stopPeriodicRefresh()
        // Refresh profile every 5 minutes to keep counter in sync
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { await self?.fetchProfile() }
        }
    }

    private func stopPeriodicRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    // MARK: - Feature Gating

    func canUseMode(_ mode: TranscriptionMode) -> Bool {
        let result = isPro || Self.freeModes.contains(mode)
        print("[SubscriptionManager] canUseMode(\(mode.rawValue)) → isPro=\(isPro) devMode=\(devModeActive) plan=\(plan) → \(result)")
        return result
    }

    func canUseLanguage(_ language: SpeechLanguage) -> Bool {
        let result = isPro || Self.freeLanguages.contains(language)
        print("[SubscriptionManager] canUseLanguage(\(language.rawValue)) → isPro=\(isPro) → \(result)")
        return result
    }

    var hasReachedFreeLimit: Bool {
        guard !isPro else { return false }
        return freeTranscriptionsUsed >= Self.freeMonthlyLimit
    }

    var freeTranscriptionsRemaining: Int {
        max(0, Self.freeMonthlyLimit - freeTranscriptionsUsed)
    }

    var isPro: Bool { devModeActive || plan == "pro" }

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
    }
}
