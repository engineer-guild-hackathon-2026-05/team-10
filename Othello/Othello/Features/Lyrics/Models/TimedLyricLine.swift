import Foundation

struct TimedLyricLine: Identifiable, Equatable {
    let startTime: TimeInterval
    let endTime: TimeInterval?
    let text: String

    var id: String {
        "\(startTime)-\(text)"
    }

    nonisolated func contains(_ playbackTime: TimeInterval) -> Bool {
        guard playbackTime >= startTime else {
            return false
        }

        guard let endTime else {
            return true
        }

        return playbackTime < endTime
    }
}
