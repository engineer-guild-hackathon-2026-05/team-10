# Firestore コメント連携・ユーザー作成 タスクリスト

- [x] Firestore schema docs を更新する
- [x] Firestore Codable models を追加する
- [x] Firestore API service を追加する
- [x] Auth sign-up 後に users ドキュメントを保存する
- [x] Firestore rules を直接書き込み用に更新する
- [x] Xcode project に FirebaseFirestore を追加する
- [x] ビルドと差分確認を実行する

## 振り返り

- 実装完了日: 2026-05-25
- Firestore 直書き用に `FirebaseFirestore` を iOS ターゲットへ追加し、`HowCardComment` / `FirestoreUser` / `FirebaseAPI` を追加した。
- Auth 作成後に `users/{uid}` を保存し、保存に失敗した場合は中途半端なログイン状態を避けるため signOut するようにした。
- Firestore Rules は認証済みユーザーの最小 read/write に更新した。`firebase` CLI がローカルにないため、rules のエミュレーター検証は未実施。
- `xcodebuild` と `git diff --check` は通過した。
