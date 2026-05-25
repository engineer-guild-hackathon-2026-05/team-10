enum AirPodsMotionStatus: Equatable {
    case idle
    case starting
    case recording
    case stopped
    case disconnected
    case unsupported
    case unavailable(String)
    case failed(String)

    var title: String {
        switch self {
        case .idle:
            return "待機中"
        case .starting:
            return "接続確認中"
        case .recording:
            return "取得中"
        case .stopped:
            return "停止中"
        case .disconnected:
            return "AirPods未接続"
        case .unsupported:
            return "非対応"
        case .unavailable:
            return "利用不可"
        case .failed:
            return "取得失敗"
        }
    }

    var detail: String {
        switch self {
        case .idle:
            return "AirPodsの頭部モーション取得を開始できます。"
        case .starting:
            return "対応AirPodsの接続状態を確認しています。"
        case .recording:
            return "頭部の加速度・回転速度・姿勢を曲中時刻に同期して記録しています。"
        case .stopped:
            return "頭部モーション取得は停止しています。"
        case .disconnected:
            return "対応AirPodsが見つかりません。曲中の反応は手動で記録できます。"
        case .unsupported:
            return "このプラットフォームではAirPods頭部モーションを取得できません。"
        case .unavailable(let reason):
            return reason
        case .failed(let reason):
            return reason
        }
    }

    var isRecording: Bool {
        self == .recording
    }
}
