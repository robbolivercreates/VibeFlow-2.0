import SwiftUI

struct AccountView: View {
    @StateObject private var auth = AuthManager.shared
    @StateObject private var subscription = SubscriptionManager.shared
    @StateObject private var trial = TrialManager.shared
    @State private var isVerifyingPurchase = false
    @State private var verifyMessage: String?

    /// Easter egg: callback when version is tapped
    var onVersionTap: (() -> Void)?
    /// Easter egg: current tap count (0-4) for visual feedback
    var versionTapCount: Int = 0

    var body: some View {
        Form {
            if auth.isAuthenticated {
                authenticatedContent
            } else {
                LoginView()
            }
        }
    }

    // MARK: - Authenticated Content

    private var authenticatedContent: some View {
        Group {
            // User Info
            Section(L10n.account) {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(VoxTheme.accent)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(auth.userEmail ?? "")
                            .font(.system(size: 14, weight: .medium))

                        HStack(spacing: 6) {
                            Text(subscription.isPro ? "PRO" : "FREE")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(subscription.isPro ? VoxTheme.accent : Color.gray)
                                .cornerRadius(4)

                            if let status = subscription.subscriptionStatus {
                                Text(status.capitalized)
                                    .font(.system(size: 11))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    Spacer()
                }
            }

            // Usage (free/trial users only)
            if !subscription.isPro {
                Section(L10n.usageThisMonth) {
                    VStack(alignment: .leading, spacing: 8) {
                        // Trial info
                        if trial.isTrialActive() {
                            HStack {
                                Image(systemName: "sparkles")
                                    .foregroundStyle(VoxTheme.accent)
                                Text("Trial Pro")
                                    .font(.system(size: 13, weight: .semibold))
                                Spacer()
                                Text("\(trial.trialDaysRemaining) \(trial.trialDaysRemaining == 1 ? L10n.dayRemaining : L10n.daysRemaining)")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(VoxTheme.accent)
                            }

                            HStack {
                                Text(L10n.trialTranscriptions)
                                    .font(.system(size: 13))
                                Spacer()
                                Text("\(trial.trialTranscriptionsUsed) / \(TrialManager.trialTranscriptionLimit)")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(trial.hasReachedTrialLimit ? .red : .primary)
                            }

                            ProgressView(
                                value: Double(trial.trialTranscriptionsUsed),
                                total: Double(TrialManager.trialTranscriptionLimit)
                            )
                            .tint(trial.hasReachedTrialLimit ? .red : VoxTheme.accent)
                        }

                        // Free tier usage (200/month)
                        HStack {
                            Text(L10n.transcriptionsUsed)
                                .font(.system(size: 13))
                            Spacer()
                            Text("\(subscription.whisperTranscriptionsUsed) / \(SubscriptionManager.whisperMonthlyLimit)")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(subscription.hasReachedWhisperLimit ? .red : .primary)
                        }

                        ProgressView(
                            value: Double(subscription.whisperTranscriptionsUsed),
                            total: Double(SubscriptionManager.whisperMonthlyLimit)
                        )
                        .tint(subscription.hasReachedWhisperLimit ? .red : VoxTheme.accent)

                        if subscription.hasReachedWhisperLimit {
                            Text(L10n.freeLimitReached)
                                .font(.system(size: 12))
                                .foregroundStyle(.red)
                        } else {
                            Text("\(subscription.whisperTranscriptionsRemaining) \(L10n.remaining)")
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            // Upgrade (free users only)
            if !subscription.isPro {
                Section(L10n.upgradeToPro) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "crown.fill")
                                .foregroundStyle(VoxTheme.accent)
                            Text(L10n.proFeatures)
                                .font(.system(size: 14, weight: .medium))
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            ProFeatureRow(text: L10n.unlimitedTranscriptions)
                            ProFeatureRow(text: L10n.allFiveModes)
                            ProFeatureRow(text: L10n.fifteenPlusLanguages)
                        }

                        HStack(spacing: 12) {
                            Button(action: { subscription.openUpgradeURL(annual: false) }) {
                                VStack(spacing: 2) {
                                    Text("R$29,90/\(L10n.month)")
                                        .font(.system(size: 13, weight: .semibold))
                                    Text(L10n.monthly)
                                        .font(.system(size: 10))
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.bordered)

                            Button(action: { subscription.openUpgradeURL(annual: true) }) {
                                VStack(spacing: 2) {
                                    Text("R$268,80/\(L10n.year)")
                                        .font(.system(size: 13, weight: .semibold))
                                    Text(L10n.annual + " (-25%)")
                                        .font(.system(size: 10))
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(VoxTheme.accent)
                        }
                    }
                }
            }

            // Verify Purchase
            Section {
                Button(action: verifyPurchase) {
                    HStack(spacing: 8) {
                        if isVerifyingPurchase {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "checkmark.shield")
                        }
                        Text(L10n.verifyPurchase)
                    }
                }
                .disabled(isVerifyingPurchase)

                if let message = verifyMessage {
                    Text(message)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }

            // About
            Section(L10n.about) {
                HStack {
                    Text(L10n.model)
                    Spacer()
                    Text("Vox AI Engine")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text(L10n.version)
                    Spacer()
                    if versionTapCount > 0 {
                        // Show progress dots while counting taps
                        HStack(spacing: 4) {
                            ForEach(0..<5, id: \.self) { i in
                                Circle()
                                    .fill(i < versionTapCount ? Color.orange : Color.gray.opacity(0.3))
                                    .frame(width: 5, height: 5)
                            }
                        }
                        .animation(.easeInOut(duration: 0.15), value: versionTapCount)
                    } else {
                        Text(AppVersion.current)
                            .foregroundStyle(.secondary)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    onVersionTap?()
                }
            }

            // Logout — signs out and quits the app
            Section {
                Button(action: {
                    auth.signOut()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        NSApplication.shared.terminate(nil)
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text(L10n.logout)
                    }
                    .foregroundStyle(.red)
                }
            }
        }
    }

    private func verifyPurchase() {
        isVerifyingPurchase = true
        verifyMessage = nil

        Task {
            let result = await subscription.verifyPurchase()
            await MainActor.run {
                isVerifyingPurchase = false
                if let result = result {
                    verifyMessage = result.message
                } else {
                    verifyMessage = L10n.verifyPurchaseFailed
                }
            }
        }
    }
}

struct ProFeatureRow: View {
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12))
                .foregroundStyle(VoxTheme.accent)
            Text(text)
                .font(.system(size: 12))
        }
    }
}

// MARK: - Localization Extensions

extension L10n {
    static var account: String { t("Account", "Conta", "Cuenta") }
    static var usageThisMonth: String { t("Usage This Month", "Uso Este Mes", "Uso Este Mes") }
    static var transcriptionsUsed: String { t("Transcriptions used", "Transcricoes usadas", "Transcripciones usadas") }
    static var remaining: String { t("remaining", "restantes", "restantes") }
    static var freeLimitReached: String { t("Free limit reached. Upgrade to Pro for AI features!", "Limite gratuito atingido. Faca upgrade para desbloquear I.A.!", "Limite gratuito alcanzado. Actualiza para desbloquear I.A.!") }
    static var upgradeToPro: String { t("Upgrade to Pro", "Fazer Upgrade para Pro", "Actualizar a Pro") }
    static var proFeatures: String { t("Agente Vox + Pro Features", "Agente Vox + Recursos Pro", "Agente Vox + Funciones Pro") }
    static var unlimitedTranscriptions: String { t("Unlimited transcriptions + AI features", "Transcricoes ilimitadas + funcionalidades de I.A.", "Transcripciones ilimitadas + funciones de I.A.") }
    static var allFiveModes: String { t("All 15 AI modes (Vibe Coder, Email, Meeting...)", "Todos os 15 modos com I.A. (Vibe Coder, Email, Reuniao...)", "Los 15 modos con I.A. (Vibe Coder, Email, Reunion...)") }
    static var fifteenPlusLanguages: String { t("30 languages", "30 idiomas", "30 idiomas") }
    static var monthly: String { t("Monthly", "Mensal", "Mensual") }
    static var annual: String { t("Annual", "Anual", "Anual") }
    static var month: String { t("month", "mes", "mes") }
    static var year: String { t("year", "ano", "ano") }
    static var verifyPurchase: String { t("Verify Purchase", "Verificar Compra", "Verificar Compra") }
    static var verifyPurchaseFailed: String { t("Could not verify purchase. Try again later.", "Nao foi possivel verificar a compra. Tente novamente.", "No se pudo verificar la compra. Intenta de nuevo.") }
    static var logout: String { t("Log Out", "Sair", "Cerrar Sesion") }
    static var dayRemaining: String { t("day remaining", "dia restante", "dia restante") }
    static var daysRemaining: String { t("days remaining", "dias restantes", "dias restantes") }
    static var trialTranscriptions: String { t("Trial transcriptions", "Transcricoes trial", "Transcripciones trial") }
}
