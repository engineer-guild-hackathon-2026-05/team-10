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

    private let service: MusicKitPlaybackService
    private var cancellables: Set<AnyCancellable> = []

    init() {
        self.service = MusicKitPlaybackService()
        bindService()
    }

    // MARK: - Public API

    func onAppear() async {
        await service.requestAuthorization()
        if service.authorizationStatus != .authorized {
            positionUnavailableAlertShown = true
        }
    }

    func search() async {
        guard !searchQuery.isEmpty else {
            searchResults = []
            return
        }
        searchResults = (try? await service.search(query: searchQuery)) ?? []
    }

    func select(track: PlaybackTrack) async {
        try? await service.play(track: track)
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
    }
}
