import Foundation
import AVFoundation
import Combine
import MediaPlayer

// MARK: - AudioPlayerService
final class AudioPlayerService: NSObject, ObservableObject {

    static let shared = AudioPlayerService()

    @Published var state: PlayerStateEnum = .idle
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var progress: Double = 0
    @Published var isBuffering: Bool = false
    @Published var currentTrack: Track?
    @Published var error: AppErrorType?

    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    private var progressTimer: Timer?

    var isPlaying: Bool { state == .playing }
    var isPaused: Bool  { state == .paused }

    private override init() {
        super.init()
        setupAudioSession()
        setupRemoteCommandCenter()
        setupInterruptionObserver()
        setupRouteChangeObserver()
    }

    deinit {
        cleanup()
    }

    // MARK: - Playback Control
    func play(track: Track) async {
        await MainActor.run {
            state = .loading
            currentTrack = track
            error = nil
        }

        let url: URL?
        if let local = track.localFileURL {
            url = local
        } else if let preview = track.previewURL {
            url = preview
        } else {
            await MainActor.run {
                error = .playerError(NSLocalizedString("error_no_audio_url", comment: ""))
                state = .error
            }
            return
        }

        guard let audioURL = url else {
            await MainActor.run {
                error = .playerError(NSLocalizedString("error_invalid_url", comment: ""))
                state = .error
            }
            return
        }

        await setupPlayer(with: audioURL, track: track)
    }

    private func setupPlayer(with url: URL, track: Track) async {
        removeTimeObserver()
        player?.pause()
        player = nil
        playerItem = nil

        let asset = AVURLAsset(url: url, options: [AVURLAssetPreferPreciseDurationAndTimingKey: true])
        let item = AVPlayerItem(asset: asset)
        playerItem = item

        observePlayerItem(item, track: track)

        await MainActor.run {
            let newPlayer = AVPlayer(playerItem: item)
            newPlayer.volume = 1.0
            self.player = newPlayer
            addTimeObserver()
            newPlayer.play()
            self.state = .playing
            self.duration = Double(track.durationMs) / 1000
            self.updateNowPlayingInfo(track: track)
        }
    }

    func pause() {
        player?.pause()
        state = .paused
        updateNowPlayingInfo(track: currentTrack)
    }

    func resume() {
        player?.play()
        state = .playing
        updateNowPlayingInfo(track: currentTrack)
    }

    func togglePlayPause() {
        if isPlaying { pause() } else { resume() }
    }

    func stop() {
        player?.pause()
        player?.seek(to: .zero)
        state = .stopped
        currentTime = 0
        progress = 0
        clearNowPlayingInfo()
    }

