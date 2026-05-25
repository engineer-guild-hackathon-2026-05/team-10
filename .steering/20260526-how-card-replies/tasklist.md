# Howカード返信機能 タスクリスト

## 実装

- [x] Steering ファイルを作成する
- [x] Functions repository に返信の取得・作成・シリアライズを追加する
- [x] Functions route に `GET/POST /how-cards/:id/replies` を追加する
- [x] iOS モデルと FirebaseAPI に返信 contract を追加する
- [x] MusicFeed の投稿モデル・カード・画面に返信数と返信 sheet を接続する
- [x] 返信 sheet の ViewModel / View を追加する
- [x] docs と AI_USAGE_LOG を更新する
- [x] 検証コマンドを実行し、結果を反映する
- [x] PRレビューコメントを確認し、返信数同期・再入防止・View分割・counter更新を修正する
- [x] 返信送信失敗の原因を確認し、未デプロイendpointを検知できるようにする
- [x] `functions:api` をデプロイし、本番 `/how-cards/:id/replies` が auth middleware まで到達することを確認する
- [x] 追加レビューの未宣言 `replyCount` 代入を削除し、再デプロイする

## 振り返り

- 実装完了日時: 2026-05-25 21:31 UTC（2026-05-26 06:31 JST）
- 計画との差分: 返信データは Howカード配下の subcollection に分離し、親 `reply_count` を transaction で更新する方式にした。UI は MusicFeed の吹き出しから sheet を開く導線として実装した。
- 次回への改善: 返信削除・通報・通知は今回の範囲外。コミュニティ機能を強めるなら moderation と notification 設計を次に追加する。
