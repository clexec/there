import Foundation

// MARK: - User
struct User: Identifiable, Codable, Equatable {
    let id: String
    var email: String?
    var displayName: String
    var avatarURL: URL?
    var avatarData: Data?
    var provider: AuthProviderType
    var createdAt: Date
    var lastLoginAt: Date
    var isPremium: Bool
    var country: String
    var language: String
    var followingArtistIDs: [String]
    var savedAlbumIDs: [String]
    var savedPlaylistIDs: [String]
    var likedTrackIDs: [String]
    var blockedUserIDs: [String]
    var bio: String?
    var website: String?

    var initials: String { displayName.initials }
    var isEmailProvider: Bool { provider == .email }

    init(
        id: String = UUID().uuidString,
        email: String? = nil,
        displayName: String,
        avatarURL: URL? = nil,
        avatarData: Data? = nil,
        provider: AuthProviderType,
        createdAt: Date = Date(),
        lastLoginAt: Date = Date(),
        isPremium: Bool = false,
        country: String = Locale.current.region?.identifier ?? "US",
        language: String = Locale.current.language.languageCode?.identifier ?? "en",
        followingArtistIDs: [String] = [],
        savedAlbumIDs: [String] = [],
        savedPlaylistIDs: [String] = [],
        likedTrackIDs: [String] = [],
        blockedUserIDs: [String] = [],
        bio: String? = nil,
        website: String? = nil
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.avatarData = avatarData
        self.provider = provider
        self.createdAt = createdAt
        self.lastLoginAt = lastLoginAt
        self.isPremium = isPremium
        self.country = country
        self.language = language
        self.followingArtistIDs = followingArtistIDs
        self.savedAlbumIDs = savedAlbumIDs
        self.savedPlaylistIDs = savedPlaylistIDs
        self.likedTrackIDs = likedTrackIDs
        self.blockedUserIDs = blockedUserIDs
        self.bio = bio
        self.website = website
    }

    static func == (lhs: User, rhs: User) -> Bool { lhs.id == rhs.id }

    var publicProfile: UserPublicProfile {
        UserPublicProfile(
            id: id,
            displayName: displayName,
            avatarURL: avatarURL,
            followingCount: followingArtistIDs.count,
            bio: bio
        )
    }
}

// MARK: - UserPublicProfile
struct UserPublicProfile: Identifiable, Codable {
    let id: String
    var displayName: String
    var avatarURL: URL?
    var followingCount: Int
    var bio: String?
}

// MARK: - AuthCredentials
struct AuthCredentials: Equatable {
    var email: String
    var password: String

    var isValid: Bool {
        email.isValidEmail && password.count >= AppConstants.Auth.minPasswordLength
    }
}

// MARK: - AuthToken
struct AuthToken: Codable {
    var accessToken: String
    var refreshToken: String?
    var expiresAt: Date
    var provider: AuthProviderType

    var isExpired: Bool { Date() >= expiresAt }
    var isExpiringSoon: Bool {
        Date().addingTimeInterval(AppConstants.Auth.tokenRefreshBuffer) >= expiresAt
    }
}

// MARK: - AuthSession
struct AuthSession: Codable, Equatable {
    var userID: String
    var provider: AuthProviderType
    var token: AuthToken
    var createdAt: Date
    var lastRefreshedAt: Date

    var isValid: Bool { !token.isExpired }

    static func == (lhs: AuthSession, rhs: AuthSession) -> Bool {
        lhs.userID == rhs.userID && lhs.token.accessToken == rhs.token.accessToken
    }
}

// MARK: - AuthResult
enum AuthResult {
    case success(User)
    case requiresAdditionalInfo(partialUser: PartialUser)
    case failure(AppErrorType)
    case cancelled
}

// MARK: - PartialUser
struct PartialUser: Codable {
    var email: String?
    var displayName: String?
    var avatarURL: URL?
    var provider: AuthProviderType
    var providerUserID: String?
    var providerToken: String?
}

// MARK: - RegistrationData
struct RegistrationData {
    var email: String
    var password: String
    var displayName: String
    var avatarData: Data?

    var isValid: Bool {
        email.isValidEmail
            && password.isValidPassword
            && displayName.count >= 2
    }
}

// MARK: - PasswordResetRequest
struct PasswordResetRequest: Codable {
    var email: String
    var code: String?
    var newPassword: String?
    var expiresAt: Date?
    var isUsed: Bool

    init(email: String) {
        self.email = email
        self.code = Self.generateCode()
        self.newPassword = nil
        self.expiresAt = Date().addingTimeInterval(3600)
        self.isUsed = false
    }

    var isValid: Bool {
        guard let exp = expiresAt else { return false }
        return !isUsed && Date() < exp
    }

    private static func generateCode() -> String {
        String(format: "%06d", Int.random(in: 100000...999999))
    }
}
