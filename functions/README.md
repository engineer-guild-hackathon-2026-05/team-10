# HowTune Functions

HowTune バックエンドの **Firebase Cloud Functions v2** デプロイターゲット。
本番環境はここからデプロイされる。

---

## アーキテクチャ

- **ランタイム:** Node.js 20 on Cloud Run（Functions v2 の実体）
- **リージョン:** `asia-northeast1`（東京）
- **エクスポート:** 単一の HTTPS Function `api` に Express アプリ全体をマウント
- **認証:** Firebase ID トークン（既存の `middleware/auth.js`）
- **データ:** Firestore（`repositories/firestore.js`、Admin SDK）
- **LLM:** Anthropic Claude（`services/claude.js`）

### コールドスタート対策

`index.js` の `onRequest` に `minInstances: 1` を設定済み。
常時 1 インスタンス温めるため、コールドスタートはほぼ発生しない。

**コスト:** 256 MiB × 1 インスタンス常駐 ≒ 月 5 USD 程度。
不要になったら `minInstances: 0` に変更して再デプロイすれば停止する。

---

## ディレクトリ構成

```
functions/
├── index.js                  # Functions エントリ（onRequest で app をラップ）
├── app.js                    # Express アプリビルダー（mount だけ、listen しない）
├── middleware/
│   └── auth.js               # Firebase ID トークン検証
├── repositories/
│   └── firestore.js          # Firestore 読み書き
├── services/
│   └── claude.js             # Claude API ラッパー
├── routes/
│   ├── sessions.js           # /sessions 配下
│   ├── how-cards.js          # /how-cards 配下
│   └── users.js              # /users/me
├── package.json
└── .gitignore
```

`../backend/` と同じファイル構成。コード変更時は両方更新する（あるいは backend/ 側の変更を諦める）。

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

### 3. シークレット登録（Anthropic API キー）

```powershell
firebase functions:secrets:set ANTHROPIC_API_KEY
```

プロンプトに API キーを貼り付ける。Secret Manager に保存される。
Firebase Admin の認証情報（サービスアカウント）は **不要**——Functions ランタイムが ADC で自動取得する。

### 4. デプロイ

```powershell
firebase deploy --only functions
```

初回は 5〜10 分（Cloud Run プロビジョニング込み）。2 回目以降は 1〜3 分。

### 5. デプロイ後の URL

```
https://asia-northeast1-egh-howtune.cloudfunctions.net/api
```

動作確認:
```powershell
curl https://asia-northeast1-egh-howtune.cloudfunctions.net/api/health
# → {"status":"ok"} が返れば OK
```

iOS チームには上記の URL をベース URL として共有する。

---

## エンドポイント一覧

API 仕様は [`../backend/README.md`](../backend/README.md) と [`../docs/backend.md`](../docs/backend.md) を参照（実装は同一）。

| メソッド | パス | 認証 | 用途 |
|---------|------|------|------|
| GET | `/health` | ✅ | 死活確認 |
| POST | `/sessions` | ✅ | セッション作成 |
| POST | `/sessions/:id/chat` | ✅ | AI 対話 |
| POST | `/sessions/:id/how-card` | ✅ | Howカード生成・保存 |
| GET | `/how-cards?tag=...` | ✅ | Howカード一覧 |
| GET | `/how-cards?song_id=...` | ✅ | Howカードコメント一覧 |
| POST | `/how-cards` | ✅ | Howカードコメント作成 |
| PATCH | `/how-cards/:id` | ✅ | 自分のHowカードコメント更新 |
| POST | `/how-cards/:id/goods` | ✅ | Howカードコメントのいいね加算 |
| GET | `/users/me` | ✅ | 自分のユーザー情報取得 |
| PUT | `/users/me` | ✅ | 自分のユーザー情報作成・更新 |

---

## 既知の注意点

### URL パスの prefix

Functions v2 では、エクスポート名 `api` がパスに含まれる可能性がある:
- 期待: `https://...cloudfunctions.net/api/health` → Express は `/health` として受信
- 万が一: Express が `/api/health` として受信する場合 → `app.js` で `app.use('/api', ...)` マウントに変更が必要

デプロイ後の `/health` リクエストで判別できる。404 なら後者。

### Anthropic クライアントの初期化

`services/claude.js` はモジュールロード時に `process.env.ANTHROPIC_API_KEY` を読む。
Functions v2 のシークレットは **コールドスタート時にランタイムが env に注入してから user code をロードする** 仕様なので、通常は動作する。

万が一「Anthropic API key not found」で落ちる場合は、`services/claude.js` を遅延初期化に書き換える:
```js
let _anthropic;
function getAnthropic() {
  if (!_anthropic) {
    _anthropic = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY, timeout: 30_000 });
  }
  return _anthropic;
}
```
そして全ての `anthropic.messages.create(...)` を `getAnthropic().messages.create(...)` に置換。

---

## ローカル開発

このディレクトリではローカル開発しない。`../backend/` を使う:

```powershell
cd ..\backend
npm run dev   # Express on localhost:3000
```

どうしても Functions エミュレーターで動かしたい場合:

```powershell
cd functions
firebase emulators:start --only functions
```

エミュレーターはシークレットを別途設定する必要がある（`.secret.local` ファイル等）。詳細は [Firebase ドキュメント](https://firebase.google.com/docs/functions/local-emulator) を参照。

---

## デプロイの取り消し / ロールバック

```powershell
firebase functions:delete api --region asia-northeast1
```

または、コンソールから過去のリビジョンに切り戻す（Cloud Run の機能）。

---

## ログ確認

```powershell
firebase functions:log
# または
firebase functions:log --only api --limit 50
```

Cloud Console の Cloud Logging でも閲覧可能。

---

## コスト

- **コールド時:** ほぼ無料（Functions v2 の無料枠 = 2M 呼び出し/月 + 400K GB-秒/月）
- **`minInstances: 1` 適用後:** 月 5 USD 程度（256 MiB × 24h × 30日）
- **Anthropic API:** 別途 Anthropic に課金（egress 課金は GCP→Anthropic への外向き通信に対して発生するが、デモ規模では誤差）
