import SwiftUI

// MARK: - LibraryView
struct LibraryView: View {
    @StateObject private var viewModel = LibraryViewModel()
    @EnvironmentObject private var libraryManager: LibraryManager
    @EnvironmentObject private var playerManager: PlayerManager

    var body: some View {
        ZStack {
            ColorPalette.backgroundBlack.ignoresSafeArea()
            VStack(spacing: 0) {
                libraryHeader
                tabSelector
                content
            }
        }
        .navigationTitle("")
        .navigationBarHidden(true)
    }

    private var libraryHeader: some View {
        HStack {
            Text(NSLocalizedString("your_library", comment: ""))
                .font(.system(size: UIConstants.FontSize.title2, weight: .bold))
                .foregroundStyle(ColorPalette.textPrimary)
            Spacer()
            HStack(spacing: UIConstants.Spacing.sm) {
                IconButton(systemName: "magnifyingglass") {}
                Button {
                    viewModel.isCreatingPlaylist = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(ColorPalette.textPrimary)
                        .frame(width: 36, height: 36)
                        .glassCard(cornerRadius: UIConstants.Radius.md)
                }
            }
        }
        .padding(.horizontal, UIConstants.Spacing.base)
        .padding(.top, UIConstants.Spacing.base)
        .padding(.bottom, UIConstants.Spacing.sm)
    }

