import Foundation

// MARK: - RepeatMode
enum RepeatMode: String, Codable, CaseIterable {
    case off        = "off"
    case all        = "all"
    case one        = "one"

    var nextMode: RepeatMode {
        switch self {
        case .off: return .all
        case .all: return .one
        case .one: return .off
        }
    }

    var systemImageName: String {
        switch self {
        case .off: return "repeat"
        case .all: return "repeat"
        case .one: return "repeat.1"
        }
    }

    var isActive: Bool { self != .off }

    var localizedTitle: String {
        switch self {
        case .off: return NSLocalizedString("repeat_off", comment: "")
        case .all: return NSLocalizedString("repeat_all", comment: "")
        case .one: return NSLocalizedString("repeat_one", comment: "")
        }
    }
}

// MARK: - PlayerStateEnum
enum PlayerStateEnum: String, Codable, Equatable {
    case idle       = "idle"
    case loading    = "loading"
    case playing    = "playing"
    case paused     = "paused"
    case stopped    = "stopped"
    case error      = "error"
    case buffering  = "buffering"
    case seeking    = "seeking"

    var isPlayingOrBuffering: Bool {
        self == .playing || self == .buffering
    }
}

// MARK: - SortOption
enum SortOption: String, CaseIterable, Codable {
    case title          = "title"
    case artist         = "artist"
    case album          = "album"
    case dateAdded      = "dateAdded"
    case duration       = "duration"
    case playCount      = "playCount"
    case recentlyPlayed = "recentlyPlayed"
    case alphabetical   = "alphabetical"

    var localizedTitle: String {
        switch self {
        case .title:          return NSLocalizedString("sort_title", comment: "")
        case .artist:         return NSLocalizedString("sort_artist", comment: "")
        case .album:          return NSLocalizedString("sort_album", comment: "")
        case .dateAdded:      return NSLocalizedString("sort_date_added", comment: "")
        case .duration:       return NSLocalizedString("sort_duration", comment: "")
        case .playCount:      return NSLocalizedString("sort_play_count", comment: "")
        case .recentlyPlayed: return NSLocalizedString("sort_recently_played", comment: "")
        case .alphabetical:   return NSLocalizedString("sort_alphabetical", comment: "")
        }
    }

    var systemImage: String {
        switch self {
        case .title, .alphabetical: return "textformat.abc"
        case .artist:               return "person"
        case .album:                return "square.stack"
        case .dateAdded:            return "calendar"
        case .duration:             return "clock"
        case .playCount:            return "play.circle"
        case .recentlyPlayed:       return "clock.arrow.circlepath"
        }
    }
}

// MARK: - FilterOption
enum FilterOption: String, CaseIterable, Codable {
    case all            = "all"
    case playlists      = "playlists"
    case albums         = "albums"
    case artists        = "artists"
    case podcasts       = "podcasts"
    case downloaded     = "downloaded"
    case liked          = "liked"

    var localizedTitle: String {
        switch self {
        case .all:          return NSLocalizedString("filter_all", comment: "")
        case .playlists:    return NSLocalizedString("filter_playlists", comment: "")
        case .albums:       return NSLocalizedString("filter_albums", comment: "")
        case .artists:      return NSLocalizedString("filter_artists", comment: "")
        case .podcasts:     return NSLocalizedString("filter_podcasts", comment: "")
        case .downloaded:   return NSLocalizedString("filter_downloaded", comment: "")
        case .liked:        return NSLocalizedString("filter_liked", comment: "")
        }
    }
}

// MARK: - Theme
enum Theme: String, CaseIterable, Codable {
    case dark           = "dark"
    case light          = "light"
    case system         = "system"

    var localizedTitle: String {
        switch self {
        case .dark:   return NSLocalizedString("theme_dark", comment: "")
        case .light:  return NSLocalizedString("theme_light", comment: "")
        case .system: return NSLocalizedString("theme_system", comment: "")
        }
    }

    var systemImage: String {
        switch self {
        case .dark:   return "moon.fill"
        case .light:  return "sun.max.fill"
        case .system: return "gear"
        }
    }
}

// MARK: - ErrorType
enum AppErrorType: Error, LocalizedError {
    case networkUnavailable
    case requestTimeout
    case serverError(Int)
    case decodingFailed
    case unauthorized
    case notFound
    case rateLimited
    case authFailed(String)
    case keychainError(String)
    case coreDataError(String)
    case playerError(String)
    case unknown(String)
    case invalidInput(String)
    case permissionDenied
    case cacheMiss
    case biometricFailed

