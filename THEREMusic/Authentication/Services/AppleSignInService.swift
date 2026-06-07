import Foundation
import AuthenticationServices
import Combine

// MARK: - AppleSignInService
final class AppleSignInService: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {

    static let shared = AppleSignInService()

    private var continuation: CheckedContinuation<User, Error>?
    private let keychainService = KeychainService.shared

    private override init() { super.init() }

    // MARK: - Sign In
    func signIn() async throws -> User {
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = generateNonce()
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }

    func checkCredentialState(userID: String) async -> ASAuthorizationAppleIDProvider.CredentialState {
        return await withCheckedContinuation { continuation in
            ASAuthorizationAppleIDProvider().getCredentialState(forUserID: userID) { state, _ in
                continuation.resume(returning: state)
            }
        }
    }

    // MARK: - ASAuthorizationControllerDelegate
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            continuation?.resume(throwing: AppErrorType.authFailed(NSLocalizedString("error_apple_auth", comment: "")))
            continuation = nil
            return
        }
        let userID = credential.user
        var displayName = NSLocalizedString("default_user_name", comment: "")
        if let firstName = credential.fullName?.givenName, let lastName = credential.fullName?.familyName {
            displayName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
        } else if let firstName = credential.fullName?.givenName {
            displayName = firstName
        }
        if displayName.isEmpty { displayName = NSLocalizedString("default_user_name", comment: "") }

        if let tokenData = credential.identityToken,
           let tokenString = String(data: tokenData, encoding: .utf8) {
            keychainService.saveAppleToken(tokenString)
        }
        keychainService.saveUserID(userID)

        let user = User(
            id: userID,
            email: credential.email,
            displayName: displayName,
            provider: .apple,
            createdAt: Date(),
            lastLoginAt: Date()
        )
        continuation?.resume(returning: user)
        continuation = nil
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        if let authError = error as? ASAuthorizationError, authError.code == .canceled {
            continuation?.resume(throwing: AppErrorType.authFailed("cancelled"))
        } else {
            continuation?.resume(throwing: AppErrorType.authFailed(error.localizedDescription))
        }
        continuation = nil
    }

    // MARK: - ASAuthorizationControllerPresentationContextProviding
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first { $0.isKeyWindow } ?? UIWindow()
    }

    // MARK: - Private
    private func generateNonce(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                return random
            }
            randoms.forEach { random in
                if remainingLength == 0 { return }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }
}
