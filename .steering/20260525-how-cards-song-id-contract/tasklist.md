# How Cards Song ID Contract Tasklist

- [x] issue #78 と既存 Functions 実装を確認する
- [x] 要件・設計・タスクを steering に記録する
- [x] Functions の payload normalize / serializer を修正する
- [x] API docs と data model docs を更新する
- [x] AI_USAGE_LOG.md を更新する
- [x] Functions の静的検証を実行する
- [x] Firebase Functions deploy を実行する

## PR #86 レビュー対応と main conflict 解消

- [x] `origin/main` を merge して `AI_USAGE_LOG.md` の conflict を解消する
- [x] `GET /how-cards?song_id=...` を `itunes_id` 主軸 + `song_id` fallback で検索する
- [x] MusicKit / Apple Music / iTunes ID validation を空でない numeric string に緩和する
- [x] docs の `goods` 表記を `likes` に統一し、Firestore schema に `itunes_id` / `song_slug` を追記する
- [x] `itunes_id + created_at` の Firestore index を追加する
- [x] Functions の静的検証、差分検証、iOS ビルドを実行する

## PR #86 再レビュー対応と main 再merge

- [x] 最新 `origin/main` を merge して `docs/backend.md` / `functions/repositories/firestore.js` の conflict を解消する
- [x] main 側の `user_name` 付与を維持したまま、`itunes_id` 主軸 + `song_id` fallback 検索を残す
- [x] Functions の公開レスポンスと docs のカウンタ表記を `likes` に統一する
- [x] 既存 `goods` データは読み取り互換として扱い、次回いいね時に `likes` へ寄せる
