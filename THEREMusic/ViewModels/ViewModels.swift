import Foundation
import Combine

// MARK: - PlayerViewModel
@MainActor
final class PlayerViewModel: ObservableObject {

    @Published var isLyricsVisible: Bool = false
    @Published var isQueueVisible: Bool = false
    @Published var isOptionsVisible: Bool = false
    @Published var isSleepTimerVisible: Bool = false
    @Published var sleepTimerMinutes: Int = 30
    @Published var isSleepTimerActive: Bool = false
    @Published var equalizerPreset: String = "Normal"
    @Published var isDraggingProgress: Bool = false
    @Published var dragProgress: Double = 0
    @Published var visualizerBars: [CGFloat] = Array(repeating: 0.3, count: 30)

    private let playerManager: PlayerManager
    private let libraryManager: LibraryManager
    private var cancellables = Set<AnyCancellable>()
    private var visualizerTimer: Timer?
    private var sleepTimer: Timer?

    var currentTrack: Track? { playerManager.currentTrack }
    var isPlaying: Bool       { playerManager.isPlaying }
    var currentTime: Double   { playerManager.currentTime }
    var duration: Double      { playerManager.duration }
    var progress: Double      { isDraggingProgress ? dragProgress : playerManager.progress }
    var isShuffled: Bool      { playerManager.isShuffled }
    var repeatMode: RepeatMode { playerManager.repeatMode }
    var hasNext: Bool         { playerManager.hasNext }
    var hasPrevious: Bool     { playerManager.hasPrevious }
    var queue: [Track]        { playerManager.queue }
    var currentIndex: Int     { playerManager.currentIndex }
    var isLiked: Bool         { currentTrack.map { libraryManager.isLiked($0) } ?? false }

    init(playerManager: PlayerManager = .shared, libraryManager: LibraryManager = .shared) {
        self.playerManager = playerManager
        self.libraryManager = libraryManager
        setupBindings()
        startVisualizer()
    }

    // MARK: - Controls
    func playPause()        { playerManager.pauseResume() }
    func skipNext()         { playerManager.skipNext() }
    func skipPrevious()     { playerManager.skipPrevious() }
    func toggleShuffle()    { playerManager.toggleShuffle() }
    func toggleRepeat()     { playerManager.toggleRepeat() }

    func seekTo(progress: Double) {
        playerManager.seek(to: progress)
        isDraggingProgress = false
    }

    func startDragging() {
        isDraggingProgress = true
        dragProgress = playerManager.progress
    }

    func updateDrag(progress: Double) {
        dragProgress = max(0, min(1, progress))
    }

    func toggleLike() async {
        guard let track = currentTrack else { return }
        await libraryManager.toggleLike(track: track)
    }

    // MARK: - Sleep Timer
    func setSleepTimer(minutes: Int) {
        cancelSleepTimer()
        isSleepTimerActive = true
        sleepTimerMinutes = minutes
        sleepTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(minutes * 60), repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.playerManager.pause()
                self?.cancelSleepTimer()
            }
        }
    }

    func cancelSleepTimer() {
        sleepTimer?.invalidate()
        sleepTimer = nil
        isSleepTimerActive = false
    }

    // MARK: - Visualizer
    private func startVisualizer() {
        visualizerTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in
            guard let self, self.isPlaying else { return }
            Task { @MainActor in
                self.visualizerBars = (0..<30).map { _ in
                    CGFloat.random(in: 0.1...1.0)
                }
            }
        }
    }

    func stopVisualizer() {
        visualizerTimer?.invalidate()
        visualizerTimer = nil
        visualizerBars = Array(repeating: 0.15, count: 30)
    }

    // MARK: - Queue Management
    func removeFromQueue(at index: Int) {
        playerManager.removeFromQueue(at: index)
    }

    func moveInQueue(from source: IndexSet, to destination: Int) {
        playerManager.moveInQueue(from: source, to: destination)
    }

    func addToQueue(_ track: Track) {
        playerManager.addToQueue(track)
    }

    func playFromQueue(at index: Int) {
        let track = playerManager.queue[index]
        playerManager.play(track: track, queue: playerManager.queue, startIndex: index)
    }

    // MARK: - Share
    func shareTrack() -> String? {
        guard let track = currentTrack else { return nil }
        return "THERE Music: \(track.title) by \(track.artistName)"
    }

    // MARK: - Bindings
    private func setupBindings() {
        playerManager.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        libraryManager.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        playerManager.$currentTrack
            .receive(on: DispatchQueue.main)
            .sink { [weak self] track in
                guard track != nil else { return }
                Task { @MainActor in self?.libraryManager.recordPlay(track: track!) }
            }
            .store(in: &cancellables)
    }
}

// MARK: - CommentViewModel
@MainActor
final class CommentViewModel: ObservableObject {

