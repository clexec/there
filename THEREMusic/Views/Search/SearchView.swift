import SwiftUI

// MARK: - SearchView
struct SearchView: View {
    @ObservedObject var viewModel: SearchViewModel
    @FocusState private var isSearchFocused: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                ColorPalette.backgroundBlack.ignoresSafeArea()
                VStack(spacing: 0) {
                    searchBar
                    content
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
        .onAppear { isSearchFocused = true }
    }

    private var searchBar: some View {
        HStack(spacing: UIConstants.Spacing.md) {
            HStack(spacing: UIConstants.Spacing.sm) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: UIConstants.SearchBar.iconSize))
                    .foregroundStyle(viewModel.isActive ? ColorPalette.textPrimary : ColorPalette.textSecondary)
                TextField(NSLocalizedString("search_placeholder", comment: ""), text: $viewModel.searchQuery)
                    .font(.system(size: UIConstants.FontSize.body))
                    .foregroundStyle(ColorPalette.textPrimary)
                    .focused($isSearchFocused)
                    .onSubmit {
                        if !viewModel.searchQuery.isEmpty {
                            Task { await viewModel.search(query: viewModel.searchQuery) }
                        }
                    }
                    .onChange(of: viewModel.searchQuery) { _, q in
                        viewModel.isActive = !q.isEmpty
                    }
                if !viewModel.searchQuery.isEmpty {
                    Button {
                        viewModel.clearSearch()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(ColorPalette.textTertiary)
                    }
                }
            }
            .padding(.horizontal, UIConstants.Spacing.md)
            .frame(height: UIConstants.SearchBar.height)
            .background {
                RoundedRectangle(cornerRadius: UIConstants.SearchBar.cornerRadius)
                    .fill(ColorPalette.surface3)
            }

            Button(NSLocalizedString("cancel", comment: "")) {
                viewModel.clearSearch()
                dismiss()
            }
            .font(.system(size: UIConstants.FontSize.body))
            .foregroundStyle(ColorPalette.textPrimary)
        }
        .padding(.horizontal, UIConstants.Spacing.base)
        .padding(.vertical, UIConstants.Spacing.sm)
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isActive {
            if viewModel.isSearching {
                SearchLoadingView()
            } else if viewModel.hasResults {
                SearchResultsScrollView(viewModel: viewModel)
            } else if !viewModel.searchQuery.isEmpty {
                SearchEmptyView(query: viewModel.searchQuery)
            }
        } else {
            BrowseView(viewModel: viewModel)
        }
    }
}

// MARK: - BrowseView
struct BrowseView: View {
    @ObservedObject var viewModel: SearchViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: UIConstants.Spacing.xl) {
                if !viewModel.searchHistory.isEmpty {
                    SearchHistorySection(viewModel: viewModel)
                }
                GenreBrowseGrid(genres: viewModel.genres)
                bottomPadding
            }
        }
        .scrollIndicators(.hidden)
    }

    private var bottomPadding: some View {
        Color.clear.frame(height: AppConstants.Player.miniPlayerHeight + AppConstants.UI.tabBarHeight)
    }
}

// MARK: - SearchHistorySection
struct SearchHistorySection: View {
    @ObservedObject var viewModel: SearchViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: UIConstants.Spacing.sm) {
            HStack {
                Text(NSLocalizedString("search_recent", comment: ""))
                    .font(.system(size: UIConstants.FontSize.title3, weight: .bold))
                    .foregroundStyle(ColorPalette.textPrimary)
                Spacer()
                Button(NSLocalizedString("clear_all", comment: "")) {
                    viewModel.clearHistory()
                }
                .font(.system(size: UIConstants.FontSize.footnote))
                .foregroundStyle(ColorPalette.textSecondary)
            }
            .padding(.horizontal, UIConstants.Spacing.base)

            ForEach(viewModel.searchHistory.prefix(10)) { item in
                Button {
                    viewModel.searchQuery = item.query
                } label: {
                    HStack(spacing: UIConstants.Spacing.md) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: UIConstants.IconSize.md))
                            .foregroundStyle(ColorPalette.textSecondary)
                        Text(item.query)
                            .font(.system(size: UIConstants.FontSize.body))
                            .foregroundStyle(ColorPalette.textPrimary)
                        Spacer()
                        Button {
                            viewModel.removeFromHistory(item)
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 12))
                                .foregroundStyle(ColorPalette.textTertiary)
                        }
                    }
                    .padding(.horizontal, UIConstants.Spacing.base)
                    .padding(.vertical, UIConstants.Spacing.sm)
                }
            }
        }
    }
}

