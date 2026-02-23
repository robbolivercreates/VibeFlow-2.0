import SwiftUI

// MARK: - Auth View Enum

private enum AuthView {
    case signIn, signUp, resetPassword
}

private enum SignInMethod {
    case password, magicLink
}

// MARK: - LoginView

struct LoginView: View {
    @StateObject private var auth = AuthManager.shared
    @State private var view: AuthView = .signIn
    @State private var signInMethod: SignInMethod = .password

    // Form fields
    @State private var email = ""
    @State private var password = ""
    @State private var firstName = ""
    @State private var lastName = ""

    // State
    @State private var errorMessage: String?
    @State private var successMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            // Logo
            VStack(spacing: 6) {
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(VoxTheme.goldGradient)
                Text("VoxAiGo")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(VoxTheme.textPrimary)
            }
            .padding(.bottom, 24)

            // Card
            VStack(spacing: 16) {
                switch view {
                case .signIn:
                    signInView
                case .signUp:
                    signUpView
                case .resetPassword:
                    resetPasswordView
                }
            }
            .padding(24)
            .background(VoxTheme.surface)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(VoxTheme.surfaceBorder, lineWidth: 1)
            )
        }
        .padding(24)
        .frame(maxWidth: 400)
    }

    // MARK: - Sign In View

    @ViewBuilder
    private var signInView: some View {
        // Header
        VStack(spacing: 4) {
            Text(L10n.welcomeBack)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(VoxTheme.textPrimary)
            Text(L10n.signInToContinue)
                .font(.system(size: 13))
                .foregroundStyle(VoxTheme.textSecondary)
        }

        // Google
        googleButton(label: L10n.signInWithGoogle)

        divider

        // Password / Magic Link tabs
        HStack(spacing: 0) {
            tabButton(L10n.passwordTab, isSelected: signInMethod == .password) {
                signInMethod = .password
            }
            tabButton(L10n.magicLinkTab, isSelected: signInMethod == .magicLink) {
                signInMethod = .magicLink
            }
        }
        .padding(3)
        .background(VoxTheme.background)
        .cornerRadius(8)

        if signInMethod == .password {
            // Email
            fieldLabel("Email")
            emailField

            // Password + Forgot
            HStack {
                fieldLabel(L10n.password)
                Spacer()
                Button(L10n.forgotPassword) {
                    switchView(.resetPassword)
                }
                .font(.system(size: 12))
                .foregroundStyle(VoxTheme.accent)
                .buttonStyle(.plain)
            }
            passwordField

            statusMessages

            submitButton(label: L10n.signIn, loadingLabel: L10n.signingIn) {
                await handleSignIn()
            }
        } else {
            // Magic Link - email only
            fieldLabel("Email")
            emailField

            statusMessages

            submitButton(label: L10n.sendMagicLink, loadingLabel: L10n.sending, icon: "envelope.fill") {
                await handleMagicLink()
            }
        }

        // Switch to Sign Up
        HStack(spacing: 4) {
            Text(L10n.dontHaveAccount)
                .font(.system(size: 13))
                .foregroundStyle(VoxTheme.textSecondary)
            Button(L10n.signUpAction) {
                switchView(.signUp)
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(VoxTheme.accent)
            .buttonStyle(.plain)
        }
    }

    // MARK: - Sign Up View

    @ViewBuilder
    private var signUpView: some View {
        // Header
        VStack(spacing: 4) {
            Text(L10n.createAccount)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(VoxTheme.textPrimary)
            Text(L10n.startDictating5x)
                .font(.system(size: 13))
                .foregroundStyle(VoxTheme.textSecondary)
        }

        // Google
        googleButton(label: L10n.signUpWithGoogle)

        divider

        // Name fields side by side
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                fieldLabel(L10n.firstNameLabel)
                TextField("John", text: $firstName)
                    .textFieldStyle(.roundedBorder)
            }
            VStack(alignment: .leading, spacing: 4) {
                fieldLabel(L10n.lastNameLabel)
                TextField("Doe", text: $lastName)
                    .textFieldStyle(.roundedBorder)
            }
        }

        // Email
        fieldLabel("Email")
        emailField

        // Password
        fieldLabel(L10n.password)
        passwordField

        statusMessages

        submitButton(label: L10n.createAccountAction, loadingLabel: L10n.creating) {
            await handleSignUp()
        }

        // Switch to Sign In
        HStack(spacing: 4) {
            Text(L10n.alreadyHaveAccountShort)
                .font(.system(size: 13))
                .foregroundStyle(VoxTheme.textSecondary)
            Button(L10n.signInAction) {
                switchView(.signIn)
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(VoxTheme.accent)
            .buttonStyle(.plain)
        }
    }

    // MARK: - Reset Password View

    @ViewBuilder
    private var resetPasswordView: some View {
        // Header
        VStack(spacing: 4) {
            Text(L10n.forgotPasswordTitle)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(VoxTheme.textPrimary)
            Text(L10n.forgotPasswordDesc)
                .font(.system(size: 13))
                .foregroundStyle(VoxTheme.textSecondary)
                .multilineTextAlignment(.center)
        }

        // Email
        fieldLabel("Email")
        emailField

        statusMessages

        submitButton(label: L10n.sendResetLink, loadingLabel: L10n.sending) {
            await handleReset()
        }

        // Switch to Sign In
        HStack(spacing: 4) {
            Text(L10n.rememberPassword)
                .font(.system(size: 13))
                .foregroundStyle(VoxTheme.textSecondary)
            Button(L10n.signInAction) {
                switchView(.signIn)
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(VoxTheme.accent)
            .buttonStyle(.plain)
        }
    }

    // MARK: - Shared UI Components

    private var emailField: some View {
        TextField("you@example.com", text: $email)
            .textFieldStyle(.roundedBorder)
    }

    private var passwordField: some View {
        SecureField(L10n.passwordPlaceholder, text: $password)
            .textFieldStyle(.roundedBorder)
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(VoxTheme.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func googleButton(label: String) -> some View {
        Button(action: { auth.signInWithGoogle() }) {
            HStack(spacing: 10) {
                Image(systemName: "globe")
                    .font(.system(size: 15))
                Text(label)
                    .font(.system(size: 14, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(VoxTheme.background)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(VoxTheme.surfaceBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var divider: some View {
        HStack {
            Rectangle().fill(VoxTheme.surfaceBorder).frame(height: 1)
            Text(L10n.orContinueWithEmail)
                .font(.system(size: 11))
                .foregroundStyle(VoxTheme.textSecondary)
            Rectangle().fill(VoxTheme.surfaceBorder).frame(height: 1)
        }
    }

    private func tabButton(_ label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background(isSelected ? VoxTheme.accent : Color.clear)
                .foregroundStyle(isSelected ? VoxTheme.background : VoxTheme.textSecondary)
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }

    private func submitButton(label: String, loadingLabel: String, icon: String? = nil, action: @escaping () async -> Void) -> some View {
        Button(action: {
            Task { await action() }
        }) {
            HStack(spacing: 8) {
                if auth.isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text(loadingLabel)
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                    }
                    Text(label)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12))
                }
            }
            .font(.system(size: 14, weight: .semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
        .buttonStyle(.borderedProminent)
        .tint(VoxTheme.accent)
        .disabled(auth.isLoading)
    }

    @ViewBuilder
    private var statusMessages: some View {
        if let error = errorMessage {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                Text(error)
            }
            .font(.system(size: 12))
            .foregroundStyle(VoxTheme.danger)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(VoxTheme.danger.opacity(0.1))
            .cornerRadius(8)
        }
        if let message = successMessage {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                Text(message)
            }
            .font(.system(size: 12))
            .foregroundStyle(VoxTheme.success)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(VoxTheme.success.opacity(0.1))
            .cornerRadius(8)
        }
    }

    // MARK: - Actions

    private func switchView(_ newView: AuthView) {
        view = newView
        errorMessage = nil
        successMessage = nil
    }

    private func handleSignIn() async {
        errorMessage = nil
        successMessage = nil
        do {
            try await auth.signIn(email: email, password: password)
        } catch let error as AuthError {
            await MainActor.run {
                switch error {
                case .emailNotConfirmed:
                    successMessage = L10n.checkYourEmail
                default:
                    errorMessage = error.errorDescription
                }
            }
        } catch {
            await MainActor.run { errorMessage = error.localizedDescription }
        }
    }

    private func handleMagicLink() async {
        errorMessage = nil
        successMessage = nil
        do {
            try await auth.sendMagicLink(email: email)
            await MainActor.run {
                successMessage = L10n.magicLinkSent
            }
        } catch {
            await MainActor.run { errorMessage = error.localizedDescription }
        }
    }

    private func handleSignUp() async {
        errorMessage = nil
        successMessage = nil
        do {
            try await auth.signUp(
                email: email,
                password: password,
                firstName: firstName.isEmpty ? nil : firstName,
                lastName: lastName.isEmpty ? nil : lastName
            )
        } catch let error as AuthError {
            await MainActor.run {
                switch error {
                case .emailNotConfirmed:
                    successMessage = L10n.checkYourEmail
                default:
                    errorMessage = error.errorDescription
                }
            }
        } catch {
            await MainActor.run { errorMessage = error.localizedDescription }
        }
    }

    private func handleReset() async {
        errorMessage = nil
        successMessage = nil
        do {
            try await auth.resetPassword(email: email)
            await MainActor.run {
                successMessage = L10n.resetEmailSentDesc
            }
        } catch {
            await MainActor.run { errorMessage = error.localizedDescription }
        }
    }
}

// MARK: - Login Onboarding Wrapper

struct LoginOnboardingWrapper: View {
    @StateObject private var auth = AuthManager.shared
    let onAuthenticated: () -> Void

    var body: some View {
        LoginView()
            .onChange(of: auth.isAuthenticated) { isAuth in
                if isAuth {
                    onAuthenticated()

                    // Auto-start 7-day Pro trial for new users
                    Task {
                        await TrialManager.shared.autoStartTrialIfEligible()
                    }
                }
            }
    }
}

// MARK: - Localization Extensions

extension L10n {
    // Sign In
    static var welcomeBack: String { t("Welcome back", "Bem-vindo de volta", "Bienvenido de vuelta") }
    static var signInToContinue: String { t("Sign in to your account to continue", "Entre na sua conta para continuar", "Inicia sesion en tu cuenta para continuar") }
    static var signInWithGoogle: String { t("Sign in with Google", "Entrar com Google", "Iniciar sesion con Google") }
    static var signUpWithGoogle: String { t("Sign up with Google", "Cadastrar com Google", "Registrarse con Google") }
    static var passwordTab: String { t("Password", "Senha", "Contrasena") }
    static var magicLinkTab: String { t("Magic Link", "Link Magico", "Enlace Magico") }
    static var orContinueWithEmail: String { t("or continue with email", "ou continue com email", "o continua con email") }
    static var loginToVoxAiGo: String { t("Log in to VoxAiGo", "Entrar no VoxAiGo", "Iniciar sesion en VoxAiGo") }
    static var loginDescription: String { t("Sign in to sync your transcriptions and unlock all features.", "Entre para sincronizar suas transcricoes e desbloquear todos os recursos.", "Inicia sesion para sincronizar tus transcripciones y desbloquear todas las funciones.") }
    static var continueWithGoogle: String { t("Continue with Google", "Continuar com Google", "Continuar con Google") }
    static var orUseEmail: String { t("or use email", "ou use email", "o usa email") }
    static var password: String { t("Password", "Senha", "Contrasena") }
    static var passwordPlaceholder: String { t("Enter your password", "Digite sua senha", "Ingresa tu contrasena") }
    static var signIn: String { t("Sign In", "Entrar", "Iniciar Sesion") }
    static var signingIn: String { t("Signing in...", "Entrando...", "Iniciando sesion...") }
    static var signUp: String { t("Sign Up", "Criar Conta", "Registrarse") }
    static var signInAction: String { t("Sign in", "Entrar", "Iniciar sesion") }
    static var signUpAction: String { t("Sign up", "Criar conta", "Registrarse") }

    // Sign Up
    static var createAccount: String { t("Create your account", "Crie sua conta", "Crea tu cuenta") }
    static var createAccountAction: String { t("Create Account", "Criar Conta", "Crear Cuenta") }
    static var creating: String { t("Creating...", "Criando...", "Creando...") }
    static var startDictating5x: String { t("Start dictating 5x faster", "Comece a ditar 5x mais rapido", "Comienza a dictar 5x mas rapido") }
    static var firstNameLabel: String { t("First name", "Nome", "Nombre") }
    static var lastNameLabel: String { t("Last name", "Sobrenome", "Apellido") }
    static var alreadyHaveAccountShort: String { t("Already have an account?", "Ja tem uma conta?", "Ya tienes cuenta?") }
    static var dontHaveAccount: String { t("Don't have an account?", "Nao tem uma conta?", "No tienes cuenta?") }
    static var alreadyHaveAccount: String { t("Already have an account? Sign in", "Ja tem uma conta? Entre", "Ya tienes cuenta? Inicia sesion") }

    // Magic Link
    static var sendMagicLink: String { t("Send Magic Link", "Enviar Link Magico", "Enviar Enlace Magico") }
    static var sending: String { t("Sending...", "Enviando...", "Enviando...") }
    static var magicLinkSent: String { t("Magic link sent! Check your email.", "Link magico enviado! Verifique seu email.", "Enlace magico enviado! Revisa tu email.") }

    // Reset Password
    static var forgotPassword: String { t("Forgot password?", "Esqueci minha senha", "Olvide mi contrasena") }
    static var forgotPasswordTitle: String { t("Reset your password", "Redefinir sua senha", "Restablecer tu contrasena") }
    static var forgotPasswordDesc: String { t("Enter your email and we'll send you a reset link", "Digite seu email e enviaremos um link de redefinicao", "Ingresa tu email y te enviaremos un enlace de restablecimiento") }
    static var sendResetLink: String { t("Send Reset Link", "Enviar Link de Redefinicao", "Enviar Enlace de Restablecimiento") }
    static var rememberPassword: String { t("Remember your password?", "Lembra da sua senha?", "Recuerdas tu contrasena?") }
    static var resetEmailSentTitle: String { t("Email sent!", "Email enviado!", "Email enviado!") }
    static var resetEmailSentDesc: String { t("Check your inbox to reset your password.", "Verifique sua caixa de entrada para redefinir a senha.", "Revisa tu bandeja de entrada para restablecer tu contrasena.") }

    // Shared
    static var checkYourEmail: String { t("Check your email to confirm your account.", "Verifique seu email para confirmar sua conta.", "Revisa tu email para confirmar tu cuenta.") }
    static var loggedIn: String { t("Logged in!", "Conectado!", "Conectado!") }
}
