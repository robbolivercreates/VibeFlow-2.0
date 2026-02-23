import SwiftUI

// MARK: - App Logo Header (reusable across all paywalls)

private struct AppLogoHeader: View {
    var body: some View {
        Image(nsImage: NSApp.applicationIconImage)
            .resizable()
            .interpolation(.high)
            .frame(width: 72, height: 72)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
    }
}

// MARK: - Pricing Toggle (annual/monthly with checkout)

private struct PricingToggle: View {
    @Binding var isAnnual: Bool
    let onSubscribe: (Bool) -> Void
    let onDismiss: () -> Void
    var dismissLabel: String = L10n.trialExpiredContinueFree

    var body: some View {
        VStack(spacing: 14) {
            // Toggle
            HStack(spacing: 0) {
                toggleButton(title: L10n.pricingMonthly, isSelected: !isAnnual) {
                    isAnnual = false
                }
                toggleButton(title: L10n.pricingAnnual, isSelected: isAnnual, badge: "-25%") {
                    isAnnual = true
                }
            }
            .background(Color.gray.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Price display
            VStack(spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(isAnnual ? "R$14,90" : "R$19,90")
                        .font(.system(size: 36, weight: .bold))
                    Text("/\(L10n.month)")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
                if isAnnual {
                    HStack(spacing: 4) {
                        Text("R$19,90")
                            .font(.system(size: 12))
                            .strikethrough()
                            .foregroundStyle(.secondary)
                        Text(L10n.pricingAnnualBilled)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Subscribe button
            Button(action: { onSubscribe(isAnnual) }) {
                HStack {
                    Image(systemName: "diamond.fill")
                    Text(isAnnual ? L10n.pricingSubscribeAnnual : L10n.pricingSubscribeMonthly)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(VoxTheme.goldGradient)
                .foregroundStyle(.white)
                .cornerRadius(10)
            }
            .buttonStyle(.borderless)

            // Dismiss
            Button(dismissLabel) { onDismiss() }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
                .font(.system(size: 13))
        }
    }

    private func toggleButton(title: String, isSelected: Bool, badge: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                if let badge = badge {
                    Text(badge)
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(VoxTheme.accent.opacity(0.2))
                        .foregroundStyle(VoxTheme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? Color.white.opacity(0.1) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.borderless)
    }
}

// MARK: - Welcome Trial View (shown right after signup — trial already started)

struct WelcomeTrialView: View {
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header with app logo
            VStack(spacing: 12) {
                AppLogoHeader()

                Text(L10n.welcomeTrialTitle)
                    .font(.system(size: 22, weight: .bold))

                Text(L10n.welcomeTrialSubtitle)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 28)
            .padding(.horizontal, 32)

            // What you get
            VStack(alignment: .leading, spacing: 10) {
                Text(L10n.welcomeTrialWhatYouGet)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(VoxTheme.accent)

                TrialFeatureRow(icon: "sparkles", text: L10n.welcomeTrialGemini)
                TrialFeatureRow(icon: "waveform.and.mic", text: L10n.welcomeTrialAllModes)
                TrialFeatureRow(icon: "globe", text: L10n.welcomeTrialAllLanguages)
                TrialFeatureRow(icon: "text.badge.checkmark", text: L10n.welcomeTrialSmartFormatting)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(VoxTheme.accentMuted)
            )
            .padding(.horizontal, 24)
            .padding(.top, 20)

            // Trial details
            VStack(spacing: 4) {
                Text(L10n.welcomeTrialDuration)
                    .font(.system(size: 14, weight: .medium))
                Text(L10n.welcomeTrialLimit)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 16)

            // After trial info
            VStack(spacing: 4) {
                Text(L10n.welcomeTrialAfter)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 8)

            // Button
            VStack(spacing: 10) {
                Button(action: { isPresented = false }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text(L10n.welcomeTrialStartButton)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(VoxTheme.goldGradient)
                    .foregroundStyle(.white)
                    .cornerRadius(10)
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 28)
        }
        .frame(width: 400)
        .background(VoxTheme.background)
    }
}

// MARK: - Trial Expired View (shown when 7-day trial ends or 50 limit reached)

struct TrialExpiredView: View {
    @Binding var isPresented: Bool
    @State private var isAnnual = true

    private var reason: ExpiryReason {
        if TrialManager.shared.hasReachedTrialLimit {
            return .limitReached
        }
        return .timeExpired
    }

    enum ExpiryReason {
        case timeExpired
        case limitReached
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with app logo
            VStack(spacing: 12) {
                AppLogoHeader()

                Text(L10n.trialExpiredTitle)
                    .font(.system(size: 22, weight: .bold))

                Text(reason == .timeExpired ? L10n.trialExpiredSubtitleTime : L10n.trialExpiredSubtitleLimit)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 28)
            .padding(.horizontal, 32)

            // What changes
            VStack(alignment: .leading, spacing: 10) {
                Text(L10n.trialExpiredWhatChanges)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.orange)

                TrialChangeRow(icon: "arrow.down.circle", text: L10n.trialExpiredDowngradeEngine, isDowngrade: true)
                TrialChangeRow(icon: "text.alignleft", text: L10n.trialExpiredDowngradeMode, isDowngrade: true)
                TrialChangeRow(icon: "globe", text: L10n.trialExpiredDowngradeLanguages, isDowngrade: true)
                TrialChangeRow(icon: "checkmark.circle", text: L10n.trialExpiredKeepTranscriptions, isDowngrade: false)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.orange.opacity(0.08))
            )
            .padding(.horizontal, 24)
            .padding(.top, 20)

            // Pricing toggle + subscribe
            VStack(spacing: 8) {
                Text(L10n.trialExpiredKeepPro)
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(.top, 20)

            PricingToggle(
                isAnnual: $isAnnual,
                onSubscribe: { annual in
                    SubscriptionManager.shared.openUpgradeURL(annual: annual)
                    TrialManager.shared.forceExpireTrial()
                    isPresented = false
                },
                onDismiss: {
                    TrialManager.shared.forceExpireTrial()
                    isPresented = false
                },
                dismissLabel: L10n.trialExpiredContinueFree
            )
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .frame(width: 420)
        .background(VoxTheme.background)
    }
}

// MARK: - Monthly Limit View (shown when 200 free limit reached — LOCKED)

struct MonthlyLimitView: View {
    @Binding var isPresented: Bool
    @State private var isAnnual = true

    var body: some View {
        VStack(spacing: 0) {
            // Header with app logo
            VStack(spacing: 12) {
                ZStack {
                    AppLogoHeader()
                    // Lock badge
                    Image(systemName: "lock.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(5)
                        .background(Circle().fill(Color.red))
                        .offset(x: 28, y: 28)
                }

                Text(L10n.monthlyLimitTitle)
                    .font(.system(size: 22, weight: .bold))

                Text(L10n.monthlyLimitSubtitle)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 28)
            .padding(.horizontal, 32)

            // What you can do
            VStack(alignment: .leading, spacing: 10) {
                Text(L10n.monthlyLimitOptions)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(VoxTheme.accent)

                TrialFeatureRow(icon: "clock.arrow.circlepath", text: L10n.monthlyLimitWaitReset)
                TrialFeatureRow(icon: "diamond.fill", text: L10n.monthlyLimitUpgradePro)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.red.opacity(0.06))
            )
            .padding(.horizontal, 24)
            .padding(.top, 20)

            // Pricing toggle + subscribe
            VStack(spacing: 8) {
                Text(L10n.monthlyLimitUnlock)
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(.top, 20)

            PricingToggle(
                isAnnual: $isAnnual,
                onSubscribe: { annual in
                    SubscriptionManager.shared.openUpgradeURL(annual: annual)
                    isPresented = false
                },
                onDismiss: { isPresented = false },
                dismissLabel: L10n.monthlyLimitDismiss
            )
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .frame(width: 420)
        .background(VoxTheme.background)
    }
}

// MARK: - Upgrade Reminder (soft — shown every 25 transcriptions)

struct UpgradeReminderView: View {
    @Binding var isPresented: Bool
    @State private var isAnnual = true

    private var used: Int { SubscriptionManager.shared.whisperTranscriptionsUsed }
    private var remaining: Int { SubscriptionManager.shared.whisperTranscriptionsRemaining }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                AppLogoHeader()

                Text(L10n.upgradeReminderTitle)
                    .font(.system(size: 20, weight: .bold))

                Text(L10n.upgradeReminderSubtitle(used: used, remaining: remaining))
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 24)
            .padding(.horizontal, 28)

            // Progress bar
            VStack(spacing: 6) {
                ProgressView(
                    value: Double(used),
                    total: Double(SubscriptionManager.whisperMonthlyLimit)
                )
                .tint(VoxTheme.accent)

                HStack {
                    Text("\(used)/\(SubscriptionManager.whisperMonthlyLimit)")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(L10n.upgradeReminderFreeForever)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 16)

            // Pro highlights
            VStack(alignment: .leading, spacing: 8) {
                TrialFeatureRow(icon: "infinity", text: L10n.upgradeReminderUnlimited)
                TrialFeatureRow(icon: "sparkles", text: L10n.upgradeReminderGemini)
                TrialFeatureRow(icon: "waveform.and.mic", text: L10n.upgradeReminderAllModes)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(VoxTheme.accentMuted)
            )
            .padding(.horizontal, 24)
            .padding(.top, 16)

            // Pricing toggle
            PricingToggle(
                isAnnual: $isAnnual,
                onSubscribe: { annual in
                    SubscriptionManager.shared.openUpgradeURL(annual: annual)
                    isPresented = false
                },
                onDismiss: { isPresented = false },
                dismissLabel: L10n.upgradeReminderDismiss
            )
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .frame(width: 400)
        .background(VoxTheme.background)
    }
}

// MARK: - Helper Views

private struct TrialFeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(VoxTheme.accent)
                .frame(width: 20)
            Text(text)
                .font(.system(size: 13))
        }
    }
}

private struct TrialChangeRow: View {
    let icon: String
    let text: String
    let isDowngrade: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(isDowngrade ? .orange : VoxTheme.success)
                .frame(width: 20)
            Text(text)
                .font(.system(size: 13))
        }
    }
}