// MARK: - GenreBrowseGrid
struct GenreBrowseGrid: View {
    let genres: [Genre]

    var body: some View {
        VStack(alignment: .leading, spacing: UIConstants.Spacing.md) {
            Text(NSLocalizedString("browse_categories", comment: ""))
                .font(.system(size: UIConstants.FontSize.title3, weight: .bold))
                .foregroundStyle(ColorPalette.textPrimary)
                .padding(.horizontal, UIConstants.Spacing.base)

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

// MARK: - SearchResultsScrollView
struct SearchResultsScrollView: View {
    @ObservedObject var viewModel: SearchViewModel
    @EnvironmentObject private var playerManager: PlayerManager

    var body: some View {
        VStack(spacing: 0) {
            searchTabBar
            ScrollView {
                LazyVStack(spacing: 0) {
                    if !viewModel.filteredTracks.isEmpty {
                        tracksSection
                    }
                    if !viewModel.filteredAlbums.isEmpty {
                        albumsSection
                    }
                    if !viewModel.filteredArtists.isEmpty {
                        artistsSection
                    }
                    bottomPadding
                }
            }
            .scrollIndicators(.hidden)
        }
    }

    private var searchTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: UIConstants.Spacing.sm) {
                ForEach(SearchViewModel.SearchTab.allCases, id: \.rawValue) { tab in
                    Button {
                        withAnimation(UIConstants.Animation.fast) { viewModel.activeTab = tab }
                    } label: {
                        Text(tab.localizedTitle)
                            .font(.system(size: UIConstants.FontSize.footnote, weight: .semibold))
                            .foregroundStyle(viewModel.activeTab == tab ? ColorPalette.backgroundBlack : ColorPalette.textPrimary)
                            .padding(.horizontal, UIConstants.Spacing.base)
                            .padding(.vertical, UIConstants.Spacing.xs)
                            .background {
                                Capsule().fill(viewModel.activeTab == tab ? ColorPalette.primaryGreen : ColorPalette.surface3)
                            }
                    }
                    .scaleOnPress()
                }
            }
            .padding(.horizontal, UIConstants.Spacing.base)
            .padding(.vertical, UIConstants.Spacing.sm)
        }
    }

    private var tracksSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            if viewModel.activeTab == .all {
                sectionHeader(NSLocalizedString("search_tracks", comment: ""))
            }
            ForEach(viewModel.filteredTracks) { track in
                TrackRowView(track: track) {
                    playerManager.play(track: track, queue: viewModel.filteredTracks)
                }
                Divider().background(ColorPalette.surface3).padding(.leading, 70)
            }
        }
    }

    private var albumsSection: some View {
        VStack(alignment: .leading, spacing: UIConstants.Spacing.md) {
            if viewModel.activeTab == .all {
                sectionHeader(NSLocalizedString("search_albums", comment: ""))
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: UIConstants.Spacing.md) {
                        ForEach(viewModel.filteredAlbums) { album in
                            NavigationLink(destination: AlbumDetailView(album: album)) {
                                AlbumCard(album: album)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, UIConstants.Spacing.base)
                }
            } else {
                ForEach(viewModel.filteredAlbums) { album in
                    NavigationLink(destination: AlbumDetailView(album: album)) {
                        AlbumRowView(album: album)
                    }
                    .buttonStyle(.plain)
                    Divider().background(ColorPalette.surface3).padding(.leading, 70)
                }
            }
        }
    }

    private var artistsSection: some View {
        VStack(alignment: .leading, spacing: UIConstants.Spacing.md) {
            if viewModel.activeTab == .all {
                sectionHeader(NSLocalizedString("search_artists", comment: ""))
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: UIConstants.Spacing.base) {
                        ForEach(viewModel.filteredArtists) { artist in
                            NavigationLink(destination: ArtistDetailView(artist: artist)) {
                                ArtistCard(artist: artist)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, UIConstants.Spacing.base)
                }
            } else {
                ForEach(viewModel.filteredArtists) { artist in
                    NavigationLink(destination: ArtistDetailView(artist: artist)) {
                        ArtistRowView(artist: artist)
                    }
                    .buttonStyle(.plain)
                    Divider().background(ColorPalette.surface3).padding(.leading, 70)
                }
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: UIConstants.FontSize.title3, weight: .bold))
            .foregroundStyle(ColorPalette.textPrimary)
            .padding(.horizontal, UIConstants.Spacing.base)
            .padding(.top, UIConstants.Spacing.xl)
            .padding(.bottom, UIConstants.Spacing.xs)
    }

    private var bottomPadding: some View {
        Color.clear.frame(height: AppConstants.Player.miniPlayerHeight + AppConstants.UI.tabBarHeight + UIConstants.Spacing.xl)
    }
}

