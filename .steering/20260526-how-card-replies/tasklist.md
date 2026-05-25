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

## 振り返り

- 実装完了日: 2026-05-26
- 計画との差分: 返信データは Howカード配下の subcollection に分離し、親 `reply_count` を transaction で更新する方式にした。UI は MusicFeed の吹き出しから sheet を開く導線として実装した。
- 次回への改善: 返信削除・通報・通知は今回の範囲外。コミュニティ機能を強めるなら moderation と notification 設計を次に追加する。
