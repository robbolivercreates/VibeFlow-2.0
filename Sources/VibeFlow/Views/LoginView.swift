import SwiftUI

struct LoginView: View {
    @StateObject private var auth = AuthManager.shared
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var errorMessage: String?
    @State private var showEmailConfirmation = false
    @State private var showForgotPassword = false

    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.purple)

                Text(isSignUp ? L10n.createAccount : L10n.loginToVoxAiGo)
                    .font(.system(size: 18, weight: .semibold))

                Text(L10n.loginDescription)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Google Sign In
            Button(action: { auth.signInWithGoogle() }) {
                HStack(spacing: 10) {
                    Image(systemName: "globe")
                        .font(.system(size: 16))
                    Text(L10n.continueWithGoogle)
                        .font(.system(size: 14, weight: .medium))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            // Divider
            HStack {
                Rectangle().fill(Color(nsColor: .separatorColor)).frame(height: 1)
                Text(L10n.orUseEmail)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Rectangle().fill(Color(nsColor: .separatorColor)).frame(height: 1)
            }

            // Email/Password Fields
            VStack(spacing: 12) {
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)

                SecureField(L10n.password, text: $password)
                    .textFieldStyle(.roundedBorder)
            }

            // Forgot password link (sign in only)
            if !isSignUp {
                Button(L10n.forgotPassword) {
                    showForgotPassword = true
                }
                .font(.system(size: 12))
                .foregroundStyle(.purple)
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }

            // Error message
            if let error = errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                    Text(error)
                }
                .font(.system(size: 12))
                .foregroundStyle(.red)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.1))
                .cornerRadius(6)
            }

            // Email confirmation message
            if showEmailConfirmation {
                HStack(spacing: 6) {
                    Image(systemName: "envelope.fill")
                    Text(L10n.checkYourEmail)
                }
                .font(.system(size: 12))
                .foregroundStyle(.green)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.green.opacity(0.1))
                .cornerRadius(6)
            }

            // Submit Button
            Button(action: submitForm) {
                HStack(spacing: 8) {
                    if auth.isLoading {
                        ProgressView()
                            .scaleEffect(0.7)
                    }
                    Text(isSignUp ? L10n.signUp : L10n.signIn)
                        .font(.system(size: 14, weight: .medium))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
            .disabled(email.isEmpty || password.isEmpty || auth.isLoading)

            // Toggle Sign Up / Sign In
            Button(action: {
                isSignUp.toggle()
                errorMessage = nil
                showEmailConfirmation = false
            }) {
                Text(isSignUp ? L10n.alreadyHaveAccount : L10n.dontHaveAccount)
                    .font(.system(size: 13))
                    .foregroundStyle(.purple)
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        .frame(maxWidth: 400)
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView()
        }
    }

    private func submitForm() {
        errorMessage = nil
        showEmailConfirmation = false

        Task {
            do {
                if isSignUp {
                    try await auth.signUp(email: email, password: password)
                    if !auth.isAuthenticated {
                        await MainActor.run {
                            showEmailConfirmation = true
                        }
                    }
                } else {
                    try await auth.signIn(email: email, password: password)
                }
            } catch let error as AuthError {
                await MainActor.run {
                    switch error {
                    case .emailNotConfirmed:
                        showEmailConfirmation = true
                    default:
                        errorMessage = error.errorDescription
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Forgot Password View

struct ForgotPasswordView: View {
    @StateObject private var auth = AuthManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var isLoading = false
    @State private var emailSent = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "envelope.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.purple)

                Text(L10n.forgotPasswordTitle)
                    .font(.system(size: 18, weight: .semibold))

                Text(L10n.forgotPasswordDesc)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if emailSent {
                // Success state
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.green)

                    Text(L10n.resetEmailSentTitle)
                        .font(.system(size: 15, weight: .medium))

                    Text(L10n.resetEmailSentDesc)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(10)

                Button(L10n.close) { dismiss() }
                    .buttonStyle(.borderedProminent)
                    .tint(.purple)

            } else {
                // Input state
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)

                if let error = errorMessage {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text(error)
                    }
                    .font(.system(size: 12))
                    .foregroundStyle(.red)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(6)
                }

                Button(action: sendReset) {
                    HStack(spacing: 8) {
                        if isLoading { ProgressView().scaleEffect(0.7) }
                        Text(L10n.sendResetLink)
                            .font(.system(size: 14, weight: .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
                .disabled(email.isEmpty || isLoading)

                Button(L10n.cancel) { dismiss() }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .font(.system(size: 13))
            }
        }
        .padding(24)
        .frame(width: 380)
    }

    private func sendReset() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                try await auth.resetPassword(email: email)
                await MainActor.run {
                    isLoading = false
                    emailSent = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Login Onboarding Wrapper
// Used on first launch: observes auth state and calls onAuthenticated when login succeeds.

struct LoginOnboardingWrapper: View {
    @StateObject private var auth = AuthManager.shared
    let onAuthenticated: () -> Void

    var body: some View {
        LoginView()
            .onChange(of: auth.isAuthenticated) { isAuth in
                if isAuth { onAuthenticated() }
            }
    }
}

// MARK: - Localization Extensions

extension L10n {
    static var loginToVoxAiGo: String { t("Log in to VoxAiGo", "Entrar no VoxAiGo", "Iniciar sesion en VoxAiGo") }
    static var createAccount: String { t("Create Account", "Criar Conta", "Crear Cuenta") }
    static var loginDescription: String { t("Sign in to sync your transcriptions and unlock all features.", "Entre para sincronizar suas transcricoes e desbloquear todos os recursos.", "Inicia sesion para sincronizar tus transcripciones y desbloquear todas las funciones.") }
    static var continueWithGoogle: String { t("Continue with Google", "Continuar com Google", "Continuar con Google") }
    static var orUseEmail: String { t("or use email", "ou use email", "o usa email") }
    static var password: String { t("Password", "Senha", "Contrasena") }
    static var signIn: String { t("Sign In", "Entrar", "Iniciar Sesion") }
    static var signUp: String { t("Sign Up", "Criar Conta", "Registrarse") }
    static var alreadyHaveAccount: String { t("Already have an account? Sign in", "Ja tem uma conta? Entre", "Ya tienes cuenta? Inicia sesion") }
    static var dontHaveAccount: String { t("Don't have an account? Sign up", "Nao tem uma conta? Crie uma", "No tienes cuenta? Registrate") }
    static var checkYourEmail: String { t("Check your email to confirm your account.", "Verifique seu email para confirmar sua conta.", "Revisa tu email para confirmar tu cuenta.") }
    static var loggedIn: String { t("Logged in!", "Conectado!", "Conectado!") }
    static var forgotPassword: String { t("Forgot password?", "Esqueci minha senha", "Olvide mi contrasena") }
    static var forgotPasswordTitle: String { t("Reset Password", "Redefinir Senha", "Restablecer Contrasena") }
    static var forgotPasswordDesc: String { t("Enter your email and we'll send you a link to reset your password.", "Digite seu email e enviaremos um link para redefinir sua senha.", "Ingresa tu email y te enviaremos un enlace para restablecer tu contrasena.") }
    static var sendResetLink: String { t("Send reset link", "Enviar link de redefinicao", "Enviar enlace de restablecimiento") }
    static var resetEmailSentTitle: String { t("Email sent!", "Email enviado!", "Email enviado!") }
    static var resetEmailSentDesc: String { t("Check your inbox to reset your password.", "Verifique sua caixa de entrada para redefinir a senha.", "Revisa tu bandeja de entrada para restablecer tu contrasena.") }
}
