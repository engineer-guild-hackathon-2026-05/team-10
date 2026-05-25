# Firestore コメント連携・ユーザー作成 設計

## 変更方針

- `docs/data-model.md` の `how-cards` / `users` をバックエンド経由の Firestore 保存前提に更新する。
- `backend/` と `functions/` に `how-cards` コメントAPIと `users/me` APIを追加する。
- `Othello/Othello/Models/` にバックエンドAPI用 Codable model を追加する。
- `Othello/Othello/Services/FirebaseAPI` は名前を維持しつつ、Firestore SDK ではなく URLSession + Firebase ID token で backend/functions を呼ぶ。
- `AuthViewModel.signUp` は Firebase Auth 作成後、backend API を呼んで user document を upsert する。
- `Othello.xcodeproj` から `FirebaseFirestore` package product を外す。
- `firestore.rules` はクライアント直接アクセスを禁止する deny-all に戻す。

## Firestore schema

```text
how-cards/{cardId}
  comment: string
  song_start: number
  song_end: number
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
- `FirebaseAPI.incrementGoods(cardID:)`
- `FirebaseAPI.upsertUser(_:)`
- `FirebaseAPI.createUserDocument(from:)`

## 注意点

- Firestore field 名はユーザー提示の snake_case に合わせる。
- `goods` は `Int` とし、作成時の default を `0` にする。
- Swift 側の `id` は backend response の `id` を使い、Firestore SDK の property wrapper は使わない。
