import Foundation
import Combine

// MARK: - HomeViewModel
@MainActor
final class HomeViewModel: ObservableObject {

    @Published var recentlyPlayed: [Track] = []
    @Published var discoverWeekly: [Track] = []
    @Published var releaseRadar: [Album] = []
    @Published var dailyMix1: [Track] = []
    @Published var dailyMix2: [Track] = []
    @Published var topCharts: [Track] = []
    @Published var newReleases: [Album] = []
    @Published var recommendations: [Recommendation] = []
    @Published var featuredArtists: [Artist] = []
    @Published var genres: [Genre] = Genre.allGenres
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var greeting: String = ""
    @Published var userName: String = ""

    private let apiService: ITunesAPIService
    private let libraryManager: LibraryManager
    private var cancellables = Set<AnyCancellable>()

    init(apiService: ITunesAPIService = .shared, libraryManager: LibraryManager = .shared) {
        self.apiService = apiService
        self.libraryManager = libraryManager
        updateGreeting()
        bindLibrary()
    }

    // MARK: - Load
    func load(user: User) async {
        userName = user.displayName
        updateGreeting()
        isLoading = true
        error = nil

        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadRecentlyPlayed() }
            group.addTask { await self.loadDiscoverWeekly() }
            group.addTask { await self.loadReleaseRadar() }
            group.addTask { await self.loadDailyMixes() }
            group.addTask { await self.loadTopCharts() }
            group.addTask { await self.loadNewReleases() }
            group.addTask { await self.loadFeaturedArtists() }
        }

        buildRecommendations()
        isLoading = false
    }

    func refresh(user: User) async {
        await load(user: user)
    }

    // MARK: - Private Loaders
    private func loadRecentlyPlayed() async {
        recentlyPlayed = libraryManager.recentlyPlayed
        if recentlyPlayed.isEmpty {
            let tracks = (try? await apiService.fetchTopTracks(limit: 10)) ?? []
            recentlyPlayed = tracks
        }
    }

    private func loadDiscoverWeekly() async {
        do {
            discoverWeekly = try await apiService.fetchTopTracks(limit: 20)
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func loadReleaseRadar() async {
        do {
            releaseRadar = try await apiService.fetchNewReleases(limit: 10)
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func loadDailyMixes() async {
        async let mix1 = apiService.searchByGenre("pop", limit: 15)
        async let mix2 = apiService.searchByGenre("hip hop", limit: 15)
        do {
            let (m1, m2) = try await (mix1, mix2)
            dailyMix1 = m1
            dailyMix2 = m2
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func loadTopCharts() async {
        do {
            topCharts = try await apiService.fetchTopTracks(limit: 25)
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func loadNewReleases() async {
        do {
            newReleases = try await apiService.fetchNewReleases(limit: 15)
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func loadFeaturedArtists() async {
        do {
            let tracks = try await apiService.fetchTopTracks(limit: 30)
            let artistNames = Array(Set(tracks.map { $0.artistName })).prefix(10)
            var artists: [Artist] = []
            for name in artistNames {
                let artistTracks = try? await apiService.fetchArtistTracks(artistName: name, limit: 5)
                let artist = Artist(
                    name: name,
                    genres: tracks.filter { $0.artistName == name }.compactMap { $0.genre },
                    topTracks: artistTracks ?? []
                )
                artists.append(artist)
            }
            featuredArtists = artists
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func buildRecommendations() {
        recommendations = [
            Recommendation(section: .recentlyPlayed,  title: NSLocalizedString("section_recently_played", comment: ""), tracks: recentlyPlayed),
            Recommendation(section: .discoverWeekly,  title: NSLocalizedString("section_discover_weekly", comment: ""), tracks: discoverWeekly),
            Recommendation(section: .releaseRadar,    title: NSLocalizedString("section_release_radar", comment: ""), albums: releaseRadar),
            Recommendation(section: .dailyMix1,       title: NSLocalizedString("section_daily_mix_1", comment: ""), tracks: dailyMix1),
            Recommendation(section: .topCharts,       title: NSLocalizedString("section_top_charts", comment: ""), tracks: topCharts),
            Recommendation(section: .newReleases,     title: NSLocalizedString("section_new_releases", comment: ""), albums: newReleases),
            Recommendation(section: .featuredArtists, title: NSLocalizedString("section_featured_artists", comment: ""), artists: featuredArtists)
        ].filter { !$0.tracks.isEmpty || !$0.albums.isEmpty || !$0.artists.isEmpty }
    }

    private func updateGreeting() {
        let hour = Calendar.current.component(.hour, from: Date())
        greeting = switch hour {
        case 5..<12:  NSLocalizedString("greeting_morning", comment: "")
        case 12..<17: NSLocalizedString("greeting_afternoon", comment: "")
        case 17..<22: NSLocalizedString("greeting_evening", comment: "")
        default:      NSLocalizedString("greeting_night", comment: "")
        }
    }

    private func bindLibrary() {
        libraryManager.$recentlyPlayed
            .receive(on: DispatchQueue.main)
            .sink { [weak self] tracks in
                if !tracks.isEmpty { self?.recentlyPlayed = tracks }
            }
            .store(in: &cancellables)
    }
}
