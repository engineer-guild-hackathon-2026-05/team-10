# データモデル設計

> 2026-05-25 時点の Functions 実装に合わせた Firestore / iOS モデルの説明。

## ストレージ選定方針

| データ種別 | ストレージ | 理由 |
|---|---|---|
| ユーザー情報 | Firestore | Firebase Auth uid と表示名を保存。Functions の `onUserSignup` と `PUT /users/me` で同期 |
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
  song_id:      string       // 新規は MusicKit / Apple Music / iTunes の数値曲 ID。既存 legacy slug は読み取り互換対象
  itunes_id:    string?      // canonical 曲 ID（新規は song_id と同じ値）
  song_slug:    string?      // 表示・移行用の曲 slug
  song_title:   string?      // 表示用タイトル
  artist_name:  string?      // 表示用アーティスト名
  artist_id:    string       // アーティスト ID
  user_id:      string       // Firebase Auth uid
  likes:        integer      // いいね数
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

`onUserSignup` が初回サインアップ時に作成し、`PUT /users/me` が追加同期する。現行 iOS は起動時や Howカード読み込み時に users seed を行わず、必要に応じてログイン中ユーザー自身の `users/{uid}` を読み取るだけにする。

### `conversations`（共鳴 DM・ADR-0006）

リアルタイム DM。`conversationId` はソート済み uid を `__` で連結（`uidA__uidB`）。iOS が Firestore を直接購読・書き込みする（楽観的更新）。参加者のみ read/write（rules で担保）。

```text
conversations/{conversationId}
  (ドキュメント本体はフィールドを持たない場合がある — messages サブコレクションが主体)

conversations/{conversationId}/messages/{messageId}
  sender_id:   string       // Firebase Auth uid
  text:        string       // 本文（1〜2000字）
  created_at:  Timestamp
```

マッチング自体は `how-cards` を `song_id` で購読し、`song_start`/`song_end` の重なり（±2.5秒）で同地点/別地点を判定する（新規コレクションは作らない）。デモは `functions/scripts/seed-resonance.js` で `song_id=howtune-demo-song` に複数地点の how-cards を seed する。

### `artists`

現時点では Firestore に `artists` collection はない。アーティスト一覧は iOS の `Artist.catalog` と、`GET /how-cards` で返るコメントから組み立てた表示用 Artist に依存している。実データと UI カタログのずれを防ぐには、将来的に `artists` / `songs` catalog を Firestore か MusicKit metadata に寄せる設計へ移すのが望ましい。

---

## Howカードコメント API データ構造

`POST /how-cards` では iOS が `comment`, `song_start`, `song_end`, `song_id`, `artist_id` を送る。`song_id` は MusicKit / Apple Music / iTunes の数値曲 ID として扱い、`radwimps-愛にできることはまだあるかい` のような slug や表示名は入れない。表示用の slug / タイトルは `song_slug` / `song_title` など別フィールドに分離する。バックエンドは Firebase ID トークンから `user_id` を決めて `likes: 0` で保存する。

既存 Firestore には legacy slug の `song_id` を持つ Howカードが残っているため、GET 系 API は読み取り互換として legacy slug も返す。`itunes_id` がない legacy ドキュメントでは、レスポンスの `song_id` も保存済み slug になる。新規作成・更新では引き続き数値 ID のみを受け付ける。

```json
{
  "comment": "ここのベースラインがコードから少し外れている感じが好き",
  "song_start": 78.4,
  "song_end": 84.2,
  "song_id": "1704093812",
  "song_slug": "ado-show",
  "artist_id": "ado"
}
```

レスポンスの公開カウンタは `likes`。新規書き込み・API contract ともに `likes` へ統一する。

```json
{
  "id": "card456",
  "comment": "ここのベースラインがコードから少し外れている感じが好き",
  "song_start": 78.4,
  "song_end": 84.2,
  "song_id": "1704093812",
  "itunes_id": "1704093812",
  "song_slug": "ado-show",
  "artist_id": "ado",
  "user_id": "uid123",
  "user_name": "Atsushi",
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
- `song_start` / `song_end` は秒単位の数値として扱い、`song_end > song_start` を前提にする
- `likes` はクライアント上では `Int`、Firestore 上では integer として扱う。
- `sessions` collection は現行 Functions では作成していない。旧 `backend/` の設計が残っているだけで、本番 contract ではない。
