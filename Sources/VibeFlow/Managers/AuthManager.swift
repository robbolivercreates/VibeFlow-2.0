import Foundation
import Combine
import AppKit

class AuthManager: ObservableObject {
    static let shared = AuthManager()

    private static let supabaseURL = SupabaseConfig.url
    private static let supabaseAnonKey = SupabaseConfig.anonKey

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let accessToken = "supabase_access_token"
        static let refreshToken = "supabase_refresh_token"
        static let expiresAt = "supabase_expires_at"
        static let userId = "supabase_user_id"
        static let userEmail = "supabase_user_email"
    }

    @Published var isAuthenticated = false
    @Published var userEmail: String?
    @Published var userId: String?
    @Published var isLoading = false

    private var refreshTimer: Timer?

    private init() {
        restoreSession()
    }

    // MARK: - Session Management

    var accessToken: String? {
        defaults.string(forKey: Keys.accessToken)
    }

    var currentSession: SupabaseSession? {
        guard let access = defaults.string(forKey: Keys.accessToken),
              let refresh = defaults.string(forKey: Keys.refreshToken) else { return nil }
        let expiresAt = defaults.integer(forKey: Keys.expiresAt)
        return SupabaseSession(accessToken: access, refreshToken: refresh, expiresAt: expiresAt)
    }

    private func restoreSession() {
        guard let session = currentSession else {
            isAuthenticated = false
            return
        }

        userId = defaults.string(forKey: Keys.userId)
        userEmail = defaults.string(forKey: Keys.userEmail)
        isAuthenticated = true

        if session.isExpired {
            Task { await refreshSession() }
        } else {
            scheduleRefresh(in: session.expiresInSeconds)
        }
    }

    private func saveSession(_ response: SupabaseAuthResponse) {
        let expiresAt = response.expiresAt ?? (Int(Date().timeIntervalSince1970) + response.expiresIn)

        defaults.set(response.accessToken, forKey: Keys.accessToken)
        defaults.set(response.refreshToken, forKey: Keys.refreshToken)
        defaults.set(expiresAt, forKey: Keys.expiresAt)
        defaults.set(response.user.id, forKey: Keys.userId)
        defaults.set(response.user.email, forKey: Keys.userEmail)

        DispatchQueue.main.async {
            self.isAuthenticated = true
            self.userId = response.user.id
            self.userEmail = response.user.email
        }

        let expiresIn = expiresAt - Int(Date().timeIntervalSince1970)
        scheduleRefresh(in: expiresIn)
    }

    private func clearSession() {
        defaults.removeObject(forKey: Keys.accessToken)
        defaults.removeObject(forKey: Keys.refreshToken)
        defaults.removeObject(forKey: Keys.expiresAt)
        defaults.removeObject(forKey: Keys.userId)
        defaults.removeObject(forKey: Keys.userEmail)

        refreshTimer?.invalidate()
        refreshTimer = nil

        DispatchQueue.main.async {
            self.isAuthenticated = false
            self.userId = nil
            self.userEmail = nil
        }
    }

    private func scheduleRefresh(in seconds: Int) {
        refreshTimer?.invalidate()
        // Refresh 60 seconds before expiry
        let delay = max(Double(seconds - 60), 10)
        refreshTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            Task { await self?.refreshSession() }
        }
    }

    // MARK: - Auth API

    func signUp(email: String, password: String) async throws {
        await MainActor.run { isLoading = true }
        defer { Task { @MainActor in isLoading = false } }

        let url = URL(string: "\(Self.supabaseURL)/auth/v1/signup")!
        let body: [String: Any] = ["email": email, "password": password]

        let response: SupabaseAuthResponse = try await postJSON(url: url, body: body)

        // If access_token is empty, it means email confirmation is required
        if response.accessToken.isEmpty {
            throw AuthError.emailNotConfirmed
        }

        saveSession(response)
    }

    func signIn(email: String, password: String) async throws {
        await MainActor.run { isLoading = true }
        defer { Task { @MainActor in isLoading = false } }

        let url = URL(string: "\(Self.supabaseURL)/auth/v1/token?grant_type=password")!
        let body: [String: Any] = ["email": email, "password": password]

        let response: SupabaseAuthResponse = try await postJSON(url: url, body: body)
        saveSession(response)
    }

    func signInWithGoogle() {
        // Open browser for Google OAuth with redirect to custom URL scheme
        let redirectURL = "voxaigo://auth/callback"
        let authURL = "\(Self.supabaseURL)/auth/v1/authorize?provider=google&redirect_to=\(redirectURL)"

        if let url = URL(string: authURL) {
            NSWorkspace.shared.open(url)
        }
    }

    /// Handle OAuth callback from voxaigo:// URL scheme
    func handleOAuthCallback(url: URL) {
        // URL format: voxaigo://auth/callback#access_token=...&refresh_token=...&expires_in=...
        // Fragment is after #, not query params
        guard let fragment = url.fragment else {
            print("[AuthManager] OAuth callback missing fragment")
            return
        }

        var params: [String: String] = [:]
        for pair in fragment.split(separator: "&") {
            let parts = pair.split(separator: "=", maxSplits: 1)
            if parts.count == 2 {
                params[String(parts[0])] = String(parts[1]).removingPercentEncoding ?? String(parts[1])
            }
        }

        guard let accessToken = params["access_token"],
              let refreshToken = params["refresh_token"],
              let expiresIn = params["expires_in"].flatMap(Int.init) else {
            print("[AuthManager] OAuth callback missing required params")
            return
        }

        let expiresAt = params["expires_at"].flatMap(Int.init)
            ?? (Int(Date().timeIntervalSince1970) + expiresIn)

        // Fetch user info with the access token
        Task {
            do {
                let user = try await fetchUser(accessToken: accessToken)
                let response = SupabaseAuthResponse(
                    accessToken: accessToken,
                    tokenType: "bearer",
                    expiresIn: expiresIn,
                    expiresAt: expiresAt,
                    refreshToken: refreshToken,
                    user: user
                )
                saveSession(response)
                print("[AuthManager] Google OAuth sign-in successful: \(user.email ?? "unknown")")
            } catch {
                print("[AuthManager] Failed to fetch user after OAuth: \(error)")
            }
        }
    }

    func refreshSession() async {
        guard let refreshToken = defaults.string(forKey: Keys.refreshToken) else {
            clearSession()
            return
        }

        let url = URL(string: "\(Self.supabaseURL)/auth/v1/token?grant_type=refresh_token")!
        let body: [String: Any] = ["refresh_token": refreshToken]

        do {
            let response: SupabaseAuthResponse = try await postJSON(url: url, body: body)
            saveSession(response)
            print("[AuthManager] Session refreshed successfully")
        } catch {
            print("[AuthManager] Session refresh failed: \(error)")
            clearSession()
        }
    }

    // MARK: - Password Reset

    func resetPassword(email: String) async throws {
        var request = URLRequest(url: URL(string: "\(Self.supabaseURL)/auth/v1/recover")!)
        request.httpMethod = "POST"
        request.setValue(Self.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["email": email])
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw AuthError.serverError("HTTP \(code)")
        }
    }

    func signOut() {
        // Fire-and-forget sign out on server
        if let token = accessToken {
            Task {
                var request = URLRequest(url: URL(string: "\(Self.supabaseURL)/auth/v1/logout")!)
                request.httpMethod = "POST"
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                request.setValue(Self.supabaseAnonKey, forHTTPHeaderField: "apikey")
                try? await URLSession.shared.data(for: request)
            }
        }
        clearSession()
    }

    // MARK: - User Info

    private func fetchUser(accessToken: String) async throws -> SupabaseUser {
        var request = URLRequest(url: URL(string: "\(Self.supabaseURL)/auth/v1/user")!)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(Self.supabaseAnonKey, forHTTPHeaderField: "apikey")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AuthError.serverError("Failed to fetch user")
        }

        return try JSONDecoder().decode(SupabaseUser.self, from: data)
    }

    // MARK: - HTTP Helpers

    private func postJSON<T: Decodable>(url: URL, body: [String: Any]) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Self.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.networkError("No response")
        }

        if httpResponse.statusCode == 200 {
            return try JSONDecoder().decode(T.self, from: data)
        }

        // Parse error response
        if let errorResponse = try? JSONDecoder().decode(SupabaseErrorResponse.self, from: data) {
            let msg = errorResponse.displayMessage
            if msg.contains("Invalid login") || msg.contains("invalid_grant") {
                throw AuthError.invalidCredentials
            }
            if msg.contains("Email not confirmed") {
                throw AuthError.emailNotConfirmed
            }
            throw AuthError.serverError(msg)
        }

        throw AuthError.serverError("HTTP \(httpResponse.statusCode)")
    }
}
