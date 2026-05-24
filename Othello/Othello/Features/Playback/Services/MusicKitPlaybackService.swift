import Foundation
import MusicKit
import Combine

@MainActor
final class MusicKitPlaybackService: ObservableObject, PlaybackPositionProviding {

    @Published private(set) var authorizationStatus: MusicAuthorization.Status = MusicAuthorization.currentStatus
    @Published private(set) var currentTrack: PlaybackTrack?
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var playbackTime: TimeInterval = 0
    @Published private(set) var isPositionAvailable: Bool = false
    @Published private(set) var unavailableReason: String?

    private let player = ApplicationMusicPlayer.shared
    private var positionTimer: AnyCancellable?
    private var playerStateCancellable: AnyCancellable?

    init() {
        observePlayerState()
    }

    // MARK: - PlaybackPositionProviding

    func currentPlaybackTime() -> TimeInterval? {
        guard isPositionAvailable else { return nil }
        return playbackTime
    }

    // MARK: - Authorization

    func requestAuthorization() async {
        let status = await MusicAuthorization.request()
        authorizationStatus = status

        if status != .authorized {
            notifyPositionUnavailable("Apple Music の認証が許可されていません。")
            return
        }

        do {
            let subscription = try await MusicSubscription.current
            guard subscription.canPlayCatalogContent else {
                notifyPositionUnavailable("Apple Music のカタログ再生が利用できません。")
                return
            }

            unavailableReason = nil
            isPositionAvailable = currentTrack != nil
        } catch {
            notifyPositionUnavailable("Apple Music の利用状態を確認できませんでした。")
        }
    }

    // MARK: - Search

    func search(query: String) async throws -> [PlaybackTrack] {
        guard authorizationStatus == .authorized else {
            notifyPositionUnavailable("Apple Music の認証が許可されていません。")
            return []
        }

        var request = MusicCatalogSearchRequest(term: query, types: [Song.self])
        request.limit = 20
        let response = try await request.response()
        return response.songs.map { PlaybackTrack(song: $0) }
    }

    // MARK: - Playback control

    func play(track: PlaybackTrack) async throws {
        guard authorizationStatus == .authorized else {
            notifyPositionUnavailable("Apple Music の認証が許可されていません。")
            return
        }

        var request = MusicCatalogResourceRequest<Song>(matching: \.id, equalTo: track.id)
        request.limit = 1
        let response = try await request.response()
        guard let song = response.items.first else {
            notifyPositionUnavailable("選択した曲を Apple Music から取得できませんでした。")
            return
        }

        player.queue = [song]
        try await player.prepareToPlay()
        try await player.play()
        currentTrack = PlaybackTrack(song: song)
        unavailableReason = nil
        isPositionAvailable = true
        isPlaying = true
        startPositionTimer()
    }

    func togglePlayback() async {
        guard currentTrack != nil else {
            notifyPositionUnavailable("曲が選択されていません。")
            return
        }

        if isPlaying {
            player.pause()
            isPlaying = false
            stopPositionTimer()
        } else {
            try? await player.play()
            isPlaying = true
            startPositionTimer()
        }
    }

    func stop() {
        player.stop()
        isPlaying = false
        stopPositionTimer()
        playbackTime = 0
        isPositionAvailable = currentTrack != nil
    }

    // MARK: - Private

    private func observePlayerState() {
        playerStateCancellable = player.state.objectWillChange.sink { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.isPlaying = self.player.state.playbackStatus == .playing
            }
        }
    }

    private func startPositionTimer() {
        stopPositionTimer()
        playbackTime = player.playbackTime
        isPositionAvailable = currentTrack != nil
        positionTimer = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                self.playbackTime = self.player.playbackTime
            }
    }

    private func stopPositionTimer() {
        positionTimer?.cancel()
        positionTimer = nil
    }

    private func notifyPositionUnavailable(_ reason: String) {
        unavailableReason = reason
        isPositionAvailable = false
    }
}
