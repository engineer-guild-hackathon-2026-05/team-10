# HowTune バックエンド

> **⚠️ DEPRECATED — このディレクトリはローカル開発の参照用です。**
>
> 本番デプロイは [`functions/`](../functions) で行います（Firebase Cloud Functions v2）。
> **新規の変更は [`functions/`](../functions) に加えてください。** ここを編集してもデプロイには反映されません。
>
> ローカルで Express を起動して動作確認したい場合のみ、このディレクトリを使ってください。
> 機能変更を加えた場合は、必ず `functions/` 側にも反映してください（コード重複・ドリフトに注意）。

---

LLM プロキシ + データ API。Node.js + Express + Firestore + Anthropic SDK + Firebase Auth（Email/Password）。

詳細設計は [`docs/backend.md`](../docs/backend.md) を参照。

---

## ディレクトリ構成

```
backend/
├── index.js                  # エントリーポイント（Firebase 初期化・ルートマウント）
├── middleware/
│   └── auth.js               # Firebase ID トークン検証 → req.uid / email / displayName
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

**`GET /health` 以外のすべてのエンドポイントは Firebase ID トークン必須。**

iOS 側は Firebase Auth（Email/Password）でサインイン後、すべてのリクエストに以下のヘッダーを付与する:

```
Authorization: Bearer <firebase-id-token>
```

ミドルウェアで以下を抽出し、各ハンドラから参照可能:

| `req.*` | 出典 | 説明 |
|---------|------|------|
| `req.uid` | token | Firebase UID |
| `req.email` | token | 認証時のメールアドレス（必ず存在） |
| `req.displayName` | token | Firebase user の displayName（未設定なら `null`） |

iOS チーム向けの実装例は [`docs/backend.md` の「iOS 実装ガイド」](../docs/backend.md#ios-実装ガイド) を参照。

---

## API エンドポイント

ベース URL（ローカル）: `http://localhost:3000`

| メソッド | パス | 認証 | 用途 |
|---------|------|------|------|
| GET | `/health` | ❌ | 死活確認 |
| POST | `/sessions` | ✅ | セッション作成 |
| POST | `/sessions/:id/chat` | ✅ | AI 対話（1ターン） |
| POST | `/sessions/:id/how-card` | ✅ | Howカード生成・保存 |
| GET | `/how-cards?tag=...` | ✅ | Howカード一覧（タグ検索） |
| GET | `/how-cards?song_id=...` | ✅ | Howカードコメント一覧 |
| POST | `/how-cards` | ✅ | Howカードコメント作成 |
| PATCH | `/how-cards/:id` | ✅ | 自分のHowカードコメント更新 |
| POST | `/how-cards/:id/goods` | ✅ | Howカードコメントのいいね加算 |
| GET | `/users/me` | ✅ | 自分のユーザー情報取得 |
| PUT | `/users/me` | ✅ | 自分のユーザー情報作成・更新 |

---

### `GET /health`

サーバーの死活確認。

**レスポンス**
```json
{ "status": "ok" }
```

---

### `POST /sessions`

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

反応区間と対話履歴から Howカードを生成し、Firestore に保存して返す。`:id` は `POST /sessions` で取得した `sessionId`。

**事前検証**: セッションが `req.uid` の所有でない場合は 403、存在しなければ 404。

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

**副作用（Firestore batch）**
- `how-cards/{id}` にカードを作成（`displayName` も保存）
- `sessions/{sessionId}` の status を `"done"` に更新
- `users/{uid}` に email / displayName / howTags をマージ（初回なら自動作成）

---

### `GET /how-cards?tag=groove`

指定タグを持つ Howカード一覧を返す。コミュニティ画面で使用する。

`displayName` がカードに含まれているので、追加のユーザー参照は不要。

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
      "displayName": "ノリ太郎",
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

### Howカードコメント API

iOS は Firestore に直接アクセスせず、Firebase ID トークン付きで以下の API を呼び出す。

`POST /how-cards` のリクエスト:

```json
{
  "comment": "このベースラインの入りが好き",
  "song_start": 78.4,
  "song_end": 84.2,
  "song_id": "1704093812",
  "artist_id": "ado"
}
```

バックエンドが `user_id` を Firebase ID トークンから補完し、`goods: 0` で `how-cards/{id}` に保存する。

`GET /how-cards/:id` / `POST /how-cards` / `PATCH /how-cards/:id` / `POST /how-cards/:id/goods` は以下の形式を返す:

```json
{
  "howCard": {
    "id": "card789",
    "comment": "このベースラインの入りが好き",
    "song_start": 78.4,
    "song_end": 84.2,
    "song_id": "1704093812",
    "artist_id": "ado",
    "user_id": "uid123",
    "goods": 0
  }
}
```

`GET /how-cards?song_id=1704093812` は同じオブジェクト配列を `{ "howCards": [...] }` で返す。

---

### `GET /users/me` / `PUT /users/me`

Firebase Auth で作成したユーザーを、バックエンド経由で `users/{uid}` に保存する。

```json
{
  "email": "user@example.com",
  "display_name": null
}
```

---

## Firestore データモデル

```
users/{uid}
  user_id: string
  email: string
  display_name: string | null
  created_at: timestamp
  updated_at: timestamp

users/{uid}                  ← 既存Howカード生成API用
  email: string
  displayName: string
  howTags: string[]         ← HowCard 生成のたびに追記
  updatedAt: timestamp

sessions/{sessionId}
  userId: string
  songTitle: string
  durationSec: number
  reactions: ReactionSpan[]
  chatHistory: ChatMessage[]
  status: "analyzing" | "done"
  createdAt: timestamp

how-cards/{cardId}
  comment: string
  song_start: number
  song_end: number
  song_id: string
  artist_id: string
  user_id: string
  goods: number

how-cards/{cardId}           ← 既存Howカード生成API用
  userId: string
  displayName: string       ← 非正規化（コミュニティ表示用）
  sessionId: string
  songTitle: string
  howTags: string[]
  tagLabel: string
  description: string
  highlightSec: number
  createdAt: timestamp
```

クライアントからの直接 Firestore アクセスは禁止し、`firestore.rules` は deny-all にする。

---

## エラーレスポンス

すべてのエラーは以下の形式で返す:

```json
{ "error": "エラーメッセージ" }
```

| HTTP ステータス | 意味 |
|----------------|------|
| 400 | リクエスト不正（パラメータ不足など） |
| 401 | 認証失敗（トークンなし・無効・期限切れ） |
| 403 | アクセス権なし（他ユーザーのリソース） |
| 404 | リソースが見つからない |
| 500 | サーバーエラー（Claude API / Firestore 障害） |
