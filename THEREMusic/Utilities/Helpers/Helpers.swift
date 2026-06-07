import Foundation
import UIKit
import UserNotifications

// MARK: - ValidationHelper
struct ValidationHelper {

    static func validateEmail(_ email: String) -> ValidationResult {
        let trimmed = email.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return .invalid(NSLocalizedString("error_invalid_email", comment: "")) }
        guard trimmed.isValidEmail else { return .invalid(NSLocalizedString("error_invalid_email", comment: "")) }
        return .valid
    }

    static func validatePassword(_ password: String) -> ValidationResult {
        guard password.count >= AppConstants.Auth.minPasswordLength else {
            return .invalid(String(format: NSLocalizedString("error_weak_password", comment: ""), AppConstants.Auth.minPasswordLength))
        }
        guard password.hasUppercase else { return .invalid(NSLocalizedString("error_weak_password", comment: "")) }
        guard password.hasLowercase else { return .invalid(NSLocalizedString("error_weak_password", comment: "")) }
        guard password.hasDigit     else { return .invalid(NSLocalizedString("error_weak_password", comment: "")) }
        return .valid
    }

    static func validateDisplayName(_ name: String) -> ValidationResult {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 2 else { return .invalid("Name must be at least 2 characters") }
        guard trimmed.count <= 50 else { return .invalid("Name must be 50 characters or less") }
        return .valid
    }

    static func validatePlaylistName(_ name: String) -> ValidationResult {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return .invalid("Playlist name cannot be empty") }
        guard trimmed.count <= AppConstants.Library.maxPlaylistNameLength else {
            return .invalid("Name must be \(AppConstants.Library.maxPlaylistNameLength) characters or less")
        }
        return .valid
    }

    static func validateComment(_ text: String) -> ValidationResult {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return .invalid("Comment cannot be empty") }
        guard trimmed.count <= AppConstants.Library.maxCommentLength else {
            return .invalid("Comment must be \(AppConstants.Library.maxCommentLength) characters or less")
        }
        return .valid
    }
}

// MARK: - ValidationResult
enum ValidationResult {
    case valid
    case invalid(String)
    var isValid: Bool { if case .valid = self { return true }; return false }
    var errorMessage: String? { if case .invalid(let msg) = self { return msg }; return nil }
}

// MARK: - TimeFormatHelper
struct TimeFormatHelper {

    static func format(seconds: Double) -> String {
        seconds.formattedDuration
    }

    static func format(milliseconds: Int) -> String {
        (Double(milliseconds) / 1000).formattedDuration
    }

    static func shortFormat(seconds: Double) -> String {
        let total = Int(seconds)
        let minutes = total / 60
        let secs = total % 60
        return String(format: "%d:%02d", minutes, secs)
    }

    static func totalDuration(tracks: [Track]) -> String {
        let total = tracks.reduce(0) { $0 + $1.durationMs }
        return format(milliseconds: total)
    }
}

// MARK: - ImageLoaderHelper
@MainActor
final class ImageLoaderHelper: ObservableObject {

    @Published var image: UIImage?
    @Published var isLoading: Bool = false

    private let cache = ImageCacheService.shared
    private var currentURL: URL?

    func load(from url: URL?) {
        guard let url, url != currentURL else { return }
        currentURL = url
        if let cached = cache.image(for: url) { image = cached; return }
        isLoading = true
        Task {
            do {
                let loaded = try await cache.downloadImage(from: url)
                if currentURL == url { image = loaded }
            } catch {}
            isLoading = false
        }
    }

    func cancel() { currentURL = nil; isLoading = false }
}

// MARK: - NotificationManager
final class NotificationManager {

    static let shared = NotificationManager()
    private init() {}

    func scheduleDiscoverWeekly() {
        var components = DateComponents()
        components.weekday = 2
        components.hour    = 8
        components.minute  = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let content = UNMutableNotificationContent()
        content.title = AppConstants.appName
        content.body  = NSLocalizedString("section_discover_weekly", comment: "")
        content.sound = .default
        content.badge = 1
        let request = UNNotificationRequest(identifier: AppConstants.Notifications.discoverWeeklyID, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func scheduleReleaseRadar() {
        var components = DateComponents()
        components.weekday = 6
        components.hour    = 10
        components.minute  = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let content = UNMutableNotificationContent()
        content.title = AppConstants.appName
        content.body  = NSLocalizedString("section_release_radar", comment: "")
        content.sound = .default
        let request = UNNotificationRequest(identifier: AppConstants.Notifications.releaseRadarID, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func scheduleNewRelease(artistName: String, albumTitle: String) {
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("section_new_releases", comment: "")
        content.body  = "\(artistName) — \(albumTitle)"
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let id = "\(AppConstants.Notifications.newFolloweeRelease)_\(UUID().uuidString)"
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    func cancelNotification(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }
}

// MARK: - AnalyticsManager
final class AnalyticsManager {

    static let shared = AnalyticsManager()
    private init() {}
    private var sessionStart: Date?

    func trackAppOpened() {
        sessionStart = Date()
        log(event: AppConstants.Analytics.appOpened)
    }

    func trackTrackPlayed(_ track: Track) {
        log(event: AppConstants.Analytics.trackPlayed, params: [
            "track_id": track.id,
            "artist":   track.artistName,
            "genre":    track.genre ?? "unknown"
        ])
    }

    func trackLiked(_ track: Track) {
        log(event: AppConstants.Analytics.trackLiked, params: ["track_id": track.id])
    }

    func trackShared(_ track: Track) {
        log(event: AppConstants.Analytics.trackShared, params: ["track_id": track.id])
    }

    func trackSearchPerformed(query: String, resultCount: Int) {
        log(event: AppConstants.Analytics.searchPerformed, params: [
            "query": query,
            "results": String(resultCount)
        ])
    }

    func trackAuthSuccess(provider: AuthProviderType) {
        log(event: AppConstants.Analytics.authSuccess, params: ["provider": provider.rawValue])
    }

    func trackAuthFailed(provider: AuthProviderType, error: String) {
        log(event: AppConstants.Analytics.authFailed, params: [
            "provider": provider.rawValue,
            "error":    error
        ])
    }

    private func log(event: String, params: [String: String] = [:]) {
        #if DEBUG
        print("[Analytics] \(event) — \(params)")
        #endif
    }
}