    var errorDescription: String? {
        switch self {
        case .networkUnavailable:       return NSLocalizedString("error_network", comment: "")
        case .requestTimeout:           return NSLocalizedString("error_timeout", comment: "")
        case .serverError(let code):    return String(format: NSLocalizedString("error_server", comment: ""), code)
        case .decodingFailed:           return NSLocalizedString("error_decoding", comment: "")
        case .unauthorized:             return NSLocalizedString("error_unauthorized", comment: "")
        case .notFound:                 return NSLocalizedString("error_not_found", comment: "")
        case .rateLimited:              return NSLocalizedString("error_rate_limited", comment: "")
        case .authFailed(let msg):      return msg
        case .keychainError(let msg):   return msg
        case .coreDataError(let msg):   return msg
        case .playerError(let msg):     return msg
        case .unknown(let msg):         return msg
        case .invalidInput(let msg):    return msg
        case .permissionDenied:         return NSLocalizedString("error_permission", comment: "")
        case .cacheMiss:                return NSLocalizedString("error_cache_miss", comment: "")
        case .biometricFailed:          return NSLocalizedString("error_biometric", comment: "")
        }
    }

    var isRecoverable: Bool {
        switch self {
        case .networkUnavailable, .requestTimeout, .rateLimited: return true
        default: return false
        }
    }
}

// MARK: - AuthProviderType
enum AuthProviderType: String, Codable, CaseIterable {
    case apple   = "apple"
    case google  = "google"
    case email   = "email"

    var localizedTitle: String {
        switch self {
        case .apple:  return "Apple"
        case .google: return "Google"
        case .email:  return NSLocalizedString("auth_email", comment: "")
        }
    }

    var systemImage: String {
        switch self {
        case .apple:  return "applelogo"
        case .google: return "g.circle.fill"
        case .email:  return "envelope.fill"
        }
    }
}

// MARK: - StreamQuality
enum StreamQuality: String, CaseIterable, Codable {
    case low    = "low"
    case normal = "normal"
    case high   = "high"
    case very_high = "very_high"

    var localizedTitle: String {
        switch self {
        case .low:       return NSLocalizedString("quality_low", comment: "")
        case .normal:    return NSLocalizedString("quality_normal", comment: "")
        case .high:      return NSLocalizedString("quality_high", comment: "")
        case .very_high: return NSLocalizedString("quality_very_high", comment: "")
        }
    }

    var bitrate: Int {
        switch self {
        case .low:       return 96
        case .normal:    return 160
        case .high:      return 320
        case .very_high: return 320
        }
    }
}

// MARK: - LibraryTab
enum LibraryTab: String, CaseIterable {
    case playlists = "playlists"
    case albums    = "albums"
    case artists   = "artists"
    case songs     = "songs"

    var localizedTitle: String {
        switch self {
        case .playlists: return NSLocalizedString("library_playlists", comment: "")
        case .albums:    return NSLocalizedString("library_albums", comment: "")
        case .artists:   return NSLocalizedString("library_artists", comment: "")
        case .songs:     return NSLocalizedString("library_songs", comment: "")
        }
    }
}

// MARK: - HomeSection
enum HomeSection: String, CaseIterable, Identifiable, Codable {
    case recentlyPlayed   = "recently_played"
    case discoverWeekly   = "discover_weekly"
    case releaseRadar     = "release_radar"
    case dailyMix1        = "daily_mix_1"
    case dailyMix2        = "daily_mix_2"
    case topCharts        = "top_charts"
    case newReleases      = "new_releases"
    case recommended      = "recommended"
    case featuredArtists  = "featured_artists"
    case genres           = "genres"

    var id: String { rawValue }

    var localizedTitle: String {
        switch self {
        case .recentlyPlayed:  return NSLocalizedString("section_recently_played", comment: "")
        case .discoverWeekly:  return NSLocalizedString("section_discover_weekly", comment: "")
        case .releaseRadar:    return NSLocalizedString("section_release_radar", comment: "")
        case .dailyMix1:       return NSLocalizedString("section_daily_mix_1", comment: "")
        case .dailyMix2:       return NSLocalizedString("section_daily_mix_2", comment: "")
        case .topCharts:       return NSLocalizedString("section_top_charts", comment: "")
        case .newReleases:     return NSLocalizedString("section_new_releases", comment: "")
        case .recommended:     return NSLocalizedString("section_recommended", comment: "")
        case .featuredArtists: return NSLocalizedString("section_featured_artists", comment: "")
        case .genres:          return NSLocalizedString("section_genres", comment: "")
        }
    }
}
