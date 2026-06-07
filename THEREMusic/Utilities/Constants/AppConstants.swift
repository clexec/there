import Foundation
import UIKit

enum AppConstants {

    // MARK: - App Info
    static let appName          = "THERE Music"
    static let appNameShort     = "THERE"
    static let bundleID         = "com.there.music"
    static let appVersion       = "1.0.0"
    static let buildNumber      = "1"

    // MARK: - Keychain
    enum Keychain {
        static let serviceName          = "com.there.music.keychain"
        static let appleTokenKey        = "apple_identity_token"
        static let googleTokenKey       = "google_access_token"
        static let googleRefreshKey     = "google_refresh_token"
        static let emailAuthKey         = "email_auth_session"
        static let userIDKey            = "current_user_id"
        static let biometricKey         = "biometric_auth_enabled"
    }

    // MARK: - UserDefaults
    enum Defaults {
        static let isOnboarded          = "isOnboarded"
        static let isAuthenticated      = "isAuthenticated"
        static let currentUserID        = "currentUserID"
        static let currentTheme         = "currentTheme"
        static let selectedLanguage     = "selectedLanguage"
        static let lastSearchQuery      = "lastSearchQuery"
        static let playerVolume         = "playerVolume"
        static let shuffleEnabled       = "shuffleEnabled"
        static let repeatMode           = "repeatMode"
        static let autoplayEnabled      = "autoplayEnabled"
        static let downloadOnWifi       = "downloadOnWifi"
        static let streamQuality        = "streamQuality"
        static let notificationsEnabled = "notificationsEnabled"
        static let discoverNotif        = "discoverWeeklyNotif"
        static let releaseNotif         = "releaseRadarNotif"
        static let searchHistory        = "searchHistory"
        static let recentSearches       = "recentSearches"
        static let lastProvider         = "lastAuthProvider"
        static let cacheSize            = "cacheSize"
        static let maxCacheGB           = "maxCacheGB"
        static let crossfadeDuration    = "crossfadeDuration"
        static let equalizerPreset      = "equalizerPreset"
        static let showLyrics           = "showLyrics"
        static let explicitContent      = "explicitContent"
    }

    // MARK: - CoreData
    enum CoreData {
        static let modelName            = "THEREMusic"
        static let containerName        = "THEREMusicContainer"
    }

    // MARK: - Networking
    enum Network {
        static let requestTimeout: TimeInterval = 30
        static let resourceTimeout: TimeInterval = 60
        static let maxRetries               = 3
        static let retryDelay: TimeInterval = 2
        static let maxConcurrentRequests    = 10
    }

    // MARK: - Cache
    enum Cache {
        static let imageCacheName       = "THEREImageCache"
        static let dataCacheName        = "THEREDataCache"
        static let maxImageDiskMB: Int  = 500
        static let maxDataDiskMB: Int   = 100
        static let maxMemoryMB: Int     = 50
        static let imageTTL: TimeInterval = 86400 * 7
        static let dataTTL: TimeInterval  = 3600
    }

    // MARK: - Player
    enum Player {
        static let miniPlayerHeight: CGFloat     = 64
        static let miniPlayerCornerRadius: CGFloat = 12
        static let progressUpdateInterval: TimeInterval = 0.5
        static let seekDebounce: TimeInterval    = 0.1
        static let maxQueueSize: Int             = 500
        static let crossfadeRange: ClosedRange<Double> = 0...12
        static let defaultCrossfade: Double      = 0
        static let skipBackwardSeconds: Double   = 10
        static let skipForwardSeconds: Double    = 30
    }

    // MARK: - Search
    enum Search {
        static let debounceMS: Int              = 300
        static let maxHistoryItems: Int         = 50
        static let maxResults: Int              = 25
        static let minQueryLength: Int          = 1
    }

    // MARK: - Library
    enum Library {
        static let maxPlaylistNameLength: Int   = 100
        static let maxPlaylistDescLength: Int   = 300
        static let maxTracksPerPlaylist: Int    = 10000
        static let maxCommentLength: Int        = 500
    }

    // MARK: - Auth
    enum Auth {
        static let minPasswordLength: Int       = 8
        static let maxPasswordLength: Int       = 64
        static let sessionDuration: TimeInterval = 86400 * 30
        static let tokenRefreshBuffer: TimeInterval = 3600
    }

    // MARK: - UI
    enum UI {
        static let animationFast: Double        = 0.2
        static let animationMedium: Double      = 0.35
        static let animationSlow: Double        = 0.5
        static let springResponse: Double       = 0.45
        static let springDamping: Double        = 0.8
        static let cornerRadiusSmall: CGFloat   = 6
        static let cornerRadiusMedium: CGFloat  = 12
        static let cornerRadiusLarge: CGFloat   = 20
        static let cornerRadiusXL: CGFloat      = 32
        static let shadowRadius: CGFloat        = 12
        static let cardWidth: CGFloat           = 160
        static let cardHeight: CGFloat          = 200
        static let tabBarHeight: CGFloat        = 80
        static let navBarHeight: CGFloat        = 56
    }

    // MARK: - Notifications
    enum Notifications {
        static let discoverWeeklyID     = "discover_weekly"
        static let releaseRadarID       = "release_radar"
        static let newFolloweeRelease   = "new_followee_release"
        static let categoryID           = "com.there.music.notifications"
    }

    // MARK: - Analytics Events
    enum Analytics {
        static let trackPlayed          = "track_played"
        static let trackLiked           = "track_liked"
        static let trackShared          = "track_shared"
        static let playlistCreated      = "playlist_created"
        static let artistFollowed       = "artist_followed"
        static let searchPerformed      = "search_performed"
        static let authSuccess          = "auth_success"
        static let authFailed           = "auth_failed"
        static let appOpened            = "app_opened"
        static let sessionStarted       = "session_started"
    }

    // MARK: - Deep Links
    enum DeepLinks {
        static let scheme               = "theremusic"
        static let trackPath            = "track"
        static let albumPath            = "album"
        static let artistPath           = "artist"
        static let playlistPath         = "playlist"
    }
}
