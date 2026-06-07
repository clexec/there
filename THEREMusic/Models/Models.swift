import Foundation

// MARK: - Track
struct Track: Identifiable, Codable, Hashable {
    let id: String
    var title: String
    var artistName: String
    var artistID: String?
    var albumTitle: String?
    var albumID: String?
    var artworkURL: URL?
    var previewURL: URL?
    var durationMs: Int
    var genre: String?
    var releaseDate: Date?
    var trackNumber: Int?
    var discNumber: Int?
    var isExplicit: Bool
    var bpm: Double?
    var energy: Double?
    var popularity: Int?
    var itunesTrackID: Int?
    var isLiked: Bool
    var isDownloaded: Bool
    var playCount: Int
    var lastPlayedAt: Date?
    var addedAt: Date?
    var localFileURL: URL?
    var waveformData: [Float]?

    var durationSeconds: Double { Double(durationMs) / 1000 }
    var formattedDuration: String { durationSeconds.formattedDuration }

    var displayArtwork: URL? { artworkURL }

    init(
        id: String = UUID().uuidString,
        title: String,
        artistName: String,
        artistID: String? = nil,
        albumTitle: String? = nil,
        albumID: String? = nil,
        artworkURL: URL? = nil,
        previewURL: URL? = nil,
        durationMs: Int = 0,
        genre: String? = nil,
        releaseDate: Date? = nil,
        trackNumber: Int? = nil,
        discNumber: Int? = nil,
        isExplicit: Bool = false,
        bpm: Double? = nil,
        energy: Double? = nil,
        popularity: Int? = nil,
        itunesTrackID: Int? = nil,
        isLiked: Bool = false,
        isDownloaded: Bool = false,
        playCount: Int = 0,
        lastPlayedAt: Date? = nil,
        addedAt: Date? = nil,
        localFileURL: URL? = nil,
        waveformData: [Float]? = nil
    ) {
        self.id = id
        self.title = title
        self.artistName = artistName
        self.artistID = artistID
        self.albumTitle = albumTitle
        self.albumID = albumID
        self.artworkURL = artworkURL
        self.previewURL = previewURL
        self.durationMs = durationMs
        self.genre = genre
        self.releaseDate = releaseDate
        self.trackNumber = trackNumber
        self.discNumber = discNumber
        self.isExplicit = isExplicit
        self.bpm = bpm
        self.energy = energy
        self.popularity = popularity
        self.itunesTrackID = itunesTrackID
        self.isLiked = isLiked
        self.isDownloaded = isDownloaded
        self.playCount = playCount
        self.lastPlayedAt = lastPlayedAt
        self.addedAt = addedAt ?? Date()
        self.localFileURL = localFileURL
        self.waveformData = waveformData
    }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: Track, rhs: Track) -> Bool { lhs.id == rhs.id }
}

// MARK: - Album
struct Album: Identifiable, Codable, Hashable {
    let id: String
    var title: String
    var artistName: String
    var artistID: String?
    var artworkURL: URL?
    var artworkURLLarge: URL?
    var releaseDate: Date?
    var trackCount: Int
    var genre: String?
    var tracks: [Track]
    var isSaved: Bool
    var itunesAlbumID: Int?
    var popularity: Int?
    var label: String?
    var copyright: String?
    var addedAt: Date?

    var year: Int? {
        guard let date = releaseDate else { return nil }
        return Calendar.current.component(.year, from: date)
    }

    var totalDurationMs: Int { tracks.reduce(0) { $0 + $1.durationMs } }
    var formattedTotalDuration: String { (Double(totalDurationMs) / 1000).formattedDuration }

    init(
        id: String = UUID().uuidString,
        title: String,
        artistName: String,
        artistID: String? = nil,
        artworkURL: URL? = nil,
        artworkURLLarge: URL? = nil,
        releaseDate: Date? = nil,
        trackCount: Int = 0,
        genre: String? = nil,
        tracks: [Track] = [],
        isSaved: Bool = false,
        itunesAlbumID: Int? = nil,
        popularity: Int? = nil,
        label: String? = nil,
        copyright: String? = nil,
        addedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.artistName = artistName
        self.artistID = artistID
        self.artworkURL = artworkURL
        self.artworkURLLarge = artworkURLLarge
        self.releaseDate = releaseDate
        self.trackCount = trackCount
        self.genre = genre
        self.tracks = tracks
        self.isSaved = isSaved
        self.itunesAlbumID = itunesAlbumID
        self.popularity = popularity
        self.label = label
        self.copyright = copyright
        self.addedAt = addedAt ?? Date()
    }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: Album, rhs: Album) -> Bool { lhs.id == rhs.id }
}

