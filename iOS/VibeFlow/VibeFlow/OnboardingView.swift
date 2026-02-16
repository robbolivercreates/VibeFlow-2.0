import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentPage = 0
    @State private var apiKey = ""
    @State private var isValidating = false
    @State private var keyError: String?

    private var pages: [OnboardingPage] {
        [
            OnboardingPage(
                icon: "waveform.circle.fill",
                title: L10n.onboardingTitle1,
                description: L10n.onboardingDesc1,
                color: .orange
            ),
            OnboardingPage(
                icon: "keyboard.fill",
                title: L10n.onboardingTitle2,
                description: L10n.onboardingDesc2,
                color: .blue
            ),
            OnboardingPage(
                icon: "sparkles",
                title: L10n.onboardingTitle3,
                description: L10n.onboardingDesc3,
                color: .purple
            )
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            // Page content
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    pageView(pages[index])
                        .tag(index)
                }

                // API Key page
                apiKeyPageView
                    .tag(pages.count)

                // Setup complete page
                setupCompleteView
                    .tag(pages.count + 1)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentPage)

            // Page indicator and buttons
            VStack(spacing: 20) {
                // Page dots
                HStack(spacing: 8) {
                    ForEach(0..<pages.count + 2, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Color.orange : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }

                // Navigation buttons
                HStack(spacing: 16) {
                    if currentPage > 0 && currentPage < pages.count + 1 {
                        Button(L10n.back) {
                            withAnimation {
                                currentPage -= 1
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .foregroundStyle(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Button(nextButtonTitle) {
                        handleNextButton()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(nextButtonEnabled ? Color.orange : Color.gray)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .disabled(!nextButtonEnabled || isValidating)
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 40)
        }
        .background(Color(.systemBackground))
    }

    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: page.icon)
                .font(.system(size: 80))
                .foregroundStyle(page.color)

            Text(page.title)
                .font(.title.bold())

            Text(page.description)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
            Spacer()
        }
    }

    private var apiKeyPageView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "key.fill")
                .font(.system(size: 60))
                .foregroundStyle(.orange)

            Text(L10n.addApiKey)
                .font(.title.bold())

            Text(L10n.apiKeyDesc)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            VStack(spacing: 12) {
                SecureField(L10n.apiKeyPlaceholder, text: $apiKey)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal, 40)

                if let error = keyError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Link(destination: URL(string: "https://aistudio.google.com/app/apikey")!) {
                    HStack {
                        Text(L10n.getApiKey)
                        Image(systemName: "arrow.up.right.square")
                    }
                    .font(.subheadline)
                }
            }

            if isValidating {
                ProgressView(L10n.validating)
            }

            Spacer()
            Spacer()
        }
    }

    private var setupCompleteView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)

            Text(L10n.allSet)
                .font(.title.bold())

            VStack(alignment: .leading, spacing: 16) {
                SetupStep(number: 1, text: L10n.setupStep1)
                SetupStep(number: 2, text: L10n.setupStep2)
                SetupStep(number: 3, text: L10n.setupStep3)
                SetupStep(number: 4, text: L10n.setupStep4)
            }
            .padding(.horizontal, 40)

            Text(L10n.setupComplete)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
            Spacer()
        }
    }

    private var nextButtonTitle: String {
        switch currentPage {
        case pages.count:
            return isValidating ? L10n.validating : L10n.validateContinue
        case pages.count + 1:
            return L10n.getStarted
        default:
            return L10n.next
        }
    }

    private var nextButtonEnabled: Bool {
        if currentPage == pages.count {
            return !apiKey.isEmpty && !isValidating
        }
        return true
    }

    private func handleNextButton() {
        if currentPage == pages.count {
            // Validate API key
            validateAPIKey()
        } else if currentPage == pages.count + 1 {
            // Complete onboarding
            appState.completeOnboarding()
        } else {
            withAnimation {
                currentPage += 1
            }
        }
    }

    private func validateAPIKey() {
        isValidating = true
        keyError = nil

        Task {
            let isValid = await GeminiService.shared.validateAPIKey(apiKey)

            await MainActor.run {
                isValidating = false

                if isValid {
                    SharedSettings.shared.apiKey = apiKey
                    withAnimation {
                        currentPage += 1
                    }
                } else {
                    keyError = L10n.invalidApiKey
                }
            }
        }
    }
}

struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

struct SetupStep: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Text("\(number)")
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(.orange)
                .clipShape(Circle())

            Text(text)
                .font(.subheadline)
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState())
}
