import SwiftUI

// MARK: - HomeView
struct HomeView: View {
    let user: User
    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject private var playerManager: PlayerManager
    @EnvironmentObject private var libraryManager: LibraryManager
    @State private var scrollOffset: CGFloat = 0

    var body: some View {
        ZStack(alignment: .top) {
            ColorPalette.backgroundBlack.ignoresSafeArea()
            ScrollView {
                LazyVStack(alignment: .leading, spacing: UIConstants.Spacing.xxl) {
                    headerSection
                    if viewModel.isLoading {
                        HomeSkeletonView()
                    } else {
                        content
                    }
                    bottomPadding
                }
            }
            .scrollIndicators(.hidden)
            .refreshable { await viewModel.refresh(user: user) }
        }
        .navigationTitle("")
        .navigationBarHidden(true)
        .onFirstAppear { Task { await viewModel.load(user: user) } }
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.greeting)
                    .font(.system(size: UIConstants.FontSize.footnote))
                    .foregroundStyle(ColorPalette.textSecondary)
                Text(viewModel.userName.isEmpty ? AppConstants.appName : viewModel.userName)
                    .font(.system(size: UIConstants.FontSize.title2, weight: .bold))
                    .foregroundStyle(ColorPalette.textPrimary)
            }
            Spacer()
            HStack(spacing: UIConstants.Spacing.sm) {
                IconButton(systemName: "bell") {}
                AvatarView(user: user, size: UIConstants.Avatar.small)
            }
        }
        .padding(.horizontal, UIConstants.Spacing.base)
        .padding(.top, UIConstants.Spacing.base)
    }

    @ViewBuilder
    private var content: some View {
        if !viewModel.recentlyPlayed.isEmpty {
            RecentlyPlayedSection(tracks: viewModel.recentlyPlayed)
        }
        if !viewModel.discoverWeekly.isEmpty {
            HorizontalTrackSection(
                title: NSLocalizedString("section_discover_weekly", comment: ""),
                tracks: viewModel.discoverWeekly,
                accentColor: Color(hex: "#1DB954")
            )
        }
        if !viewModel.releaseRadar.isEmpty {
            HorizontalAlbumSection(
                title: NSLocalizedString("section_release_radar", comment: ""),
                albums: viewModel.releaseRadar
            )
        }
        if !viewModel.dailyMix1.isEmpty {
            HorizontalTrackSection(
                title: NSLocalizedString("section_daily_mix_1", comment: ""),
                tracks: viewModel.dailyMix1,
                accentColor: ColorPalette.genreElectronic
            )
        }
        if !viewModel.topCharts.isEmpty {
            TopChartsSection(tracks: viewModel.topCharts)
        }
        if !viewModel.newReleases.isEmpty {
            HorizontalAlbumSection(
                title: NSLocalizedString("section_new_releases", comment: ""),
                albums: viewModel.newReleases
            )
        }
        if !viewModel.featuredArtists.isEmpty {
            FeaturedArtistsSection(artists: viewModel.featuredArtists)
        }
        GenresGridSection(genres: viewModel.genres)
    }

    private var bottomPadding: some View {
        Color.clear.frame(height: AppConstants.Player.miniPlayerHeight + AppConstants.UI.tabBarHeight + UIConstants.Spacing.xl)
    }
}

// MARK: - RecentlyPlayedSection
struct RecentlyPlayedSection: View {
    let tracks: [Track]
    @EnvironmentObject private var playerManager: PlayerManager

    var body: some View {
        VStack(alignment: .leading, spacing: UIConstants.Spacing.md) {
            SectionHeader(title: NSLocalizedString("section_recently_played", comment: ""))
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: UIConstants.Spacing.sm) {
                ForEach(tracks.prefix(6)) { track in
                    RecentTrackCard(track: track) {
                        playerManager.play(track: track, queue: tracks)
                    }
                }
            }
            .padding(.horizontal, UIConstants.Spacing.base)
        }
    }
}

struct RecentTrackCard: View {
    let track: Track
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: UIConstants.Spacing.sm) {
                AsyncArtworkView(url: track.artworkURL, size: 48)
                    .cornerRadius(UIConstants.Radius.sm)
                Text(track.title)
                    .font(.system(size: UIConstants.FontSize.footnote, weight: .semibold))
                    .foregroundStyle(ColorPalette.textPrimary)
                    .lineLimit(2)
                Spacer()
            }
            .padding(UIConstants.Spacing.sm)
            .glassBackground(cornerRadius: UIConstants.Radius.md)
        }
        .scaleOnPress()
    }
}

// MARK: - HorizontalTrackSection
struct HorizontalTrackSection: View {
    let title: String
    let tracks: [Track]
    var accentColor: Color = ColorPalette.primaryGreen
    @EnvironmentObject private var playerManager: PlayerManager

