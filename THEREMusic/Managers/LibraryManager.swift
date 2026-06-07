import Foundation
import UIKit

// MARK: - UserDefaultsManager
final class UserDefaultsManager {

    static let shared = UserDefaultsManager()
    private let defaults: UserDefaults

    private init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func set<T>(_ value: T, for key: String) {
        defaults.set(value, forKey: key)
    }

    func get<T>(for key: String) -> T? {
        defaults.object(forKey: key) as? T
    }

    func string(for key: String) -> String? { defaults.string(forKey: key) }
    func bool(for key: String) -> Bool       { defaults.bool(forKey: key) }
    func int(for key: String) -> Int         { defaults.integer(forKey: key) }
    func double(for key: String) -> Double   { defaults.double(forKey: key) }
    func data(for key: String) -> Data?      { defaults.data(forKey: key) }

    func remove(key: String) { defaults.removeObject(forKey: key) }

    func saveCodable<T: Codable>(_ value: T, for key: String) {
        if let data = try? JSONEncoder().encode(value) {
            defaults.set(data, forKey: key)
        }
    }

    func loadCodable<T: Codable>(_ type: T.Type, for key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    func appendToArray<T: Codable>(_ element: T, key: String, maxCount: Int = 100) {
        var array = loadCodable([T].self, for: key) ?? []
        array.insert(element, at: 0)
        if array.count > maxCount { array = Array(array.prefix(maxCount)) }
        saveCodable(array, for: key)
    }

    func clearAll() { defaults.dictionaryRepresentation().keys.forEach { defaults.removeObject(forKey: $0) } }
}

// MARK: - ThemeManager
@MainActor
final class ThemeManager: ObservableObject {

    static let shared = ThemeManager()
    @Published var currentTheme: Theme = .dark

    private init() {
        let raw = UserDefaultsManager.shared.string(for: AppConstants.Defaults.currentTheme)
        currentTheme = Theme(rawValue: raw ?? "dark") ?? .dark
    }

    func setTheme(_ theme: Theme) {
        currentTheme = theme
        UserDefaultsManager.shared.set(theme.rawValue, for: AppConstants.Defaults.currentTheme)
        applyTheme()
    }

    private func applyTheme() {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        for scene in scenes {
            for window in scene.windows {
                switch currentTheme {
                case .dark:   window.overrideUserInterfaceStyle = .dark
                case .light:  window.overrideUserInterfaceStyle = .light
                case .system: window.overrideUserInterfaceStyle = .unspecified
                }
            }
        }
    }
}

// MARK: - LibraryManager
@MainActor
final class LibraryManager: ObservableObject {

    static let shared = LibraryManager()

    @Published var likedTracks: [Track] = []
    @Published var savedAlbums: [Album] = []
    @Published var playlists: [Playlist] = []
    @Published var followingArtists: [Artist] = []
    @Published var recentlyPlayed: [Track] = []

    private let coreDataService: CoreDataService
    private var userID: String?

    private init(coreDataService: CoreDataService = .shared) {
        self.coreDataService = coreDataService
    }

    func configure(userID: String) {
        self.userID = userID
        Task { await loadAll() }
    }

    func loadAll() async {
        guard let uid = userID else { return }
        async let liked    = coreDataService.fetchLikedTracks(userID: uid)
        async let recent   = coreDataService.fetchRecentlyPlayed(userID: uid)
        async let lists    = coreDataService.fetchPlaylists(userID: uid)
        let (l, r, p) = await (liked, recent, lists)
        likedTracks     = l
        recentlyPlayed  = r
        playlists       = p
    }

    func toggleLike(track: Track) async {
        guard let uid = userID else { return }
        let isNowLiked = !likedTracks.contains(where: { $0.id == track.id })
        var updatedTrack = track
        updatedTrack.isLiked = isNowLiked
        await coreDataService.saveTrack(updatedTrack, userID: uid)
        await coreDataService.updateTrackLike(trackID: track.id, userID: uid, isLiked: isNowLiked)
        if isNowLiked {
            likedTracks.insert(updatedTrack, at: 0)
        } else {
            likedTracks.removeAll { $0.id == track.id }
        }
    }

    func isLiked(_ track: Track) -> Bool {
        likedTracks.contains(where: { $0.id == track.id })
    }

    func recordPlay(track: Track) async {
        guard let uid = userID else { return }
        await coreDataService.saveTrack(track, userID: uid)
        await coreDataService.updatePlayCount(trackID: track.id, userID: uid, playedAt: Date())
        if !recentlyPlayed.contains(where: { $0.id == track.id }) {
            recentlyPlayed.insert(track, at: 0)
            if recentlyPlayed.count > 50 { recentlyPlayed = Array(recentlyPlayed.prefix(50)) }
        } else {
            recentlyPlayed.removeAll { $0.id == track.id }
            recentlyPlayed.insert(track, at: 0)
        }
    }

    func createPlaylist(name: String, description: String?) async -> Playlist {
        guard let uid = userID else { fatalError("No user") }
        let playlist = Playlist(
            name: name,
            description: description,
            ownerID: uid,
            ownerName: AuthenticationManager.shared.currentUser?.displayName ?? "Me"
        )
        await coreDataService.savePlaylists([playlist], userID: uid)
        playlists.insert(playlist, at: 0)
        return playlist
    }

    func addTrack(_ track: Track, to playlistID: String) async {
        guard let idx = playlists.firstIndex(where: { $0.id == playlistID }),
              let uid = userID else { return }
        var updatedPlaylist = playlists[idx]
        guard !updatedPlaylist.tracks.contains(where: { $0.id == track.id }) else { return }
        updatedPlaylist.tracks.append(track)
        updatedPlaylist.updatedAt = Date()
        playlists[idx] = updatedPlaylist
        await coreDataService.savePlaylists([updatedPlaylist], userID: uid)
        await coreDataService.saveTrack(track, userID: uid)
    }

    func removeTrack(_ track: Track, from playlistID: String) async {
        guard let idx = playlists.firstIndex(where: { $0.id == playlistID }),
              let uid = userID else { return }
        var updatedPlaylist = playlists[idx]
        updatedPlaylist.tracks.removeAll { $0.id == track.id }
        updatedPlaylist.updatedAt = Date()
        playlists[idx] = updatedPlaylist
        await coreDataService.savePlaylists([updatedPlaylist], userID: uid)
    }

    func deletePlaylist(_ playlist: Playlist) async {
        guard let uid = userID else { return }
        playlists.removeAll { $0.id == playlist.id }
        await coreDataService.deletePlaylist(id: playlist.id, userID: uid)
    }

    func saveAlbum(_ album: Album) {
        guard !savedAlbums.contains(where: { $0.id == album.id }) else { return }
        savedAlbums.insert(album, at: 0)
    }

    func removeAlbum(_ album: Album) {
        savedAlbums.removeAll { $0.id == album.id }
    }

    func isAlbumSaved(_ album: Album) -> Bool {
        savedAlbums.contains(where: { $0.id == album.id })
    }

    func followArtist(_ artist: Artist) {
        guard !followingArtists.contains(where: { $0.id == artist.id }) else { return }
        followingArtists.insert(artist, at: 0)
    }

    func unfollowArtist(_ artist: Artist) {
        followingArtists.removeAll { $0.id == artist.id }
    }

    func isFollowing(_ artist: Artist) -> Bool {
        followingArtists.contains(where: { $0.id == artist.id })
    }

    func clearHistory() async {
        recentlyPlayed = []
    }
}
