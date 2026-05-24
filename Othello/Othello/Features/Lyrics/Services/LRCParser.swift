import Foundation

enum LRCParser {
    nonisolated static func parse(_ body: String) -> [TimedLyricLine] {
        let rawLines = body
            .components(separatedBy: .newlines)
            .flatMap(parseLine)
            .sorted { $0.startTime < $1.startTime }

        guard !rawLines.isEmpty else {
            return []
        }

        return rawLines.enumerated().map { index, rawLine in
            let nextStartTime = rawLines.indices.contains(index + 1)
                ? rawLines[index + 1].startTime
                : nil

            return TimedLyricLine(
                startTime: rawLine.startTime,
                endTime: nextStartTime,
                text: rawLine.text
            )
        }
    }

    private nonisolated static func parseLine(_ line: String) -> [RawLyricLine] {
        let timestampPattern = #"\[(\d{1,2}):(\d{2})(?:[.:](\d{1,3}))?\]"#
        guard let regex = try? NSRegularExpression(pattern: timestampPattern) else {
            return []
        }

        let range = NSRange(line.startIndex..<line.endIndex, in: line)
        let matches = regex.matches(in: line, range: range)

        guard !matches.isEmpty else {
            return []
        }

        let text = regex.stringByReplacingMatches(
            in: line,
            range: range,
            withTemplate: ""
        )
        .trimmingCharacters(in: .whitespacesAndNewlines)

        return matches.compactMap { match in
            guard
                let minuteRange = Range(match.range(at: 1), in: line),
                let secondRange = Range(match.range(at: 2), in: line),
                let minutes = TimeInterval(String(line[minuteRange])),
                let seconds = TimeInterval(String(line[secondRange]))
            else {
                return nil
            }

            var fraction: TimeInterval = 0
            if
                match.range(at: 3).location != NSNotFound,
                let fractionRange = Range(match.range(at: 3), in: line),
                let fractionValue = TimeInterval(String(line[fractionRange]))
            {
                let digitCount = line[fractionRange].count
                fraction = fractionValue / pow(10, TimeInterval(digitCount))
            }

            return RawLyricLine(
                startTime: minutes * 60 + seconds + fraction,
                text: text
            )
        }
    }

    private struct RawLyricLine {
        let startTime: TimeInterval
        let text: String
    }
}
