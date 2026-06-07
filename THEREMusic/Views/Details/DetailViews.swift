import SwiftUI

// MARK: - ArtistDetailView
struct ArtistDetailView: View {
    let artist: Artist
    @StateObject private var viewModel: ArtistDetailViewModel
    @EnvironmentObject private var playerManager: PlayerManager
    @EnvironmentObject private var libraryManager: LibraryManager

    init(artist: Artist) {
        self.artist = artist
        _viewModel = StateObject(wrappedValue: ArtistDetailViewModel(artist: artist))
    }

    var body: some View {
        ZStack {
            ColorPalette.backgroundBlack.ignoresSafeArea()
            ScrollView {
                LazyVStack(spacing: 0) {
                    artistHeader
                    actionButtons
                    if !viewModel.topTracks.isEmpty {
                        topTracksSection
                    }
                    if !viewModel.albums.isEmpty {
                        albumsSection
                    }
                    bottomPadding
                }
            }
            .scrollIndicators(.hidden)
            .ignoresSafeArea(edges: .top)
            if viewModel.isLoading { loadingOverlay }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onFirstAppear { Task { await viewModel.load() } }
        .toolbar { toolbarContent }
    }

    private var artistHeader: some View {
        ZStack(alignment: .bottom) {
            GeometryReader { geo in
                AsyncArtworkView(url: viewModel.artist.photoURL ?? viewModel.artist.headerURL, size: geo.size.width, isCircle: false)
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.width)
                    .clipped()
            }
            .frame(height: UIScreen.main.bounds.width)
            .gradientOverlay(
                colors: [.clear, ColorPalette.backgroundBlack.opacity(0.5), ColorPalette.backgroundBlack],
                startPoint: .top, endPoint: .bottom
            )
            VStack(alignment: .leading, spacing: UIConstants.Spacing.xs) {
                Text(viewModel.artist.name)
                    .font(.system(size: UIConstants.FontSize.largeTitle, weight: .black))
                    .foregroundStyle(.white)
                if let followers = viewModel.artist.followers {
                    Text(String(format: NSLocalizedString("followers_count", comment: ""), followers.formattedCount))
                        .font(.system(size: UIConstants.FontSize.footnote))
                        .foregroundStyle(ColorPalette.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, UIConstants.Spacing.base)
            .padding(.bottom, UIConstants.Spacing.xl)
        }
    }

    private var actionButtons: some View {
        HStack(spacing: UIConstants.Spacing.md) {
            Button {
                if let first = viewModel.topTracks.first {
                    playerManager.play(track: first, queue: viewModel.topTracks)
                }
            } label: {
                HStack(spacing: UIConstants.Spacing.sm) {
                    Image(systemName: "play.fill")
                    Text(NSLocalizedString("play", comment: ""))
                }
                .font(.system(size: UIConstants.FontSize.callout, weight: .bold))
                .foregroundStyle(ColorPalette.backgroundBlack)
                .frame(maxWidth: .infinity).frame(height: 44)
                .background(Capsule().fill(ColorPalette.primaryGreen))
            }
            .scaleOnPress()

            Button {
                viewModel.toggleFollow()
            } label: {
                Text(viewModel.isFollowing ? NSLocalizedString("following", comment: "") : NSLocalizedString("follow", comment: ""))
                    .font(.system(size: UIConstants.FontSize.callout, weight: .semibold))
                    .foregroundStyle(viewModel.isFollowing ? ColorPalette.primaryGreen : ColorPalette.textPrimary)
                    .frame(width: 120).frame(height: 44)
                    .background {
                        Capsule().strokeBorder(viewModel.isFollowing ? ColorPalette.primaryGreen : ColorPalette.textSecondary, lineWidth: 1.5)
                    }
            }
            .scaleOnPress()

            Spacer()

            Button {} label: {
                Image(systemName: "ellipsis")
                    .foregroundStyle(ColorPalette.textSecondary)
                    .frame(width: 40, height: 44)
                    .glassCard(cornerRadius: UIConstants.Radius.md)
            }
        }
        .padding(.horizontal, UIConstants.Spacing.base)
        .padding(.vertical, UIConstants.Spacing.base)
    }

    private var topTracksSection: some View {
        VStack(alignment: .leading, spacing: UIConstants.Spacing.sm) {
            Text(NSLocalizedString("popular", comment: ""))
                .font(.system(size: UIConstants.FontSize.title3, weight: .bold))
                .foregroundStyle(ColorPalette.textPrimary)
                .padding(.horizontal, UIConstants.Spacing.base)
            ForEach(Array(viewModel.topTracks.prefix(5).enumerated()), id: \.element.id) { idx, track in
                TopChartRow(rank: idx + 1, track: track) {
                    playerManager.play(track: track, queue: viewModel.topTracks, startIndex: idx)
                }
                if idx < 4 { Divider().background(ColorPalette.surface3).padding(.leading, 70) }
            }
        }
        .padding(.bottom, UIConstants.Spacing.xl)
    }

    private var albumsSection: some View {
        VStack(alignment: .leading, spacing: UIConstants.Spacing.md) {
            SectionHeader(title: NSLocalizedString("albums", comment: ""))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: UIConstants.Spacing.md) {
                    ForEach(viewModel.albums) { album in
                        NavigationLink(destination: AlbumDetailView(album: album)) {
                            AlbumCard(album: album)
                        }.buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, UIConstants.Spacing.base)
            }
        }
        .padding(.bottom, UIConstants.Spacing.xl)
    }

    private var loadingOverlay: some View {
        ProgressView().tint(ColorPalette.primaryGreen).scaleEffect(1.5)
    }

    private var bottomPadding: some View {
        Color.clear.frame(height: AppConstants.Player.miniPlayerHeight + AppConstants.UI.tabBarHeight + UIConstants.Spacing.xl)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {} label: {
                Image(systemName: "square.and.arrow.up").foregroundStyle(ColorPalette.textPrimary)
            }
        }
    }
}

