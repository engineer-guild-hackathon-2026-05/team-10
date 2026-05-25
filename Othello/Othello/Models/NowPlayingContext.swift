import Foundation

struct NowPlayingContext: Identifiable, Equatable {
    let id = UUID()
    let song: Song
    let initialPlaybackTime: TimeInterval
    let highlightStart: TimeInterval?
    let highlightEnd: TimeInterval?
    let sourceHowCardID: String?

    init(
        song: Song,
        initialPlaybackTime: TimeInterval? = nil,
        highlightStart: TimeInterval? = nil,
        highlightEnd: TimeInterval? = nil,
        sourceHowCardID: String? = nil
    ) {
        self.song = song
        self.initialPlaybackTime = Self.clamp(initialPlaybackTime ?? 0, duration: song.duration)
        self.highlightStart = Self.clampedOptional(highlightStart, duration: song.duration)
        self.highlightEnd = Self.clampedOptional(highlightEnd, duration: song.duration)
        self.sourceHowCardID = sourceHowCardID
    }

    init(song: Song, howCardComment: HowCardComment) {
        let start = Self.clamp(howCardComment.songStart, duration: song.duration)
        let end = Self.clampedOptional(howCardComment.songEnd, duration: song.duration)
        let hasExplicitRange = start > 0 || end.map { $0 > start } == true

        self.init(
            song: song,
            initialPlaybackTime: start,
            highlightStart: hasExplicitRange ? start : nil,
            highlightEnd: end.flatMap { $0 > start ? $0 : nil },
            sourceHowCardID: howCardComment.documentID
        )
    }

    var hasHighlight: Bool {
        highlightStart != nil || highlightEnd != nil
    }

    private static func clamp(_ value: TimeInterval, duration: TimeInterval) -> TimeInterval {
        guard value.isFinite else { return 0 }
        return min(max(value, 0), max(duration, 0))
    }

    private static func clampedOptional(_ value: TimeInterval?, duration: TimeInterval) -> TimeInterval? {
        guard let value else { return nil }
        return clamp(value, duration: duration)
    }
}

private extension Song {
    var duration: TimeInterval {
        TimeInterval(max(durationSeconds, 0))
    }
}
