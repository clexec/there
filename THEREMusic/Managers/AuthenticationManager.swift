import Foundation
import Combine

// MARK: - AuthenticationManager
@MainActor
final class AuthenticationManager: ObservableObject {

    static let shared = AuthenticationManager()

    @Published var currentUser: User?
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var authError: String?

    private let emailAuthService: EmailAuthService
    private let appleSignInService: AppleSignInService
    private let googleSignInService: GoogleSignInService
    private let coreDataService: CoreDataService
    private let userDefaultsManager: UserDefaultsManager
    private var cancellables = Set<AnyCancellable>()

    private init(
        emailAuthService: EmailAuthService = EmailAuthService(),
        appleSignInService: AppleSignInService = .shared,
        googleSignInService: GoogleSignInService = .shared,
        coreDataService: CoreDataService = .shared,
        userDefaultsManager: UserDefaultsManager = .shared
    ) {
        self.emailAuthService = emailAuthService
        self.appleSignInService = appleSignInService
        self.googleSignInService = googleSignInService
        self.coreDataService = coreDataService
        self.userDefaultsManager = userDefaultsManager
        Task { await restoreSession() }
    }

    // MARK: - Sign In with Apple
    func signInWithApple() async {
        isLoading = true
        authError = nil
        do {
            let user = try await appleSignInService.signIn()
            await handleSuccessfulAuth(user: user)
        } catch let error as AppErrorType {
            if case .authFailed(let msg) = error, msg == "cancelled" {
                isLoading = false
                return
            }
            authError = error.errorDescription
        } catch {
            authError = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Sign In with Google
    func signInWithGoogle() async {
        isLoading = true
        authError = nil
        do {
            let user = try await googleSignInService.signIn()
            await handleSuccessfulAuth(user: user)
        } catch let error as AppErrorType {
            if case .authFailed(let msg) = error, msg == "cancelled" {
                isLoading = false
                return
            }
            authError = error.errorDescription
        } catch {
            authError = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Register with Email
    func register(with data: RegistrationData) async {
        isLoading = true
        authError = nil
        do {
            let user = try await emailAuthService.register(with: data)
            await handleSuccessfulAuth(user: user)
        } catch let error as AppErrorType {
            authError = error.errorDescription
        } catch {
            authError = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Login with Email
    func login(email: String, password: String) async {
        isLoading = true
        authError = nil
        do {
            let user = try await emailAuthService.login(email: email, password: password)
            await handleSuccessfulAuth(user: user)
        } catch let error as AppErrorType {
            authError = error.errorDescription
        } catch {
            authError = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Check Email
    func checkEmailExists(_ email: String) async throws -> Bool {
        try await emailAuthService.checkEmailExists(email)
    }

    // MARK: - Forgot Password
    func requestPasswordReset(email: String) async throws -> PasswordResetRequest {
        try await emailAuthService.requestPasswordReset(email: email)
    }

    func resetPassword(email: String, code: String, newPassword: String) async throws {
        try await emailAuthService.resetPassword(email: email, code: code, newPassword: newPassword)
    }

    // MARK: - Update Profile
    func updateProfile(displayName: String, avatarData: Data?) async throws {
        guard let userID = currentUser?.id else { throw AppErrorType.unauthorized }
        let updated = try await emailAuthService.updateProfile(userID: userID, displayName: displayName, avatarData: avatarData)
        currentUser = updated
        await coreDataService.saveUser(updated)
    }

    // MARK: - Sign Out
    func signOut() {
        isLoading = true
        switch currentUser?.provider {
        case .apple:
            KeychainService.shared.deleteAppleToken()
        case .google:
            googleSignInService.signOut()
        case .email:
            emailAuthService.signOut()
        case .none:
            break
        }
        KeychainService.shared.clearAllAuthData()
        userDefaultsManager.remove(key: AppConstants.Defaults.isAuthenticated)
        userDefaultsManager.remove(key: AppConstants.Defaults.currentUserID)
        currentUser = nil
        isAuthenticated = false
        isLoading = false
    }

    // MARK: - Restore Session
    func restoreSession() async {
        isLoading = true
        defer { isLoading = false }

        if let userID = KeychainService.shared.loadUserID() {
            if let savedUser = await coreDataService.fetchUser(id: userID) {
                await handleSuccessfulAuth(user: savedUser)
                return
            }
        }

        if let user = try? emailAuthService.restoreSession() {
            await handleSuccessfulAuth(user: user)
            return
        }

        if let user = try? await googleSignInService.restorePreviousSignIn() {
            await handleSuccessfulAuth(user: user)
            return
        }

        isAuthenticated = false
    }

    // MARK: - Private
    private func handleSuccessfulAuth(user: User) async {
        await coreDataService.saveUser(user)
        userDefaultsManager.set(true, for: AppConstants.Defaults.isAuthenticated)
        userDefaultsManager.set(user.id, for: AppConstants.Defaults.currentUserID)
        userDefaultsManager.set(user.provider.rawValue, for: AppConstants.Defaults.lastProvider)
        currentUser = user
        isAuthenticated = true
    }
}
