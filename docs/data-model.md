# データモデル設計

> 2026-05-25 時点の Functions 実装に合わせた Firestore / iOS モデルの説明。

## ストレージ選定方針

| データ種別 | ストレージ | 理由 |
|---|---|---|
| ユーザー情報 | Firestore | Firebase Auth uid と表示名を保存。Functions の `onUserSignup` と、iOS からの自分自身の `users/{uid}` seed で同期 |
| Howカードコメント | Firestore | 曲中区間に紐づくコメント、いいね、投稿者表示名を扱う |
| 認証状態 | Firebase Auth / iOS Keychain | Firebase SDK がセッションを保持 |
| 歌詞取得設定 | `ENV.plist` | Musixmatch API key など、git 管理しない値を端末側で注入 |

HealthKit / 心拍データは現行実装から削除済み。Firestore に心拍データや心拍トレンドは保存しない。

---

## Firestore コレクション設計

### `how-cards`

曲中の一部分に対する How コメント1件を1ドキュメントで管理する。Howカードコメントは iOS から直接 Firestore に書き込まず、Firebase ID token 付きで Functions API を呼び出す。

```text
how-cards/{cardId}
  comment:      string       // ユーザーコメント
  song_start:   number       // コメント対象範囲の開始秒
  song_end:     number       // コメント対象範囲の終了秒
  song_id:      string       // MusicKit / Apple Music 側の曲 ID
  artist_id:    string       // アーティスト ID
  user_id:      string       // Firebase Auth uid
  goods:        integer      // いいね数
  created_at:   Timestamp
  updated_at:   Timestamp | absent

how-cards/{cardId}/liked-by/{uid}
  user_id:      string       // Firebase Auth uid
  liked_at:     Timestamp
```

`updated_at` は作成時には存在しない場合がある。`PATCH /how-cards/:id` または `POST /how-cards/:id/like` で更新される。

### `users`

```text
users/{uid}
  user_id:      string       // Firebase Auth uid
  email:        string | null
  display_name: string | null
  created_at:   Timestamp
  updated_at:   Timestamp
```

`onUserSignup` が初回サインアップ時に作成し、`PUT /users/me` または iOS の `UserSeedService` が追加同期する。Firestore rules はログイン中ユーザー自身の `users/{uid}` の get/create/update のみ許可する。

---

## Howカードコメント API データ構造

`POST /how-cards` では iOS が `comment`, `song_start`, `song_end`, `song_id`, `artist_id` を送り、Functions が Firebase ID token から `user_id` を補完して `goods: 0` で保存する。

```json
{
  "comment": "ここのベースラインがコードから少し外れている感じが好き",
  "song_start": 78.4,
  "song_end": 84.2,
  "song_id": "1704093812",
  "artist_id": "ado"
}
```

レスポンスでは `goods` と互換用の `likes` を同じ値で返す。

```json
{
  "id": "card456",
  "comment": "ここのベースラインがコードから少し外れている感じが好き",
  "song_start": 78.4,
  "song_end": 84.2,
  "song_id": "1704093812",
  "artist_id": "ado",
  "user_id": "uid123",
  "user_name": "Atsushi",
  "goods": 3,
  "likes": 3,
  "created_at": "2026-05-25T12:00:00.000Z",
  "updated_at": "2026-05-25T12:05:00.000Z"
}
```

---

## ユーザー API データ構造

Firebase Auth のユーザーを `users/{uid}` に保存する。

```json
{
  "id": "firebase-uid",
  "user_id": "firebase-uid",
  "email": "user@example.com",
  "display_name": "Atsushi",
  "created_at": "2026-05-25T12:00:00.000Z",
  "updated_at": "2026-05-25T12:05:00.000Z"
}
```

---

## 反応区間（ReactionEvent）構造

iOS 内部の反応区間は Firestore へ永続化していない。AirPods 頭部モーションから得た特徴量を 2 秒窓で評価し、画面表示と HowChat の入力に使う。

```json
{
  "startTime": 78.4,
  "endTime": 84.2,
  "intensity": 0.82,
  "tags": ["groove"],
  "lyricLine": "歌詞行",
  "heartRateTrend": "stable"
}
```

`heartRateTrend` は legacy 表示互換のフィールドで、現行実装では実測心拍に基づかない。

---

## 注意事項

- iOS クライアントは Howカードコメントを Firestore に直接書き込まない。例外として、ログイン中ユーザー自身の `users/{uid}` だけは Firestore rules の範囲内で read/write する。
- `how-cards.user_id` は Firebase Auth の `uid` と一致させる。
- `song_start` / `song_end` は秒単位の数値として扱い、`song_end > song_start` を前提にする。
- `goods` は Firestore 上では integer、API では `goods` と `likes` の両方として返す。
- `sessions` collection は現行 Functions では作成していない。旧 `backend/` の設計が残っているだけで、本番 contract ではない。
