# データモデル設計

## ストレージ選定方針

| データ種別 | ストレージ | 理由 |
|-----------|----------|------|
| ユーザー情報 | Firestore | iOS SDK あり、リアルタイム同期 |
| リスニングセッション | Firestore | セッション単位で更新 |
| センサー生データ（学習用）| Cloud Storage 等 | 大容量・追記。教師データ収集（別仕様 002-） |
| Howカード | Firestore | Howタグ検索・一覧取得 |
| 認証トークン | iOS Keychain | 機微情報 |
| 心拍データ | HealthKit（端末内）| 機微情報。端末内処理優先 |

---

## Firestore コレクション設計

### `how-cards`

Howカードコメント1件を1ドキュメントで管理する。iOS SDK から直接読み書きする最小スキーマ。

```text
how-cards/{cardId}
  comment:      string       // ユーザーコメント
  song_id:      string       // 曲 ID
  artist_id:    string       // アーティスト ID
  user_id:      string       // Firebase Auth uid
  goods:        integer      // いいね数
```

### `sessions`

リスニングセッション1回を1ドキュメントで管理する。

```
sessions/{sessionId}
  uid:          string
  songTitle:    string
  startedAt:    Timestamp
  endedAt:      Timestamp | null
  sensorLog:    object[]    // センサーデータのサマリ（生データは Cloud Storage）
  reactions:    object[]    // 検出された反応区間
  chatHistory:  object[]    // AI 対話ログ
```

### `users`

```
users/{uid}
  user_id:      string       // Firebase Auth uid
  email:        string
  display_name: string | null
  created_at:   Timestamp
  updated_at:   Timestamp
```

---

## Howカードコメント データ構造（iOS ↔ Firestore）

Firestore に保存する Howカードコメント：

```json
{
  "comment": "このベースラインの入りが好き",
  "song_id": "1704093812",
  "artist_id": "ado",
  "user_id": "firebase-uid",
  "goods": 0
}
```

## ユーザー データ構造（Firebase Auth → Firestore）

Firebase Auth で作成したユーザーを `users/{uid}` に保存する。

```json
{
  "user_id": "firebase-uid",
  "email": "user@example.com",
  "display_name": null,
  "created_at": "server timestamp",
  "updated_at": "server timestamp"
}
```

---

## 反応区間（ReactionEvent）構造

3状態スコアと時刻を持つ、センサー検出の最小単位。

```json
{
  "timestamp": 78.4,
  "durationSec": 2.0,
  "scores": {
    "groove":  0.82,
    "chill":   0.05,
    "neutral": 0.13
  }
}
```

---

## 注意事項

- 心拍の生データは HealthKit 内に留め、Firestore には書き込まない
- センサー生ログ（全フレーム）は Cloud Storage に保存し、Firestore には反応区間サマリのみ持つ（DECISION-04）
- `how-cards.user_id` は Firebase Auth の `uid` と一致させる
- `goods` はクライアント上では `Int`、Firestore 上では integer として扱う