    @Published var comments: [Comment] = []
    @Published var newCommentText: String = ""
    @Published var isLoading: Bool = false
    @Published var editingComment: Comment?
    @Published var editText: String = ""
    @Published var error: String?

    private let coreDataService: CoreDataService
    private let authManager: AuthenticationManager

    var canPost: Bool {
        newCommentText.trimmingCharacters(in: .whitespaces).count >= 1
            && newCommentText.count <= AppConstants.Library.maxCommentLength
    }

    init(coreDataService: CoreDataService = .shared, authManager: AuthenticationManager = .shared) {
        self.coreDataService = coreDataService
        self.authManager = authManager
    }

    func loadComments(trackID: String) async {
        isLoading = true
        comments = await coreDataService.fetchComments(for: trackID)
        isLoading = false
    }

    func postComment(trackID: String) async {
        guard let user = authManager.currentUser,
              !newCommentText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isLoading = true
        let comment = Comment(
            trackID: trackID,
            userID: user.id,
            userName: user.displayName,
            avatarURL: user.avatarURL,
            text: newCommentText.trimmingCharacters(in: .whitespaces)
        )
        await coreDataService.saveComment(comment)
        comments.insert(comment, at: 0)
        newCommentText = ""
        isLoading = false
    }

    func startEditing(_ comment: Comment) {
        editingComment = comment
        editText = comment.text
    }

    func saveEdit() async {
        guard var comment = editingComment,
              !editText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        comment.text = editText.trimmingCharacters(in: .whitespaces)
        comment.isEdited = true
        comment.updatedAt = Date()
        await coreDataService.saveComment(comment)
        if let idx = comments.firstIndex(where: { $0.id == comment.id }) {
            comments[idx] = comment
        }
        editingComment = nil
        editText = ""
    }

    func deleteComment(_ comment: Comment) async {
        await coreDataService.deleteComment(id: comment.id)
        comments.removeAll { $0.id == comment.id }
    }

    func cancelEditing() {
        editingComment = nil
        editText = ""
    }
}

// MARK: - ProfileViewModel
@MainActor
final class ProfileViewModel: ObservableObject {

    @Published var displayName: String = ""
    @Published var email: String = ""
    @Published var avatarData: Data?
    @Published var bio: String = ""
    @Published var isEditing: Bool = false
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var showSignOutConfirm: Bool = false
    @Published var showDeleteAccountConfirm: Bool = false
    @Published var likedCount: Int = 0
    @Published var playlistCount: Int = 0
    @Published var followingCount: Int = 0

    private let authManager: AuthenticationManager
    private let libraryManager: LibraryManager
    private var cancellables = Set<AnyCancellable>()

    init(authManager: AuthenticationManager = .shared, libraryManager: LibraryManager = .shared) {
        self.authManager = authManager
        self.libraryManager = libraryManager
        loadUserData()
        setupBindings()
    }

    func loadUserData() {
        guard let user = authManager.currentUser else { return }
        displayName = user.displayName
        email = user.email ?? ""
        avatarData = user.avatarData
        bio = user.bio ?? ""
        likedCount = libraryManager.likedTracks.count
        playlistCount = libraryManager.playlists.count
        followingCount = libraryManager.followingArtists.count
    }

    func saveProfile() async {
        isLoading = true
        error = nil
        do {
            try await authManager.updateProfile(displayName: displayName, avatarData: avatarData)
            isEditing = false
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func signOut() {
        authManager.signOut()
    }

    private func setupBindings() {
        authManager.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.loadUserData() }
            .store(in: &cancellables)

        libraryManager.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.likedCount     = self?.libraryManager.likedTracks.count ?? 0
                self?.playlistCount  = self?.libraryManager.playlists.count ?? 0
                self?.followingCount = self?.libraryManager.followingArtists.count ?? 0
            }
            .store(in: &cancellables)
    }
}

// MARK: - ArtistDetailViewModel
@MainActor
final class ArtistDetailViewModel: ObservableObject {

    @Published var artist: Artist
    @Published var topTracks: [Track] = []
    @Published var albums: [Album] = []
    @Published var similarArtists: [Artist] = []
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var isFollowing: Bool = false

    private let apiService: ITunesAPIService
    private let libraryManager: LibraryManager

    init(artist: Artist, apiService: ITunesAPIService = .shared, libraryManager: LibraryManager = .shared) {
        self.artist = artist
        self.apiService = apiService
        self.libraryManager = libraryManager
        self.isFollowing = libraryManager.isFollowing(artist)
    }

