import Foundation

// MARK: - Supabase Configuration

enum SupabaseConfig {
    static let url = "https://bvdbpyjudmkkspcxevlp.supabase.co"
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ2ZGJweWp1ZG1ra3NwY3hldmxwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEzNDA2MzMsImV4cCI6MjA4NjkxNjYzM30.hRaoAXKTesJarVvg8cBky2Umtb1R7R824gJwgEle77w"
}

// MARK: - Supabase Auth Models

struct SupabaseAuthResponse: Codable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
    let expiresAt: Int?
    let refreshToken: String
    let user: SupabaseUser

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case expiresAt = "expires_at"
        case refreshToken = "refresh_token"
        case user
    }
}

struct SupabaseUser: Codable {
    let id: String
    let email: String?
    let phone: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, email, phone
        case createdAt = "created_at"
    }
}

struct SupabaseSession: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Int

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresAt = "expires_at"
    }

    var isExpired: Bool {
        Date().timeIntervalSince1970 > Double(expiresAt)
    }

    var expiresInSeconds: Int {
        max(0, expiresAt - Int(Date().timeIntervalSince1970))
    }
}

// MARK: - Profile & Subscription

struct UserProfile: Codable {
    let id: String
    let email: String?
    let plan: String
    let subscriptionStatus: String?
    let freeTranscriptionsUsed: Int
    let freeTranscriptionsResetAt: String?

    enum CodingKeys: String, CodingKey {
        case id, email, plan
        case subscriptionStatus = "subscription_status"
        case freeTranscriptionsUsed = "free_transcriptions_used"
        case freeTranscriptionsResetAt = "free_transcriptions_reset_at"
    }

    var isPro: Bool { plan == "pro" }
    var isFree: Bool { plan == "free" }
}

// MARK: - Transcription Response

struct TranscriptionResponse: Codable {
    let text: String?
    let error: String?
    let code: String?
    let usage: UsageInfo?
    // 429 responses put used/limit at root level (not inside usage)
    let used: Int?
    let limit: Int?
    let resets_at: String?
}

struct UsageInfo: Codable {
    let used: Int
    let remaining: Int
    let limit: Int
}

// MARK: - Verify Purchase Response

struct VerifyPurchaseResponse: Codable {
    let success: Bool
    let plan: String?
    let subscription: String?
    let message: String?
    let error: String?
}

// MARK: - Supabase Error

struct SupabaseErrorResponse: Codable {
    let error: String?
    let errorDescription: String?
    let msg: String?
    let message: String?
    let code: String?

    enum CodingKeys: String, CodingKey {
        case error
        case errorDescription = "error_description"
        case msg, message, code
    }

    var displayMessage: String {
        errorDescription ?? message ?? msg ?? error ?? "Unknown error"
    }
}

// MARK: - Auth Error

enum AuthError: LocalizedError {
    case notAuthenticated
    case invalidCredentials
    case networkError(String)
    case serverError(String)
    case tokenExpired
    case emailNotConfirmed

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Not authenticated"
        case .invalidCredentials:
            return "Invalid email or password"
        case .networkError(let msg):
            return "Network error: \(msg)"
        case .serverError(let msg):
            return "Server error: \(msg)"
        case .tokenExpired:
            return "Session expired. Please log in again."
        case .emailNotConfirmed:
            return "Please confirm your email before logging in."
        }
    }
}

// MARK: - Transcription Service Type

enum TranscriptionServiceType {
    case supabase
    case byok(apiKey: String)
    case none
}
