import Foundation
#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

// MARK: - GoogleSignInService
final class GoogleSignInService {

    static let shared = GoogleSignInService()
    private let keychainService = KeychainService.shared
    private init() {}

    func configure() {
#if canImport(GoogleSignIn)
        guard let clientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String else { return }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
#endif
    }

    @MainActor
    func signIn() async throws -> User {
#if canImport(GoogleSignIn)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            throw AppErrorType.authFailed(NSLocalizedString("error_no_window", comment: ""))
        }
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            return try mapToUser(from: result.user)
        } catch let error as GIDSignInError {
            if error.code == .canceled { throw AppErrorType.authFailed("cancelled") }
            throw AppErrorType.authFailed(error.localizedDescription)
        } catch {
            throw AppErrorType.authFailed(error.localizedDescription)
        }
#else
        throw AppErrorType.authFailed("Google Sign In not available")
#endif
    }

    @MainActor
    func restorePreviousSignIn() async throws -> User? {
#if canImport(GoogleSignIn)
        guard GIDSignIn.sharedInstance.hasPreviousSignIn() else { return nil }
        do {
            try await GIDSignIn.sharedInstance.restorePreviousSignIn()
            guard let user = GIDSignIn.sharedInstance.currentUser else { return nil }
            return try mapToUser(from: user)
        } catch {
            return nil
        }
#else
        return nil
#endif
    }

    func signOut() {
#if canImport(GoogleSignIn)
        GIDSignIn.sharedInstance.signOut()
#endif
        keychainService.deleteGoogleTokens()
    }

    func handle(_ url: URL) -> Bool {
#if canImport(GoogleSignIn)
        return GIDSignIn.sharedInstance.handle(url)
#else
        return false
#endif
    }

#if canImport(GoogleSignIn)
    private func mapToUser(from googleUser: GIDGoogleUser) throws -> User {
        let profile = googleUser.profile
        let userID = googleUser.userID ?? UUID().uuidString
        let displayName = profile?.name ?? NSLocalizedString("default_user_name", comment: "")
        let email = profile?.email
        let avatarURL = profile?.imageURL(withDimension: 200)
        let tokenString = googleUser.accessToken.tokenString
        keychainService.saveGoogleToken(tokenString)
        if let refresh = googleUser.refreshToken.tokenString as String? {
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
#endif
}
