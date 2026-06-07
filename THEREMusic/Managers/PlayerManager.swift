import Foundation
import Combine

// MARK: - PlayerManager
@MainActor
final class PlayerManager: ObservableObject {

    static let shared = PlayerManager()

    @Published var currentTrack: Track?
    @Published var queue: [Track] = []
    @Published var originalQueue: [Track] = []
    @Published var currentIndex: Int = 0
    @Published var isShuffled: Bool = false
    @Published var repeatMode: RepeatMode = .off
    @Published var isPlayerVisible: Bool = false
    @Published var isFullPlayerPresented: Bool = false

    let audioService: AudioPlayerService

    private var cancellables = Set<AnyCancellable>()
    private var userID: String?

    var state: PlayerStateEnum  { audioService.state }
    var isPlaying: Bool         { audioService.isPlaying }
    var currentTime: Double     { audioService.currentTime }
    var duration: Double        { audioService.duration }
    var progress: Double        { audioService.progress }

    var hasNext: Bool     { currentIndex < queue.count - 1 || repeatMode != .off }
    var hasPrevious: Bool { currentIndex > 0 || repeatMode != .off }

    private init(audioService: AudioPlayerService = .shared) {
        self.audioService = audioService
        setupObservers()
        restoreState()
    }

    // MARK: - Play
    func play(track: Track, queue: [Track] = [], startIndex: Int = 0, context: String? = nil) {
        let playQueue = queue.isEmpty ? [track] : queue
        self.originalQueue = playQueue
        if isShuffled {
            self.queue = shuffleQueue(playQueue, keeping: track)
            self.currentIndex = self.queue.firstIndex(where: { $0.id == track.id }) ?? 0
        } else {
            self.queue = playQueue
            self.currentIndex = startIndex
        }
        currentTrack = track
        isPlayerVisible = true
        Task { await audioService.play(track: track) }
        saveState()
    }

    func playPlaylist(_ playlist: Playlist, startIndex: Int = 0) {
        guard !playlist.tracks.isEmpty else { return }
        let track = playlist.tracks[startIndex]
        play(track: track, queue: playlist.tracks, startIndex: startIndex)
    }

    func playAlbum(_ album: Album, startIndex: Int = 0) {
        guard !album.tracks.isEmpty else { return }
        let track = album.tracks[startIndex]
        play(track: track, queue: album.tracks, startIndex: startIndex)
    }

    // MARK: - Controls
    func pauseResume() {
        audioService.togglePlayPause()
    }

    func pause() { audioService.pause() }
    func resume() { audioService.resume() }

    func skipNext() {
        switch repeatMode {
        case .one:
            audioService.seek(to: 0)
            audioService.resume()
        case .all:
            let nextIndex = (currentIndex + 1) % queue.count
            playAtIndex(nextIndex)
        case .off:
            guard currentIndex < queue.count - 1 else { return }
            playAtIndex(currentIndex + 1)
        }
    }

    func skipPrevious() {
        if audioService.currentTime > 3 {
            audioService.seek(to: 0)
            return
        }
        switch repeatMode {
        case .one, .all:
            let prevIndex = currentIndex == 0 ? queue.count - 1 : currentIndex - 1
            playAtIndex(prevIndex)
        case .off:
            guard currentIndex > 0 else { audioService.seek(to: 0); return }
            playAtIndex(currentIndex - 1)
        }
    }

    func seek(to progress: Double) {
        audioService.seek(to: progress * duration)
    }

    func setVolume(_ volume: Double) {
        audioService.setVolume(Float(volume))
    }

    // MARK: - Queue Management
    func addToQueue(_ track: Track) {
        let insertIndex = currentIndex + 1
        if insertIndex < queue.count {
            queue.insert(track, at: insertIndex)
        } else {
            queue.append(track)
        }
    }

    func addToQueueEnd(_ track: Track) {
        queue.append(track)
    }

    func removeFromQueue(at index: Int) {
        guard index != currentIndex, index < queue.count else { return }
        queue.remove(at: index)
        if index < currentIndex { currentIndex -= 1 }
    }

    func moveInQueue(from source: IndexSet, to destination: Int) {
        queue.move(fromOffsets: source, toOffset: destination)
        let movedTrack = currentTrack
        currentIndex = queue.firstIndex(where: { $0.id == movedTrack?.id }) ?? 0
    }

    func clearQueue() {
        guard let track = currentTrack else { return }
        queue = [track]
        originalQueue = [track]
        currentIndex = 0
    }

    // MARK: - Shuffle
    func toggleShuffle() {
        isShuffled.toggle()
        if isShuffled {
            queue = shuffleQueue(originalQueue, keeping: currentTrack)
            currentIndex = queue.firstIndex(where: { $0.id == currentTrack?.id }) ?? 0
        } else {
            queue = originalQueue
            currentIndex = queue.firstIndex(where: { $0.id == currentTrack?.id }) ?? 0
        }
        saveState()
    }

    func toggleRepeat() {
        repeatMode = repeatMode.nextMode
        saveState()
    }

    // MARK: - Private
    private func playAtIndex(_ index: Int) {
        guard index < queue.count else { return }
        currentIndex = index
        let track = queue[index]
        currentTrack = track
        Task { await audioService.play(track: track) }
        saveState()
    }

    private func shuffleQueue(_ tracks: [Track], keeping current: Track?) -> [Track] {
        var shuffled = tracks.filter { $0.id != current?.id }.shuffled()
        if let current { shuffled.insert(current, at: 0) }
        return shuffled
    }

    private func setupObservers() {
        NotificationCenter.default.publisher(for: .playerDidFinishTrack)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.skipNext() }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .playerSkipNext)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.skipNext() }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .playerSkipPrevious)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.skipPrevious() }
            .store(in: &cancellables)
    }

    private func saveState() {
        UserDefaultsManager.shared.set(isShuffled, for: AppConstants.Defaults.shuffleEnabled)
        UserDefaultsManager.shared.set(repeatMode.rawValue, for: AppConstants.Defaults.repeatMode)
    }

    private func restoreState() {
        isShuffled = UserDefaultsManager.shared.bool(for: AppConstants.Defaults.shuffleEnabled)
        let repeatRaw = UserDefaultsManager.shared.string(for: AppConstants.Defaults.repeatMode)
        repeatMode = RepeatMode(rawValue: repeatRaw ?? "off") ?? .off
    }
}
