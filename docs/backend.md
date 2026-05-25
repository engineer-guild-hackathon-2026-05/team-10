# バックエンド設計書

> 2026-05-25 時点の実装に追従する。本番バックエンドは **Firebase Cloud Functions v2 + Express + Firestore Admin SDK + Firebase Auth**。旧 `backend/` はローカル参照用であり、本番デプロイ対象ではない。

---

## 本番構成

```text
functions/
├── index.js                  # HTTPS api + Auth onCreate trigger
├── app.js                    # Express app mount
├── middleware/
│   └── auth.js               # Firebase ID token 検証
├── routes/
│   ├── how-cards.js          # Howカードコメント API
│   ├── recommended-comments.js # Home dashboard 向けおすすめコメント API
│   └── users.js              # 自分のユーザー情報 API
├── repositories/
│   └── firestore.js          # Firestore read/write
└── package.json
```

- Runtime: Node.js 20
- Region: `asia-northeast1`
- Base URL: `https://asia-northeast1-egh-howtune.cloudfunctions.net/api`
- Auth: Firebase ID token (`Authorization: Bearer <token>`)
- Data store: Firestore
- `api`: Express app を HTTPS Function に mount
- `onUserSignup`: Firebase Auth onCreate で `users/{uid}` を自動作成

---

## 現在のエンドポイント

| Method | Path | Auth | 用途 |
|---|---|---|---|
| GET | `/health` | 不要 | 死活確認 |
| GET | `/how-cards` | 必須 | Howカードコメント一覧 |
| GET | `/how-cards?song_id=...` | 必須 | 曲ごとの Howカードコメント一覧 |
| GET | `/how-cards/:id` | 必須 | Howカードコメント詳細 |
| POST | `/how-cards` | 必須 | Howカードコメント作成 |
| PATCH | `/how-cards/:id` | 必須 | 自分の Howカードコメント更新 |
| POST | `/how-cards/:id/like` | 必須 | いいね。冪等、二重防止 |
| GET | `/recommended-comments` | 必須 | Home dashboard 向けおすすめコメント一覧 |
| GET | `/users/me` | 必須 | 自分のユーザー情報取得 |
| PUT | `/users/me` | 必須 | 自分のユーザー情報作成・更新 |

`/sessions`, `/sessions/:id/chat`, `/sessions/:id/how-card`, `GET /how-cards?tag=...` は Functions 本番には実装されていない。HowChat 側には legacy/mock client が残っているが、本番 API contract ではない。

---

## 認証フロー

1. iOS が Firebase Auth でサインアップまたはサインインする。
2. iOS は API request ごとに Firebase ID token を取得し、`Authorization: Bearer <token>` を付与する。
3. `functions/middleware/auth.js` が token を検証し、`req.uid`, `req.email`, `req.displayName` を設定する。
4. 新規サインアップ時は `onUserSignup` が `users/{uid}` を作成する。
5. iOS は必要に応じて `PUT /users/me`、または Firestore rules で許可された自分自身の `users/{uid}` 直接 read/write で display name などを同期する。

`PUT /users/me` の email は ID token の値を正とする。body の email が token と異なる場合は 400 を返す。

---

## API 詳細

### GET /health

```json
{ "status": "ok" }
```

### POST /how-cards

Howカードコメントを作成する。`user_id` は ID token から補完される。

```json
{
  "comment": "ここのベースラインが少し外れている感じが好き",
  "song_start": 78.4,
  "song_end": 84.2,
  "song_id": "1704093812",
  "song_slug": "ado-show",
  "artist_id": "ado"
}
```

Validation:

- `comment`: string, 1〜140 chars
- `song_start`: number, 0 以上
- `song_end`: number, `song_start` より大きい
- `song_id`: string, 1〜64 chars, numeric MusicKit / Apple Music / iTunes ID
- `itunes_id`: optional string, 1〜64 chars, numeric canonical 曲 ID
- `song_slug`: optional string, 1〜120 chars, 表示・移行用の slug
- `artist_id`: string, 1〜120 chars

Response:

```json
{
  "howCard": {
    "id": "card456",
    "comment": "ここのベースラインが少し外れている感じが好き",
    "song_start": 78.4,
    "song_end": 84.2,
    "song_id": "1704093812",
    "itunes_id": "1704093812",
    "song_slug": "ado-show",
    "artist_id": "ado",
    "user_id": "uid123",
    "user_name": null,
    "likes": 0,
    "created_at": null,
    "updated_at": null
  }
}
```

作成直後の response は Firestore server timestamp 確定前のため `created_at` が `null` になり得る。`updated_at` は作成時には書かれず、更新または like 時に付与される。

