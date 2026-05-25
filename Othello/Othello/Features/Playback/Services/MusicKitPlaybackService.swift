import Foundation
import MusicKit
import Combine

@MainActor
final class MusicKitPlaybackService: ObservableObject, PlaybackPositionProviding {

    @Published private(set) var authorizationStatus: MusicAuthorization.Status = .notDetermined
    @Published private(set) var currentTrack: PlaybackTrack?
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var playbackTime: TimeInterval = 0
    @Published private(set) var isPositionAvailable: Bool = false

    private let player = ApplicationMusicPlayer.shared
    private var positionTimer: AnyCancellable?
    private var playerStateCancellable: AnyCancellable?

    init() {
        // メインスレッドをブロックしないよう非同期で遅延初期化
        Task { @MainActor in self.observePlayerState() }
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
        isPositionAvailable = (status == .authorized)
        if status != .authorized {
            notifyPositionUnavailable()
        }
    }

    // MARK: - Search

    func search(query: String) async throws -> [PlaybackTrack] {
        guard authorizationStatus == .authorized else { return [] }
        var request = MusicCatalogSearchRequest(term: query, types: [Song.self])
        request.limit = 20
        let response = try await request.response()
        return response.songs.map { PlaybackTrack(song: $0) }
    }

    // MARK: - Playback control

    func play(track: PlaybackTrack) async throws {
        guard authorizationStatus == .authorized else { return }
        var request = MusicCatalogResourceRequest<Song>(matching: \.id, equalTo: track.id)
        request.limit = 1
        let response = try await request.response()
        guard let song = response.items.first else { return }
        player.queue = [song]
        try await player.play()
        currentTrack = track
        startPositionTimer()
    }

    func togglePlayback() async {
        if isPlaying {
            player.pause()
            stopPositionTimer()
        } else {
            try? await player.play()
            startPositionTimer()
        }
    }

    func stop() {
        player.stop()
        stopPositionTimer()
        playbackTime = 0
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

    private func notifyPositionUnavailable() {
        isPositionAvailable = false
    }
}
