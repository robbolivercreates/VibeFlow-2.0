import SwiftUI

struct AccountView: View {
    @StateObject private var auth = AuthManager.shared
    @StateObject private var subscription = SubscriptionManager.shared
    @State private var isVerifyingPurchase = false
    @State private var verifyMessage: String?

    /// Easter egg: callback when version is tapped
    var onVersionTap: (() -> Void)?

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
                        .foregroundStyle(.purple)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(auth.userEmail ?? "")
                            .font(.system(size: 14, weight: .medium))

                        HStack(spacing: 6) {
                            Text(subscription.isPro ? "PRO" : "FREE")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(subscription.isPro ? Color.purple : Color.gray)
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

            // Usage (free users only)
            if !subscription.isPro {
                Section(L10n.usageThisMonth) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(L10n.transcriptionsUsed)
                                .font(.system(size: 13))
                            Spacer()
                            Text("\(subscription.freeTranscriptionsUsed) / \(SubscriptionManager.freeMonthlyLimit)")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(subscription.hasReachedFreeLimit ? .red : .primary)
                        }

                        ProgressView(
                            value: Double(subscription.freeTranscriptionsUsed),
                            total: Double(SubscriptionManager.freeMonthlyLimit)
                        )
                        .tint(subscription.hasReachedFreeLimit ? .red : .purple)

                        if subscription.hasReachedFreeLimit {
                            Text(L10n.freeLimitReached)
                                .font(.system(size: 12))
                                .foregroundStyle(.red)
                        } else {
                            Text("\(subscription.freeTranscriptionsRemaining) \(L10n.remaining)")
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
                                .foregroundStyle(.yellow)
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
                                    Text("R$19,90/\(L10n.month)")
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
                                    Text("R$178,80/\(L10n.year)")
                                        .font(.system(size: 13, weight: .semibold))
                                    Text(L10n.annual + " (-25%)")
                                        .font(.system(size: 10))
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.purple)
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
                    Text("Gemini 2.5 Flash")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text(L10n.version)
                    Spacer()
                    Text(AppVersion.current)
                        .foregroundStyle(.secondary)
                }
                .onTapGesture {
                    onVersionTap?()
                }
            }

            // Logout
            Section {
                Button(action: { auth.signOut() }) {
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
                .foregroundStyle(.green)
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
    static var freeLimitReached: String { t("Free limit reached. Upgrade to Pro for unlimited!", "Limite gratuito atingido. Faca upgrade para Pro!", "Limite gratuito alcanzado. Actualiza a Pro!") }
    static var upgradeToPro: String { t("Upgrade to Pro", "Fazer Upgrade para Pro", "Actualizar a Pro") }
    static var proFeatures: String { t("Pro Features", "Recursos Pro", "Funciones Pro") }
    static var unlimitedTranscriptions: String { t("Unlimited transcriptions", "Transcricoes ilimitadas", "Transcripciones ilimitadas") }
    static var allFiveModes: String { t("All 5 modes (Code, Text, Email, UX, Command)", "Todos os 5 modos (Code, Text, Email, UX, Command)", "Los 5 modos (Code, Text, Email, UX, Command)") }
    static var fifteenPlusLanguages: String { t("15+ languages", "15+ idiomas", "15+ idiomas") }
    static var monthly: String { t("Monthly", "Mensal", "Mensual") }
    static var annual: String { t("Annual", "Anual", "Anual") }
    static var month: String { t("month", "mes", "mes") }
    static var year: String { t("year", "ano", "ano") }
    static var verifyPurchase: String { t("Verify Purchase", "Verificar Compra", "Verificar Compra") }
    static var verifyPurchaseFailed: String { t("Could not verify purchase. Try again later.", "Nao foi possivel verificar a compra. Tente novamente.", "No se pudo verificar la compra. Intenta de nuevo.") }
    static var logout: String { t("Log Out", "Sair", "Cerrar Sesion") }
}
