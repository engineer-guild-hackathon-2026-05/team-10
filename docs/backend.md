# バックエンド設計書

> スタック: **Node.js + Express**、**Firestore**（Admin SDK）、**Firebase Auth（Email/Password）**、**Anthropic SDK（Claude）**

---

## ディレクトリ構成

```text
backend/
├── index.js                  # Express アプリのエントリーポイント
├── middleware/
│   └── auth.js               # Firebase ID トークン検証 → req.uid / email / displayName をセット
├── routes/
│   ├── sessions.js           # POST /sessions、POST /sessions/:id/chat、POST /sessions/:id/how-card
│   ├── how-cards.js          # /how-cards 配下
│   └── users.js              # GET/PUT /users/me
├── services/
│   └── claude.js             # Anthropic SDK ラッパー（対話・Howカード生成）
├── repositories/
│   └── firestore.js          # Firestore の読み書きをまとめる
├── .env                      # gitignore 対象
├── serviceAccountKey.json    # gitignore 対象
└── package.json
```

---

## 環境変数（`.env`）

```bash
ANTHROPIC_API_KEY=
PORT=3000
```

サービスアカウントキーは `backend/serviceAccountKey.json` に置く（gitignore 対象）。
本番では `GOOGLE_APPLICATION_CREDENTIALS` 環境変数でパスを指定可能。

---

## Firebase セットアップ（コードを書く前に済ませる）

1. Firebase コンソールでプロジェクトを作成
2. Firestore を有効化（クライアント直接アクセス禁止前提。テストモードは使わない）
3. Authentication → Sign-in method → **Email/Password を有効化**（メール確認は無効のまま）
4. サービスアカウントキーを生成 → `backend/serviceAccountKey.json` として保存（gitignore 対象）
5. `GoogleService-Info.plist` をダウンロード → `Othello/Othello/` に追加（iOS 側のみ）
6. リポジトリルートで `firebase init` を実行 → Firestore のみ選択 → `firestore.rules` と `firestore.indexes.json` を生成し、ルールは `allow read, write: if false;` に設定

---

## Firestore データモデル

### コレクション

```text
users/{uid}
  user_id: string
  email: string
  display_name: string | null
  created_at: timestamp
  updated_at: timestamp

users/{uid}                ← 既存Howカード生成API用
  email: string
  displayName: string
  howTags: string[]        ← HowCard 生成時に追記される
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

how-cards/{cardId}         ← 既存Howカード生成API用
  userId: string
  displayName: string      ← 非正規化（コミュニティ表示用に user 参照不要）
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
{ startSec, endSec, scores: { groove, chill, neutral } }

// ChatMessage
{ role: "user" | "assistant", content: string }
```

### Firestore セキュリティルール

バックエンドは Admin SDK 経由（ルールをバイパス）で `how-cards` を扱う。
iOS クライアントからの直接アクセスは、ログイン中ユーザー自身の `users/{uid}` の `get/create/update` のみに限定する。
`users` の list や他ユーザーの書き込み、`how-cards` への直接アクセスは禁止する。

```text
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid} {
      allow get, create, update: if request.auth != null && request.auth.uid == uid;
      allow list, delete: if false;
    }

    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

---

## 認証フロー（Email/Password）

### 全体像

1. iOS が Firebase Auth で Email/Password サインアップまたはサインイン
2. iOS は Firebase user の displayName を設定（推奨）
3. iOS はすべてのリクエストに Firebase ID トークンを付与:
   ```
   Authorization: Bearer <firebase-id-token>
   ```
4. `middleware/auth.js` が Admin SDK でトークンを検証 → `req.uid` / `req.email` / `req.displayName` をセット
5. サインアップ後、iOS が `PUT /users/me` を呼び、`users/{uid}` をバックエンド経由で作成・更新する

### 認証が必要なエンドポイント

| エンドポイント | 認証 |
|---|---|
| `POST /sessions` | ✅ 必須 |
| `POST /sessions/:id/chat` | ✅ 必須 |
| `POST /sessions/:id/how-card` | ✅ 必須 |
| `GET /how-cards` | ✅ 必須 |
| `POST /how-cards` | ✅ 必須 |
| `PATCH /how-cards/:id` | ✅ 必須 |
| `POST /how-cards/:id/like` | ✅ 必須 |
| `GET /users/me` | ✅ 必須 |
| `PUT /users/me` | ✅ 必須 |
| `GET /health` | ❌ 不要 |

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
      "scores": { "groove": 0.82, "chill": 0.05, "neutral": 0.13 }
    }
  ]
}
```

**レスポンス**
```json
{ "sessionId": "abc123" }
```

---

### POST /sessions/:id/chat

1ターン分の対話を Claude に中継する。iOS 側が `history[]` を管理し、毎回リクエストに含める（ステートレス）。

**リクエスト**
```json
{
  "startTime": 78,
  "tags": ["groove"],
  "intensity": 0.82,
  "lyric": "歌詞行",
  "history": [
    { "role": "user", "content": "対話を開始してください" },
    { "role": "assistant", "content": "..." }
  ]
}
```

