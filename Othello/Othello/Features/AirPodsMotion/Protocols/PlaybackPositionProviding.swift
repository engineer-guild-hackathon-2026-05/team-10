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

struct SessionAnchoredPlaybackPositionProvider: PlaybackPositionProviding {
    let startedAt: Date
    let initialPlaybackTime: TimeInterval

    func currentPlaybackTime() -> TimeInterval? {
        initialPlaybackTime + Date().timeIntervalSince(startedAt)
    }
}