// MARK: - Artist
struct Artist: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var photoURL: URL?
    var headerURL: URL?
    var bio: String?
    var genres: [String]
    var followers: Int?
    var popularity: Int?
    var topTracks: [Track]
    var albums: [Album]
    var similarArtists: [Artist]
    var isFollowing: Bool
    var itunesArtistID: Int?
    var lastFMURL: URL?
    var addedAt: Date?

    var formattedFollowers: String { (followers ?? 0).formattedCount }

    init(
        id: String = UUID().uuidString,
        name: String,
        photoURL: URL? = nil,
        headerURL: URL? = nil,
        bio: String? = nil,
        genres: [String] = [],
        followers: Int? = nil,
        popularity: Int? = nil,
        topTracks: [Track] = [],
        albums: [Album] = [],
        similarArtists: [Artist] = [],
        isFollowing: Bool = false,
        itunesArtistID: Int? = nil,
        lastFMURL: URL? = nil,
        addedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.photoURL = photoURL
        self.headerURL = headerURL
        self.bio = bio
        self.genres = genres
        self.followers = followers
        self.popularity = popularity
        self.topTracks = topTracks
        self.albums = albums
        self.similarArtists = similarArtists
        self.isFollowing = isFollowing
        self.itunesArtistID = itunesArtistID
        self.lastFMURL = lastFMURL
        self.addedAt = addedAt ?? Date()
    }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: Artist, rhs: Artist) -> Bool { lhs.id == rhs.id }
}

// MARK: - Playlist
struct Playlist: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var description: String?
    var ownerID: String
    var ownerName: String
    var artworkURL: URL?
    var tracks: [Track]
    var isPublic: Bool
    var isCollaborative: Bool
    var isByTHERE: Bool
    var genre: String?
    var createdAt: Date
    var updatedAt: Date
    var playCount: Int
    var followers: Int
    var isLiked: Bool
    var isSaved: Bool
    var sortOption: SortOption?

    var trackCount: Int { tracks.count }
    var totalDurationMs: Int { tracks.reduce(0) { $0 + $1.durationMs } }
    var formattedDuration: String { (Double(totalDurationMs) / 1000).formattedDuration }

    var coverArtworks: [URL] {
        Array(tracks.compactMap { $0.artworkURL }.prefix(4))
    }

    init(
        id: String = UUID().uuidString,
        name: String,
        description: String? = nil,
        ownerID: String,
        ownerName: String,
        artworkURL: URL? = nil,
        tracks: [Track] = [],
        isPublic: Bool = false,
        isCollaborative: Bool = false,
        isByTHERE: Bool = false,
        genre: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        playCount: Int = 0,
        followers: Int = 0,
        isLiked: Bool = false,
        isSaved: Bool = true,
        sortOption: SortOption? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.ownerID = ownerID
        self.ownerName = ownerName
        self.artworkURL = artworkURL
        self.tracks = tracks
        self.isPublic = isPublic
        self.isCollaborative = isCollaborative
        self.isByTHERE = isByTHERE
        self.genre = genre
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.playCount = playCount
        self.followers = followers
        self.isLiked = isLiked
        self.isSaved = isSaved
        self.sortOption = sortOption
    }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: Playlist, rhs: Playlist) -> Bool { lhs.id == rhs.id }
}

// MARK: - PlaylistItem
struct PlaylistItem: Identifiable, Codable, Hashable {
    let id: String
    var playlistID: String
    var track: Track
    var addedBy: String?
    var addedAt: Date
    var position: Int

    init(id: String = UUID().uuidString, playlistID: String, track: Track, addedBy: String? = nil, addedAt: Date = Date(), position: Int = 0) {
        self.id = id
        self.playlistID = playlistID
        self.track = track
        self.addedBy = addedBy
        self.addedAt = addedAt
        self.position = position
    }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: PlaylistItem, rhs: PlaylistItem) -> Bool { lhs.id == rhs.id }
}

