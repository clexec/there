import Foundation
import GoogleSignIn

// MARK: - GoogleSignInService
final class GoogleSignInService {

    static let shared = GoogleSignInService()
    private let keychainService = KeychainService.shared
    private init() {}

    // MARK: - Configure
    func configure() {
        guard let clientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String else {
            return
        }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
    }

    // MARK: - Sign In
    @MainActor
    func signIn() async throws -> User {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            throw AppErrorType.authFailed(NSLocalizedString("error_no_window", comment: ""))
        }
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            return try mapToUser(from: result.user)
        } catch let error as GIDSignInError {
            if error.code == .canceled {
                throw AppErrorType.authFailed("cancelled")
            }
            throw AppErrorType.authFailed(error.localizedDescription)
        } catch {
            throw AppErrorType.authFailed(error.localizedDescription)
        }
    }

    // MARK: - Restore
    @MainActor
    func restorePreviousSignIn() async throws -> User? {
        guard GIDSignIn.sharedInstance.hasPreviousSignIn() else { return nil }
        do {
            try await GIDSignIn.sharedInstance.restorePreviousSignIn()
            guard let user = GIDSignIn.sharedInstance.currentUser else { return nil }
            return try mapToUser(from: user)
        } catch {
            return nil
        }
    }

    // MARK: - Sign Out
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        keychainService.deleteGoogleTokens()
    }

    // MARK: - Handle URL
    func handle(_ url: URL) -> Bool {
        GIDSignIn.sharedInstance.handle(url)
    }

    // MARK: - Private
    private func mapToUser(from googleUser: GIDGoogleUser) throws -> User {
        let profile = googleUser.profile
        let userID = googleUser.userID ?? UUID().uuidString
        let displayName = profile?.name ?? NSLocalizedString("default_user_name", comment: "")
        let email = profile?.email

        var avatarURL: URL? = nil
        if let url = profile?.imageURL(withDimension: 200) { avatarURL = url }

        if let token = googleUser.accessToken.tokenString {
            keychainService.saveGoogleToken(token)
        }
        if let refresh = googleUser.refreshToken?.tokenString {
            keychainService.saveGoogleRefresh(refresh)
        }
        keychainService.saveUserID(userID)

        return User(
            id: userID,
            email: email,
            displayName: displayName,
            avatarURL: avatarURL,
            provider: .google,
            createdAt: Date(),
            lastLoginAt: Date()
        )
    }
}
