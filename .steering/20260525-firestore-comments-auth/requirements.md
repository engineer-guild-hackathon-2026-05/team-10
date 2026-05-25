# Firestore コメント連携・ユーザー作成 要件

## 背景

Howカードのコメント保存とユーザー作成を Firebase に寄せるため、iOS 側にバックエンドAPI用の Codable モデルと API レイヤーを用意する。

## 要件

- `how-cards` コレクションは、ドキュメントごとに `comment`, `song_start`, `song_end`, `song_id`, `artist_id`, `user_id`, `goods` を持つ。
- iOS 側に Howカードコメント用の `Codable` struct を追加する。
- iOS 側にバックエンドAPI呼び出し用の API / Service を追加する。
- View との本格接続は今回の範囲外とする。
- Firebase Auth でユーザー作成した後、`users/{uid}` にユーザー情報を保存する。
- iOS SDK から Firestore へ直接書き込まない。Firebase ID トークン付きで backend/functions の API を呼び、Firestore は Admin SDK に集約する。
- Firestore Rules は deny-all とする。
- FirebaseAuth と URLSession の async/await、Codable mapping を使い、既存の MVVM / Service 方針に合わせる。

## 非要件

- コメント投稿 UI との接続。
- いいね UI との接続。
- 既存 backend API の削除。