    func load() async {
        isLoading = true
        error = nil
        do {
            async let tracks = apiService.fetchArtistTracks(artistName: artist.name, limit: 10)
            async let releases = apiService.fetchNewReleases(limit: 6)
            let (t, r) = try await (tracks, releases)
            topTracks = t
            albums = r
            artist.topTracks = t
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func toggleFollow() {
        if isFollowing {
            libraryManager.unfollowArtist(artist)
        } else {
            libraryManager.followArtist(artist)
        }
        isFollowing.toggle()
    }
}

// MARK: - AlbumDetailViewModel
@MainActor
final class AlbumDetailViewModel: ObservableObject {

    @Published var album: Album
    @Published var tracks: [Track] = []
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var isSaved: Bool = false

    private let apiService: ITunesAPIService
    private let libraryManager: LibraryManager

    init(album: Album, apiService: ITunesAPIService = .shared, libraryManager: LibraryManager = .shared) {
        self.album = album
        self.apiService = apiService
        self.libraryManager = libraryManager
        self.isSaved = libraryManager.isAlbumSaved(album)
        self.tracks = album.tracks
    }

    func load() async {
        guard tracks.isEmpty else { return }
        isLoading = true
        do {
            if let id = album.itunesAlbumID {
                tracks = try await apiService.fetchAlbumTracks(albumID: id)
            } else {
                tracks = try await apiService.fetchArtistTracks(artistName: album.artistName, limit: 15)
            }
            album.tracks = tracks
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func toggleSave() {
        if isSaved {
            libraryManager.removeAlbum(album)
        } else {
            libraryManager.saveAlbum(album)
        }
        isSaved.toggle()
    }
}

// MARK: - PlaylistDetailViewModel
@MainActor
final class PlaylistDetailViewModel: ObservableObject {

    @Published var playlist: Playlist
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var isEditingName: Bool = false
    @Published var editName: String = ""

    private let libraryManager: LibraryManager

    init(playlist: Playlist, libraryManager: LibraryManager = .shared) {
        self.playlist = playlist
        self.libraryManager = libraryManager
        self.editName = playlist.name
    }

    func removeTrack(_ track: Track) async {
        await libraryManager.removeTrack(track, from: playlist.id)
        playlist.tracks.removeAll { $0.id == track.id }
    }

    func saveName() {
        guard !editName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        playlist.name = editName
        isEditingName = false
        Task { await libraryManager.createPlaylist(name: playlist.name, description: playlist.description) }
    }
}

// MARK: - SettingsViewModel
@MainActor
final class SettingsViewModel: ObservableObject {

    @Published var selectedTheme: Theme = .dark
    @Published var selectedLanguage: String = "system"
    @Published var streamQuality: StreamQuality = .high
    @Published var crossfadeDuration: Double = 0
    @Published var downloadOnWifi: Bool = true
    @Published var showExplicit: Bool = true
    @Published var notificationsEnabled: Bool = true
    @Published var discoverNotif: Bool = true
    @Published var releaseNotif: Bool = true
    @Published var cacheSize: String = "0 MB"
    @Published var isLoading: Bool = false

    private let userDefaultsManager: UserDefaultsManager
    private let themeManager: ThemeManager
    private let imageCache: ImageCacheService

    init(
        userDefaultsManager: UserDefaultsManager = .shared,
        themeManager: ThemeManager = .shared,
        imageCache: ImageCacheService = .shared
    ) {
        self.userDefaultsManager = userDefaultsManager
        self.themeManager = themeManager
        self.imageCache = imageCache
        loadSettings()
    }

    func loadSettings() {
        selectedTheme = themeManager.currentTheme
        let qualityRaw = userDefaultsManager.string(for: AppConstants.Defaults.streamQuality)
        streamQuality = StreamQuality(rawValue: qualityRaw ?? "high") ?? .high
        crossfadeDuration = userDefaultsManager.double(for: AppConstants.Defaults.crossfadeDuration)
        downloadOnWifi = userDefaultsManager.bool(for: AppConstants.Defaults.downloadOnWifi)
        notificationsEnabled = userDefaultsManager.bool(for: AppConstants.Defaults.notificationsEnabled)
        discoverNotif = userDefaultsManager.bool(for: AppConstants.Defaults.discoverNotif)
        releaseNotif = userDefaultsManager.bool(for: AppConstants.Defaults.releaseNotif)
        updateCacheSize()
    }

    func applyTheme(_ theme: Theme) {
        selectedTheme = theme
        themeManager.setTheme(theme)
    }

    func setQuality(_ quality: StreamQuality) {
        streamQuality = quality
        userDefaultsManager.set(quality.rawValue, for: AppConstants.Defaults.streamQuality)
    }

    func setCrossfade(_ duration: Double) {
        crossfadeDuration = duration
        userDefaultsManager.set(duration, for: AppConstants.Defaults.crossfadeDuration)
    }

    func clearCache() async {
        isLoading = true
        imageCache.clearAll()
        DataCacheService.shared.clearAll()
        updateCacheSize()
        isLoading = false
    }

    private func updateCacheSize() {
        let mb = imageCache.diskCacheSizeMB
        if mb < 1 { cacheSize = String(format: "%.0f KB", mb * 1024) }
        else       { cacheSize = String(format: "%.1f MB", mb) }
    }
}
