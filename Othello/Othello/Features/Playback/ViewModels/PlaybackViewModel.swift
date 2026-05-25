import Foundation
import MusicKit
import Combine

@MainActor
final class PlaybackViewModel: ObservableObject {

    @Published private(set) var currentTrack: PlaybackTrack?
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var playbackTime: TimeInterval = 0
    @Published private(set) var isPositionAvailable: Bool = false
    @Published private(set) var authorizationStatus: MusicAuthorization.Status = .notDetermined
    @Published var searchResults: [PlaybackTrack] = []
    @Published var searchQuery: String = ""
    @Published var positionUnavailableAlertShown: Bool = false
    @Published private(set) var positionUnavailableMessage: String = "Apple Music の認証が必要です。このセッションでは反応の同期が無効になります。"

    private let service: MusicKitPlaybackService
    private var cancellables: Set<AnyCancellable> = []

    init() {
        self.service = MusicKitPlaybackService()
        bindService()
    }

    // MARK: - Public API

    func onAppear() async {
        // 起動直後のwatchdogタイムアウトを避けるため少し遅延してから認証
        try? await Task.sleep(for: .milliseconds(500))
        await service.requestAuthorization()
    }

    func search() async {
        guard !searchQuery.isEmpty else {
            searchResults = []
            return
        }
        searchResults = (try? await service.search(query: searchQuery)) ?? []
    }

    @discardableResult
    func select(track: PlaybackTrack) async -> PlaybackTrack? {
        try? await service.play(track: track)
        if !service.isPositionAvailable {
            positionUnavailableAlertShown = true
            return nil
        }
        return service.currentTrack
    }

    @discardableResult
    func select(song: Song) async -> PlaybackTrack? {
        if let musicKitID = song.musicKitID {
            let track = PlaybackTrack(
                id: MusicItemID(rawValue: musicKitID),
                musicKitID: musicKitID,
                title: song.title,
                artistName: song.artistName,
                albumTitle: nil,
                isrc: nil,
                hasLyrics: false,
                duration: song.duration,
                artworkURL: song.artworkURL
            )
            return await select(track: track)
        }

        do {
            let results = try await service.search(query: "\(song.title) \(song.artistName)")
            guard let track = bestMatch(for: song, in: results) else {
                positionUnavailableMessage = "Apple Music で \(song.title) を見つけられませんでした。"
                positionUnavailableAlertShown = true
                return nil
            }
            return await select(track: track)
        } catch {
            positionUnavailableMessage = "Apple Music の曲検索に失敗しました。"
            positionUnavailableAlertShown = true
            return nil
        }
    }

    func togglePlayback() async {
        await service.togglePlayback()
    }

    func stop() {
        service.stop()
    }

    /// センサー記録に渡す再生位置（取得不可の場合 nil）
    func currentPlaybackTime() -> TimeInterval? {
        service.currentPlaybackTime()
    }

    func playbackPositionProvider() -> PlaybackPositionProviding {
        service
    }

    // MARK: - Private

    private func bindService() {
        service.$currentTrack
            .receive(on: RunLoop.main)
            .assign(to: \.currentTrack, on: self)
            .store(in: &cancellables)

        service.$isPlaying
            .receive(on: RunLoop.main)
            .assign(to: \.isPlaying, on: self)
            .store(in: &cancellables)

        service.$playbackTime
            .receive(on: RunLoop.main)
            .assign(to: \.playbackTime, on: self)
            .store(in: &cancellables)

        service.$isPositionAvailable
            .receive(on: RunLoop.main)
            .assign(to: \.isPositionAvailable, on: self)
            .store(in: &cancellables)

        service.$authorizationStatus
            .receive(on: RunLoop.main)
            .assign(to: \.authorizationStatus, on: self)
            .store(in: &cancellables)

        service.$unavailableReason
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] message in
                guard let self else { return }
                self.positionUnavailableMessage = message
                if self.currentTrack != nil {
                    self.positionUnavailableAlertShown = true
                }
            }
            .store(in: &cancellables)
    }

    private func bestMatch(for song: Song, in tracks: [PlaybackTrack]) -> PlaybackTrack? {
        tracks.first {
            $0.title.localizedCaseInsensitiveContains(song.title)
                && $0.artistName.localizedCaseInsensitiveContains(song.artistName)
        } ?? tracks.first {
            $0.title.localizedCaseInsensitiveContains(song.title)
        } ?? tracks.first
    }
}
