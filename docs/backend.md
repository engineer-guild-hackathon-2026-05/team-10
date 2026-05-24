# バックエンド設計書

> スタック: **Node.js + Express**、**Firestore**（Admin SDK）、**Firebase Auth**、**Anthropic SDK（Claude）**

---

## ディレクトリ構成

```
backend/
├── src/
│   ├── index.js                  # Express アプリのエントリーポイント
│   ├── middleware/
│   │   └── auth.js               # Firebase ID トークン検証
│   ├── routes/
│   │   ├── sessions.js           # POST /sessions、POST /sessions/:id/chat、POST /sessions/:id/how-card
│   │   └── how-cards.js          # GET /how-cards
│   ├── services/
│   │   └── claude.js             # Anthropic SDK ラッパー（対話・Howカード生成）
│   └── repositories/
│       └── firestore.js          # Firestore の読み書きをまとめる
├── .env                          # gitignore 対象
├── serviceAccountKey.json        # gitignore 対象
└── package.json
```

---

## 環境変数（`.env`）

```
ANTHROPIC_API_KEY=
GOOGLE_APPLICATION_CREDENTIALS=./serviceAccountKey.json
PORT=3000
```

---

## Firebase セットアップ（コードを書く前に済ませる）

1. Firebase コンソールでプロジェクトを作成
2. Firestore を有効化（クライアント直接アクセス禁止前提。テストモードは使わない）
3. Authentication → Sign in with Apple を有効化
4. サービスアカウントキーを生成 → `backend/serviceAccountKey.json` として保存（gitignore 対象）
5. `GoogleService-Info.plist` をダウンロード → `Othello/Othello/` に追加（iOS 側のみ）
6. リポジトリルートで `firebase init` を実行 → Firestore のみ選択 → `firestore.rules` と `firestore.indexes.json` を生成し、ルールは `allow read, write: if false;` に設定

---

## Firestore データモデル

### コレクション

```
users/{uid}
  displayName: string
  howTags: string[]
  createdAt: timestamp

sessions/{sessionId}
  userId: string
  songTitle: string
  durationSec: number
  reactions: ReactionSpan[]
  chatHistory: ChatMessage[]
  status: "analyzing" | "done"
  createdAt: timestamp

how-cards/{cardId}
  userId: string
  sessionId: string
  songTitle: string
  howTags: string[]
  tagLabel: string
  description: string
  highlightSec: number
  createdAt: timestamp
```

### 型定義

```js
// ReactionSpan
{ startSec, endSec, scores: { groove, hype, chill, immersion, hit, afterglow } }

// ChatMessage
{ role: "user" | "assistant", content: string }
```

### Firestore セキュリティルール

バックエンドはすべて Admin SDK 経由（ルールをバイパス）。iOS クライアントからの直接アクセスは禁止。

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

---

## 認証フロー

1. iOS が Firebase Auth（Sign in with Apple）でサインイン
2. iOS はすべてのリクエストに Firebase ID トークンを付与:
   ```
   Authorization: Bearer <firebase-id-token>
   ```
3. `middleware/auth.js` が Admin SDK でトークンを検証 → `req.uid` をセット
4. すべてのルートがこのミドルウェアで保護される

---

## API エンドポイント

### POST /sessions

Core ML がオンデバイスで計算した反応区間を受け取り、セッションを Firestore に保存する。

**リクエスト**
```json
{
  "songTitle": "Blinding Lights",
  "durationSec": 200,
  "reactions": [
    {
      "startSec": 78,
      "endSec": 84,
      "scores": { "groove": 0.82, "hype": 0.31, "chill": 0.05, "immersion": 0.12, "hit": 0.44, "afterglow": 0.08 }
    }
  ]
}
```

**レスポンス**
```json
{ "sessionId": "abc123" }
```

**Firestore 書き込み**: `sessions/{sessionId}` を作成。`userId = req.uid`、`status = "analyzing"`、`chatHistory = []`。

---

### POST /sessions/:id/chat

1ターン分の対話を Claude に中継し、レスポンスを SSE でストリームする。ストリーム完了後、ユーザーメッセージと Claude の返答を Firestore の `chatHistory` に追記する。

**リクエスト**
```json
{ "message": "ベースが入った瞬間が好きだった" }
```

**レスポンス**: SSE ストリーム
```
data: {"delta": "そう"}
data: {"delta": "でしたか"}
data: [DONE]
```

**Claude に渡すコンテキスト**:
- セッションの `reactions[]` — どこで身体が反応したかを伝える
- セッションの `chatHistory[]` — 複数ターンにわたる会話状態を維持する

**Firestore 書き込み**: ストリーム終了後、`{ role: "user" }` と `{ role: "assistant" }` を `chatHistory` に追記。

---

### POST /sessions/:id/how-card

Firestore からセッション（reactions + chatHistory）を読み込み、Claude に Howカードを JSON で生成させ、保存して返す。

**リクエスト**: ボディ不要（Firestore から読み込む）

**レスポンス**
```json
{
  "howCard": {
    "id": "card456",
    "howTags": ["groove", "bass-driven"],
    "tagLabel": "ベースの入りに反応する人",
    "description": "メロディより先に、低音の重心やリズムの入り方に反応するタイプ。",
    "highlightSec": 78
  }
}
```

**Claude プロンプト**: reactions + chatHistory 全体を渡し、JSON のみ返すよう指示する。

**Firestore 書き込み**:
- `how-cards/{cardId}` を作成
- `sessions/{sessionId}` の status を `"done"` に更新
- 主要な `howTags` を `users/{uid}/howTags` に追記

---

### GET /how-cards

タグで絞り込んだ Howカード一覧を返す。コミュニティ画面で使用する。

**クエリパラメータ**: `?tag=groove`

**レスポンス**
```json
{
  "howCards": [
    {
      "id": "card456",
      "userId": "uid123",
      "songTitle": "Blinding Lights",
      "howTags": ["groove", "bass-driven"],
      "tagLabel": "ベースの入りに反応する人",
      "description": "...",
      "highlightSec": 78
    }
  ]
}
```

**Firestore クエリ**: `how-cards` コレクションで `howTags` 配列に `tag` が含まれるドキュメントを取得。

---

## Claude 連携（`services/claude.js`）

### `streamChat(reactions, chatHistory, userMessage, onDelta)`
- reactions を含むシステムプロンプトを構築
- chatHistory + 新しいユーザーメッセージを Claude に送信
- トークンごとに `onDelta(chunk)` を呼び出してストリーム
- ストリーム完了後、全文を返す
- モデル: `claude-sonnet-4-6`

### `generateHowCard(reactions, chatHistory)`
- reactions + chatHistory 全体を Claude に送信
- JSON のみ返すよう指示し、Howカードのスキーマに沿った構造体を取得
- パースして返す
- モデル: `claude-sonnet-4-6`

---

## 実装順序

1. `package.json` — 依存パッケージ追加（`express`、`firebase-admin`、`@anthropic-ai/sdk`、`dotenv`）
2. `src/repositories/firestore.js` — Firestore の読み書きを一箇所にまとめる
3. `src/middleware/auth.js` — トークン検証
4. `src/services/claude.js` — Claude API ラッパー
5. `src/routes/sessions.js` — セッション関連の3エンドポイント
6. `src/routes/how-cards.js` — GET エンドポイント
7. `src/index.js` — すべてを組み合わせる
