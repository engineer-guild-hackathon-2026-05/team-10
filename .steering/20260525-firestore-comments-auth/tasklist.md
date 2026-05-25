# Firestore コメント連携・ユーザー作成 タスクリスト

- [x] Firestore schema docs を更新する
- [x] Backend API Codable models を追加する
- [x] Backend API service を追加する
- [x] Auth sign-up 後に users ドキュメントを保存する
- [x] Firestore rules を直接アクセス禁止に更新する
- [x] Xcode project から FirebaseFirestore を外す
- [x] ビルドと差分確認を実行する

## 振り返り

- 実装完了日: 2026-05-25
- 当初は直接Firestore書き込みのモデル/APIとして実装したが、既存バックエンド構成に合わせて Admin SDK 経由の API 呼び出しに変更した。
- Auth 作成後に `PUT /users/me` で `users/{uid}` を保存し、保存に失敗した場合は中途半端なログイン状態を避けるため signOut する。
- Firestore Rules は deny-all に戻し、iOS ターゲットから `FirebaseFirestore` 依存を削除した。
- `node --check`、`git diff --check`、`xcodebuild` は通過した。

## PRレビュー対応

- [x] Markdown fence に言語指定を追加
- [x] `users` の create / update ルールで timestamp の整合性を検証
- [x] `users` 書き込みを `serverTimestamp()` に変更
- [x] Auth 作成後の Firestore 保存失敗時に signOut 失敗も通知

## バックエンド経由化対応

- [x] `backend/` と `functions/` に Howカードコメント API を追加
- [x] `backend/` と `functions/` に `users/me` API を追加
- [x] iOS の `FirebaseAPI` を直接 Firestore 呼び出しから Firebase ID トークン付き HTTP 呼び出しへ変更
- [x] `FirebaseFirestore` 依存と Firestore property wrapper を削除
- [x] Firestore Rules を deny-all に戻す

## Howカードコメント range 対応

- [x] `HowCardComment` と API payload に `song_start` / `song_end` を追加
- [x] `backend/` と `functions/` のコメント API 入出力を新スキーマに更新
- [x] docs と AI usage log を新スキーマに更新
- [x] ビルドと差分確認を実行
