import SwiftUI
import UserNotifications

// MARK: - QueueManager
@MainActor
final class QueueManager: ObservableObject {

    static let shared = QueueManager()

    @Published var upcomingTracks: [Track] = []
    @Published var playedTracks: [Track] = []
    @Published var queueSource: String = ""

    private init() {}

    func set(tracks: [Track], from source: String) {
        upcomingTracks = tracks
        playedTracks = []
        queueSource = source
    }

    func markPlayed(_ track: Track) {
        upcomingTracks.removeAll { $0.id == track.id }
        playedTracks.insert(track, at: 0)
    }

    func insertNext(_ track: Track) {
        if !upcomingTracks.isEmpty {
            upcomingTracks.insert(track, at: 0)
        } else {
            upcomingTracks.append(track)
        }
    }

    func remove(at index: Int) {
        guard upcomingTracks.indices.contains(index) else { return }
        upcomingTracks.remove(at: index)
    }

    func move(from source: IndexSet, to destination: Int) {
        upcomingTracks.move(fromOffsets: source, toOffset: destination)
    }

    func clear() {
        upcomingTracks = []
    }
}

// MARK: - AudioSessionManager
final class AudioSessionManager {

    static let shared = AudioSessionManager()
    private init() {}

    func activateForPlayback() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.allowBluetooth, .allowAirPlay])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("AudioSession activation failed: \(error)")
        }
    }

    func deactivate() {
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    var currentRoute: String {
        let output = AVAudioSession.sharedInstance().currentRoute.outputs.first
        return output?.portName ?? "Speaker"
    }

    var isHeadphonesConnected: Bool {
        let outputs = AVAudioSession.sharedInstance().currentRoute.outputs
        return outputs.contains { $0.portType == .headphones || $0.portType == .bluetoothA2DP }
    }
}

// MARK: - TokenService
final class TokenService {

    static let shared = TokenService()
    private let keychainService = KeychainService.shared
    private init() {}

    func saveToken(_ token: AuthToken, for provider: AuthProviderType) throws {
        let key = tokenKey(for: provider)
        try keychainService.saveCodable(token, for: key)
    }

    func loadToken(for provider: AuthProviderType) throws -> AuthToken? {
        let key = tokenKey(for: provider)
        return try keychainService.loadCodable(AuthToken.self, key: key)
    }

    func deleteToken(for provider: AuthProviderType) {
        keychainService.delete(key: tokenKey(for: provider))
    }

    func isTokenValid(for provider: AuthProviderType) -> Bool {
        guard let token = try? loadToken(for: provider) else { return false }
        return !token.isExpired
    }

    func isTokenExpiringSoon(for provider: AuthProviderType) -> Bool {
        guard let token = try? loadToken(for: provider) else { return true }
        return token.isExpiringSoon
    }

    private func tokenKey(for provider: AuthProviderType) -> String {
        "token_\(provider.rawValue)"
    }
}

// MARK: - AuthRepository
final class AuthRepository {

    private let emailService: EmailAuthService
    private let appleService: AppleSignInService
    private let googleService: GoogleSignInService
    private let coreDataService: CoreDataService

    init(
        emailService: EmailAuthService = EmailAuthService(),
        appleService: AppleSignInService = .shared,
        googleService: GoogleSignInService = .shared,
        coreDataService: CoreDataService = .shared
    ) {
        self.emailService = emailService
        self.appleService = appleService
        self.googleService = googleService
        self.coreDataService = coreDataService
    }

    func signInWithApple() async throws -> User {
        try await appleService.signIn()
    }

    func signInWithGoogle() async throws -> User {
        try await googleService.signIn()
    }

    func registerWithEmail(data: RegistrationData) async throws -> User {
        try await emailService.register(with: data)
    }

    func loginWithEmail(email: String, password: String) async throws -> User {
        try await emailService.login(email: email, password: password)
    }

    func checkEmailExists(_ email: String) async throws -> Bool {
        try await emailService.checkEmailExists(email)
    }

    func requestPasswordReset(email: String) async throws -> PasswordResetRequest {
        try await emailService.requestPasswordReset(email: email)
    }

    func resetPassword(email: String, code: String, newPassword: String) async throws {
        try await emailService.resetPassword(email: email, code: code, newPassword: newPassword)
    }

    func restoreSession() throws -> User? {
        try emailService.restoreSession()
    }

    func saveUser(_ user: User) async {
        await coreDataService.saveUser(user)
    }

