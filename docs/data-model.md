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

Howカード1件を1ドキュメントで管理する。

```
how-cards/{cardId}
  uid:          string       // ユーザー ID（未認証時は "anonymous"）
  sessionId:    string       // 生成元セッション ID
  songTitle:    string       // 曲名
  title:        string       // Howカードのタイトル
  description:  string       // 説明文
  howTags:      string[]     // Howタグ（例: ["グルーヴ派", "余韻に浸る人"]）
  reactions:    object[]     // 反応区間スナップショット
  createdAt:    Timestamp
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
  displayName:  string
  howCards:     string[]    // 生成済み Howカード ID の配列
  createdAt:    Timestamp
```

---

## Howカード データ構造（iOS ← backend）

バックエンドが返す Howカード生成レスポンス：

```json
{
  "howCard": {
    "id": "50Q4oDFypDok6x1WMb20",
    "title": "余韻に浸るリスナー",
    "description": "曲が終わった後も世界に残り続けるタイプ。",
    "howTags": ["余韻派", "immersion"]
  }
}
```

---

## 反応区間（ReactionEvent）構造

6軸スコアと時刻を持つ、センサー検出の最小単位。

```json
{
  "timestamp": 78.4,
  "durationSec": 2.0,
  "scores": {
    "groove":     0.82,
    "hype":       0.41,
    "chill":      0.15,
    "immersion":  0.67,
    "hit":        0.90,
    "afterglow":  0.55
  }
}
```

---

## 注意事項

- 心拍の生データは HealthKit 内に留め、Firestore には書き込まない
- センサー生ログ（全フレーム）は Cloud Storage に保存し、Firestore には反応区間サマリのみ持つ（DECISION-04）
- `uid: "anonymous"` はハッカソン期間中の暫定対応。本番では Firebase Auth と連携する