// MARK: - Localization

extension L10n {
    // Pricing toggle (shared)
    static var pricingMonthly: String { t("Monthly", "Mensal", "Mensual") }
    static var pricingAnnual: String { t("Annual", "Anual", "Anual") }
    static var pricingAnnualBilled: String { t("R$178.80 billed yearly", "R$178,80 cobrado anualmente", "R$178,80 cobrado anualmente") }
    static var pricingSubscribeMonthly: String { t("Subscribe — R$19.90/month", "Assinar — R$19,90/mes", "Suscribir — R$19,90/mes") }
    static var pricingSubscribeAnnual: String { t("Subscribe — R$14.90/month", "Assinar — R$14,90/mes", "Suscribir — R$14,90/mes") }

    // Welcome Trial (shown after signup — trial already active)
    static var welcomeTrialTitle: String { t("Your Pro Trial is Active!", "Seu Trial Pro Esta Ativo!", "Tu Prueba Pro Esta Activa!") }
    static var welcomeTrialSubtitle: String { t(
        "Welcome to VoxAiGo! You have 7 free days\nto explore the Agente Vox inteligente and all Pro features.",
        "Bem-vindo ao VoxAiGo! Voce tem 7 dias gratis\npara experimentar o Agente Vox inteligente e todos os recursos Pro.",
        "Bienvenido a VoxAiGo! Tienes 7 dias gratis\npara probar el Agente Vox inteligente y todas las funciones Pro."
    ) }
    static var welcomeTrialWhatYouGet: String { t("What's included in your trial:", "O que esta incluido no seu trial:", "Lo que incluye tu prueba:") }
    static var welcomeTrialGemini: String { t("Agente Vox — intelligent formatting and filler removal", "Agente Vox — formatacao inteligente e remocao de fillers", "Agente Vox — formato inteligente y eliminacion de muletillas") }
    static var welcomeTrialAllModes: String { t("All 15 AI modes (Vibe Coder, Email, Meeting...)", "Todos os 15 modos com I.A. (Vibe Coder, Email, Reuniao...)", "Los 15 modos con I.A. (Vibe Coder, Email, Reunion...)") }
    static var welcomeTrialAllLanguages: String { t("30 languages available", "30 idiomas disponiveis", "30 idiomas disponibles") }
    static var welcomeTrialSmartFormatting: String { t("AI-powered text cleanup and restructuring", "Limpeza e reestruturacao do texto com I.A.", "Limpieza y reestructuracion del texto con I.A.") }
    static var welcomeTrialDuration: String { t("7 days free — no credit card needed", "7 dias gratis — sem cartao de credito", "7 dias gratis — sin tarjeta de credito") }
    static var welcomeTrialLimit: String { t("Up to 50 AI transcriptions during trial", "Ate 50 transcricoes com I.A. durante o trial", "Hasta 50 transcripciones con I.A. durante la prueba") }
    static var welcomeTrialAfter: String { t(
        "After the trial, you keep Text mode with 200 free transcriptions/month.\nAI features require Pro.",
        "Apos o trial, voce mantem o modo Texto com 200 transcricoes gratis/mes.\nFuncionalidades de I.A. requerem Pro.",
        "Despues de la prueba, mantendras el modo Texto con 200 transcripciones gratis/mes.\nFunciones de I.A. requieren Pro."
    ) }
    static var welcomeTrialStartButton: String { t("Got it, let's go!", "Entendi, vamos la!", "Entendido, vamos!") }

