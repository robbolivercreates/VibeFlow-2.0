import SwiftUI

@main
struct VibeFlowApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            if appState.showOnboarding {
                OnboardingView()
                    .environmentObject(appState)
            } else {
                MainView()
                    .environmentObject(appState)
            }
        }
    }
}

/// App-wide state management
class AppState: ObservableObject {
    @Published var showOnboarding: Bool

    private let settings = SharedSettings.shared

    init() {
        showOnboarding = !settings.onboardingCompleted
    }

    func completeOnboarding() {
        settings.onboardingCompleted = true
        withAnimation {
            showOnboarding = false
        }
    }
}
