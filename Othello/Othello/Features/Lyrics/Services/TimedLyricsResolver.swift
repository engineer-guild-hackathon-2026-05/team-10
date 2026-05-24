import Foundation

enum TimedLyricsResolver {
    nonisolated static func line(at playbackTime: TimeInterval, in lines: [TimedLyricLine]) -> TimedLyricLine? {
        guard !lines.isEmpty else {
            return nil
        }

        if let directMatch = lines.first(where: { $0.contains(playbackTime) }) {
            return directMatch
        }

        return lines.last(where: { $0.startTime <= playbackTime })
    }
}