    // Trial Expired
    static var trialExpiredTitle: String { t("Your Pro Trial Has Ended", "Seu Trial Pro Acabou", "Tu Prueba Pro Termino") }
    static var trialExpiredSubtitleTime: String { t(
        "Your 7-day Pro trial has expired.\nYou lose access to AI features. Text mode stays free.",
        "Seu trial Pro de 7 dias expirou.\nVoce perde acesso as funcionalidades de I.A. O modo Texto continua gratis.",
        "Tu prueba Pro de 7 dias expiro.\nPierdes acceso a las funciones de I.A. El modo Texto sigue gratis."
    ) }
    static var trialExpiredSubtitleLimit: String { t(
        "You've used all 50 trial transcriptions.\nAI features are now locked. Text mode stays free.",
        "Voce usou todas as 50 transcricoes do trial.\nFuncionalidades de I.A. bloqueadas. Modo Texto continua gratis.",
        "Usaste las 50 transcripciones de prueba.\nFunciones de I.A. bloqueadas. Modo Texto sigue gratis."
    ) }
    static var trialExpiredWhatChanges: String { t("What changes now:", "O que muda agora:", "Lo que cambia ahora:") }
    static var trialExpiredDowngradeEngine: String { t("No AI — basic transcription only", "Sem I.A. — apenas transcricao basica", "Sin I.A. — solo transcripcion basica") }
    static var trialExpiredDowngradeMode: String { t("Text mode only (no Agente Vox)", "Somente modo Texto (sem Agente Vox)", "Solo modo Texto (sin Agente Vox)") }
    static var trialExpiredDowngradeLanguages: String { t("Portuguese and English only", "Somente Portugues e Ingles", "Solo Portugues e Ingles") }
    static var trialExpiredKeepTranscriptions: String { t("200 transcriptions/month — always free", "200 transcricoes/mes — sempre gratis", "200 transcripciones/mes — siempre gratis") }
    static var trialExpiredKeepPro: String { t("Want to keep AI features?", "Quer manter as funcionalidades de I.A.?", "Quieres mantener las funciones de I.A.?") }
    static var trialExpiredContinueFree: String { t("Continue without AI (Free plan)", "Continuar sem I.A. (plano Gratuito)", "Continuar sin I.A. (plan Gratuito)") }

