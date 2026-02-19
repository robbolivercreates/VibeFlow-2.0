import Foundation
import SwiftUI

// MARK: - Conversation Context

struct ConversationContext {
    let originalText: String
    let translation: String
    let fromLanguageName: String
    let fromLanguageCode: String
    let toLanguageName: String
}

// MARK: - Manager

/// Drives the state machine for the Conversation Reply HUD.
/// Select foreign text → ⌃⇧R → read translation → hold ⌥⌘ → speak reply → paste in their language.
class ConversationReplyManager: ObservableObject {
    static let shared = ConversationReplyManager()

    enum State {
        case idle
        case translating                    // Reading selection & calling Gemini
        case ready(ConversationContext)     // Showing translation + countdown
        case recording                      // User is recording reply
        case processing                     // Translating spoken reply
    }

    @Published var state: State = .idle
    @Published var timeoutProgress: CGFloat = 1.0

    var isActive: Bool {
        if case .idle = state { return false }
        return true
    }

    /// Language the user should reply in (detected from selected text)
    var detectedLanguageName: String {
        if case .ready(let ctx) = state { return ctx.fromLanguageName }
        return ""
    }

    var detectedLanguageCode: String {
        if case .ready(let ctx) = state { return ctx.fromLanguageCode }
        return ""
    }

    private var progressTimer: Timer?
    let timeoutDuration: TimeInterval = 15.0

    private init() {}

    func beginTranslating() {
        DispatchQueue.main.async {
            self.state = .translating
            self.timeoutProgress = 1.0
        }
    }

    func showReady(_ context: ConversationContext) {
        DispatchQueue.main.async {
            self.state = .ready(context)
            self.startCountdown()
        }
    }

    func beginRecordingReply() {
        DispatchQueue.main.async {
            self.stopCountdown()
            self.state = .recording
        }
    }

    func beginProcessingReply() {
        DispatchQueue.main.async {
            self.state = .processing
        }
    }

    func dismiss() {
        DispatchQueue.main.async {
            self.stopCountdown()
            self.state = .idle
            self.timeoutProgress = 1.0
        }
    }

    private func startCountdown() {
        stopCountdown()
        timeoutProgress = 1.0
        let startTime = Date()
        let duration = timeoutDuration

        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let elapsed = Date().timeIntervalSince(startTime)
            let progress = CGFloat(max(0.0, 1.0 - elapsed / duration))

            DispatchQueue.main.async {
                self.timeoutProgress = progress
                if progress <= 0 {
                    self.stopCountdown()
                    self.dismiss()
                    NotificationCenter.default.post(name: .conversationReplyTimedOut, object: nil)
                }
            }
        }
    }

    private func stopCountdown() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let conversationReplyTimedOut = Notification.Name("conversationReplyTimedOut")
    static let conversationReplyActivate = Notification.Name("conversationReplyActivate")
}