// MARK: - Genre
struct Genre: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var localizedName: String?
    var colorHex: String
    var iconName: String
    var description: String?
    var artworkURL: URL?
    var tracks: [Track]
    var popularity: Int?

    var displayName: String { localizedName ?? name }

    init(
        id: String = UUID().uuidString,
        name: String,
        localizedName: String? = nil,
        colorHex: String = "#1ED760",
        iconName: String = "music.note",
        description: String? = nil,
        artworkURL: URL? = nil,
        tracks: [Track] = [],
        popularity: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.localizedName = localizedName
        self.colorHex = colorHex
        self.iconName = iconName
        self.description = description
        self.artworkURL = artworkURL
        self.tracks = tracks
        self.popularity = popularity
    }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: Genre, rhs: Genre) -> Bool { lhs.id == rhs.id }

    static let allGenres: [Genre] = [
        Genre(id: "pop",         name: "Pop",        localizedName: NSLocalizedString("genre_pop", comment: ""),        colorHex: "#E91E63", iconName: "star.fill"),
        Genre(id: "rock",        name: "Rock",       localizedName: NSLocalizedString("genre_rock", comment: ""),       colorHex: "#FF5722", iconName: "guitars.fill"),
        Genre(id: "hiphop",      name: "Hip-Hop",    localizedName: NSLocalizedString("genre_hiphop", comment: ""),     colorHex: "#9C27B0", iconName: "mic.fill"),
        Genre(id: "electronic",  name: "Electronic", localizedName: NSLocalizedString("genre_electronic", comment: ""), colorHex: "#00BCD4", iconName: "waveform"),
        Genre(id: "jazz",        name: "Jazz",       localizedName: NSLocalizedString("genre_jazz", comment: ""),       colorHex: "#FF9800", iconName: "music.quarternote.3"),
        Genre(id: "classical",   name: "Classical",  localizedName: NSLocalizedString("genre_classical", comment: ""),  colorHex: "#607D8B", iconName: "music.note.list"),
        Genre(id: "rnb",         name: "R&B",        localizedName: NSLocalizedString("genre_rnb", comment: ""),        colorHex: "#F44336", iconName: "heart.fill"),
        Genre(id: "country",     name: "Country",    localizedName: NSLocalizedString("genre_country", comment: ""),    colorHex: "#8BC34A", iconName: "guitars"),
        Genre(id: "reggae",      name: "Reggae",     localizedName: NSLocalizedString("genre_reggae", comment: ""),     colorHex: "#FFEB3B", iconName: "sun.max.fill"),
        Genre(id: "metal",       name: "Metal",      localizedName: NSLocalizedString("genre_metal", comment: ""),      colorHex: "#424242", iconName: "bolt.fill"),
        Genre(id: "folk",        name: "Folk",       localizedName: NSLocalizedString("genre_folk", comment: ""),       colorHex: "#795548", iconName: "leaf.fill"),
        Genre(id: "latino",      name: "Latino",     localizedName: NSLocalizedString("genre_latino", comment: ""),     colorHex: "#FF4081", iconName: "flame.fill"),
        Genre(id: "soul",        name: "Soul",       localizedName: NSLocalizedString("genre_soul", comment: ""),       colorHex: "#673AB7", iconName: "sparkles"),
        Genre(id: "punk",        name: "Punk",       localizedName: NSLocalizedString("genre_punk", comment: ""),       colorHex: "#F50057", iconName: "exclamationmark.triangle.fill"),
        Genre(id: "indie",       name: "Indie",      localizedName: NSLocalizedString("genre_indie", comment: ""),      colorHex: "#00E5FF", iconName: "cloud.fill"),
        Genre(id: "blues",       name: "Blues",      localizedName: NSLocalizedString("genre_blues", comment: ""),      colorHex: "#1565C0", iconName: "waveform.path")
    ]
}

// MARK: - SearchResult
struct SearchResult: Identifiable, Codable {
    let id: String
    var tracks: [Track]
    var albums: [Album]
    var artists: [Artist]
    var playlists: [Playlist]
    var query: String
    var totalResults: Int

