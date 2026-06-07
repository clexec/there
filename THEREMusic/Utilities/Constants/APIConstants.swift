import Foundation

enum APIConstants {

    // MARK: - iTunes
    enum iTunes {
        static let baseURL              = "https://itunes.apple.com"
        static let searchPath           = "/search"
        static let lookupPath           = "/lookup"
        static let topChartsPath        = "/us/rss"
        static let defaultLimit: Int    = 25
        static let maxLimit: Int        = 200
        static let country              = "us"
        static let mediaType            = "music"

        enum MediaKind {
            static let song             = "song"
            static let album            = "album"
            static let artist           = "musicArtist"
            static let playlist         = "playlist"
        }
    }

    // MARK: - Last.fm
    enum LastFM {
        static let baseURL              = "https://ws.audioscrobbler.com/2.0/"
        static let apiKey               = "YOUR_LASTFM_API_KEY"
        static let secret               = "YOUR_LASTFM_SECRET"
        static let format               = "json"
        static let defaultLimit: Int    = 20

        enum Method {
            static let trackSearch      = "track.search"
            static let trackGetInfo     = "track.getInfo"
            static let trackGetSimilar  = "track.getSimilar"
            static let artistGetInfo    = "artist.getInfo"
            static let artistGetSimilar = "artist.getSimilar"
            static let artistTopTracks  = "artist.getTopTracks"
            static let artistTopAlbums  = "artist.getTopAlbums"
            static let albumGetInfo     = "album.getInfo"
            static let chartGetTracks   = "chart.getTopTracks"
            static let chartGetArtists  = "chart.getTopArtists"
            static let userGetTopTracks = "user.getTopTracks"
            static let tagGetTopTracks  = "tag.getTopTracks"
            static let tagGetTopArtists = "tag.getTopArtists"
        }
    }

    // MARK: - MusicBrainz
    enum MusicBrainz {
        static let baseURL              = "https://musicbrainz.org/ws/2"
        static let userAgent            = "THEREMusic/1.0 (contact@theremusic.app)"
        static let format               = "json"
    }

    // MARK: - Deezer
    enum Deezer {
        static let baseURL              = "https://api.deezer.com"
        static let searchPath           = "/search"
        static let trackPath            = "/track"
        static let albumPath            = "/album"
        static let artistPath           = "/artist"
        static let chartPath            = "/chart"
        static let defaultLimit: Int    = 25
    }

    // MARK: - Google OAuth
    enum Google {
        static let clientID             = "YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com"
        static let reverseClientID      = "com.googleusercontent.apps.YOUR_GOOGLE_CLIENT_ID"
        static let scopes               = ["profile", "email"]
    }

    // MARK: - Headers
    enum Headers {
        static let contentType          = "Content-Type"
        static let accept               = "Accept"
        static let authorization        = "Authorization"
        static let userAgent            = "User-Agent"
        static let appJSON              = "application/json"
        static let userAgentValue       = "THEREMusic/1.0 iOS"
    }

    // MARK: - HTTP Status
    enum Status {
        static let ok                   = 200
        static let created              = 201
        static let noContent            = 204
        static let badRequest           = 400
        static let unauthorized         = 401
        static let forbidden            = 403
        static let notFound             = 404
        static let tooManyRequests      = 429
        static let serverError          = 500
    }
}