    func fetchUser(id: String) async -> User? {
        await coreDataService.fetchUser(id: id)
    }

    func signOut(provider: AuthProviderType) {
        switch provider {
        case .apple:  KeychainService.shared.deleteAppleToken()
        case .google: GoogleSignInService.shared.signOut()
        case .email:  emailService.signOut()
        }
        KeychainService.shared.clearAllAuthData()
    }
}

// MARK: - TrackRepository
final class TrackRepository {

    private let apiService: ITunesAPIService
    private let coreDataService: CoreDataService
    private let cacheService: DataCacheService

    init(
        apiService: ITunesAPIService = .shared,
        coreDataService: CoreDataService = .shared,
        cacheService: DataCacheService = .shared
    ) {
        self.apiService = apiService
        self.coreDataService = coreDataService
        self.cacheService = cacheService
    }

    func fetchTopTracks(limit: Int = 25) async throws -> [Track] {
        let key = "top_tracks_\(limit)"
        if let cached: [Track] = try? cacheService.get(key: key) { return cached }
        let tracks = try await apiService.fetchTopTracks(limit: limit)
        try? cacheService.set(tracks, key: key)
        return tracks
    }

    func search(query: String) async throws -> SearchResult {
        try await apiService.search(query: query)
    }

    func fetchArtistTracks(artistName: String) async throws -> [Track] {
        try await apiService.fetchArtistTracks(artistName: artistName)
    }

    func fetchAlbumTracks(albumID: Int) async throws -> [Track] {
        try await apiService.fetchAlbumTracks(albumID: albumID)
    }

    func getLikedTracks(userID: String) async -> [Track] {
        await coreDataService.fetchLikedTracks(userID: userID)
    }

    func toggleLike(track: Track, userID: String, isLiked: Bool) async {
        var updated = track
        updated.isLiked = isLiked
        await coreDataService.saveTrack(updated, userID: userID)
        await coreDataService.updateTrackLike(trackID: track.id, userID: userID, isLiked: isLiked)
    }

    func recordPlay(track: Track, userID: String) async {
        await coreDataService.saveTrack(track, userID: userID)
        await coreDataService.updatePlayCount(trackID: track.id, userID: userID, playedAt: Date())
    }

    func getRecentlyPlayed(userID: String, limit: Int = 50) async -> [Track] {
        await coreDataService.fetchRecentlyPlayed(userID: userID, limit: limit)
    }
}

// MARK: - PlaylistRepository
final class PlaylistRepository {

    private let coreDataService: CoreDataService

    init(coreDataService: CoreDataService = .shared) {
        self.coreDataService = coreDataService
    }

    func fetchPlaylists(userID: String) async -> [Playlist] {
        await coreDataService.fetchPlaylists(userID: userID)
    }

    func createPlaylist(name: String, description: String?, ownerID: String, ownerName: String) async -> Playlist {
        let playlist = Playlist(name: name, description: description, ownerID: ownerID, ownerName: ownerName)
        await coreDataService.savePlaylists([playlist], userID: ownerID)
        return playlist
    }

    func addTrack(_ track: Track, to playlist: inout Playlist, userID: String) async {
        playlist.tracks.append(track)
        playlist.updatedAt = Date()
        await coreDataService.savePlaylists([playlist], userID: userID)
        await coreDataService.saveTrack(track, userID: userID)
    }

    func removeTrack(_ track: Track, from playlist: inout Playlist, userID: String) async {
        playlist.tracks.removeAll { $0.id == track.id }
        playlist.updatedAt = Date()
        await coreDataService.savePlaylists([playlist], userID: userID)
    }

    func deletePlaylist(_ playlist: Playlist, userID: String) async {
        await coreDataService.deletePlaylist(id: playlist.id, userID: userID)
    }
}

// MARK: - CommentRepository
final class CommentRepository {

    private let coreDataService: CoreDataService

    init(coreDataService: CoreDataService = .shared) {
        self.coreDataService = coreDataService
    }

    func fetchComments(for trackID: String) async -> [Comment] {
        await coreDataService.fetchComments(for: trackID)
    }

    func addComment(_ comment: Comment) async {
        await coreDataService.saveComment(comment)
    }

    func updateComment(_ comment: Comment) async {
        await coreDataService.saveComment(comment)
    }

    func deleteComment(id: String) async {
        await coreDataService.deleteComment(id: id)
    }
}