// MARK: - SearchLoadingView
struct SearchLoadingView: View {
    var body: some View {
        VStack {
            Spacer()
            ProgressView()
                .tint(ColorPalette.primaryGreen)
                .scaleEffect(1.2)
            Spacer()
        }
    }
}

// MARK: - SearchEmptyView
struct SearchEmptyView: View {
    let query: String

    var body: some View {
        VStack(spacing: UIConstants.Spacing.base) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(ColorPalette.textTertiary)
            Text(String(format: NSLocalizedString("search_no_results", comment: ""), query))
                .font(.system(size: UIConstants.FontSize.body))
                .foregroundStyle(ColorPalette.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(.horizontal, UIConstants.Spacing.xxl)
    }
}

// MARK: - GenreCategoryView
struct GenreCategoryView: View {
    let genre: Genre
    @StateObject private var viewModel: GenreCategoryViewModel
    @EnvironmentObject private var playerManager: PlayerManager

    init(genre: Genre) {
        self.genre = genre
        _viewModel = StateObject(wrappedValue: GenreCategoryViewModel(genre: genre))
    }

    var body: some View {
        ZStack {
            ColorPalette.backgroundBlack.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    genreHeader
                    if viewModel.isLoading {
                        ProgressView().tint(ColorPalette.primaryGreen).padding(UIConstants.Spacing.xxl)
                    } else {
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.tracks) { track in
                                TrackRowView(track: track) {
                                    playerManager.play(track: track, queue: viewModel.tracks)
                                }
                                Divider().background(ColorPalette.surface3).padding(.leading, 70)
                            }
                        }
                        bottomPadding
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle(genre.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .onFirstAppear { Task { await viewModel.load() } }
    }

    private var genreHeader: some View {
        ZStack(alignment: .bottomLeading) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: genre.colorHex), Color(hex: genre.colorHex).opacity(0.3), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 200)
            VStack(alignment: .leading, spacing: UIConstants.Spacing.xs) {
                Image(systemName: genre.iconName)
                    .font(.system(size: 32))
                    .foregroundStyle(.white)
                Text(genre.displayName)
                    .font(.system(size: UIConstants.FontSize.title, weight: .black))
                    .foregroundStyle(.white)
            }
            .padding(UIConstants.Spacing.base)
        }
    }

    private var bottomPadding: some View {
        Color.clear.frame(height: AppConstants.Player.miniPlayerHeight + AppConstants.UI.tabBarHeight)
    }
}

// MARK: - GenreCategoryViewModel
@MainActor
final class GenreCategoryViewModel: ObservableObject {
    @Published var tracks: [Track] = []
    @Published var isLoading: Bool = false
    let genre: Genre
    private let apiService: ITunesAPIService

    init(genre: Genre, apiService: ITunesAPIService = .shared) {
        self.genre = genre
        self.apiService = apiService
    }

    func load() async {
        isLoading = true
        tracks = (try? await apiService.searchByGenre(genre.name, limit: 30)) ?? []
        isLoading = false
    }
}
