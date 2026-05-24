import Foundation

struct SynchronizedLyrics: Equatable {
    let providerName: String
    let providerTrackID: String?
    let query: LyricsTrackQuery
    let lines: [TimedLyricLine]

    var isEmpty: Bool {
        lines.isEmpty
    }

    func line(at playbackTime: TimeInterval) -> TimedLyricLine? {
        TimedLyricsResolver.line(at: playbackTime, in: lines)
    }
}

struct ReactionLyricMatch: Equatable {
    let reactionTime: TimeInterval
    let line: TimedLyricLine?

    var shouldShowTimeOnly: Bool {
        line == nil
    }
}
