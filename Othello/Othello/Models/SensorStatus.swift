import SwiftUI
import Foundation

// FR-SENS-03: センサー取得状態（取得中/停止/未許可/非対応）
enum SensorAcquisitionState {
    case acquiring
    case stopped
    case unauthorized
    case unsupported

    var label: String {
        switch self {
        case .acquiring:    return "取得中"
        case .stopped:      return "停止"
        case .unauthorized: return "未許可"
        case .unsupported:  return "非対応"
        }
    }

    var color: Color {
        switch self {
        case .acquiring:    return .green
        case .stopped:      return .yellow
        case .unauthorized: return .red
        case .unsupported:  return .gray
        }
    }

    var systemImage: String {
        switch self {
        case .acquiring:    return "checkmark.circle.fill"
        case .stopped:      return "pause.circle.fill"
        case .unauthorized: return "exclamationmark.circle.fill"
        case .unsupported:  return "xmark.circle.fill"
        }
    }
}

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

// 3センサーをまとめる値型
struct SensorStatusBundle {
    var headMotion: HeadMotionState
    var bodyMotion: SensorAcquisitionState
    var heartRate: SensorAcquisitionState

    static let initial = SensorStatusBundle(
        headMotion: .disconnected,
        bodyMotion: .stopped,
        heartRate: .stopped
    )

    static func from(_ permissionState: PermissionState) -> SensorStatusBundle {
        let headMotion: HeadMotionState = permissionState.airPodsAvailable ? .disconnected : .unsupported
        let bodyMotion: SensorAcquisitionState = permissionState.motion == .denied ? .unauthorized : .stopped
        let heartRate: SensorAcquisitionState = permissionState.health == .denied ? .unauthorized : .stopped
        return SensorStatusBundle(headMotion: headMotion, bodyMotion: bodyMotion, heartRate: heartRate)
    }
}
