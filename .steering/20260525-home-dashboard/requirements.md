# Home Dashboard Renewal Requirements

## Goal

Home を、再生中のアーティスト体験とコミュニティコメント発見を同じ画面で扱える dashboard に刷新する。

## Requirements

- `update/home` ブランチ上で実装する。
- Home 上部にはアーティストカードを表示し、カード背景には可能な限りアーティストまたは楽曲のジャケット画像を使う。
- Home 下部には Firebase Functions の `/how-cards` を実際に呼び出して取得したおすすめコメントを複数表示する。
- コメントカードをタップすると、そのコメントに紐づくアーティストの画面へ遷移し、対象コメントが表示される。
- 既存の通常コメント画面の見た目や文脈を崩さず、Home から遷移した場合も自然に読めるようにする。
- API 未設定、未ログイン、通信失敗時は画面が破綻しない loading / empty / error state を持つ。
- `AI_USAGE_LOG.md` に Codex 作業ログを残す。

## Non-Goals

- Firestore / Firebase Functions の新規 endpoint 追加は行わない。
- Howカード作成フローの全面刷新は行わない。
- MusicFeed の mock 投稿を完全に実データ化することは今回の必須範囲外とする。
