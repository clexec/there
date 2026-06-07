// Paste this into your THEREMusicApp.swift onFirstAppear
// or run once via DatabaseSeeder.shared.seedIfNeeded()

import Foundation
import CoreData

// MARK: - DatabaseSeeder
final class DatabaseSeeder {

    static let shared = DatabaseSeeder()
    private let defaults = UserDefaults.standard
    private let seededKey = "database_seeded_v1"

    private init() {}

    func seedIfNeeded(context: NSManagedObjectContext) async {
        guard !defaults.bool(forKey: seededKey) else { return }
        await seed(context: context)
        defaults.set(true, forKey: seededKey)
    }

    // MARK: - Load from seed.json bundled in app
    private func seed(context: NSManagedObjectContext) async {
        guard let url = Bundle.main.url(forResource: "seed", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let seed = try? JSONDecoder().decode(SeedData.self, from: data)
        else {
            print("[Seeder] seed.json not found in bundle")
            return
        }

        print("[Seeder] Seeding \(seed.tracks.count) tracks from bundle...")

        await context.perform {
            for t in seed.tracks {
                let entity = TrackEntity(context: context)
                entity.id            = t.id
                entity.title         = t.title
                entity.artistName    = t.artistName
                entity.artistID      = t.artistId
                entity.albumTitle    = t.albumTitle
                entity.albumID       = t.albumId
                entity.artworkURLString = t.artworkUrl
                entity.previewURLString = t.previewUrl
                entity.durationMs    = Int32(t.durationMs ?? 0)
                entity.genre         = t.genre
                entity.isExplicit    = t.isExplicit == 1
                entity.itunesTrackID = Int64(t.itunesTrackId ?? 0)
                entity.ownerID       = "seed"
                entity.addedAt       = Date()
            }
            try? context.save()
        }

        print("[Seeder] Done seeding.")
    }
}

// MARK: - Seed DTOs
private struct SeedData: Decodable {
    let artists: [SeedArtist]
    let albums:  [SeedAlbum]
    let tracks:  [SeedTrack]
}

private struct SeedArtist: Decodable {
    let id, name: String
    let itunesId: Int?
    let genre, photoUrl: String?
    enum CodingKeys: String, CodingKey {
        case id, name, genre
        case itunesId  = "itunes_id"
        case photoUrl  = "photo_url"
    }
}

private struct SeedAlbum: Decodable {
    let id, title, artistName: String
    let artworkUrl, artworkLarge, releaseDate, genre: String?
    let itunesId, trackCount: Int?
    enum CodingKeys: String, CodingKey {
        case id, title, genre
        case artistName  = "artist_name"
        case artworkUrl  = "artwork_url"
        case artworkLarge = "artwork_large"
        case releaseDate = "release_date"
        case itunesId    = "itunes_id"
        case trackCount  = "track_count"
    }
}

private struct SeedTrack: Decodable {
    let id, title, artistName: String
    let artistId, albumId, albumTitle: String?
    let artworkUrl, previewUrl, genre, releaseDate: String?
    let durationMs, itunesTrackId, isExplicit, trackNumber: Int?
    enum CodingKeys: String, CodingKey {
        case id, title, genre
        case artistName   = "artist_name"
        case artistId     = "artist_id"
        case albumId      = "album_id"
        case albumTitle   = "album_title"
        case artworkUrl   = "artwork_url"
        case previewUrl   = "preview_url"
        case releaseDate  = "release_date"
        case durationMs   = "duration_ms"
        case itunesTrackId = "itunes_track_id"
        case isExplicit   = "is_explicit"
        case trackNumber  = "track_number"
    }
}