    var body: some View {
        VStack(alignment: .leading, spacing: UIConstants.Spacing.md) {
            SectionHeader(title: title, accentColor: accentColor)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: UIConstants.Spacing.md) {
                    ForEach(tracks) { track in
                        TrackCard(track: track, accentColor: accentColor) {
                            playerManager.play(track: track, queue: tracks)
                        }
                    }
                }
                .padding(.horizontal, UIConstants.Spacing.base)
            }
        }
    }
}

struct TrackCard: View {
    let track: Track
    var accentColor: Color = ColorPalette.primaryGreen
    let onTap: () -> Void
    @EnvironmentObject private var playerManager: PlayerManager

    var isPlaying: Bool { playerManager.currentTrack?.id == track.id && playerManager.isPlaying }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: UIConstants.Spacing.sm) {
                ZStack(alignment: .bottomTrailing) {
                    AsyncArtworkView(url: track.artworkURL, size: UIConstants.Card.mediumWidth)
                        .cornerRadius(UIConstants.Radius.md)
                    if isPlaying {
                        AudioBarsIndicator(color: accentColor)
                            .padding(UIConstants.Spacing.xs)
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(track.title)
                        .font(.system(size: UIConstants.FontSize.footnote, weight: .semibold))
                        .foregroundStyle(isPlaying ? accentColor : ColorPalette.textPrimary)
                        .lineLimit(1)
                    Text(track.artistName)
                        .font(.system(size: UIConstants.FontSize.caption))
                        .foregroundStyle(ColorPalette.textSecondary)
                        .lineLimit(1)
                }
            }
            .frame(width: UIConstants.Card.mediumWidth)
        }
        .scaleOnPress()
        .contextMenu { TrackContextMenu(track: track) }
    }
}

// MARK: - HorizontalAlbumSection
struct HorizontalAlbumSection: View {
    let title: String
    let albums: [Album]

    var body: some View {
        VStack(alignment: .leading, spacing: UIConstants.Spacing.md) {
            SectionHeader(title: title)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: UIConstants.Spacing.md) {
                    ForEach(albums) { album in
                        NavigationLink(destination: AlbumDetailView(album: album)) {
                            AlbumCard(album: album)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, UIConstants.Spacing.base)
            }
        }
    }
}

struct AlbumCard: View {
    let album: Album

    var body: some View {
        VStack(alignment: .leading, spacing: UIConstants.Spacing.sm) {
            AsyncArtworkView(url: album.artworkURL, size: UIConstants.Card.mediumWidth)
                .cornerRadius(UIConstants.Radius.md)
                .cardShadow()
            VStack(alignment: .leading, spacing: 2) {
                Text(album.title)
                    .font(.system(size: UIConstants.FontSize.footnote, weight: .semibold))
                    .foregroundStyle(ColorPalette.textPrimary)
                    .lineLimit(1)
                Text(album.artistName)
                    .font(.system(size: UIConstants.FontSize.caption))
                    .foregroundStyle(ColorPalette.textSecondary)
                    .lineLimit(1)
                if let year = album.year {
                    Text(String(year))
                        .font(.system(size: UIConstants.FontSize.caption2))
                        .foregroundStyle(ColorPalette.textTertiary)
                }
            }
        }
        .frame(width: UIConstants.Card.mediumWidth)
    }
}

// MARK: - TopChartsSection
struct TopChartsSection: View {
    let tracks: [Track]
    @EnvironmentObject private var playerManager: PlayerManager
    @State private var showAll = false

    var body: some View {
        VStack(alignment: .leading, spacing: UIConstants.Spacing.md) {
            SectionHeader(title: NSLocalizedString("section_top_charts", comment: ""), showAll: true) {
                showAll = true
            }
            VStack(spacing: 0) {
                ForEach(Array(tracks.prefix(showAll ? tracks.count : 5).enumerated()), id: \.element.id) { index, track in
                    TopChartRow(rank: index + 1, track: track) {
                        playerManager.play(track: track, queue: tracks, startIndex: index)
                    }
                    if index < (showAll ? tracks.count : 5) - 1 {
                        Divider().background(ColorPalette.surface3).padding(.leading, 70)
                    }
                }
            }
            .glassCard()
            .padding(.horizontal, UIConstants.Spacing.base)
        }
    }
}

