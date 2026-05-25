# HowTune Functions

HowTune バックエンドの **Firebase Cloud Functions v2** デプロイターゲット。
本番環境はここからデプロイされる。

---

## アーキテクチャ

- **ランタイム:** Node.js 20 on Cloud Run（Functions v2 の実体）
- **リージョン:** `asia-northeast1`（東京）
- **エクスポート:**
  - `api` — HTTPS Function に Express アプリ全体をマウント
  - `onUserSignup` — Firebase Auth の `onCreate` トリガー（v1）。新規サインアップ時に `users/{uid}` を自動生成
- **認証:** Firebase ID トークン（`middleware/auth.js`）
- **データ:** Firestore（`repositories/firestore.js`、Admin SDK）

### コールドスタート対策

`index.js` の `onRequest` に `minInstances: 1` を設定済み。
常時 1 インスタンス温めるため、HTTP API のコールドスタートはほぼ発生しない。

**コスト:** 256 MiB × 1 インスタンス常駐 ≒ 月 5 USD 程度。
不要になったら `minInstances: 0` に変更して再デプロイすれば停止する。

Auth トリガー (`onUserSignup`) には `minInstances` を設定していない（サインアップは頻度が低く、多少のコールドスタートは許容）。

### Auth トリガー (onUserSignup)

Firebase Auth で新規ユーザー作成が走ったタイミングで `users/{uid}` を自動生成する。

- 発火条件: Firebase Auth で新規ユーザーが作成された時（iOS の初回サインアップ）
- 既存ユーザーには発火しない（onCreate なので新規のみ）
- iOS 側の `PUT /users/me` は追加同期用。メールアドレスは ID トークンの値を正とする
- ドキュメント内容: `{ user_id, email, display_name, created_at }`
- 実装は v1 SDK（`firebase-functions/v1`）。v2 の Auth トリガーは blocking 専用なので、非同期で完了する onCreate には v1 を使う

---

## ディレクトリ構成

```text
functions/
├── index.js                  # Functions エントリ（HTTP api + Auth トリガー）
├── app.js                    # Express アプリビルダー（mount だけ、listen しない）
├── middleware/
│   └── auth.js               # Firebase ID トークン検証
├── repositories/
│   └── firestore.js          # Firestore 読み書き（how-cards / users）
├── routes/
│   ├── how-cards.js          # /how-cards 配下
│   └── users.js              # /users / /users/me
├── package.json
└── .gitignore
```

---

## 初回デプロイ

### 1. 前提条件の確認

```powershell
firebase --version            # 14.x 以上
firebase projects:list        # egh-howtune が見えること
firebase use egh-howtune      # アクティブプロジェクト設定（.firebaserc にあるので通常は不要）
```

未インストールなら:

```powershell
npm install -g firebase-tools
firebase login
```

### 2. 依存関係インストール

```powershell
cd functions
npm install
```

### 3. デプロイ

```powershell
firebase deploy --only "functions,firestore:indexes"
```

> PowerShell では `--only` の値全体を **ダブルクオートで囲む**こと。クオート無しだとカンマが PowerShell のオプション区切りと解釈されてエラーになる。

初回は 5〜10 分（Cloud Run プロビジョニング込み）。2 回目以降は 1〜3 分。

### 4. デプロイ後の URL

```text
https://asia-northeast1-egh-howtune.cloudfunctions.net/api
```

動作確認:

```powershell
curl https://asia-northeast1-egh-howtune.cloudfunctions.net/api/health
# → {"status":"ok"} が返れば OK
```

iOS チームには上記の URL をベース URL として共有する。

### 5. Auth トリガーの動作確認

iOS でテストユーザーを新規サインアップ → Firebase Console の Firestore で `users/{uid}` ドキュメントが自動生成されていることを確認する。

---

## エンドポイント一覧

ベース URL: `https://asia-northeast1-egh-howtune.cloudfunctions.net/api`

