import Foundation
import Combine

// MARK: - ITunesAPIService
final class ITunesAPIService {

    static let shared = ITunesAPIService()
    private let session: URLSession
    private let cache: DataCacheService

    private init(session: URLSession = .shared, cache: DataCacheService = .shared) {
        self.session = session
        self.cache = cache
    }

    // MARK: - Search
    func search(query: String, limit: Int = APIConstants.iTunes.defaultLimit) async throws -> SearchResult {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            return SearchResult(query: query)
        }
        let cacheKey = "itunes_search_\(query)_\(limit)"
        if let cached: SearchResult = try? cache.get(key: cacheKey) { return cached }

        let url = buildURL(path: APIConstants.iTunes.searchPath, params: [
            "term":    query,
            "media":   APIConstants.iTunes.mediaType,
            "limit":   String(min(limit, APIConstants.iTunes.maxLimit)),
            "country": APIConstants.iTunes.country,
            "lang":    Locale.current.language.languageCode?.identifier == "ru" ? "ru_RU" : "en_us"
        ])
        let response: ITunesSearchResponse = try await session.fetch(ITunesSearchResponse.self, from: url)
        let result = mapSearchResponse(response, query: query)
        try? cache.set(result, key: cacheKey, ttl: AppConstants.Cache.dataTTL)
        return result
    }

    // MARK: - Top Charts
    func fetchTopTracks(limit: Int = 25, genre: String? = nil) async throws -> [Track] {
        let cacheKey = "itunes_top_tracks_\(limit)_\(genre ?? "all")"
        if let cached: [Track] = try? cache.get(key: cacheKey) { return cached }

        var params: [String: String] = [
            "term":  genre ?? "music",
            "media": "music",
            "entity": "song",
            "limit": String(limit),
            "country": APIConstants.iTunes.country
        ]
        if let genre { params["genreId"] = genre }
        let url = buildURL(path: APIConstants.iTunes.searchPath, params: params)
        let response: ITunesSearchResponse = try await session.fetch(ITunesSearchResponse.self, from: url)
        let tracks = response.results.compactMap { mapResult($0) }.compactMap { $0 as? Track }
        try? cache.set(tracks, key: cacheKey, ttl: AppConstants.Cache.dataTTL)
        return tracks
    }

    // MARK: - Lookup by ID
    func lookupTrack(id: Int) async throws -> Track? {
        let url = buildURL(path: APIConstants.iTunes.lookupPath, params: [
            "id":     String(id),
            "entity": "song"
        ])
        let response: ITunesSearchResponse = try await session.fetch(ITunesSearchResponse.self, from: url)
        return response.results.first.flatMap { mapResult($0) as? Track }
    }

    func lookupAlbum(id: Int) async throws -> Album? {
        let url = buildURL(path: APIConstants.iTunes.lookupPath, params: [
            "id":     String(id),
            "entity": "song"
        ])
        let response: ITunesSearchResponse = try await session.fetch(ITunesSearchResponse.self, from: url)
        return mapAlbumFromLookup(response)
    }

    func lookupArtist(id: Int) async throws -> Artist? {
        let cacheKey = "itunes_artist_\(id)"
        if let cached: Artist = try? cache.get(key: cacheKey) { return cached }
        let url = buildURL(path: APIConstants.iTunes.lookupPath, params: [
            "id":     String(id),
            "entity": "song",
            "limit":  "20"
        ])
        let response: ITunesSearchResponse = try await session.fetch(ITunesSearchResponse.self, from: url)
        let artist = mapArtistFromLookup(response, artistID: id)
        if let a = artist { try? cache.set(a, key: cacheKey, ttl: AppConstants.Cache.dataTTL) }
        return artist
    }

    // MARK: - Artist Top Tracks
    func fetchArtistTracks(artistName: String, limit: Int = 20) async throws -> [Track] {
        let cacheKey = "itunes_artist_tracks_\(artistName)_\(limit)"
        if let cached: [Track] = try? cache.get(key: cacheKey) { return cached }
        let url = buildURL(path: APIConstants.iTunes.searchPath, params: [
            "term":    artistName,
            "entity":  "song",
            "limit":   String(limit),
            "attribute": "artistTerm"
        ])
        let response: ITunesSearchResponse = try await session.fetch(ITunesSearchResponse.self, from: url)
        let tracks = response.results.compactMap { mapResult($0) as? Track }
        try? cache.set(tracks, key: cacheKey, ttl: AppConstants.Cache.dataTTL)
        return tracks
    }

    // MARK: - Album Tracks
    func fetchAlbumTracks(albumID: Int) async throws -> [Track] {
        let url = buildURL(path: APIConstants.iTunes.lookupPath, params: [
            "id":     String(albumID),
            "entity": "song"
        ])
        let response: ITunesSearchResponse = try await session.fetch(ITunesSearchResponse.self, from: url)
        return response.results
            .filter { $0.wrapperType == "track" }
            .compactMap { mapResult($0) as? Track }
    }

    // MARK: - Genre Search
    func searchByGenre(_ genre: String, limit: Int = 20) async throws -> [Track] {
        try await fetchTopTracks(limit: limit, genre: genre)
    }

    // MARK: - New Releases
    func fetchNewReleases(limit: Int = 20) async throws -> [Album] {
        let url = buildURL(path: APIConstants.iTunes.searchPath, params: [
            "term":   "new music 2026",
            "entity": "album",
            "limit":  String(limit)
        ])
        let response: ITunesSearchResponse = try await session.fetch(ITunesSearchResponse.self, from: url)
        return response.results.compactMap { mapAlbumResult($0) }
    }

    // MARK: - Recommendations
    func fetchRecommendations(basedOn track: Track, limit: Int = 10) async throws -> [Track] {
        try await fetchArtistTracks(artistName: track.artistName, limit: limit)
    }

    // MARK: - Private Builders
    private func buildURL(path: String, params: [String: String]) -> URL {
        var components = URLComponents(string: APIConstants.iTunes.baseURL + path)!
        components.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        return components.url!
    }

    // MARK: - Private Mappers
    private func mapSearchResponse(_ response: ITunesSearchResponse, query: String) -> SearchResult {
        var tracks: [Track] = []
        var albums: [Album] = []
        var artists: [Artist] = []

        for item in response.results {
            switch mapResult(item) {
            case .track(let t):  tracks.append(t)
            case .album(let al): albums.append(al)
            case .artist(let ar): artists.append(ar)
            case nil: break
            }
        }
        return SearchResult(tracks: tracks, albums: albums, artists: artists, query: query)
    }

    private enum MappedResult {
        case track(Track), album(Album), artist(Artist)
    }

    private func mapResult(_ item: ITunesResult) -> MappedResult? {
        switch item.wrapperType {
        case "track":
            return mapTrackResult(item).map { .track($0) }
        case "collection":
            return mapAlbumResult(item).map { .album($0) }
        case "artist":
            return mapArtistResult(item).map { .artist($0) }
        default:
            if item.kind == "song" { return mapTrackResult(item).map { .track($0) } }
            return nil
        }
    }

    private func mapTrackResult(_ item: ITunesResult) -> Track? {
        guard let title = item.trackName else { return nil }
        let artworkURL = item.artworkUrl100.flatMap { URL(string: $0.replacingOccurrences(of: "100x100", with: "600x600")) }
        let previewURL = item.previewUrl.flatMap { URL(string: $0) }
        return Track(
            id: "itunes_\(item.trackId ?? item.collectionId ?? Int.random(in: 1...999999))",
            title: title,
            artistName: item.artistName ?? NSLocalizedString("unknown_artist", comment: ""),
            artistID: item.artistId.map { "itunes_artist_\($0)" },
            albumTitle: item.collectionName,
            albumID: item.collectionId.map { "itunes_album_\($0)" },
            artworkURL: artworkURL,
            previewURL: previewURL,
            durationMs: item.trackTimeMillis ?? 0,
            genre: item.primaryGenreName,
            releaseDate: item.releaseDate.flatMap { Date.fromISO8601($0) },
            trackNumber: item.trackNumber,
            discNumber: item.discNumber,
            isExplicit: item.trackExplicitness == "explicit",
            itunesTrackID: item.trackId
        )
    }

    private func mapAlbumResult(_ item: ITunesResult) -> Album? {
        guard let title = item.collectionName else { return nil }
        let artworkURL = item.artworkUrl100.flatMap { URL(string: $0.replacingOccurrences(of: "100x100", with: "300x300")) }
        let artworkLarge = item.artworkUrl100.flatMap { URL(string: $0.replacingOccurrences(of: "100x100", with: "600x600")) }
        return Album(
            id: "itunes_album_\(item.collectionId ?? Int.random(in: 1...999999))",
            title: title,
            artistName: item.artistName ?? NSLocalizedString("unknown_artist", comment: ""),
            artistID: item.artistId.map { "itunes_artist_\($0)" },
            artworkURL: artworkURL,
            artworkURLLarge: artworkLarge,
            releaseDate: item.releaseDate.flatMap { Date.fromISO8601($0) },
            trackCount: item.trackCount ?? 0,
            genre: item.primaryGenreName,
            itunesAlbumID: item.collectionId
        )
    }

    private func mapArtistResult(_ item: ITunesResult) -> Artist? {
        guard let name = item.artistName else { return nil }
        return Artist(
            id: "itunes_artist_\(item.artistId ?? Int.random(in: 1...999999))",
            name: name,
            genres: [item.primaryGenreName].compactMap { $0 },
            itunesArtistID: item.artistId
        )
    }

    private func mapAlbumFromLookup(_ response: ITunesSearchResponse) -> Album? {
        let albumItem = response.results.first { $0.wrapperType == "collection" }
        guard let albumItem else { return nil }
        var album = mapAlbumResult(albumItem) ?? Album(id: UUID().uuidString, title: "Unknown", artistName: "Unknown", ownerID: "", ownerName: "")
        album.tracks = response.results
            .filter { $0.wrapperType == "track" }
            .compactMap { mapTrackResult($0) }
        return album
    }

    private func mapArtistFromLookup(_ response: ITunesSearchResponse, artistID: Int) -> Artist? {
        let artistItem = response.results.first { $0.wrapperType == "artist" }
        let name = artistItem?.artistName ?? "Unknown Artist"
        let tracks = response.results
            .filter { $0.wrapperType == "track" }
            .compactMap { mapTrackResult($0) }
        return Artist(
            id: "itunes_artist_\(artistID)",
            name: name,
            genres: artistItem?.primaryGenreName.map { [$0] } ?? [],
            topTracks: tracks,
            itunesArtistID: artistID
        )
    }
}

// MARK: - Album init extension
extension Album {
    init(id: String, title: String, artistName: String, ownerID: String, ownerName: String) {
        self.init(id: id, title: title, artistName: artistName)
    }
}

// MARK: - iTunes Response DTOs
struct ITunesSearchResponse: Codable {
    let resultCount: Int
    let results: [ITunesResult]
}

struct ITunesResult: Codable {
    let wrapperType: String?
    let kind: String?
    let artistId: Int?
    let collectionId: Int?
    let trackId: Int?
    let artistName: String?
    let collectionName: String?
    let trackName: String?
    let previewUrl: String?
    let artworkUrl60: String?
    let artworkUrl100: String?
    let collectionPrice: Double?
    let trackPrice: Double?
    let releaseDate: String?
    let collectionExplicitness: String?
    let trackExplicitness: String?
    let discCount: Int?
    let discNumber: Int?
    let trackCount: Int?
    let trackNumber: Int?
    let trackTimeMillis: Int?
    let country: String?
    let currency: String?
    let primaryGenreName: String?
    let isStreamable: Bool?
    let artistViewUrl: String?
    let collectionViewUrl: String?
    let trackViewUrl: String?
}
