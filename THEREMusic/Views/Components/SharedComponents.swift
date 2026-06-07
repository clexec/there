import SwiftUI

// MARK: - TrackRowView
struct TrackRowView: View {
    let track: Track
    let onTap: () -> Void
    @EnvironmentObject private var playerManager: PlayerManager
    @EnvironmentObject private var libraryManager: LibraryManager
    var isPlaying: Bool { playerManager.currentTrack?.id == track.id && playerManager.isPlaying }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: UIConstants.Spacing.md) {
                ZStack {
                    AsyncArtworkView(url: track.artworkURL, size: 52).cornerRadius(UIConstants.Radius.sm)
                    if isPlaying {
                        RoundedRectangle(cornerRadius: UIConstants.Radius.sm)
                            .fill(Color.black.opacity(0.4)).frame(width: 52, height: 52)
                        AudioBarsIndicator(color: ColorPalette.primaryGreen)
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(track.title)
                        .font(.system(size: UIConstants.FontSize.subheadline, weight: isPlaying ? .bold : .regular))
                        .foregroundStyle(isPlaying ? ColorPalette.primaryGreen : ColorPalette.textPrimary)
                        .lineLimit(1)
                    HStack(spacing: UIConstants.Spacing.xs) {
                        if track.isExplicit {
                            Text("E").font(.system(size: 9, weight: .bold))
                                .foregroundStyle(ColorPalette.textTertiary)
                                .padding(.horizontal, 3).padding(.vertical, 1)
                                .background(RoundedRectangle(cornerRadius: 2).fill(ColorPalette.surface3))
                        }
                        Text(track.artistName)
                            .font(.system(size: UIConstants.FontSize.caption))
                            .foregroundStyle(ColorPalette.textSecondary)
                            .lineLimit(1)
                    }
                }
                Spacer()
                Button {} label: {
                    Image(systemName: "ellipsis").font(.system(size: 16)).foregroundStyle(ColorPalette.textTertiary).frame(width: 36, height: 36)
                }
            }
            .padding(.horizontal, UIConstants.Spacing.base)
            .padding(.vertical, UIConstants.Spacing.sm)
        }
        .scaleOnPress()
        .contextMenu { TrackContextMenu(track: track) }
    }
}

// MARK: - AlbumRowView
struct AlbumRowView: View {
    let album: Album

    var body: some View {
        HStack(spacing: UIConstants.Spacing.md) {
            AsyncArtworkView(url: album.artworkURL, size: 56).cornerRadius(UIConstants.Radius.sm)
            VStack(alignment: .leading, spacing: 2) {
                Text(album.title).font(.system(size: UIConstants.FontSize.subheadline, weight: .semibold)).foregroundStyle(ColorPalette.textPrimary).lineLimit(1)
                HStack(spacing: UIConstants.Spacing.xs) {
                    Text(album.artistName)
                    if let year = album.year { Text("·"); Text(String(year)) }
                }
                .font(.system(size: UIConstants.FontSize.caption)).foregroundStyle(ColorPalette.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 13)).foregroundStyle(ColorPalette.textTertiary)
        }
        .padding(.horizontal, UIConstants.Spacing.base).padding(.vertical, UIConstants.Spacing.sm)
        .scaleOnPress()
    }
}

// MARK: - ArtistRowView
struct ArtistRowView: View {
    let artist: Artist

    var body: some View {
        HStack(spacing: UIConstants.Spacing.md) {
            AsyncArtworkView(url: artist.photoURL, size: 56, isCircle: true)
            VStack(alignment: .leading, spacing: 2) {
                Text(artist.name).font(.system(size: UIConstants.FontSize.subheadline, weight: .semibold)).foregroundStyle(ColorPalette.textPrimary).lineLimit(1)
                Text(NSLocalizedString("artist", comment: "")).font(.system(size: UIConstants.FontSize.caption)).foregroundStyle(ColorPalette.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 13)).foregroundStyle(ColorPalette.textTertiary)
        }
        .padding(.horizontal, UIConstants.Spacing.base).padding(.vertical, UIConstants.Spacing.sm)
        .scaleOnPress()
    }
}

// MARK: - PlaylistRowView
struct PlaylistRowView: View {
    let playlist: Playlist

    var body: some View {
        HStack(spacing: UIConstants.Spacing.md) {
            if let url = playlist.artworkURL {
                AsyncArtworkView(url: url, size: 56).cornerRadius(UIConstants.Radius.sm)
            } else {
                PlaylistCoverGrid(tracks: playlist.coverArtworks, size: 56)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(playlist.name).font(.system(size: UIConstants.FontSize.subheadline, weight: .semibold)).foregroundStyle(ColorPalette.textPrimary).lineLimit(1)
                HStack(spacing: UIConstants.Spacing.xs) {
                    if playlist.isByTHERE { Text(AppConstants.appNameShort).foregroundStyle(ColorPalette.primaryGreen) }
                    else { Text(NSLocalizedString("playlist", comment: "")) }
                    Text("·")
                    Text(String(format: NSLocalizedString("track_count", comment: ""), playlist.trackCount))
                }
                .font(.system(size: UIConstants.FontSize.caption)).foregroundStyle(ColorPalette.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 13)).foregroundStyle(ColorPalette.textTertiary)
        }
        .padding(.horizontal, UIConstants.Spacing.base).padding(.vertical, UIConstants.Spacing.sm)
        .scaleOnPress()
    }
}

