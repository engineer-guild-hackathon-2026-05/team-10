# HowTune バックエンド

LLM プロキシ + データ API。Node.js + Express + Firestore + Anthropic SDK。

---

## ディレクトリ構成

```
backend/
├── index.js                  # エントリーポイント（Firebase 初期化・ルートマウント）
├── middleware/
│   └── auth.js               # Firebase ID トークン検証 → req.uid をセット
├── repositories/
│   └── firestore.js          # Firestore 読み書き（sessions / how-cards / users）
├── services/
│   └── claude.js             # Claude API ラッパー（chat / generateHowCard）
├── routes/
│   ├── sessions.js           # /sessions 配下の全ルート
│   └── how-cards.js          # GET /how-cards
├── .env                      # gitignore 対象（.env.example を参照）
├── serviceAccountKey.json    # gitignore 対象（Firebase サービスアカウントキー）
└── package.json
```

---

## ローカル起動

```bash
cd backend
npm install
cp .env.example .env   # ANTHROPIC_API_KEY を記入
npm run dev            # node --watch index.js
```

サーバーは `http://localhost:3000` で起動する。

---

## 環境変数（`.env`）

| 変数名 | 説明 |
|--------|------|
| `ANTHROPIC_API_KEY` | Anthropic の API キー |
| `PORT` | ポート番号（デフォルト: 3000） |

Firebase の認証情報は `serviceAccountKey.json`（Firebase コンソール → プロジェクト設定 → サービスアカウント → 秘密鍵を生成）で管理する。

---

## 認証

**`POST /sessions/:id/chat` 以外のすべてのエンドポイントは Firebase ID トークンが必要。**

iOS 側は Firebase Auth でサインイン後、すべてのリクエストに以下のヘッダーを付与する:

```
Authorization: Bearer <firebase-id-token>
```

Swift での取得方法:

```swift
let token = try await Auth.auth().currentUser?.getIDToken()
// → "Authorization: Bearer \(token)" としてリクエストヘッダーに追加
```

---

## API エンドポイント

ベース URL（ローカル）: `http://localhost:3000`

---

### `GET /health`

認証不要。サーバーの死活確認。

**レスポンス**
```json
{ "status": "ok" }
```

---

### `POST /sessions`

**認証必須。**

Core ML がオンデバイスで計算した反応区間を受け取り、Firestore にセッションを作成する。返却された `sessionId` を以降のエンドポイントで使用する。

**リクエスト**
```json
{
  "songTitle": "Blinding Lights",
  "durationSec": 200,
  "reactions": [
    {
      "startSec": 78,
      "endSec": 84,
      "scores": {
        "groove": 0.82,
        "hype": 0.31,
        "chill": 0.05,
        "immersion": 0.12,
        "hit": 0.44,
        "afterglow": 0.08
      }
    }
  ]
}
```

**レスポンス**
```json
{ "sessionId": "abc123" }
```

---

### `POST /sessions/:id/chat`

**認証不要**（iOS 既存実装との互換性維持のため）。

反応区間の情報をもとに Claude が確認形の問いかけと選択肢を返す。iOS 側が `history` を管理し、毎回リクエストに含める（ステートレス）。

**リクエスト**
```json
{
  "startTime": 78,
  "tags": ["groove", "hit"],
  "intensity": 0.82,
  "lyric": "I said, ooh, I'm blinded by the lights",
  "history": [
    { "role": "user", "content": "対話を開始してください" },
    { "role": "assistant", "content": "..." }
  ]
}
```

| フィールド | 型 | 説明 |
|-----------|-----|------|
| `startTime` | number | 反応地点（秒） |
| `tags` | string[] | 反応タグ（groove / hype / chill / immersion / hit / afterglow） |
| `intensity` | number | 反応強度（0〜1） |
| `lyric` | string? | 反応地点の歌詞（任意） |
| `history` | array? | 対話履歴。初回は空配列または省略 |

**レスポンス**
```json
{
  "question": "ベースが入った瞬間に何か感じましたか？",
  "choices": ["体が動いた", "テンションが上がった", "鳥肌が立った", "言葉にできない"]
}
```

**対話の継続方法**

次のターンでは、前回のレスポンスとユーザーの回答を `history` に追加して送る:

```json
{
  "startTime": 78,
  "tags": ["groove"],
  "intensity": 0.82,
  "history": [
    { "role": "user", "content": "対話を開始してください" },
    { "role": "assistant", "content": "{\"question\": \"ベースが...\", \"choices\": [...]}" },
    { "role": "user", "content": "体が動いた" }
  ]
}
```

---

### `POST /sessions/:id/how-card`

**認証必須。**

反応区間と対話履歴から Howカードを生成し、Firestore に保存して返す。`:id` は `POST /sessions` で取得した `sessionId`。

**リクエスト**
```json
{
  "songTitle": "Blinding Lights",
  "reactions": [
    {
      "startSec": 78,
      "endSec": 84,
      "scores": { "groove": 0.82, "hype": 0.31, "chill": 0.05, "immersion": 0.12, "hit": 0.44, "afterglow": 0.08 }
    }
  ],
  "chatHistory": [
    { "role": "user", "content": "体が動いた" },
    { "role": "assistant", "content": "リズムに乗っていたんですね。" }
  ]
}
```

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

**副作用（Firestore）**
- `how-cards/{id}` にカードを作成
- `sessions/{sessionId}` の status を `"done"` に更新
- `users/{uid}/howTags` に今回のタグを追記

---

### `GET /how-cards?tag=groove`

**認証必須。**

指定タグを持つ Howカード一覧を返す。コミュニティ画面で使用する。

**クエリパラメータ**

| パラメータ | 必須 | 説明 |
|-----------|------|------|
| `tag` | ✅ | 検索タグ（例: `groove`, `chill`, `hype`） |

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
      "description": "メロディより先に、低音の重心やリズムの入り方に反応するタイプ。",
      "highlightSec": 78
    }
  ]
}
```

最大50件、`createdAt` 降順で返す。

---

## Firestore データモデル

```
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

users/{uid}
  howTags: string[]     ← HowCard 生成のたびに追記される
```

---

## エラーレスポンス

すべてのエラーは以下の形式で返す:

```json
{ "error": "エラーメッセージ" }
```

| HTTP ステータス | 意味 |
|----------------|------|
| 400 | リクエスト不正（パラメータ不足など） |
| 401 | 認証失敗（トークンなし・無効） |
| 500 | サーバーエラー（Claude API / Firestore 障害） |
