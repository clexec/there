import Foundation
import Combine

// MARK: - AuthViewModel
@MainActor
final class AuthViewModel: ObservableObject {

    enum AuthFlow {
        case landing
        case emailEntry
        case login(email: String)
        case register(email: String)
        case forgotPassword(email: String)
        case resetPassword(email: String)
    }

    @Published var flow: AuthFlow = .landing
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var infoMessage: String?

    private let authManager: AuthenticationManager

    init(authManager: AuthenticationManager = .shared) {
        self.authManager = authManager
    }

    func signInWithApple() async {
        error = nil
        await authManager.signInWithApple()
        error = authManager.authError
    }

    func signInWithGoogle() async {
        error = nil
        await authManager.signInWithGoogle()
        error = authManager.authError
    }

    func proceedWithEmail(_ email: String) async {
        guard email.isValidEmail else {
            error = NSLocalizedString("error_invalid_email", comment: ""); return
        }
        isLoading = true
        error = nil
        do {
            let exists = try await authManager.checkEmailExists(email)
            flow = exists ? .login(email: email) : .register(email: email)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func navigateToForgotPassword(email: String) {
        flow = .forgotPassword(email: email)
    }

    func requestPasswordReset(email: String) async {
        isLoading = true
        error = nil
        infoMessage = nil
        do {
            let _ = try await authManager.requestPasswordReset(email: email)
            infoMessage = NSLocalizedString("info_reset_code_sent", comment: "")
            flow = .resetPassword(email: email)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func resetPassword(email: String, code: String, newPassword: String) async {
        guard newPassword.isValidPassword else {
            error = NSLocalizedString("error_weak_password", comment: ""); return
        }
        isLoading = true
        error = nil
        do {
            try await authManager.resetPassword(email: email, code: code, newPassword: newPassword)
            infoMessage = NSLocalizedString("info_password_reset_success", comment: "")
            flow = .login(email: email)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func back() {
        switch flow {
        case .emailEntry:          flow = .landing
        case .login, .register:    flow = .emailEntry
        case .forgotPassword(let e): flow = .login(email: e)
        case .resetPassword(let e):  flow = .forgotPassword(email: e)
        case .landing:             break
        }
    }

    func clearError() { error = nil }
}

// MARK: - LoginViewModel
@MainActor
final class LoginViewModel: ObservableObject {

    @Published var email: String
    @Published var password: String = ""
    @Published var isPasswordVisible: Bool = false
    @Published var isLoading: Bool = false
    @Published var error: String?

    private let authManager: AuthenticationManager

    var canLogin: Bool { email.isValidEmail && password.count >= AppConstants.Auth.minPasswordLength }

    init(email: String, authManager: AuthenticationManager = .shared) {
        self.email = email
        self.authManager = authManager
    }

    func login() async {
        guard canLogin else {
            error = NSLocalizedString("error_invalid_credentials", comment: ""); return
        }
        isLoading = true
        error = nil
        await authManager.login(email: email, password: password)
        error = authManager.authError
        isLoading = false
    }
}

// MARK: - RegisterViewModel
@MainActor
final class RegisterViewModel: ObservableObject {

    @Published var email: String
    @Published var displayName: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    @Published var isPasswordVisible: Bool = false
    @Published var isConfirmVisible: Bool = false
    @Published var avatarData: Data?
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var termsAccepted: Bool = false

    private let authManager: AuthenticationManager

    var passwordStrength: PasswordStrength { password.passwordStrength }
    var passwordsMatch: Bool { !confirmPassword.isEmpty && password == confirmPassword }
    var canRegister: Bool {
        email.isValidEmail
            && displayName.count >= 2
            && password.isValidPassword
            && passwordsMatch
            && termsAccepted
    }

    init(email: String, authManager: AuthenticationManager = .shared) {
        self.email = email
        self.authManager = authManager
    }

    func register() async {
        guard canRegister else {
            error = NSLocalizedString("error_fill_all_fields", comment: ""); return
        }
        isLoading = true
        error = nil
        let data = RegistrationData(
            email: email,
            password: password,
            displayName: displayName.trimmingCharacters(in: .whitespaces),
            avatarData: avatarData
        )
        await authManager.register(with: data)
        error = authManager.authError
        isLoading = false
    }
}

// MARK: - ForgotPasswordViewModel
@MainActor
final class ForgotPasswordViewModel: ObservableObject {

    @Published var email: String
    @Published var code: String = ""
    @Published var newPassword: String = ""
    @Published var confirmPassword: String = ""
    @Published var isPasswordVisible: Bool = false
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var successMessage: String?
    @Published var codeSent: Bool = false

    private let authManager: AuthenticationManager

    var passwordStrength: PasswordStrength { newPassword.passwordStrength }
    var canSubmitCode: Bool { code.count == 6 && newPassword.isValidPassword && newPassword == confirmPassword }

    init(email: String, authManager: AuthenticationManager = .shared) {
        self.email = email
        self.authManager = authManager
    }

    func sendResetCode() async {
        guard email.isValidEmail else {
            error = NSLocalizedString("error_invalid_email", comment: ""); return
        }
        isLoading = true
        error = nil
        do {
            let _ = try await authManager.requestPasswordReset(email: email)
            codeSent = true
            successMessage = NSLocalizedString("info_reset_code_sent", comment: "")
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func resetPassword() async {
        guard canSubmitCode else {
            error = NSLocalizedString("error_passwords_no_match", comment: ""); return
        }
        isLoading = true
        error = nil
        do {
            try await authManager.resetPassword(email: email, code: code, newPassword: newPassword)
            successMessage = NSLocalizedString("info_password_reset_success", comment: "")
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