| メソッド | パス | 認証 | 用途 |
|---------|------|------|------|
| GET | `/health` | ❌ | 死活確認 |
| GET | `/how-cards` | ✅ | Howカードコメント一覧（最新250件） |
| GET | `/how-cards?song_id=...` | ✅ | 曲ごとのHowカードコメント一覧 |
| GET | `/how-cards/:id` | ✅ | Howカードコメント取得 |
| POST | `/how-cards` | ✅ | Howカードコメント作成 |
| PATCH | `/how-cards/:id` | ✅ | 自分のHowカードコメント更新 |
| POST | `/how-cards/:id/like` | ✅ | いいね（冪等、二重防止） |
| GET | `/users/me` | ✅ | 自分のユーザー情報取得 |
| PUT | `/users/me` | ✅ | 自分のユーザー情報作成・更新 |

### `POST /how-cards`

ユーザー入力の Howカードコメントを作成する。

**リクエスト**

```json
{
  "comment": "このベースラインの入りが好き",
  "song_start": 78.4,
  "song_end": 84.2,
  "song_id": "1704093812",
  "song_slug": "ado-show",
  "artist_id": "ado"
}
```

| フィールド | 型 | 説明 |
|-----------|-----|------|
| `comment` | string | ユーザー記入のコメント（空文字不可） |
| `song_start` | number | 区間開始（秒、0 以上） |
| `song_end` | number | 区間終了（秒、`song_start` より大きい） |
| `song_id` | string | MusicKit / Apple Music / iTunes の曲 ID |
| `itunes_id` | string | 任意。`song_id` が legacy slug の場合に canonical 曲 ID として使う |
| `song_slug` | string | 任意。表示・移行用の曲 slug。`song_id` には入れない |
| `artist_id` | string | アーティスト ID |

`song_id` は client が MusicKit metadata lookup に使う canonical ID とする。slug や曲名由来の値は `song_slug` など別フィールドで送る。

**レスポンス**

```json
{
  "howCard": {
    "id": "card456",
    "comment": "このベースラインの入りが好き",
    "song_start": 78.4,
    "song_end": 84.2,
    "song_id": "1704093812",
    "itunes_id": "1704093812",
    "artist_id": "ado",
    "user_id": "uid123",
    "likes": 0
  }
}
```

### `GET /how-cards`

最新の Howカードコメント一覧を返す（最大 250 件、`created_at` 降順）。
`song_id` を指定した場合は曲ごとのコメント一覧を返す。

**レスポンス**

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
      "likes": 3
    }
  ]
}
```

`user_name` は `users/{user_id}.display_name` から Admin SDK で参照した表示用フィールド。メールアドレスなどの user 詳細は返さない。

### `POST /how-cards/:id/like`

カードに「いいね」を付ける。冪等（同じユーザーが何度叩いても 1 件のみカウント）。

**レスポンス**

```json
{ "likes": 4 }
```

**動作:**

- `how-cards/{id}/liked-by/{uid}` の存在を確認
- 未いいねなら: `liked-by/{uid}` 作成 + `likes` を +1
- 既いいねなら: ノーオペ（現在の `likes` を返す）

### `GET /users/me` / `PUT /users/me`

`onUserSignup` で自動生成された `users/{uid}` を取得・追加同期する。
`PUT /users/me` では ID トークンのメールアドレスを正とし、body の `email` が異なる場合は 400 を返す。ID トークンにメールアドレスがない場合は `null` として保存する。

**リクエスト**

```json
{
  "email": null,
  "display_name": "Atsushi"
}
```

---

## Firestore スキーマ

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
  updated_at: timestamp

how-cards/{cardId}/liked-by/{uid}
  user_id: string
  liked_at: timestamp
```

---

## 既知の注意点

### URL パスの prefix

Functions v2 では、エクスポート名 `api` がパスに含まれる可能性がある:

- 現状動作確認済み: `https://...cloudfunctions.net/api/health` → Express は `/health` として正しく受信する
- 万一 Express が `/api/health` として受信し始めた場合は `app.js` で `app.use('/api', ...)` マウントに変更が必要

### v1 と v2 の混在

`index.js` で `firebase-functions/v2/https` の `onRequest` と `firebase-functions/v1` の `auth.user().onCreate` を併用している。これは Firebase が公式に許容しているパターン（v2 の Auth トリガーは blocking 専用なので、非同期処理を後追いで走らせたいケースでは v1 を使う）。

---

## ローカル開発

このディレクトリではローカル開発しない。`../backend/` を使う（ただし `backend/` のコードは古いままで凍結されている可能性が高い。`backend/README.md` の警告を参照）:

```powershell
cd ..\backend
npm run dev   # Express on localhost:3000
```
