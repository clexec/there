import Foundation
import Combine

// MARK: - SearchViewModel
@MainActor
final class SearchViewModel: ObservableObject {

    @Published var searchQuery: String = ""
    @Published var searchResult: SearchResult = SearchResult()
    @Published var searchHistory: [SearchHistoryItem] = []
    @Published var genres: [Genre] = Genre.allGenres
    @Published var isSearching: Bool = false
    @Published var isActive: Bool = false
    @Published var error: String?
    @Published var activeTab: SearchTab = .all

    enum SearchTab: String, CaseIterable {
        case all      = "All"
        case tracks   = "Tracks"
        case albums   = "Albums"
        case artists  = "Artists"
        var localizedTitle: String { NSLocalizedString("search_tab_\(rawValue.lowercased())", comment: "") }
    }

    private let apiService: ITunesAPIService
    private let userDefaultsManager: UserDefaultsManager
    private var searchTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    init(apiService: ITunesAPIService = .shared, userDefaultsManager: UserDefaultsManager = .shared) {
        self.apiService = apiService
        self.userDefaultsManager = userDefaultsManager
        loadHistory()
        setupSearchDebounce()
    }

    // MARK: - Search
    func search(query: String) async {
        guard query.count >= AppConstants.Search.minQueryLength else {
            searchResult = SearchResult()
            isSearching = false
            return
        }
        isSearching = true
        error = nil
        do {
            let result = try await apiService.search(query: query, limit: AppConstants.Search.maxResults)
            searchResult = result
            if !query.isEmpty {
                addToHistory(query: query, resultCount: result.totalResults)
            }
        } catch {
            self.error = error.localizedDescription
        }
        isSearching = false
    }

    func clearSearch() {
        searchQuery = ""
        searchResult = SearchResult()
        isActive = false
    }

    // MARK: - History
    private func loadHistory() {
        searchHistory = userDefaultsManager.loadCodable([SearchHistoryItem].self, for: AppConstants.Defaults.searchHistory) ?? []
    }

    func addToHistory(query: String, resultCount: Int) {
        searchHistory.removeAll { $0.query.lowercased() == query.lowercased() }
        let item = SearchHistoryItem(query: query, resultCount: resultCount)
        searchHistory.insert(item, at: 0)
        if searchHistory.count > AppConstants.Search.maxHistoryItems {
            searchHistory = Array(searchHistory.prefix(AppConstants.Search.maxHistoryItems))
        }
        userDefaultsManager.saveCodable(searchHistory, for: AppConstants.Defaults.searchHistory)
    }

    func removeFromHistory(_ item: SearchHistoryItem) {
        searchHistory.removeAll { $0.id == item.id }
        userDefaultsManager.saveCodable(searchHistory, for: AppConstants.Defaults.searchHistory)
    }

    func clearHistory() {
        searchHistory = []
        userDefaultsManager.remove(key: AppConstants.Defaults.searchHistory)
    }

    // MARK: - Filtered Results
    var filteredTracks: [Track] {
        switch activeTab {
        case .all, .tracks: return searchResult.tracks
        default: return []
        }
    }

    var filteredAlbums: [Album] {
        switch activeTab {
        case .all, .albums: return searchResult.albums
        default: return []
        }
    }

    var filteredArtists: [Artist] {
        switch activeTab {
        case .all, .artists: return searchResult.artists
        default: return []
        }
    }

    var hasResults: Bool { !searchResult.isEmpty }

    // MARK: - Debounce
    private func setupSearchDebounce() {
        $searchQuery
            .debounce(for: .milliseconds(AppConstants.Search.debounceMS), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] query in
                guard let self else { return }
                self.searchTask?.cancel()
                if query.isEmpty {
                    self.searchResult = SearchResult()
                    self.isSearching = false
                } else {
                    self.searchTask = Task { await self.search(query: query) }
                }
            }
            .store(in: &cancellables)
    }
}
