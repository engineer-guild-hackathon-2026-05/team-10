# Firestore コメント連携・ユーザー作成 設計

## 変更方針

- `docs/data-model.md` の `how-cards` / `users` を今回の Firestore 直書き前提に更新する。
- `Othello/Othello/Models/` に Firestore 保存用モデルを追加する。
- `Othello/Othello/Services/` に Firestore API を追加し、Firestore の collection name と encode/decode を集約する。
- `AuthViewModel.signUp` は Firebase Auth 作成後、Firestore API を呼んで user document を upsert する。
- `Othello.xcodeproj` に `FirebaseFirestore` package product を追加する。
- `firestore.rules` は認証済みユーザーの own user document と、`user_id == request.auth.uid` の Howカード作成を許可する。

## Firestore schema

```text
how-cards/{cardId}
  comment: string
  song_id: string
  artist_id: string
  user_id: string
  goods: integer

users/{uid}
  user_id: string
  email: string
  display_name: string | null
  created_at: Timestamp
  updated_at: Timestamp
```

## API

- `FirebaseAPI.createHowCard(_:)`
- `FirebaseAPI.fetchHowCard(id:)`
- `FirebaseAPI.fetchHowCards(songID:limit:)`
- `FirebaseAPI.updateHowCard(_:)`
- `FirebaseAPI.incrementGoods(cardID:by:)`
- `FirebaseAPI.upsertUser(_:)`
- `FirebaseAPI.createUserDocument(from:)`

## 注意点

- Firestore field 名はユーザー提示の snake_case に合わせる。
- `goods` は `Int` とし、作成時の default を `0` にする。
- `@DocumentID` は Swift 側の識別子として使い、Firestore field には保存しない。
