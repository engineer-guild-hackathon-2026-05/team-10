import Foundation

enum StaticLyricsParser {
    nonisolated static func parse(_ body: String) -> [TimedLyricLine] {
        body
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .enumerated()
            .map { index, text in
                TimedLyricLine(
                    startTime: TimeInterval(index),
                    endTime: nil,
                    text: text
                )
            }
    }
}
