import Foundation
import CoreData
import Combine

// MARK: - EmailAuthService
final class EmailAuthService {

    private let persistenceController: PersistenceController
    private let hashingService: PasswordHashingService
    private let keychainService: KeychainService

    init(
        persistenceController: PersistenceController = .shared,
        hashingService: PasswordHashingService = .shared,
        keychainService: KeychainService = .shared
    ) {
        self.persistenceController = persistenceController
        self.hashingService = hashingService
        self.keychainService = keychainService
    }

    // MARK: - Register
    func register(with data: RegistrationData) async throws -> User {
        guard data.isValid else {
            throw AppErrorType.invalidInput(NSLocalizedString("error_invalid_registration", comment: ""))
        }
        let context = persistenceController.container.viewContext
        let existing = try await fetchUserEntity(byEmail: data.email, context: context)
        guard existing == nil else {
            throw AppErrorType.authFailed(NSLocalizedString("error_email_exists", comment: ""))
        }
        let passwordHash = try hashingService.hashPBKDF2(data.password)
        let userID = UUID().uuidString
        let user = User(
            id: userID,
            email: data.email,
            displayName: data.displayName,
            avatarData: data.avatarData,
            provider: .email,
            createdAt: Date(),
            lastLoginAt: Date()
        )
        try await saveUserEntity(user: user, passwordHash: passwordHash, context: context)
        let token = createLocalToken(for: userID)
        let session = AuthSession(userID: userID, provider: .email, token: token, createdAt: Date(), lastRefreshedAt: Date())
        try keychainService.saveEmailSession(session)
        keychainService.saveUserID(userID)
        return user
    }

    // MARK: - Login
    func login(email: String, password: String) async throws -> User {
        guard email.isValidEmail else {
            throw AppErrorType.invalidInput(NSLocalizedString("error_invalid_email", comment: ""))
        }
        let context = persistenceController.container.viewContext
        guard let entity = try await fetchUserEntity(byEmail: email, context: context) else {
            throw AppErrorType.authFailed(NSLocalizedString("error_account_not_found", comment: ""))
        }
        guard let storedHash = entity.passwordHash else {
            throw AppErrorType.authFailed(NSLocalizedString("error_invalid_credentials", comment: ""))
        }
        let isValid = try hashingService.verifyPBKDF2(password, against: storedHash)
        guard isValid else {
            throw AppErrorType.authFailed(NSLocalizedString("error_wrong_password", comment: ""))
        }
        entity.lastLoginAt = Date()
        try context.save()
        let user = entityToUser(entity)
        let token = createLocalToken(for: user.id)
        let session = AuthSession(userID: user.id, provider: .email, token: token, createdAt: Date(), lastRefreshedAt: Date())
        try keychainService.saveEmailSession(session)
        keychainService.saveUserID(user.id)
        return user
    }

    // MARK: - Check Email
    func checkEmailExists(_ email: String) async throws -> Bool {
        let context = persistenceController.container.viewContext
        let entity = try await fetchUserEntity(byEmail: email, context: context)
        return entity != nil
    }

    // MARK: - Forgot Password
    func requestPasswordReset(email: String) async throws -> PasswordResetRequest {
        let context = persistenceController.container.viewContext
        guard let _ = try await fetchUserEntity(byEmail: email, context: context) else {
            throw AppErrorType.authFailed(NSLocalizedString("error_account_not_found", comment: ""))
        }
        let request = PasswordResetRequest(email: email)
        let data = try JSONEncoder().encode(request)
        keychainService.save(data, for: "reset_\(email)")
        return request
    }

    func resetPassword(email: String, code: String, newPassword: String) async throws {
        guard newPassword.isValidPassword else {
            throw AppErrorType.invalidInput(NSLocalizedString("error_weak_password", comment: ""))
        }
        guard let resetData = keychainService.load(key: "reset_\(email)"),
              let request = try? JSONDecoder().decode(PasswordResetRequest.self, from: resetData),
              request.code == code,
              request.isValid
        else {
            throw AppErrorType.authFailed(NSLocalizedString("error_invalid_reset_code", comment: ""))
        }
        let context = persistenceController.container.viewContext
        guard let entity = try await fetchUserEntity(byEmail: email, context: context) else {
            throw AppErrorType.notFound
        }
        entity.passwordHash = try hashingService.hashPBKDF2(newPassword)
        try context.save()
        keychainService.delete(key: "reset_\(email)")
    }

    // MARK: - Update Profile
    func updateProfile(userID: String, displayName: String, avatarData: Data?) async throws -> User {
        let context = persistenceController.container.viewContext
        guard let entity = try await fetchUserEntity(byID: userID, context: context) else {
            throw AppErrorType.notFound
        }
        entity.displayName = displayName
        entity.avatarData = avatarData
        entity.lastLoginAt = Date()
        try context.save()
        return entityToUser(entity)
    }

    // MARK: - Restore Session
    func restoreSession() throws -> User? {
        guard let session = try keychainService.loadEmailSession(),
              session.isValid,
              let userID = keychainService.loadUserID()
        else { return nil }
        let context = persistenceController.container.viewContext
        guard let entity = fetchUserEntitySync(byID: userID, context: context) else { return nil }
        return entityToUser(entity)
    }

    // MARK: - Sign Out
    func signOut() {
        keychainService.deleteEmailSession()
        keychainService.delete(key: AppConstants.Keychain.userIDKey)
    }

    // MARK: - Private Helpers
    private func createLocalToken(for userID: String) -> AuthToken {
        AuthToken(
            accessToken: UUID().uuidString,
            refreshToken: UUID().uuidString,
            expiresAt: Date().addingTimeInterval(AppConstants.Auth.sessionDuration),
            provider: .email
        )
    }

    private func fetchUserEntity(byEmail email: String, context: NSManagedObjectContext) async throws -> UserEntity? {
        return try await context.perform {
            let request = UserEntity.fetchRequest()
            request.predicate = NSPredicate(format: "email == %@", email)
            request.fetchLimit = 1
            return try context.fetch(request).first
        }
    }

    private func fetchUserEntity(byID id: String, context: NSManagedObjectContext) async throws -> UserEntity? {
        return try await context.perform {
            let request = UserEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id)
            request.fetchLimit = 1
            return try context.fetch(request).first
        }
    }

    private func fetchUserEntitySync(byID id: String, context: NSManagedObjectContext) -> UserEntity? {
        let request = UserEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

    private func saveUserEntity(user: User, passwordHash: String?, context: NSManagedObjectContext) async throws {
        try await context.perform {
            let entity = UserEntity(context: context)
            entity.id = user.id
            entity.email = user.email
            entity.displayName = user.displayName
            entity.avatarData = user.avatarData
            entity.provider = user.provider.rawValue
            entity.createdAt = user.createdAt
            entity.lastLoginAt = user.lastLoginAt
            entity.passwordHash = passwordHash
            try context.save()
        }
    }

    private func entityToUser(_ entity: UserEntity) -> User {
        User(
            id: entity.id ?? UUID().uuidString,
            email: entity.email,
            displayName: entity.displayName ?? NSLocalizedString("default_user_name", comment: ""),
            avatarData: entity.avatarData,
            provider: AuthProviderType(rawValue: entity.provider ?? "email") ?? .email,
            createdAt: entity.createdAt ?? Date(),
            lastLoginAt: entity.lastLoginAt ?? Date()
        )
    }
}
