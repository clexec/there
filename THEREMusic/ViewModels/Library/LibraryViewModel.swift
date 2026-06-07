import Foundation
import Combine

// MARK: - LibraryViewModel
@MainActor
final class LibraryViewModel: ObservableObject {

    @Published var selectedTab: LibraryTab = .playlists
    @Published var sortOption: SortOption = .dateAdded
    @Published var filterOption: FilterOption = .all
    @Published var searchQuery: String = ""
    @Published var isCreatingPlaylist: Bool = false
    @Published var newPlaylistName: String = ""
    @Published var newPlaylistDescription: String = ""
    @Published var isLoading: Bool = false
    @Published var error: String?

    private let libraryManager: LibraryManager
    private var cancellables = Set<AnyCancellable>()

    var playlists: [Playlist]      { filtered(libraryManager.playlists) }
    var likedTracks: [Track]        { sorted(libraryManager.likedTracks) }
    var savedAlbums: [Album]        { libraryManager.savedAlbums }
    var followingArtists: [Artist]  { libraryManager.followingArtists }
    var recentlyPlayed: [Track]     { libraryManager.recentlyPlayed }

    init(libraryManager: LibraryManager = .shared) {
        self.libraryManager = libraryManager
        bindLibraryManager()
    }

    // MARK: - Playlist Actions
    func createPlaylist() async {
        guard !newPlaylistName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isLoading = true
        let _ = await libraryManager.createPlaylist(
            name: newPlaylistName.trimmingCharacters(in: .whitespaces),
            description: newPlaylistDescription.isEmpty ? nil : newPlaylistDescription
        )
        newPlaylistName = ""
        newPlaylistDescription = ""
        isCreatingPlaylist = false
        isLoading = false
    }

    func deletePlaylist(_ playlist: Playlist) async {
        await libraryManager.deletePlaylist(playlist)
    }

    func toggleLike(track: Track) async {
        await libraryManager.toggleLike(track: track)
    }

    func isLiked(_ track: Track) -> Bool {
        libraryManager.isLiked(track)
    }

    func unfollowArtist(_ artist: Artist) {
        libraryManager.unfollowArtist(artist)
    }

    func removeAlbum(_ album: Album) {
        libraryManager.removeAlbum(album)
    }

    // MARK: - Filtering & Sorting
    private func filtered(_ playlists: [Playlist]) -> [Playlist] {
        var result = playlists
        if !searchQuery.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchQuery) ||
                ($0.description?.localizedCaseInsensitiveContains(searchQuery) == true)
            }
        }
        return sorted(result)
    }

    private func sorted<T>(_ items: [T]) -> [T] where T: Identifiable {
        items
    }

    private func sorted(_ playlists: [Playlist]) -> [Playlist] {
        switch sortOption {
        case .title, .alphabetical: return playlists.sorted { $0.name < $1.name }
        case .dateAdded:            return playlists.sorted { $0.createdAt > $1.createdAt }
        case .recentlyPlayed:       return playlists.sorted { $0.updatedAt > $1.updatedAt }
        default:                    return playlists
        }
    }

    private func sorted(_ tracks: [Track]) -> [Track] {
        switch sortOption {
        case .title, .alphabetical:  return tracks.sorted { $0.title < $1.title }
        case .artist:                return tracks.sorted { $0.artistName < $1.artistName }
        case .dateAdded:             return tracks.sorted { ($0.addedAt ?? Date.distantPast) > ($1.addedAt ?? Date.distantPast) }
        case .duration:              return tracks.sorted { $0.durationMs > $1.durationMs }
        case .recentlyPlayed:        return tracks.sorted { ($0.lastPlayedAt ?? Date.distantPast) > ($1.lastPlayedAt ?? Date.distantPast) }
        case .playCount:             return tracks.sorted { $0.playCount > $1.playCount }
        default:                     return tracks
        }
    }

    private func bindLibraryManager() {
        libraryManager.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }
}
