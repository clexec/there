import Foundation
import UIKit

// MARK: - ImageCacheService
final class ImageCacheService {

    static let shared = ImageCacheService()

    private let memoryCache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL

    private init() {
        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = caches.appendingPathComponent(AppConstants.Cache.imageCacheName)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        memoryCache.totalCostLimit = AppConstants.Cache.maxMemoryMB * 1024 * 1024
        memoryCache.countLimit = 200
    }

    // MARK: - Store
    func store(_ image: UIImage, for url: URL) {
        let key = cacheKey(for: url)
        memoryCache.setObject(image, forKey: key as NSString, cost: imageCost(image))
        let filePath = cacheDirectory.appendingPathComponent(key)
        if let data = image.jpegData(compressionQuality: 0.85) {
            try? data.write(to: filePath)
        }
    }

    // MARK: - Retrieve
    func image(for url: URL) -> UIImage? {
        let key = cacheKey(for: url)
        if let cached = memoryCache.object(forKey: key as NSString) { return cached }
        let filePath = cacheDirectory.appendingPathComponent(key)
        guard fileManager.fileExists(atPath: filePath.path),
              let data = try? Data(contentsOf: filePath),
              let image = UIImage(data: data) else { return nil }
        memoryCache.setObject(image, forKey: key as NSString, cost: imageCost(image))
        return image
    }

    // MARK: - Download
    func downloadImage(from url: URL) async throws -> UIImage {
        if let cached = image(for: url) { return cached }
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let image = UIImage(data: data) else {
            throw AppErrorType.decodingFailed
        }
        store(image, for: url)
        return image
    }

    // MARK: - Remove
    func remove(for url: URL) {
        let key = cacheKey(for: url)
        memoryCache.removeObject(forKey: key as NSString)
        let filePath = cacheDirectory.appendingPathComponent(key)
        try? fileManager.removeItem(at: filePath)
    }

    func clearAll() {
        memoryCache.removeAllObjects()
        if let files = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil) {
            files.forEach { try? fileManager.removeItem(at: $0) }
        }
    }

    // MARK: - Cache Size
    var diskCacheSizeBytes: Int64 {
        guard let files = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) else { return 0 }
        return files.reduce(0) { acc, url in
            let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            return acc + Int64(size)
        }
    }

    var diskCacheSizeMB: Double { Double(diskCacheSizeBytes) / 1_048_576 }

    // MARK: - Helpers
    private func cacheKey(for url: URL) -> String {
        url.absoluteString
            .components(separatedBy: .alphanumerics.inverted)
            .joined()
            .prefix(64)
            .description
    }

    private func imageCost(_ image: UIImage) -> Int {
        Int(image.size.width * image.size.height * image.scale * image.scale * 4)
    }
}

// MARK: - DataCacheService
final class DataCacheService {

    static let shared = DataCacheService()
    private var cache: [String: CacheEntry] = [:]
    private let queue = DispatchQueue(label: "com.there.music.datacache", attributes: .concurrent)

    private init() {}

    private struct CacheEntry {
        let data: Data
        let expiresAt: Date
        var isExpired: Bool { Date() > expiresAt }
    }

    func set<T: Codable>(_ value: T, key: String, ttl: TimeInterval = AppConstants.Cache.dataTTL) throws {
        let data = try JSONEncoder().encode(value)
        queue.async(flags: .barrier) {
            self.cache[key] = CacheEntry(data: data, expiresAt: Date().addingTimeInterval(ttl))
        }
    }

    func get<T: Codable>(key: String) throws -> T? {
        return queue.sync {
            guard let entry = cache[key], !entry.isExpired else { return nil }
            return try? JSONDecoder().decode(T.self, from: entry.data)
        }
    }

    func remove(key: String) {
        queue.async(flags: .barrier) { self.cache.removeValue(forKey: key) }
    }

    func clearExpired() {
        queue.async(flags: .barrier) {
            self.cache = self.cache.filter { !$0.value.isExpired }
        }
    }

    func clearAll() {
        queue.async(flags: .barrier) { self.cache.removeAll() }
    }
}