**レスポンス**
```json
{
  "question": "ベースが入った瞬間に何か感じましたか？",
  "choices": ["体が動いた", "テンションが上がった", "鳥肌が立った", "言葉にできない"]
}
```

---

### POST /sessions/:id/how-card

セッションが `req.uid` 所有であることを検証してから Howカードを生成・保存する。

**リクエスト**
```json
{
  "songTitle": "Blinding Lights",
  "reactions": [...],
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

**Firestore 書き込み（batch）**
- `how-cards/{cardId}` を作成（`displayName` を非正規化）
- `sessions/{sessionId}` の status を `"done"` に更新
- `users/{uid}` に email / displayName / howTags をマージ（auto-create）

**エラー**
- `403`: セッションが他ユーザーのもの
- `404`: セッションが存在しない

---

### GET /how-cards?tag=groove

タグで絞り込んだ Howカード一覧。`displayName` が含まれるので、コミュニティ画面でそのまま表示できる（追加の user 参照不要）。

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
      "description": "...",
      "highlightSec": 78
    }
  ]
}
```

最大50件、`createdAt` 降順。

---

### Howカードコメント API

iOS は `how-cards` へ直接アクセスせず、Firebase ID トークン付きでこのAPIを呼び出す。

`POST /how-cards`:

```json
{
  "comment": "このベースラインの入りが好き",
  "song_start": 78.4,
  "song_end": 84.2,
  "song_id": "1704093812",
  "artist_id": "ado"
}
```

バックエンドは `user_id` をトークンから補完し、`goods: 0` で保存する。
`GET /how-cards` / `GET /how-cards/:id` は `users/{user_id}.display_name` を Admin SDK で参照し、表示用の `user_name` だけをレスポンスへ付与する。

`GET /how-cards?song_id=1704093812` は `{ "howCards": [...] }`、`GET /how-cards/:id` / `POST /how-cards` / `PATCH /how-cards/:id` は `{ "howCard": ... }` を返す。

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
    "user_name": "Atsushi",
    "goods": 0
  }
}
```

`POST /how-cards/:id/like` は同じユーザーの二重いいねを防ぎ、`{ "goods": 4, "likes": 4 }` を返す。

---

### ユーザー API

`PUT /users/me`:

```json
{
  "email": "user@example.com",
  "display_name": null
}
```

`GET /users/me` / `PUT /users/me` は `{ "user": ... }` を返す。

---

## iOS 実装ガイド

iOS チームがこのバックエンドと連携するための最小実装メモ。

### Firebase SDK セットアップ

```swift
// AppDelegate or App
import FirebaseCore
import FirebaseAuth

FirebaseApp.configure()
```

### サインアップ（初回ユーザー）

```swift
// 1. ユーザー作成
let result = try await Auth.auth().createUser(withEmail: email, password: password)

// 2. displayName を設定（重要：これをやらないと token に name claim が入らない）
let changeRequest = result.user.createProfileChangeRequest()
changeRequest.displayName = displayName
try await changeRequest.commitChanges()

// 3. プロファイル更新を token に反映させるために強制リフレッシュ
let token = try await result.user.getIDToken(forcingRefresh: true)
```

### サインイン（既存ユーザー）

```swift
let result = try await Auth.auth().signIn(withEmail: email, password: password)
let token = try await result.user.getIDToken()
```

### アプリ起動時の状態チェック

Firebase Auth は Keychain にセッションを保持するので、再ログイン不要。

```swift
if let user = Auth.auth().currentUser {
    let token = try await user.getIDToken()  // 自動リフレッシュされる
    // ログイン済み → メイン画面
} else {
    // 未ログイン → ログイン画面
}
```

### リクエストへのトークン付与

```swift
var request = URLRequest(url: url)
request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
```

### 401 ハンドリング

トークンは1時間で失効する。`getIDToken()` は自動リフレッシュするが、ネットワーク状況やサインアウトで失敗することがある。

```swift
if response.statusCode == 401 {
    try? Auth.auth().signOut()
    // ログイン画面へ遷移
}
```

### よくある落とし穴

1. **displayName を設定した直後の token に name claim が入らない**
   → `getIDToken(forcingRefresh: true)` で強制リフレッシュする
2. **シミュレータでネットワーク権限ダイアログが出ない**
   → 実機で確認
3. **`GoogleService-Info.plist` を Xcode の "Copy items if needed" で追加していない**
   → ビルドエラーになる
4. **iOS 側で Firestore に直接書き込もうとする**
   → Firestore rules で全拒否しているので必ず backend 経由

---

## エラーレスポンス

```json
{ "error": "エラーメッセージ" }
```

| HTTP | 意味 |
|------|------|
| 400 | リクエスト不正（パラメータ不足など） |
| 401 | 認証失敗（トークンなし・無効・期限切れ） |
| 403 | アクセス権なし（他ユーザーのリソース） |
| 404 | リソースが見つからない |
| 500 | サーバーエラー（Claude API / Firestore 障害） |
