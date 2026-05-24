import Foundation

enum LyricsError: LocalizedError, Equatable {
    case missingAPIKey
    case invalidRequest
    case invalidResponse
    case requestFailed(String)
    case apiStatus(code: Int, message: String?)
    case trackNotFound
    case synchronizedLyricsUnavailable

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Musixmatch API キーが設定されていません。ENV.plist の MUSIXMATCH_API_KEY を設定してください。"
        case .invalidRequest:
            return "歌詞取得リクエストを作成できませんでした。"
        case .invalidResponse:
            return "歌詞APIのレスポンスを読み取れませんでした。"
        case .requestFailed(let message):
            return "歌詞APIへの通信に失敗しました: \(message)"
        case .apiStatus(let code, let message):
            return "歌詞APIがエラーを返しました: \(code)\(message.map { " \($0)" } ?? "")"
        case .trackNotFound:
            return "曲名とアーティスト名に一致する歌詞が見つかりませんでした。"
        case .synchronizedLyricsUnavailable:
            return "この曲の時間同期歌詞は取得できませんでした。"
        }
    }
}
