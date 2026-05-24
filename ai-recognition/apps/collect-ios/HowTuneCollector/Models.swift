import Foundation
import SwiftUI

enum ListeningLabel: String, CaseIterable, Codable, Identifiable {
    case groove
    case hype
    case chill
    case immersion
    case hit
    case afterglow
    case unknown
    case noise

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .groove: "ノってる"
        case .hype: "上がった"
        case .chill: "チルい"
        case .immersion: "聴き入ってる"
        case .hit: "刺さった"
        case .afterglow: "余韻"
        case .unknown: "わからない"
        case .noise: "ノイズ"
        }
    }

    var hint: String {
        switch self {
        case .groove: "リズムに身体が合っている"
        case .hype: "展開やサビで反応した"
        case .chill: "ゆるく心地よく聴いている"
        case .immersion: "静かに集中している"
        case .hit: "一瞬の音・歌詞・展開"
        case .afterglow: "反応後に味わっている"
        case .unknown: "判断できない"
        case .noise: "操作ミスや揺れノイズ"
        }
    }

    var trainingLabel: Bool {
        switch self {
        case .groove, .hype, .chill, .immersion, .hit, .afterglow: true
        case .unknown, .noise: false
        }
    }

    var color: Color {
        switch self {
        case .groove: Color(red: 0.06, green: 0.55, blue: 0.55)
        case .hype: Color(red: 0.86, green: 0.33, blue: 0.25)
        case .chill: Color(red: 0.29, green: 0.56, blue: 0.34)
        case .immersion: Color(red: 0.30, green: 0.46, blue: 0.68)
        case .hit: Color(red: 0.80, green: 0.58, blue: 0.10)
        case .afterglow: Color(red: 0.44, green: 0.42, blue: 0.25)
        case .unknown: .gray
        case .noise: .red.opacity(0.75)
        }
    }

    var defaultBeforeSec: TimeInterval {
        switch self {
        case .hit: 1.5
        case .hype, .afterglow: 2.0
        case .immersion: 1.0
        default: 5.0
        }
    }

    var defaultAfterSec: TimeInterval {
        switch self {
        case .hit: 1.5
        case .hype: 5.0
        case .afterglow: 6.0
        case .immersion: 4.0
        default: 5.0
        }
    }

    static let primaryCases: [ListeningLabel] = [.groove, .hype, .chill, .immersion, .hit, .afterglow]
}

struct DemoSong: Identifiable, Codable, Equatable {
    enum Pattern: String, Codable {
        case groove
        case hype
        case chill
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
            id: "hype-demo",
            title: "Hype Drop Track",
            description: "BPM 126 / 展開変化と刺さり",
            bpm: 126,
            durationSec: 60,
            pattern: .hype
        ),
        DemoSong(
            id: "chill-demo",
            title: "Chill Afterglow Track",
            description: "BPM 76 / チル、没入、余韻",
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
