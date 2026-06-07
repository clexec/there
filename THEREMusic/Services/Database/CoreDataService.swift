import Foundation
import CoreData

// MARK: - PersistenceController
final class PersistenceController {

    static let shared = PersistenceController()

    let container: NSPersistentContainer

    private init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: AppConstants.CoreData.modelName)
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.persistentStoreDescriptions.first?.setOption(
            true as NSNumber,
            forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey
        )
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.loadPersistentStores { _, error in
            if let error { fatalError("CoreData load failed: \(error)") }
        }
    }

    static var preview: PersistenceController {
        PersistenceController(inMemory: true)
    }

    func newBackgroundContext() -> NSManagedObjectContext {
        let ctx = container.newBackgroundContext()
        ctx.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        ctx.automaticallyMergesChangesFromParent = true
        return ctx
    }

    func save(context: NSManagedObjectContext? = nil) {
        let ctx = context ?? container.viewContext
        guard ctx.hasChanges else { return }
        do { try ctx.save() } catch { print("CoreData save error: \(error)") }
    }

    func performBackground(_ block: @escaping (NSManagedObjectContext) -> Void) {
        container.performBackgroundTask(block)
    }
}

// MARK: - CoreDataManager
final class CoreDataManager {

    static let shared = CoreDataManager()
    private let controller: PersistenceController

    private init(controller: PersistenceController = .shared) {
        self.controller = controller
    }

    var viewContext: NSManagedObjectContext { controller.container.viewContext }

    // MARK: - Generic Fetch
    func fetch<T: NSManagedObject>(_ type: T.Type, predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor] = [], limit: Int? = nil) throws -> [T] {
        let request = NSFetchRequest<T>(entityName: String(describing: type))
        request.predicate = predicate
        request.sortDescriptors = sortDescriptors
        if let limit { request.fetchLimit = limit }
        return try viewContext.fetch(request)
    }

    func fetchAsync<T: NSManagedObject>(_ type: T.Type, predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor] = [], limit: Int? = nil) async throws -> [T] {
        let context = controller.newBackgroundContext()
        return try await context.perform {
            let request = NSFetchRequest<T>(entityName: String(describing: type))
            request.predicate = predicate
            request.sortDescriptors = sortDescriptors
            if let limit { request.fetchLimit = limit }
            return try context.fetch(request)
        }
    }

    func count<T: NSManagedObject>(_ type: T.Type, predicate: NSPredicate? = nil) throws -> Int {
        let request = NSFetchRequest<T>(entityName: String(describing: type))
        request.predicate = predicate
        return try viewContext.count(for: request)
    }

    func delete(_ object: NSManagedObject) {
        viewContext.delete(object)
        controller.save()
    }

    func deleteAll<T: NSManagedObject>(_ type: T.Type, predicate: NSPredicate? = nil) throws {
        let objects = try fetch(type, predicate: predicate)
        objects.forEach { viewContext.delete($0) }
        controller.save()
    }

    func save() { controller.save() }
}

// MARK: - CoreDataService
final class CoreDataService {

    static let shared = CoreDataService()
    private let manager: CoreDataManager

    private init(manager: CoreDataManager = .shared) {
        self.manager = manager
    }

    // MARK: - User CRUD
    func saveUser(_ user: User) async {
        let context = PersistenceController.shared.newBackgroundContext()
        await context.perform {
            let request = UserEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", user.id)
            let entity = (try? context.fetch(request))?.first ?? UserEntity(context: context)
            entity.id = user.id
            entity.email = user.email
            entity.displayName = user.displayName
            entity.avatarData = user.avatarData
            entity.provider = user.provider.rawValue
            entity.createdAt = user.createdAt
            entity.lastLoginAt = user.lastLoginAt
            entity.isPremium = user.isPremium
            try? context.save()
        }
    }