// MARK: - AlbumDetailView
struct AlbumDetailView: View {
    let album: Album
    @StateObject private var viewModel: AlbumDetailViewModel
    @EnvironmentObject private var playerManager: PlayerManager
    @EnvironmentObject private var libraryManager: LibraryManager

    init(album: Album) {
        self.album = album
        _viewModel = StateObject(wrappedValue: AlbumDetailViewModel(album: album))
    }

    var body: some View {
        ZStack {
            ColorPalette.backgroundBlack.ignoresSafeArea()
            ScrollView {
                LazyVStack(spacing: 0) {
                    albumHeader
                    albumActions
                    if viewModel.isLoading {
                        ProgressView().tint(ColorPalette.primaryGreen).padding(UIConstants.Spacing.xxl)
                    } else {
                        ForEach(Array(viewModel.tracks.enumerated()), id: \.element.id) { idx, track in
                            AlbumTrackRow(track: track, index: idx + 1) {
                                playerManager.play(track: track, queue: viewModel.tracks, startIndex: idx)
                            }
                            if idx < viewModel.tracks.count - 1 {
                                Divider().background(ColorPalette.surface3).padding(.leading, 60)
                            }
                        }
                    }
                    albumFooter
                    bottomPadding
                }
            }
            .scrollIndicators(.hidden)
            .ignoresSafeArea(edges: .top)
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onFirstAppear { Task { await viewModel.load() } }
    }

    private var albumHeader: some View {
        VStack(spacing: UIConstants.Spacing.base) {
            AsyncArtworkView(url: viewModel.album.artworkURLLarge ?? viewModel.album.artworkURL, size: 220)
                .cornerRadius(UIConstants.Radius.lg)
                .cardShadow()
                .padding(.top, UIConstants.Spacing.xxl)
            VStack(spacing: UIConstants.Spacing.xs) {
                Text(viewModel.album.title)
                    .font(.system(size: UIConstants.FontSize.title2, weight: .bold))
                    .foregroundStyle(ColorPalette.textPrimary)
                    .multilineTextAlignment(.center)
                NavigationLink(destination: ArtistDetailView(artist: Artist(name: viewModel.album.artistName))) {
                    Text(viewModel.album.artistName)
                        .font(.system(size: UIConstants.FontSize.body))
                        .foregroundStyle(ColorPalette.primaryGreen)
                }
                HStack(spacing: UIConstants.Spacing.xs) {
                    if let year = viewModel.album.year {
                        Text(String(year))
                    }
                    if let genre = viewModel.album.genre {
                        Text("·")
                        Text(genre)
                    }
                    Text("·")
                    Text(String(format: NSLocalizedString("track_count", comment: ""), viewModel.album.trackCount))
                }
                .font(.system(size: UIConstants.FontSize.caption))
                .foregroundStyle(ColorPalette.textSecondary)
            }
        }
        .padding(.horizontal, UIConstants.Spacing.base)
        .padding(.bottom, UIConstants.Spacing.md)
    }

    private var albumActions: some View {
        HStack(spacing: UIConstants.Spacing.md) {
            Button {
                if let first = viewModel.tracks.first {
                    playerManager.play(track: first, queue: viewModel.tracks)
                }
            } label: {
                HStack(spacing: UIConstants.Spacing.xs) {
                    Image(systemName: "play.fill")
                    Text(NSLocalizedString("play", comment: ""))
                }
                .font(.system(size: UIConstants.FontSize.callout, weight: .bold))
                .foregroundStyle(ColorPalette.backgroundBlack)
                .frame(maxWidth: .infinity).frame(height: 44)
                .background(Capsule().fill(ColorPalette.primaryGreen))
            }
            .scaleOnPress()

            Button {
                let shuffled = viewModel.tracks.shuffled()
                if let first = shuffled.first {
                    playerManager.play(track: first, queue: shuffled)
                }
            } label: {
                HStack(spacing: UIConstants.Spacing.xs) {
                    Image(systemName: "shuffle")
                    Text(NSLocalizedString("shuffle", comment: ""))
                }
                .font(.system(size: UIConstants.FontSize.callout, weight: .semibold))
                .foregroundStyle(ColorPalette.textPrimary)
                .frame(maxWidth: .infinity).frame(height: 44)
                .background { Capsule().strokeBorder(ColorPalette.textSecondary, lineWidth: 1.5) }
            }
            .scaleOnPress()
        }
        .padding(.horizontal, UIConstants.Spacing.base)
        .padding(.bottom, UIConstants.Spacing.md)
    }

    private var albumFooter: some View {
        VStack(alignment: .leading, spacing: UIConstants.Spacing.xs) {
            if let date = viewModel.album.releaseDate {
                Text(date.formatted_date)
                    .font(.system(size: UIConstants.FontSize.caption))
                    .foregroundStyle(ColorPalette.textTertiary)
            }
            if let copyright = viewModel.album.copyright {
                Text(copyright)
                    .font(.system(size: UIConstants.FontSize.caption2))
                    .foregroundStyle(ColorPalette.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, UIConstants.Spacing.base)
        .padding(.top, UIConstants.Spacing.base)
    }

    private var bottomPadding: some View {
        Color.clear.frame(height: AppConstants.Player.miniPlayerHeight + AppConstants.UI.tabBarHeight + UIConstants.Spacing.xl)
    }
}

struct AlbumTrackRow: View {
    let track: Track
    let index: Int
    let onTap: () -> Void
    @EnvironmentObject private var playerManager: PlayerManager
    var isPlaying: Bool { playerManager.currentTrack?.id == track.id && playerManager.isPlaying }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: UIConstants.Spacing.base) {
                Text("\(index)")
                    .font(.system(size: UIConstants.FontSize.subheadline))
                    .foregroundStyle(isPlaying ? ColorPalette.primaryGreen : ColorPalette.textTertiary)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(track.title)
                        .font(.system(size: UIConstants.FontSize.subheadline, weight: isPlaying ? .bold : .regular))
                        .foregroundStyle(isPlaying ? ColorPalette.primaryGreen : ColorPalette.textPrimary)
                        .lineLimit(1)
                    if track.isExplicit {
                        Text("E")
                            .font(.system(size: UIConstants.FontSize.caption2, weight: .bold))
                            .foregroundStyle(ColorPalette.textTertiary)
                            .padding(.horizontal, 4).padding(.vertical, 1)
                            .background(RoundedRectangle(cornerRadius: 2).fill(ColorPalette.surface3))
                    }
                }
                Spacer()
                if isPlaying { AudioBarsIndicator(color: ColorPalette.primaryGreen) }
                else { Text(track.formattedDuration).font(.system(size: UIConstants.FontSize.caption)).foregroundStyle(ColorPalette.textTertiary) }
                Button {} label: { Image(systemName: "ellipsis").foregroundStyle(ColorPalette.textTertiary).frame(width: 32) }
            }
            .padding(.horizontal, UIConstants.Spacing.base)
            .padding(.vertical, UIConstants.Spacing.md)
        }
        .scaleOnPress()
        .contextMenu { TrackContextMenu(track: track) }
    }
}

