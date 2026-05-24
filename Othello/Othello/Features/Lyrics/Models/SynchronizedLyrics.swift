import Foundation

struct SynchronizedLyrics: Equatable {
    let providerName: String
    let providerTrackID: String?
    let query: LyricsTrackQuery
    let lines: [TimedLyricLine]
    let isTimeSynced: Bool

    init(
        providerName: String,
        providerTrackID: String?,
        query: LyricsTrackQuery,
        lines: [TimedLyricLine],
        isTimeSynced: Bool = true
    ) {
        self.providerName = providerName
        self.providerTrackID = providerTrackID
        self.query = query
        self.lines = lines
        self.isTimeSynced = isTimeSynced
    }

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
