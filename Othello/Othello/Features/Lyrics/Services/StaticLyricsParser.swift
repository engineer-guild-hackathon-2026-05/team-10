import Foundation

enum StaticLyricsParser {
    nonisolated static func parse(_ body: String) -> [TimedLyricLine] {
        body
            .components(separatedBy: .newlines)
            .compactMap(cleanedLyricText)
            .enumerated()
            .map { index, text in
                TimedLyricLine(
                    startTime: TimeInterval(index),
                    endTime: nil,
                    text: text
                )
            }
    }

    nonisolated static func parseLRC(_ body: String) -> [TimedLyricLine] {
        let pattern = #"\[(\d{1,2}):(\d{2})(?:[\.:](\d{1,3}))?\]"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return []
        }

        var parsedLines: [(startTime: TimeInterval, text: String)] = []

        for rawLine in body.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            let range = NSRange(line.startIndex..<line.endIndex, in: line)
            let matches = regex.matches(in: line, range: range)
            guard !matches.isEmpty else { continue }

            let lyricText = regex
                .stringByReplacingMatches(in: line, range: range, withTemplate: "")

            guard let text = cleanedLyricText(lyricText) else { continue }

            for match in matches {
                guard let startTime = timestamp(from: match, in: line) else { continue }
                parsedLines.append((startTime, text))
            }
        }

        let sortedLines = parsedLines.sorted { lhs, rhs in
            if lhs.startTime == rhs.startTime {
                return lhs.text < rhs.text
            }
            return lhs.startTime < rhs.startTime
        }

        return sortedLines.enumerated().map { index, line in
            let nextStart = sortedLines.indices.contains(index + 1)
                ? sortedLines[index + 1].startTime
                : nil
            return TimedLyricLine(
                startTime: line.startTime,
                endTime: nextStart,
                text: line.text
            )
        }
    }

    private nonisolated static func timestamp(
        from match: NSTextCheckingResult,
        in line: String
    ) -> TimeInterval? {
        guard
            let minutes = integerValue(at: 1, from: match, in: line),
            let seconds = integerValue(at: 2, from: match, in: line)
        else {
            return nil
        }

        let fractionRaw = stringValue(at: 3, from: match, in: line) ?? ""
        let fraction: TimeInterval
        if fractionRaw.isEmpty {
            fraction = 0
        } else {
            let divisor = pow(10.0, Double(fractionRaw.count))
            fraction = Double(Int(fractionRaw) ?? 0) / divisor
        }

        return TimeInterval(minutes * 60 + seconds) + fraction
    }

    private nonisolated static func integerValue(
        at index: Int,
        from match: NSTextCheckingResult,
        in line: String
    ) -> Int? {
        guard let value = stringValue(at: index, from: match, in: line) else {
            return nil
        }
        return Int(value)
    }

    private nonisolated static func stringValue(
        at index: Int,
        from match: NSTextCheckingResult,
        in line: String
    ) -> String? {
        let range = match.range(at: index)
        guard range.location != NSNotFound, let stringRange = Range(range, in: line) else {
            return nil
        }
        return String(line[stringRange])
    }

    private nonisolated static func cleanedLyricText(_ rawText: String) -> String? {
        let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }
        guard !(text.hasPrefix("[") && text.hasSuffix("]")) else { return nil }
        guard !text.hasPrefix("*******") else { return nil }
        guard !text.localizedCaseInsensitiveContains("This Lyrics is NOT for Commercial use") else {
            return nil
        }
        guard !text.localizedCaseInsensitiveContains("This Lyrics is NOT for Broadcast") else {
            return nil
        }
        return text
    }
}