    private var tabSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: UIConstants.Spacing.sm) {
                ForEach(LibraryTab.allCases, id: \.rawValue) { tab in
                    Button {
                        withAnimation(UIConstants.Animation.fast) { viewModel.selectedTab = tab }
                    } label: {
                        Text(tab.localizedTitle)
                            .font(.system(size: UIConstants.FontSize.footnote, weight: .semibold))
                            .foregroundStyle(viewModel.selectedTab == tab ? ColorPalette.backgroundBlack : ColorPalette.textPrimary)
                            .padding(.horizontal, UIConstants.Spacing.md)
                            .padding(.vertical, UIConstants.Spacing.xs)
                            .background { Capsule().fill(viewModel.selectedTab == tab ? ColorPalette.primaryGreen : ColorPalette.surface3) }
                    }
                    .scaleOnPress()
                }
            }
            .padding(.horizontal, UIConstants.Spacing.base)
            .padding(.bottom, UIConstants.Spacing.sm)
        }
    }

    @ViewBuilder
    private var content: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                switch viewModel.selectedTab {
                case .playlists:
                    likedSongsCard
                    ForEach(viewModel.playlists) { playlist in
                        NavigationLink(destination: PlaylistDetailView(playlist: playlist)) {
                            PlaylistRowView(playlist: playlist)
                        }
                        .buttonStyle(.plain)
                        Divider().background(ColorPalette.surface3).padding(.leading, 72)
                    }
                case .albums:
                    ForEach(viewModel.savedAlbums) { album in
                        NavigationLink(destination: AlbumDetailView(album: album)) {
                            AlbumRowView(album: album)
                        }
                        .buttonStyle(.plain)
                        Divider().background(ColorPalette.surface3).padding(.leading, 72)
                    }
                case .artists:
                    ForEach(viewModel.followingArtists) { artist in
                        NavigationLink(destination: ArtistDetailView(artist: artist)) {
                            ArtistRowView(artist: artist)
                        }
                        .buttonStyle(.plain)
                        Divider().background(ColorPalette.surface3).padding(.leading, 72)
                    }
                case .songs:
                    ForEach(viewModel.likedTracks) { track in
                        TrackRowView(track: track) {
                            playerManager.play(track: track, queue: viewModel.likedTracks)
                        }
                        Divider().background(ColorPalette.surface3).padding(.leading, 72)
                    }
                }
                bottomPadding
            }
        }
        .scrollIndicators(.hidden)
    }

    private var likedSongsCard: some View {
        NavigationLink(destination: LikedSongsView()) {
            HStack(spacing: UIConstants.Spacing.md) {
                ZStack {
                    LinearGradient(
                        colors: [Color(hex: "#4A6CF7"), Color(hex: "#B33EFF")],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                    .frame(width: 56, height: 56)
                    .cornerRadius(UIConstants.Radius.sm)
                    Image(systemName: "heart.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(NSLocalizedString("liked_songs", comment: ""))
                        .font(.system(size: UIConstants.FontSize.subheadline, weight: .semibold))
                        .foregroundStyle(ColorPalette.textPrimary)
                    Text(String(format: NSLocalizedString("track_count", comment: ""), viewModel.likedTracks.count))
                        .font(.system(size: UIConstants.FontSize.caption))
                        .foregroundStyle(ColorPalette.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundStyle(ColorPalette.textTertiary)
            }
            .padding(.horizontal, UIConstants.Spacing.base)
            .padding(.vertical, UIConstants.Spacing.md)
        }
        .buttonStyle(.plain)
    }

    private var bottomPadding: some View {
        Color.clear.frame(height: AppConstants.Player.miniPlayerHeight + AppConstants.UI.tabBarHeight + UIConstants.Spacing.xl)
    }
}

// MARK: - FavoritesView
struct FavoritesView: View {
    @EnvironmentObject private var libraryManager: LibraryManager
    @EnvironmentObject private var playerManager: PlayerManager
    @State private var sortOption: SortOption = .dateAdded

    var body: some View {
        ZStack {
            ColorPalette.backgroundBlack.ignoresSafeArea()
            if libraryManager.likedTracks.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        favHeader
                        ForEach(sortedTracks) { track in
                            TrackRowView(track: track) {
                                playerManager.play(track: track, queue: sortedTracks)
                            }
                            Divider().background(ColorPalette.surface3).padding(.leading, 72)
                        }
                        bottomPadding
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
        .navigationTitle(NSLocalizedString("tab_favorites", comment: ""))
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    ForEach(SortOption.allCases, id: \.rawValue) { option in
                        Button {
                            sortOption = option
                        } label: {
                            Label(option.localizedTitle, systemImage: option.systemImage)
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                        .foregroundStyle(ColorPalette.textPrimary)
                }
            }
        }
    }

    private var sortedTracks: [Track] {
        switch sortOption {
        case .title, .alphabetical: return libraryManager.likedTracks.sorted { $0.title < $1.title }
        case .artist:               return libraryManager.likedTracks.sorted { $0.artistName < $1.artistName }
        case .duration:             return libraryManager.likedTracks.sorted { $0.durationMs > $1.durationMs }
        case .recentlyPlayed:       return libraryManager.likedTracks.sorted { ($0.lastPlayedAt ?? .distantPast) > ($1.lastPlayedAt ?? .distantPast) }
        default:                    return libraryManager.likedTracks
        }
    }

    private var favHeader: some View {
        HStack(spacing: UIConstants.Spacing.base) {
            ZStack {
                LinearGradient(colors: [Color(hex: "#4A6CF7"), Color(hex: "#B33EFF")], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .frame(width: 100, height: 100).cornerRadius(UIConstants.Radius.md)
                Image(systemName: "heart.fill").font(.system(size: 40)).foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: UIConstants.Spacing.xs) {
                Text(NSLocalizedString("liked_songs", comment: ""))
                    .font(.system(size: UIConstants.FontSize.title3, weight: .bold))
                    .foregroundStyle(ColorPalette.textPrimary)
                Text(String(format: NSLocalizedString("track_count", comment: ""), libraryManager.likedTracks.count))
                    .font(.system(size: UIConstants.FontSize.footnote))
                    .foregroundStyle(ColorPalette.textSecondary)
                Button {
                    playerManager.play(
                        track: libraryManager.likedTracks[0],
                        queue: libraryManager.likedTracks
                    )
                } label: {
                    HStack(spacing: UIConstants.Spacing.xs) {
                        Image(systemName: "play.fill")
                        Text(NSLocalizedString("play_all", comment: ""))
                    }
                    .font(.system(size: UIConstants.FontSize.footnote, weight: .bold))
                    .foregroundStyle(ColorPalette.backgroundBlack)
                    .padding(.horizontal, UIConstants.Spacing.md)
                    .padding(.vertical, UIConstants.Spacing.xs)
                    .background(Capsule().fill(ColorPalette.primaryGreen))
                }
                .scaleOnPress()
                .disabled(libraryManager.likedTracks.isEmpty)
            }
        }
        .padding(.horizontal, UIConstants.Spacing.base)
        .padding(.vertical, UIConstants.Spacing.xl)
    }

    private var emptyState: some View {
        VStack(spacing: UIConstants.Spacing.base) {
            Image(systemName: "heart").font(.system(size: 64)).foregroundStyle(ColorPalette.textTertiary)
            Text(NSLocalizedString("no_liked_songs", comment: ""))
                .font(.system(size: UIConstants.FontSize.title3, weight: .bold))
                .foregroundStyle(ColorPalette.textPrimary)
            Text(NSLocalizedString("no_liked_songs_subtitle", comment: ""))
                .font(.system(size: UIConstants.FontSize.body))
                .foregroundStyle(ColorPalette.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, UIConstants.Spacing.xxl)
    }

    private var bottomPadding: some View {
        Color.clear.frame(height: AppConstants.Player.miniPlayerHeight + AppConstants.UI.tabBarHeight + UIConstants.Spacing.xl)
    }
}

// MARK: - LikedSongsView
struct LikedSongsView: View {
    @EnvironmentObject private var libraryManager: LibraryManager
    @EnvironmentObject private var playerManager: PlayerManager

    var body: some View {
        FavoritesView()
    }
}

// MARK: - CreateView
struct CreateView: View {
    @StateObject private var viewModel = LibraryViewModel()
    @EnvironmentObject private var libraryManager: LibraryManager
    @State private var showNewPlaylist: Bool = false
    @State private var playlistName: String = ""
    @State private var playlistDescription: String = ""

    var body: some View {
        ZStack {
            ColorPalette.backgroundBlack.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: UIConstants.Spacing.xl) {
                    createPlaylistCard
                    if !libraryManager.playlists.isEmpty {
                        myPlaylistsSection
                    }
                    bottomPadding
                }
                .padding(.horizontal, UIConstants.Spacing.base)
            }
        }
        .navigationTitle(NSLocalizedString("tab_create", comment: ""))
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showNewPlaylist) { newPlaylistSheet }
    }

    private var createPlaylistCard: some View {
        Button { showNewPlaylist = true } label: {
            HStack(spacing: UIConstants.Spacing.base) {
                ZStack {
                    RoundedRectangle(cornerRadius: UIConstants.Radius.md)
                        .fill(ColorPalette.surface3).frame(width: 64, height: 64)
                    Image(systemName: "plus")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(ColorPalette.primaryGreen)
                }
                VStack(alignment: .leading, spacing: UIConstants.Spacing.xs) {
                    Text(NSLocalizedString("create_playlist", comment: ""))
                        .font(.system(size: UIConstants.FontSize.subheadline, weight: .bold))
                        .foregroundStyle(ColorPalette.textPrimary)
                    Text(NSLocalizedString("create_playlist_subtitle", comment: ""))
                        .font(.system(size: UIConstants.FontSize.caption))
                        .foregroundStyle(ColorPalette.textSecondary)
                }
                Spacer()
            }
            .padding(UIConstants.Spacing.base)
            .glassCard()
        }
        .scaleOnPress()
        .padding(.top, UIConstants.Spacing.base)
    }

    private var myPlaylistsSection: some View {
        VStack(alignment: .leading, spacing: UIConstants.Spacing.md) {
            Text(NSLocalizedString("my_playlists", comment: ""))
                .font(.system(size: UIConstants.FontSize.title3, weight: .bold))
                .foregroundStyle(ColorPalette.textPrimary)
            ForEach(libraryManager.playlists) { playlist in
                NavigationLink(destination: PlaylistDetailView(playlist: playlist)) {
                    PlaylistRowView(playlist: playlist)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var newPlaylistSheet: some View {
        NavigationStack {
            VStack(spacing: UIConstants.Spacing.xl) {
                ZStack {
                    RoundedRectangle(cornerRadius: UIConstants.Radius.xl)
                        .fill(ColorPalette.surface3).frame(width: 150, height: 150)
                    Image(systemName: "music.note.list")
                        .font(.system(size: 60)).foregroundStyle(ColorPalette.textTertiary)
                }
                VStack(spacing: UIConstants.Spacing.md) {
                    TextField(NSLocalizedString("playlist_name_placeholder", comment: ""), text: $playlistName)
                        .font(.system(size: UIConstants.FontSize.title3, weight: .bold))
                        .foregroundStyle(ColorPalette.textPrimary)
                        .multilineTextAlignment(.center)
                    TextField(NSLocalizedString("playlist_description_placeholder", comment: ""), text: $playlistDescription, axis: .vertical)
                        .font(.system(size: UIConstants.FontSize.body))
                        .foregroundStyle(ColorPalette.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(1...3)
                }
                .padding(.horizontal, UIConstants.Spacing.xl)
                Spacer()
            }
            .padding(.top, UIConstants.Spacing.xl)
            .background(ColorPalette.backgroundBlack.ignoresSafeArea())
            .navigationTitle(NSLocalizedString("new_playlist", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(NSLocalizedString("cancel", comment: "")) { showNewPlaylist = false }
                        .foregroundStyle(ColorPalette.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(NSLocalizedString("create", comment: "")) {
                        Task {
                            await viewModel.createPlaylist()
                            showNewPlaylist = false
                        }
                    }
                    .foregroundStyle(playlistName.isEmpty ? ColorPalette.textTertiary : ColorPalette.primaryGreen)
                    .disabled(playlistName.isEmpty)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var bottomPadding: some View {
        Color.clear.frame(height: AppConstants.Player.miniPlayerHeight + AppConstants.UI.tabBarHeight)
    }
}
