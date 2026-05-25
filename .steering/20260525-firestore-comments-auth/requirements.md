# Firestore コメント連携・ユーザー作成 要件

## 背景

Howカードのコメント保存とユーザー作成を Firebase に寄せるため、iOS 側に Firestore の Codable モデルと API レイヤーを用意する。

## 要件

- `how-cards` コレクションは、ドキュメントごとに `comment`, `song_id`, `artist_id`, `user_id`, `goods` を持つ。
- iOS 側に Howカードコメント用の `Codable` struct を追加する。
- iOS 側に Firestore 読み書き用の API / Service を追加する。
- View との本格接続は今回の範囲外とする。
- Firebase Auth でユーザー作成した後、`users/{uid}` にユーザー情報を保存する。
- iOS SDK から直接書き込めるよう、`users` / `how-cards` の最小 Firestore Rules を追加する。
- Firebase SDK の async/await と Codable mapping を使い、既存の MVVM / Service 方針に合わせる。

## 非要件

- コメント投稿 UI との接続。
- いいね UI との接続。
- 既存 backend API の削除。