    // Monthly Limit (200 free exhausted — LOCKED)
    static var monthlyLimitTitle: String { t("Monthly Limit Reached", "Limite Mensal Atingido", "Limite Mensual Alcanzado") }
    static var monthlyLimitSubtitle: String { t(
        "You've used all 200 free transcriptions this month.\nTranscriptions are locked until next month.",
        "Voce usou todas as 200 transcricoes gratis deste mes.\nTranscricoes bloqueadas ate o proximo mes.",
        "Usaste las 200 transcripciones gratis de este mes.\nTranscripciones bloqueadas hasta el proximo mes."
    ) }
    static var monthlyLimitOptions: String { t("Your options:", "Suas opcoes:", "Tus opciones:") }
    static var monthlyLimitWaitReset: String { t("Wait for monthly reset (free)", "Aguardar reset mensal (gratis)", "Esperar el reinicio mensual (gratis)") }
    static var monthlyLimitUpgradePro: String { t("Upgrade to Pro — unlimited + AI features", "Assinar Pro — ilimitado + funcionalidades de I.A.", "Suscribir Pro — ilimitado + funciones de I.A.") }
    static var monthlyLimitUnlock: String { t("Unlock Agente Vox + unlimited access", "Desbloqueie o Agente Vox + acesso ilimitado", "Desbloquea el Agente Vox + acceso ilimitado") }
    static var monthlyLimitDismiss: String { t("I'll wait", "Vou aguardar", "Voy a esperar") }

    // Upgrade Reminder (soft, every 25 transcriptions)
    static var upgradeReminderTitle: String { t("You're doing great!", "Voce esta arrasando!", "Lo estas haciendo genial!") }
    static func upgradeReminderSubtitle(used: Int, remaining: Int) -> String {
        t(
            "You've used \(used) of your 200 free transcriptions.\n\(remaining) remaining this month — you can keep going!",
            "Voce usou \(used) de 200 transcricoes gratis.\n\(remaining) restantes este mes — pode continuar!",
            "Usaste \(used) de 200 transcripciones gratis.\n\(remaining) restantes este mes — puedes continuar!"
        )
    }
    static var upgradeReminderFreeForever: String { t("200/month — Text mode only, always free", "200/mes — apenas modo Texto, sempre gratis", "200/mes — solo modo Texto, siempre gratis") }
    static var upgradeReminderUnlimited: String { t("Unlimited transcriptions + AI features", "Transcricoes ilimitadas + funcionalidades de I.A.", "Transcripciones ilimitadas + funciones de I.A.") }
    static var upgradeReminderGemini: String { t("Agente Vox — intelligent formatting", "Agente Vox — formatacao inteligente", "Agente Vox — formato inteligente") }
    static var upgradeReminderAllModes: String { t("All 15 AI modes + 30 languages", "Todos os 15 modos com I.A. + 30 idiomas", "Los 15 modos con I.A. + 30 idiomas") }
    static var upgradeReminderDismiss: String { t("No thanks, continue without AI", "Nao, continuar sem I.A.", "No, continuar sin I.A.") }
}
