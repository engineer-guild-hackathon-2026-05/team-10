import Foundation
import SwiftUI

enum ListeningLabel: String, CaseIterable, Codable, Identifiable {
    case groove
    case chill
    case neutral

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .groove: "ノってる"
        case .chill: "チルい"
        case .neutral: "neutral"
        }
    }

    var hint: String {
        switch self {
        case .groove: "リズムに身体が合っている"
        case .chill: "ゆるく心地よく聴いている"
        case .neutral: "大きな反応がない"
        }
    }

    var color: Color {
        switch self {
        case .groove: Color(red: 0.06, green: 0.55, blue: 0.55)
        case .chill: Color(red: 0.29, green: 0.56, blue: 0.34)
        case .neutral: Color(red: 0.37, green: 0.42, blue: 0.40)
        }
    }

    var defaultBeforeSec: TimeInterval {
        5.0
    }

    var defaultAfterSec: TimeInterval {
        5.0
    }

    static let primaryCases: [ListeningLabel] = [.groove, .chill, .neutral]
}

struct DemoSong: Identifiable, Codable, Equatable {
    enum Pattern: String, Codable {
        case groove
        case chill
        case neutral
    }

    let id: String
    let title: String
    let description: String
    let bpm: Double
    let durationSec: TimeInterval
    let pattern: Pattern

    static let catalog: [DemoSong] = [
        DemoSong(
            id: "groove-demo",
            title: "Groove Track",
            description: "BPM 100 / 継続的なノリを集める",
            bpm: 100,
            durationSec: 60,
            pattern: .groove
        ),
        DemoSong(
            id: "neutral-demo",
            title: "Neutral Track",
            description: "BPM 92 / 大きな反応なしを集める",
            bpm: 92,
            durationSec: 60,
            pattern: .neutral
        ),
        DemoSong(
            id: "chill-demo",
            title: "Chill Track",
            description: "BPM 76 / 小さく心地よい揺れを集める",
            bpm: 76,
            durationSec: 60,
            pattern: .chill
        )
    ]
}

struct MotionSample: Codable, Identifiable {
    var id = UUID()
    var t: TimeInterval
    var ax: Double
    var ay: Double
    var az: Double
    var gx: Double?
    var gy: Double?
    var gz: Double?
    var source: MotionSensorSource?
    var pitch: Double?
    var roll: Double?
    var yaw: Double?

    enum CodingKeys: String, CodingKey {
        case t, ax, ay, az, gx, gy, gz, source, pitch, roll, yaw
    }
}

enum MotionSensorSource: String, Codable {
    case headphoneMotion = "headphone_motion"
    case deviceMotion = "device_motion"
    case accelerometer = "accelerometer"
}

struct LabelEvent: Codable, Identifiable {
    var id: String
    var sessionId: String
    var label: ListeningLabel
    var startedAtSec: TimeInterval
    var endedAtSec: TimeInterval
    var source: String
    var confidence: Int?
}

struct SessionRecord: Codable, Identifiable {
    var id: String
    var userId: String
    var songId: String
    var startedAt: Date
    var endedAt: Date?
    var device: DeviceInfo
}

struct DeviceInfo: Codable {
    var name: String
    var systemName: String
    var systemVersion: String
    var model: String
}

struct CollectedSession: Codable {
    var session: SessionRecord
    var samples: [MotionSample]
    var labels: [LabelEvent]
}
