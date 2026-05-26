import MusicKit

enum AppleMusicAccessStatus: Equatable {
    case notDetermined
    case checking
    case authorized
    case permissionDenied
    case subscriptionRequired
    case unavailable

    init(authorizationStatus: MusicAuthorization.Status) {
        switch authorizationStatus {
        case .authorized:
            self = .checking
        case .notDetermined:
            self = .notDetermined
        case .denied, .restricted:
            self = .permissionDenied
        @unknown default:
            self = .unavailable
        }
    }

    var canUseCatalogPlayback: Bool {
        self == .authorized
    }

    var shouldShowNotice: Bool {
        switch self {
        case .permissionDenied, .subscriptionRequired, .unavailable:
            return true
        case .notDetermined, .checking, .authorized:
            return false
        }
    }

    var title: String {
        switch self {
        case .notDetermined:
            return "Apple Music の認証が必要です"
        case .checking:
            return "Apple Music を確認しています"
        case .authorized:
            return "Apple Music を利用できます"
        case .permissionDenied:
            return "Apple Music の認証が必要です"
        case .subscriptionRequired:
            return "Apple Music の契約が必要です"
        case .unavailable:
            return "Apple Music の状態を確認できません"
        }
    }

    var message: String {
        switch self {
        case .notDetermined:
            return "曲の再生と再生位置の同期には、Apple Music へのアクセス許可が必要です。"
        case .checking:
            return "Apple Music の認証と契約状態を確認しています。"
        case .authorized:
            return "曲の再生と再生位置の同期が利用できます。"
        case .permissionDenied:
            return "設定の「メディアと Apple Music」で HowTune へのアクセスを許可してください。"
        case .subscriptionRequired:
            return "曲を再生するには Apple Music の契約が必要です。契約済みの Apple ID でサインインしてから、もう一度確認してください。"
        case .unavailable:
            return "通信状況や Apple ID の状態を確認してから、もう一度お試しください。"
        }
    }

    var systemImage: String {
        switch self {
        case .subscriptionRequired:
            return "music.note.list"
        case .permissionDenied:
            return "lock.slash"
        case .unavailable:
            return "exclamationmark.triangle"
        case .checking:
            return "music.note"
        case .notDetermined, .authorized:
            return "music.note"
        }
    }
}