    init(
        id: String = UUID().uuidString,
        tracks: [Track] = [],
        albums: [Album] = [],
        artists: [Artist] = [],
        playlists: [Playlist] = [],
        query: String = "",
        totalResults: Int = 0
    ) {
        self.id = id
        self.tracks = tracks
        self.albums = albums
        self.artists = artists
        self.playlists = playlists
        self.query = query
        self.totalResults = tracks.count + albums.count + artists.count + playlists.count
    }

    var isEmpty: Bool { totalResults == 0 }
}

// MARK: - Comment
struct Comment: Identifiable, Codable, Hashable {
    let id: String
    var trackID: String
    var userID: String
    var userName: String
    var userAvatarURL: URL?
    var text: String
    var createdAt: Date
    var updatedAt: Date?
    var isEdited: Bool
    var likesCount: Int
    var isLikedByCurrentUser: Bool

    init(
        id: String = UUID().uuidString,
        trackID: String,
        userID: String,
        userName: String,
        userAvatarURL: URL? = nil,
        text: String,
        createdAt: Date = Date(),
        updatedAt: Date? = nil,
        isEdited: Bool = false,
        likesCount: Int = 0,
        isLikedByCurrentUser: Bool = false
    ) {
        self.id = id
        self.trackID = trackID
        self.userID = userID
        self.userName = userName
        self.userAvatarURL = userAvatarURL
        self.text = text
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isEdited = isEdited
        self.likesCount = likesCount
        self.isLikedByCurrentUser = isLikedByCurrentUser
    }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: Comment, rhs: Comment) -> Bool { lhs.id == rhs.id }
}

// MARK: - PlayerState
struct PlayerState: Codable, Equatable {
    var currentTrack: Track?
    var queue: [Track]
    var currentIndex: Int
    var state: PlayerStateEnum
    var currentTimeSeconds: Double
    var durationSeconds: Double
    var progress: Double
    var volume: Double
    var isShuffled: Bool
    var repeatMode: RepeatMode
    var isMuted: Bool
    var crossfadeDuration: Double

    static let idle = PlayerState(
        currentTrack: nil,
        queue: [],
        currentIndex: 0,
        state: .idle,
        currentTimeSeconds: 0,
        durationSeconds: 0,
        progress: 0,
        volume: 1.0,
        isShuffled: false,
        repeatMode: .off,
        isMuted: false,
        crossfadeDuration: 0
    )
}

// MARK: - Recommendation
struct Recommendation: Identifiable, Codable {
    let id: String
    var section: HomeSection
    var title: String
    var subtitle: String?
    var artworkURL: URL?
    var tracks: [Track]
    var albums: [Album]
    var playlists: [Playlist]
    var artists: [Artist]
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        section: HomeSection,
        title: String,
        subtitle: String? = nil,
        artworkURL: URL? = nil,
        tracks: [Track] = [],
        albums: [Album] = [],
        playlists: [Playlist] = [],
        artists: [Artist] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.section = section
        self.title = title
        self.subtitle = subtitle
        self.artworkURL = artworkURL
        self.tracks = tracks
        self.albums = albums
        self.playlists = playlists
        self.artists = artists
        self.createdAt = createdAt
    }
}

// MARK: - HistoryItem
struct HistoryItem: Identifiable, Codable {
    let id: String
    var track: Track
    var playedAt: Date
    var playDurationSeconds: Double
    var context: String?

    init(id: String = UUID().uuidString, track: Track, playedAt: Date = Date(), playDurationSeconds: Double = 0, context: String? = nil) {
        self.id = id
        self.track = track
        self.playedAt = playedAt
        self.playDurationSeconds = playDurationSeconds
        self.context = context
    }
}

// MARK: - SearchHistoryItem
struct SearchHistoryItem: Identifiable, Codable {
    let id: String
    var query: String
    var searchedAt: Date
    var resultCount: Int

    init(id: String = UUID().uuidString, query: String, searchedAt: Date = Date(), resultCount: Int = 0) {
        self.id = id
        self.query = query
        self.searchedAt = searchedAt
        self.resultCount = resultCount
    }
}