// MARK: - AsyncArtworkView
struct AsyncArtworkView: View {
    let url: URL?
    let size: CGFloat
    var isCircle: Bool = false

    var body: some View {
        Group {
            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        placeholderImage
                    default:
                        placeholderImage.shimmer()
                    }
                }
            } else {
                placeholderImage
            }
        }
        .frame(width: size, height: size)
        .clipShape(isCircle ? AnyShape(Circle()) : AnyShape(RoundedRectangle(cornerRadius: 4)))
    }

    private var placeholderImage: some View {
        ZStack {
            Rectangle().fill(ColorPalette.surface3)
            Image(systemName: "music.note")
                .font(.system(size: size * 0.3))
                .foregroundStyle(ColorPalette.textTertiary)
        }
    }
}

// MARK: - AnyShape helper
struct AnyShape: Shape {
    private let pathBuilder: (CGRect) -> Path
    init<S: Shape>(_ shape: S) { pathBuilder = shape.path(in:) }
    func path(in rect: CGRect) -> Path { pathBuilder(rect) }
}

// MARK: - AudioBarsIndicator
struct AudioBarsIndicator: View {
    let color: Color
    @State private var heights: [CGFloat] = [0.3, 0.7, 0.5, 0.8, 0.4]
    @State private var animating = false

    var body: some View {
        HStack(alignment: .bottom, spacing: 1.5) {
            ForEach(0..<5, id: \.self) { i in
                RoundedRectangle(cornerRadius: 1)
                    .fill(color)
                    .frame(width: 2.5, height: heights[i] * 14)
                    .animation(
                        Animation.easeInOut(duration: Double.random(in: 0.3...0.6)).repeatForever(autoreverses: true).delay(Double(i) * 0.1),
                        value: heights[i]
                    )
            }
        }
        .onAppear {
            for i in 0..<5 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.05) {
                    heights[i] = CGFloat.random(in: 0.3...1.0)
                }
            }
        }
    }
}

// MARK: - IconButton
struct IconButton: View {
    let systemName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: UIConstants.IconSize.md))
                .foregroundStyle(ColorPalette.textPrimary)
                .frame(width: 36, height: 36)
                .glassCard(cornerRadius: UIConstants.Radius.md)
        }
        .scaleOnPress()
    }
}

// MARK: - AvatarView
struct AvatarView: View {
    let user: User
    let size: CGFloat

    var body: some View {
        Group {
            if let data = user.avatarData, let img = UIImage(data: data) {
                Image(uiImage: img).resizable().scaledToFill()
            } else if let url = user.avatarURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img): img.resizable().scaledToFill()
                    default:
                        Circle().fill(ColorPalette.surface3)
                            .overlay(Text(user.initials).font(.system(size: size * 0.35, weight: .bold)).foregroundStyle(ColorPalette.textPrimary))
                    }
                }
            } else {
                Circle().fill(ColorPalette.surface3)
                    .overlay(Text(user.initials).font(.system(size: size * 0.35, weight: .bold)).foregroundStyle(ColorPalette.textPrimary))
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(ColorPalette.glassBorder, lineWidth: 1))
    }
}

// MARK: - TrackContextMenu
struct TrackContextMenu: View {
    let track: Track
    @EnvironmentObject private var libraryManager: LibraryManager
    @EnvironmentObject private var playerManager: PlayerManager

    var body: some View {
        Button(libraryManager.isLiked(track) ? NSLocalizedString("remove_from_liked", comment: "") : NSLocalizedString("add_to_liked", comment: ""),
               systemImage: libraryManager.isLiked(track) ? "heart.fill" : "heart") {
            Task { await libraryManager.toggleLike(track: track) }
        }
        Button(NSLocalizedString("add_to_queue", comment: ""), systemImage: "text.badge.plus") {
            playerManager.addToQueue(track)
        }
        NavigationLink(destination: ArtistDetailView(artist: Artist(name: track.artistName))) {
            Label(NSLocalizedString("go_to_artist", comment: ""), systemImage: "person")
        }
        if let albumTitle = track.albumTitle {
            NavigationLink(destination: AlbumDetailView(album: Album(id: track.albumID ?? UUID().uuidString, title: albumTitle, artistName: track.artistName))) {
                Label(NSLocalizedString("go_to_album", comment: ""), systemImage: "square.stack")
            }
        }
        Divider()
        Button(NSLocalizedString("share", comment: ""), systemImage: "square.and.arrow.up") {}
        Button(NSLocalizedString("track_details", comment: ""), systemImage: "info.circle") {}
    }
}

// MARK: - ShareSheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