// MARK: - PlaylistDetailView
struct PlaylistDetailView: View {
    let playlist: Playlist
    @StateObject private var viewModel: PlaylistDetailViewModel
    @EnvironmentObject private var playerManager: PlayerManager
    @EnvironmentObject private var libraryManager: LibraryManager

    init(playlist: Playlist) {
        self.playlist = playlist
        _viewModel = StateObject(wrappedValue: PlaylistDetailViewModel(playlist: playlist))
    }

    var body: some View {
        ZStack {
            ColorPalette.backgroundBlack.ignoresSafeArea()
            ScrollView {
                LazyVStack(spacing: 0) {
                    playlistHeader
                    playlistActions
                    ForEach(Array(viewModel.playlist.tracks.enumerated()), id: \.element.id) { idx, track in
                        TrackRowView(track: track) {
                            playerManager.play(track: track, queue: viewModel.playlist.tracks, startIndex: idx)
                        }
                        Divider().background(ColorPalette.surface3).padding(.leading, 72)
                    }
                    bottomPadding
                }
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle(viewModel.playlist.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var playlistHeader: some View {
        VStack(spacing: UIConstants.Spacing.base) {
            if let artworkURL = viewModel.playlist.artworkURL {
                AsyncArtworkView(url: artworkURL, size: 200).cornerRadius(UIConstants.Radius.lg).cardShadow()
            } else {
                PlaylistCoverGrid(tracks: viewModel.playlist.coverArtworks, size: 200)
            }
            VStack(spacing: UIConstants.Spacing.xs) {
                Text(viewModel.playlist.name)
                    .font(.system(size: UIConstants.FontSize.title2, weight: .bold))
                    .foregroundStyle(ColorPalette.textPrimary)
                    .multilineTextAlignment(.center)
                if let desc = viewModel.playlist.description {
                    Text(desc).font(.system(size: UIConstants.FontSize.footnote)).foregroundStyle(ColorPalette.textSecondary).multilineTextAlignment(.center)
                }
                HStack(spacing: UIConstants.Spacing.xs) {
                    Text(viewModel.playlist.ownerName)
                    Text("·")
                    Text(String(format: NSLocalizedString("track_count", comment: ""), viewModel.playlist.trackCount))
                }
                .font(.system(size: UIConstants.FontSize.caption)).foregroundStyle(ColorPalette.textSecondary)
            }
        }
        .padding(.horizontal, UIConstants.Spacing.base)
        .padding(.vertical, UIConstants.Spacing.xl)
    }

    private var playlistActions: some View {
        HStack(spacing: UIConstants.Spacing.md) {
            Button {
                if let first = viewModel.playlist.tracks.first {
                    playerManager.playPlaylist(viewModel.playlist)
                    _ = first
                }
            } label: {
                HStack(spacing: UIConstants.Spacing.xs) {
                    Image(systemName: "play.fill")
                    Text(NSLocalizedString("play", comment: ""))
                }
                .font(.system(size: UIConstants.FontSize.callout, weight: .bold))
                .foregroundStyle(ColorPalette.backgroundBlack)
                .frame(maxWidth: .infinity).frame(height: 44)
                .background(Capsule().fill(ColorPalette.primaryGreen))
            }
            .scaleOnPress().disabled(viewModel.playlist.tracks.isEmpty)
            Button {} label: {
                Image(systemName: "ellipsis")
                    .foregroundStyle(ColorPalette.textSecondary).frame(width: 44, height: 44)
                    .glassCard(cornerRadius: UIConstants.Radius.md)
            }
        }
        .padding(.horizontal, UIConstants.Spacing.base).padding(.bottom, UIConstants.Spacing.md)
    }

    private var bottomPadding: some View {
        Color.clear.frame(height: AppConstants.Player.miniPlayerHeight + AppConstants.UI.tabBarHeight + UIConstants.Spacing.xl)
    }
}

// MARK: - PlaylistCoverGrid
struct PlaylistCoverGrid: View {
    let tracks: [URL]
    let size: CGFloat

    var body: some View {
        if tracks.count >= 4 {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 2) {
                ForEach(Array(tracks.prefix(4).enumerated()), id: \.offset) { _, url in
                    AsyncArtworkView(url: url, size: (size - 2) / 2, isCircle: false).scaledToFill()
                }
            }
            .frame(width: size, height: size).cornerRadius(UIConstants.Radius.lg).clipped()
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: UIConstants.Radius.lg).fill(ColorPalette.surface3).frame(width: size, height: size)
                Image(systemName: "music.note.list").font(.system(size: size * 0.3)).foregroundStyle(ColorPalette.textTertiary)
            }
        }
    }
}