    func seek(to seconds: Double) {
        let time = CMTime(seconds: seconds, preferredTimescale: 600)
        player?.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
            Task { @MainActor in
                self?.currentTime = seconds
                self?.progress = seconds / max(self?.duration ?? 1, 1)
            }
        }
    }

    func seekByOffset(_ offset: Double) {
        let newTime = max(0, min(currentTime + offset, duration))
        seek(to: newTime)
    }

    func setVolume(_ volume: Float) {
        player?.volume = volume
    }

    // MARK: - Time Observer
    private func addTimeObserver() {
        let interval = CMTime(seconds: AppConstants.Player.progressUpdateInterval, preferredTimescale: 600)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self else { return }
            let seconds = time.seconds
            guard seconds.isFinite && seconds >= 0 else { return }
            self.currentTime = seconds
            self.duration = self.player?.currentItem?.duration.seconds ?? self.duration
            if self.duration > 0 {
                self.progress = seconds / self.duration
            }
        }
    }

    private func removeTimeObserver() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
    }

    // MARK: - Player Item Observation
    private func observePlayerItem(_ item: AVPlayerItem, track: Track) {
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main
        ) { [weak self] _ in
            self?.handlePlaybackFinished()
        }
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime, object: item, queue: .main
        ) { [weak self] notification in
            let err = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error
            self?.handlePlaybackError(err)
        }
        item.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                switch status {
                case .readyToPlay: self?.isBuffering = false
                case .failed:
                    self?.error = .playerError(item.error?.localizedDescription ?? "Playback failed")
                    self?.state = .error
                default: break
                }
            }
            .store(in: &cancellables)

        item.publisher(for: \.isPlaybackBufferEmpty)
            .receive(on: DispatchQueue.main)
            .assign(to: \.isBuffering, on: self)
            .store(in: &cancellables)
    }

    private func handlePlaybackFinished() {
        state = .stopped
        currentTime = 0
        progress = 0
        NotificationCenter.default.post(name: .playerDidFinishTrack, object: currentTrack)
    }

    private func handlePlaybackError(_ error: Error?) {
        self.error = .playerError(error?.localizedDescription ?? "Unknown error")
        self.state = .error
    }

    // MARK: - Audio Session
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers, .allowBluetooth, .allowAirPlay])
            try session.setActive(true)
        } catch {
            print("Audio session setup failed: \(error)")
        }
    }

    // MARK: - Remote Command Center
    private func setupRemoteCommandCenter() {
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.addTarget { [weak self] _ in
            self?.resume(); return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            self?.pause(); return .success
        }
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.togglePlayPause(); return .success
        }
        center.nextTrackCommand.addTarget { _ in
            NotificationCenter.default.post(name: .playerSkipNext, object: nil)
            return .success
        }
        center.previousTrackCommand.addTarget { _ in
            NotificationCenter.default.post(name: .playerSkipPrevious, object: nil)
            return .success
        }
        center.changePlaybackPositionCommand.addTarget { [weak self] event in
            if let e = event as? MPChangePlaybackPositionCommandEvent {
                self?.seek(to: e.positionTime)
            }
            return .success
        }
        center.skipForwardCommand.preferredIntervals = [NSNumber(value: AppConstants.Player.skipForwardSeconds)]
        center.skipForwardCommand.addTarget { [weak self] _ in
            self?.seekByOffset(AppConstants.Player.skipForwardSeconds); return .success
        }
        center.skipBackwardCommand.preferredIntervals = [NSNumber(value: AppConstants.Player.skipBackwardSeconds)]
        center.skipBackwardCommand.addTarget { [weak self] _ in
            self?.seekByOffset(-AppConstants.Player.skipBackwardSeconds); return .success
        }
    }

    // MARK: - Now Playing Info
    private func updateNowPlayingInfo(track: Track?) {
        guard let track else { clearNowPlayingInfo(); return }
        var info: [String: Any] = [
            MPMediaItemPropertyTitle:         track.title,
            MPMediaItemPropertyArtist:        track.artistName,
            MPMediaItemPropertyAlbumTitle:    track.albumTitle ?? "",
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPMediaItemPropertyPlaybackDuration:         duration,
            MPNowPlayingInfoPropertyPlaybackRate:         isPlaying ? 1.0 : 0.0
        ]
        if let artworkURL = track.artworkURL {
            Task {
                if let data = try? Data(contentsOf: artworkURL),
                   let image = UIImage(data: data) {
                    info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
                    MPNowPlayingInfoCenter.default().nowPlayingInfo = info
                }
            }
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func clearNowPlayingInfo() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    // MARK: - Interruption Observer
    private func setupInterruptionObserver() {
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification, object: nil, queue: .main
        ) { [weak self] notification in
            guard let userInfo = notification.userInfo,
                  let type = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let interruptionType = AVAudioSession.InterruptionType(rawValue: type)
            else { return }
            switch interruptionType {
            case .began:  self?.pause()
            case .ended:
                let options = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt
                if options.map({ AVAudioSession.InterruptionOptions(rawValue: $0) })?.contains(.shouldResume) == true {
                    self?.resume()
                }
            @unknown default: break
            }
        }
    }

    // MARK: - Route Change Observer
    private func setupRouteChangeObserver() {
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification, object: nil, queue: .main
        ) { [weak self] notification in
            guard let reason = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
                  AVAudioSession.RouteChangeReason(rawValue: reason) == .oldDeviceUnavailable
            else { return }
            self?.pause()
        }
    }

    // MARK: - Cleanup
    private func cleanup() {
        removeTimeObserver()
        player?.pause()
        player = nil
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let playerDidFinishTrack  = Notification.Name("playerDidFinishTrack")
    static let playerSkipNext        = Notification.Name("playerSkipNext")
    static let playerSkipPrevious    = Notification.Name("playerSkipPrevious")
}