    func fetchUser(id: String) async -> User? {
        let context = PersistenceController.shared.newBackgroundContext()
        return await context.perform {
            let request = UserEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id)
            request.fetchLimit = 1
            guard let entity = try? context.fetch(request).first else { return nil }
            return User(
                id: entity.id ?? id,
                email: entity.email,
                displayName: entity.displayName ?? "User",
                avatarData: entity.avatarData,
                provider: AuthProviderType(rawValue: entity.provider ?? "email") ?? .email,
                createdAt: entity.createdAt ?? Date(),
                lastLoginAt: entity.lastLoginAt ?? Date(),
                isPremium: entity.isPremium
            )
        }
    }

    func deleteUser(id: String) async {
        let context = PersistenceController.shared.newBackgroundContext()
        await context.perform {
            let request = UserEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id)
            if let entity = try? context.fetch(request).first {
                context.delete(entity)
                try? context.save()
            }
        }
    }

    // MARK: - Track CRUD
    func saveTrack(_ track: Track, userID: String) async {
        let context = PersistenceController.shared.newBackgroundContext()
        await context.perform {
            let request = TrackEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@ AND ownerID == %@", track.id, userID)
            let entity = (try? context.fetch(request))?.first ?? TrackEntity(context: context)
            entity.id = track.id
            entity.title = track.title
            entity.artistName = track.artistName
            entity.artistID = track.artistID
            entity.albumTitle = track.albumTitle
            entity.albumID = track.albumID
            entity.artworkURLString = track.artworkURL?.absoluteString
            entity.previewURLString = track.previewURL?.absoluteString
            entity.durationMs = Int32(track.durationMs)
            entity.genre = track.genre
            entity.isLiked = track.isLiked
            entity.isDownloaded = track.isDownloaded
            entity.playCount = Int32(track.playCount)
            entity.lastPlayedAt = track.lastPlayedAt
            entity.addedAt = track.addedAt
            entity.ownerID = userID
            entity.itunesTrackID = Int64(track.itunesTrackID ?? 0)
            entity.isExplicit = track.isExplicit
            try? context.save()
        }
    }

    func fetchLikedTracks(userID: String) async -> [Track] {
        let context = PersistenceController.shared.newBackgroundContext()
        return await context.perform {
            let request = TrackEntity.fetchRequest()
            request.predicate = NSPredicate(format: "ownerID == %@ AND isLiked == YES", userID)
            request.sortDescriptors = [NSSortDescriptor(key: "addedAt", ascending: false)]
            let entities = (try? context.fetch(request)) ?? []
            return entities.map { Self.entityToTrack($0) }
        }
    }

    func fetchRecentlyPlayed(userID: String, limit: Int = 50) async -> [Track] {
        let context = PersistenceController.shared.newBackgroundContext()
        return await context.perform {
            let request = TrackEntity.fetchRequest()
            request.predicate = NSPredicate(format: "ownerID == %@ AND lastPlayedAt != nil", userID)
            request.sortDescriptors = [NSSortDescriptor(key: "lastPlayedAt", ascending: false)]
            request.fetchLimit = limit
            let entities = (try? context.fetch(request)) ?? []
            return entities.map { Self.entityToTrack($0) }
        }
    }

    func updateTrackLike(trackID: String, userID: String, isLiked: Bool) async {
        let context = PersistenceController.shared.newBackgroundContext()
        await context.perform {
            let request = TrackEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@ AND ownerID == %@", trackID, userID)
            if let entity = (try? context.fetch(request))?.first {
                entity.isLiked = isLiked
                try? context.save()
            }
        }
    }

    func updatePlayCount(trackID: String, userID: String, playedAt: Date) async {
        let context = PersistenceController.shared.newBackgroundContext()
        await context.perform {
            let request = TrackEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@ AND ownerID == %@", trackID, userID)
            if let entity = (try? context.fetch(request))?.first {
                entity.playCount += 1
                entity.lastPlayedAt = playedAt
                try? context.save()
            }
        }
    }

    // MARK: - Comment CRUD
    func saveComment(_ comment: Comment) async {
        let context = PersistenceController.shared.newBackgroundContext()
        await context.perform {
            let request = CommentEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", comment.id)
            let entity = (try? context.fetch(request))?.first ?? CommentEntity(context: context)
            entity.id = comment.id
            entity.trackID = comment.trackID
            entity.userID = comment.userID
            entity.userName = comment.userName
            entity.text = comment.text
            entity.createdAt = comment.createdAt
            entity.updatedAt = comment.updatedAt
            entity.isEdited = comment.isEdited
            entity.likesCount = Int32(comment.likesCount)
            try? context.save()
        }
    }

    func fetchComments(for trackID: String) async -> [Comment] {
        let context = PersistenceController.shared.newBackgroundContext()
        return await context.perform {
            let request = CommentEntity.fetchRequest()
            request.predicate = NSPredicate(format: "trackID == %@", trackID)
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
            let entities = (try? context.fetch(request)) ?? []
            return entities.map {
                Comment(
                    id: $0.id ?? UUID().uuidString,
                    trackID: $0.trackID ?? trackID,
                    userID: $0.userID ?? "",
                    userName: $0.userName ?? "User",
                    text: $0.text ?? "",
                    createdAt: $0.createdAt ?? Date(),
                    updatedAt: $0.updatedAt,
                    isEdited: $0.isEdited,
                    likesCount: Int($0.likesCount)
                )
            }
        }
    }

    func deleteComment(id: String) async {
        let context = PersistenceController.shared.newBackgroundContext()
        await context.perform {
            let request = CommentEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id)
            if let entity = (try? context.fetch(request))?.first {
                context.delete(entity)
                try? context.save()
            }
        }
    }

    // MARK: - Playlist CRUD
    func savePlaylists(_ playlists: [Playlist], userID: String) async {
        let context = PersistenceController.shared.newBackgroundContext()
        await context.perform {
            for playlist in playlists {
                let request = PlaylistEntity.fetchRequest()
                request.predicate = NSPredicate(format: "id == %@ AND ownerID == %@", playlist.id, userID)
                let entity = (try? context.fetch(request))?.first ?? PlaylistEntity(context: context)
                entity.id = playlist.id
                entity.name = playlist.name
                entity.playlistDescription = playlist.description
                entity.ownerID = userID
                entity.ownerName = playlist.ownerName
                entity.isPublic = playlist.isPublic
                entity.isByTHERE = playlist.isByTHERE
                entity.createdAt = playlist.createdAt
                entity.updatedAt = playlist.updatedAt
                if let trackData = try? JSONEncoder().encode(playlist.tracks) {
                    entity.tracksData = trackData
                }
            }
            try? context.save()
        }
    }

    func fetchPlaylists(userID: String) async -> [Playlist] {
        let context = PersistenceController.shared.newBackgroundContext()
        return await context.perform {
            let request = PlaylistEntity.fetchRequest()
            request.predicate = NSPredicate(format: "ownerID == %@", userID)
            request.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
            let entities = (try? context.fetch(request)) ?? []
            return entities.compactMap { entity -> Playlist? in
                var tracks: [Track] = []
                if let data = entity.tracksData {
                    tracks = (try? JSONDecoder().decode([Track].self, from: data)) ?? []
                }
                return Playlist(
                    id: entity.id ?? UUID().uuidString,
                    name: entity.name ?? "Playlist",
                    description: entity.playlistDescription,
                    ownerID: entity.ownerID ?? userID,
                    ownerName: entity.ownerName ?? "Me",
                    tracks: tracks,
                    isPublic: entity.isPublic,
                    isByTHERE: entity.isByTHERE,
                    createdAt: entity.createdAt ?? Date(),
                    updatedAt: entity.updatedAt ?? Date(),
                    isSaved: true
                )
            }
        }
    }

    func deletePlaylist(id: String, userID: String) async {
        let context = PersistenceController.shared.newBackgroundContext()
        await context.perform {
            let request = PlaylistEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@ AND ownerID == %@", id, userID)
            if let entity = (try? context.fetch(request))?.first {
                context.delete(entity)
                try? context.save()
            }
        }
    }

    // MARK: - Helpers
    static func entityToTrack(_ entity: TrackEntity) -> Track {
        Track(
            id: entity.id ?? UUID().uuidString,
            title: entity.title ?? "",
            artistName: entity.artistName ?? "",
            artistID: entity.artistID,
            albumTitle: entity.albumTitle,
            albumID: entity.albumID,
            artworkURL: entity.artworkURLString.flatMap { URL(string: $0) },
            previewURL: entity.previewURLString.flatMap { URL(string: $0) },
            durationMs: Int(entity.durationMs),
            genre: entity.genre,
            isExplicit: entity.isExplicit,
            itunesTrackID: entity.itunesTrackID != 0 ? Int(entity.itunesTrackID) : nil,
            isLiked: entity.isLiked,
            isDownloaded: entity.isDownloaded,
            playCount: Int(entity.playCount),
            lastPlayedAt: entity.lastPlayedAt,
            addedAt: entity.addedAt
        )
    }
}
