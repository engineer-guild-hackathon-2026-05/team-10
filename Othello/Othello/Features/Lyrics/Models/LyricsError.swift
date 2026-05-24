import Foundation

enum LyricsError: LocalizedError, Equatable {
    case missingAPIKey
    case invalidRequest
    case invalidResponse
    case requestFailed(String)
    case apiStatus(code: Int, message: String?)
    case trackNotFound
    case restrictedLyrics
    case emptyLyricsBody
    case synchronizedLyricsUnavailable
    case lookupFailed([String])

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
            if code == 401 {
                return "Musixmatch API キーが無効、または設定されていません。ENV.plist の MUSIXMATCH_API_KEY を確認してください。"
            }
            if code == 402 {
                return "Musixmatch API の利用上限、または残高の制限に達しています。"
            }
            if code == 403 {
                return "Musixmatch API のこの操作を実行する権限がありません。利用中のプラン/APIキーで使えるエンドポイントを確認してください。"
            }
            return "歌詞APIがエラーを返しました: \(code)\(message.map { " \($0)" } ?? "")"
        case .trackNotFound:
            return "曲名とアーティスト名に一致する歌詞が見つかりませんでした。"
        case .restrictedLyrics:
            return "この曲の歌詞は権利制限により表示できません。"
        case .emptyLyricsBody:
            return "歌詞の本文が空でした。"
        case .synchronizedLyricsUnavailable:
            return "この曲の歌詞は取得できませんでした。"
        case .lookupFailed(let failures):
            let details = failures.prefix(3).joined(separator: " / ")
            return details.isEmpty
                ? "この曲の歌詞は取得できませんでした。"
                : "この曲の歌詞は取得できませんでした。詳細: \(details)"
        }
    }
}
