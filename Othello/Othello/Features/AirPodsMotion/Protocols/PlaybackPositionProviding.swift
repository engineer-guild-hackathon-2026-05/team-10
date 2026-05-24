import Foundation

protocol PlaybackPositionProviding {
    func currentPlaybackTime() -> TimeInterval?
}

struct SessionElapsedPlaybackPositionProvider: PlaybackPositionProviding {
    let startedAt: Date

    func currentPlaybackTime() -> TimeInterval? {
        Date().timeIntervalSince(startedAt)
    }
}
