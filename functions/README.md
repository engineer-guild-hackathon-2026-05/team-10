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
- iOS 側で追加 API 呼び出しは不要——サインアップが完了すれば自動的に走る
- ドキュメント内容: `{ email, displayName, createdAt }`
- 実装は v1 SDK（`firebase-functions/v1`）。v2 の Auth トリガーは blocking 専用なので、非同期で完了する onCreate には v1 を使う

---

## ディレクトリ構成

```
functions/
├── index.js                  # Functions エントリ（HTTP api + Auth トリガー）
├── app.js                    # Express アプリビルダー（mount だけ、listen しない）
├── middleware/
│   └── auth.js               # Firebase ID トークン検証
├── repositories/
│   └── firestore.js          # Firestore 読み書き（how-cards / users）
├── routes/
│   └── how-cards.js          # /how-cards 配下
└── package.json
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

```
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
| GET | `/health` | ✅ | 死活確認 |
| GET | `/how-cards` | ✅ | Howカード一覧（最新50件） |
| POST | `/how-cards` | ✅ | Howカード作成 |
| POST | `/how-cards/:id/like` | ✅ | いいね（冪等、二重防止） |

### `POST /how-cards`

ユーザー入力の Howカードを作成する。

**リクエスト**
```json
{
  "comment": "ベースの入りで身体が動いた",
  "songStart": 78,
  "songEnd": 92,
  "songTitle": "Blinding Lights"
}
```

| フィールド | 型 | 説明 |
|-----------|-----|------|
| `comment` | string | ユーザー記入のコメント（空文字不可） |
| `songStart` | number | 区間開始（秒、0 以上） |
| `songEnd` | number | 区間終了（秒、songStart より大きい） |
| `songTitle` | string | 曲名 |

**レスポンス**
```json
{
  "howCard": {
    "id": "card456",
    "userId": "uid123",
    "comment": "ベースの入りで身体が動いた",
    "songStart": 78,
    "songEnd": 92,
    "songTitle": "Blinding Lights",
    "likes": 0
  }
}
```

### `GET /how-cards`

最新の Howカード一覧を返す（最大 50 件、`createdAt` 降順）。

**レスポンス**
```json
{
  "howCards": [
    {
      "id": "card456",
      "userId": "uid123",
      "comment": "...",
      "songStart": 78,
      "songEnd": 92,
      "songTitle": "...",
      "likes": 3,
      "createdAt": { "_seconds": ..., "_nanoseconds": ... }
    }
  ]
}
```

### `POST /how-cards/:id/like`

カードに「いいね」を付ける。冪等（同じユーザーが何度叩いても 1 件のみカウント）。

**レスポンス**
```json
{ "likes": 4 }
```

**動作:**
- `how-cards/{id}/liked-by/{uid}` の存在を確認
- 未いいねなら: バッチで `liked-by/{uid}` 作成 + `likes` を +1
- 既いいねなら: ノーオペ（現在の `likes` を返す）

---

## Firestore スキーマ

```
users/{uid}                          # onUserSignup で自動作成
  email: string | null
  displayName: string | null
  createdAt: timestamp

how-cards/{cardId}
  userId: string
  comment: string
  songStart: number
  songEnd: number
  songTitle: string
  likes: number                       # 初期値 0、いいねごとに +1
  createdAt: timestamp

how-cards/{cardId}/liked-by/{uid}    # いいね二重防止用サブコレクション
  likedAt: timestamp
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

どうしても Functions エミュレーターで動かしたい場合:

```powershell
cd functions
firebase emulators:start --only functions
```

---

## デプロイの取り消し / ロールバック

```powershell
firebase functions:delete api --region asia-northeast1
firebase functions:delete onUserSignup --region asia-northeast1
```

または、コンソールから過去のリビジョンに切り戻す（Cloud Run の機能）。

---

## ログ確認

```powershell
firebase functions:log
# または特定の関数のみ
firebase functions:log --only api --limit 50
firebase functions:log --only onUserSignup --limit 20
```

Cloud Console の Cloud Logging でも閲覧可能。

---

## コスト

- **コールド時:** ほぼ無料（Functions v2 の無料枠 = 2M 呼び出し/月 + 400K GB-秒/月）
- **`minInstances: 1` 適用後:** 月 5 USD 程度（256 MiB × 24h × 30日）
- **Auth トリガー:** 呼び出しごとに微小な実行コストのみ。実質無料
- **Firestore:** 読み書きごとに微小な課金。デモ規模では誤差
