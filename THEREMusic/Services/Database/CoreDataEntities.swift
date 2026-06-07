import CoreData

// MARK: - UserEntity
@objc(UserEntity)
public class UserEntity: NSManagedObject {
    @NSManaged public var id: String?
    @NSManaged public var email: String?
    @NSManaged public var displayName: String?
    @NSManaged public var avatarData: Data?
    @NSManaged public var provider: String?
    @NSManaged public var passwordHash: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var lastLoginAt: Date?
    @NSManaged public var isPremium: Bool

    public static func fetchRequest() -> NSFetchRequest<UserEntity> {
        NSFetchRequest<UserEntity>(entityName: "UserEntity")
    }
}

// MARK: - TrackEntity
@objc(TrackEntity)
public class TrackEntity: NSManagedObject {
    @NSManaged public var id: String?
    @NSManaged public var title: String?
    @NSManaged public var artistName: String?
    @NSManaged public var artistID: String?
    @NSManaged public var albumTitle: String?
    @NSManaged public var albumID: String?
    @NSManaged public var artworkURLString: String?
    @NSManaged public var previewURLString: String?
    @NSManaged public var durationMs: Int32
    @NSManaged public var genre: String?
    @NSManaged public var isLiked: Bool
    @NSManaged public var isDownloaded: Bool
    @NSManaged public var isExplicit: Bool
    @NSManaged public var playCount: Int32
    @NSManaged public var lastPlayedAt: Date?
    @NSManaged public var addedAt: Date?
    @NSManaged public var ownerID: String?
    @NSManaged public var itunesTrackID: Int64

    public static func fetchRequest() -> NSFetchRequest<TrackEntity> {
        NSFetchRequest<TrackEntity>(entityName: "TrackEntity")
    }
}

// MARK: - CommentEntity
@objc(CommentEntity)
public class CommentEntity: NSManagedObject {
    @NSManaged public var id: String?
    @NSManaged public var trackID: String?
    @NSManaged public var userID: String?
    @NSManaged public var userName: String?
    @NSManaged public var text: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var isEdited: Bool
    @NSManaged public var likesCount: Int32

    public static func fetchRequest() -> NSFetchRequest<CommentEntity> {
        NSFetchRequest<CommentEntity>(entityName: "CommentEntity")
    }
}

// MARK: - PlaylistEntity
@objc(PlaylistEntity)
public class PlaylistEntity: NSManagedObject {
    @NSManaged public var id: String?
    @NSManaged public var name: String?
    @NSManaged public var playlistDescription: String?
    @NSManaged public var ownerID: String?
    @NSManaged public var ownerName: String?
    @NSManaged public var isPublic: Bool
    @NSManaged public var isByTHERE: Bool
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var tracksData: Data?

    public static func fetchRequest() -> NSFetchRequest<PlaylistEntity> {
        NSFetchRequest<PlaylistEntity>(entityName: "PlaylistEntity")
    }
}
