import Foundation
import SwiftUI

// FR-HMOTION-02: 頭部モーション取得状態（接続中/未接続/非対応機種）
enum HeadMotionState {
    case connected
    case disconnected
    case unsupported

    var label: String {
        switch self {
        case .connected:    return "接続中"
        case .disconnected: return "未接続"
        case .unsupported:  return "非対応機種"
        }
    }

    var color: Color {
        switch self {
        case .connected:    return .green
        case .disconnected: return .orange
        case .unsupported:  return .gray
        }
    }

    var systemImage: String {
        switch self {
        case .connected:    return "airpods"
        case .disconnected: return "airpods"
        case .unsupported:  return "airpods"
        }
    }
}

struct SensorStatusBundle {
    var headMotion: HeadMotionState

    static let initial = SensorStatusBundle(
        headMotion: .disconnected
    )

    static func from(_ permissionState: PermissionState) -> SensorStatusBundle {
        let headMotion: HeadMotionState = permissionState.airPodsAvailable ? .disconnected : .unsupported
        return SensorStatusBundle(headMotion: headMotion)
    }
}