### GET /how-cards

最新順に Howカードコメント一覧を返す。デフォルトは 50 件、`limit` 指定時は 1〜250 件に丸める。

```json
{
  "howCards": [
    {
      "id": "card456",
      "comment": "...",
      "song_start": 78.4,
      "song_end": 84.2,
      "song_id": "1704093812",
      "itunes_id": "1704093812",
      "artist_id": "ado",
      "user_id": "uid123",
      "user_name": "Atsushi",
      "likes": 3,
      "created_at": "2026-05-25T12:00:00.000Z",
      "updated_at": "2026-05-25T12:05:00.000Z"
    }
  ]
}
```

`song_id` を指定した場合は canonical `itunes_id` を主軸に検索し、後方互換として `song_id` も併用して曲単位のコメントを返す。`user_name` は `users/{user_id}.display_name` を Admin SDK で参照して付与する。

### GET /how-cards/:id

指定 ID の Howカードコメントを `{ "howCard": ... }` で返す。存在しない場合は 404。

### PATCH /how-cards/:id

作成時と同じ payload で、自分の Howカードコメントだけを更新できる。他ユーザーのカードは 403。

更新対象:

- `comment`
- `song_start`
- `song_end`
- `song_id`
- `itunes_id`
- `song_slug`
- `artist_id`
- `updated_at`

### POST /how-cards/:id/like

`how-cards/{id}/liked-by/{uid}` を使って二重いいねを防ぐ。未いいねなら `likes` を +1 し、既いいねなら現在値をそのまま返す。

```json
{ "likes": 4 }
```

### GET /recommended-comments

Home dashboard 向けにおすすめ Howカードコメント一覧を返す。`created_at` が新しいコメントと `likes` が多いコメントを候補にして Functions 側でスコアリングする。`limit` は 1〜50、未指定時は 12。

```json
{
  "comments": [
    {
      "id": "card456",
      "comment": "...",
      "song_start": 78.4,
      "song_end": 84.2,
      "song_id": "1704093812",
      "itunes_id": "1704093812",
      "artist_id": "ado",
      "user_id": "uid123",
      "user_name": "Atsushi",
      "likes": 3
    }
  ]
}
```

### GET /users/me / PUT /users/me

`GET /users/me` は現在ログイン中の `users/{uid}` を返す。
現行 iOS では `UserSeedService` がログイン中ユーザー自身の `users/{uid}` を Firestore SDK で read/write する経路もある。Firestore rules は自分自身の get/create/update のみに制限する。

`PUT /users/me`:

```json
{
  "email": "user@example.com",
  "display_name": "Atsushi"
}
```

Response:

```json
{
  "user": {
    "id": "uid123",
    "user_id": "uid123",
    "email": "user@example.com",
    "display_name": "Atsushi",
    "created_at": "2026-05-25T12:00:00.000Z",
    "updated_at": "2026-05-25T12:05:00.000Z"
  }
}
```

---

## Firestore データモデル

```text
users/{uid}
  user_id: string
  email: string | null
  display_name: string | null
  created_at: timestamp
  updated_at: timestamp

how-cards/{cardId}
  comment: string
  song_start: number
  song_end: number
  song_id: string
  itunes_id: string
  song_slug: string | null
  artist_id: string
  user_id: string
  likes: number
  created_at: timestamp
  updated_at: timestamp | absent

how-cards/{cardId}/liked-by/{uid}
  user_id: string
  liked_at: timestamp
```

---

## iOS 連携

iOS の `FirebaseAPI` は `API_BASE_URL` から base URL を読み取り、上記 Functions API へ Firebase ID token 付きでアクセスする。

```swift
request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
```

`ENV.plist` には最低限以下を設定する。

```text
API_BASE_URL=https://asia-northeast1-egh-howtune.cloudfunctions.net/api
MUSIXMATCH_API_KEY=...
HOWTUNE_CHAT_MOCK=false
```

---

## 旧 backend/ の扱い

`backend/` には Claude / sessions 連携の古い Express 実装が残っている。現在の本番デプロイには反映されないため、新規 API 変更は `functions/` に追加する。

HowChat の `/sessions` 系 API を本番化する場合は、`functions/` 側へ明示的に移植し、このドキュメントを再更新する。

---

## エラーレスポンス

```json
{ "error": "エラーメッセージ" }
```

| HTTP | 意味 |
|---|---|
| 400 | リクエスト不正 |
| 401 | token なし、または token 不正 |
| 403 | 他ユーザーのリソースなどアクセス権なし |
| 404 | リソースが存在しない |
| 500 | Firestore / Functions 内部エラー |