struct TopChartRow: View {
    let rank: Int
    let track: Track
    let onTap: () -> Void
    @EnvironmentObject private var playerManager: PlayerManager
    var isPlaying: Bool { playerManager.currentTrack?.id == track.id && playerManager.isPlaying }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: UIConstants.Spacing.md) {
                Text("\(rank)")
                    .font(.system(size: UIConstants.FontSize.subheadline, weight: .bold))
                    .foregroundStyle(ColorPalette.textTertiary)
                    .frame(width: 20)
                AsyncArtworkView(url: track.artworkURL, size: 44)
                    .cornerRadius(UIConstants.Radius.xs)
                VStack(alignment: .leading, spacing: 2) {
                    Text(track.title)
                        .font(.system(size: UIConstants.FontSize.subheadline, weight: .semibold))
                        .foregroundStyle(isPlaying ? ColorPalette.primaryGreen : ColorPalette.textPrimary)
                        .lineLimit(1)
                    Text(track.artistName)
                        .font(.system(size: UIConstants.FontSize.caption))
                        .foregroundStyle(ColorPalette.textSecondary)
                        .lineLimit(1)
                }
                Spacer()
                if isPlaying {
                    AudioBarsIndicator(color: ColorPalette.primaryGreen)
                } else {
                    Text(track.formattedDuration)
                        .font(.system(size: UIConstants.FontSize.caption))
                        .foregroundStyle(ColorPalette.textTertiary)
                }
            }
            .padding(.horizontal, UIConstants.Spacing.base)
            .padding(.vertical, UIConstants.Spacing.sm)
        }
        .scaleOnPress()
        .contextMenu { TrackContextMenu(track: track) }
    }
}

// MARK: - FeaturedArtistsSection
struct FeaturedArtistsSection: View {
    let artists: [Artist]

    var body: some View {
        VStack(alignment: .leading, spacing: UIConstants.Spacing.md) {
            SectionHeader(title: NSLocalizedString("section_featured_artists", comment: ""))
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: UIConstants.Spacing.base) {
                    ForEach(artists) { artist in
                        NavigationLink(destination: ArtistDetailView(artist: artist)) {
                            ArtistCard(artist: artist)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, UIConstants.Spacing.base)
            }
        }
    }
}

struct ArtistCard: View {
    let artist: Artist

    var body: some View {
        VStack(spacing: UIConstants.Spacing.sm) {
            AsyncArtworkView(url: artist.photoURL, size: UIConstants.Card.smallWidth, isCircle: true)
                .overlay(Circle().strokeBorder(ColorPalette.glassBorder, lineWidth: 1))
            Text(artist.name)
                .font(.system(size: UIConstants.FontSize.caption, weight: .semibold))
                .foregroundStyle(ColorPalette.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(width: 90)
    }
}

// MARK: - GenresGridSection
struct GenresGridSection: View {
    let genres: [Genre]

    var body: some View {
        VStack(alignment: .leading, spacing: UIConstants.Spacing.md) {
            SectionHeader(title: NSLocalizedString("section_genres", comment: ""))
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: UIConstants.Spacing.sm) {
                ForEach(genres) { genre in
                    NavigationLink(destination: GenreCategoryView(genre: genre)) {
                        GenreCard(genre: genre)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, UIConstants.Spacing.base)
        }
    }
}

struct GenreCard: View {
    let genre: Genre

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: UIConstants.Radius.lg, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: genre.colorHex), Color(hex: genre.colorHex).opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: UIConstants.Grid.genreItemHeight)
            HStack {
                Text(genre.displayName)
                    .font(.system(size: UIConstants.FontSize.subheadline, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(UIConstants.Spacing.md)
                Spacer()
                Image(systemName: genre.iconName)
                    .font(.system(size: 28))
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(UIConstants.Spacing.sm)
                    .rotationEffect(.degrees(10))
            }
        }
        .scaleOnPress()
        .cardShadow()
    }
}

// MARK: - HomeSkeletonView
struct HomeSkeletonView: View {
    var body: some View {
        VStack(spacing: UIConstants.Spacing.xxl) {
            skeletonRow(count: 2, height: 64)
            skeletonScroll(count: 4, size: UIConstants.Card.mediumWidth)
            skeletonScroll(count: 3, size: UIConstants.Card.largeWidth)
        }
        .padding(.horizontal, UIConstants.Spacing.base)
    }

    private func skeletonRow(count: Int, height: CGFloat) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: UIConstants.Spacing.sm) {
            ForEach(0..<count, id: \.self) { _ in
                RoundedRectangle(cornerRadius: UIConstants.Radius.md)
                    .fill(ColorPalette.surface3)
                    .frame(height: height)
                    .shimmer()
            }
        }
    }

    private func skeletonScroll(count: Int, size: CGFloat) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: UIConstants.Spacing.md) {
                ForEach(0..<count, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: UIConstants.Radius.md)
                        .fill(ColorPalette.surface3)
                        .frame(width: size, height: size)
                        .shimmer()
                }
            }
        }
    }
}

// MARK: - Shared Section Header
struct SectionHeader: View {
    let title: String
    var accentColor: Color = ColorPalette.textPrimary
    var showAll: Bool = false
    var onShowAll: (() -> Void)?

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: UIConstants.FontSize.title3, weight: .bold))
                .foregroundStyle(accentColor)
            Spacer()
            if showAll {
                Button(NSLocalizedString("see_all", comment: ""), action: onShowAll ?? {})
                    .font(.system(size: UIConstants.FontSize.footnote))
                    .foregroundStyle(ColorPalette.textSecondary)
            }
        }
        .padding(.horizontal, UIConstants.Spacing.base)
    }
}
