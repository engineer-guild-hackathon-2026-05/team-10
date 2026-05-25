# セットアップ手順

## 前提条件

- macOS + Xcode 15 以上
- Node.js 20 以上
- iPhone 実機（AirPods の頭部モーション・心拍はシミュレータ不可）
- 対応 AirPods（AirPods Pro 2 世代目 / AirPods 4 等）

---

## 1. バックエンドを起動する（必須）

> ⚠️ **iOS アプリを動かす前に、必ずバックエンドを起動してください。**
> バックエンドが起動していないと、AI 対話・Howカード生成・Firestore 保存がすべて動作しません。

```bash
cd backend
cp .env.example .env          # .env を作成し API キーを記入
npm install
npm start                      # localhost:3000 で起動
```

`.env` に必要なキー：

| 変数名 | 説明 |
|---|---|
| `ANTHROPIC_API_KEY` | Claude API キー |
| `GOOGLE_APPLICATION_CREDENTIALS` | Firebase Admin SDK サービスアカウント JSON のパス |

---

## 2. iOS アプリを起動する

```bash
# リポジトリのクローン
git clone https://github.com/engineer-guild-hackathon-2026-05/team-10.git
cd team-10

# iOS アプリを Xcode で開く
open Othello/Othello.xcodeproj
```

Xcode で以下を設定してから Run：

1. **Signing & Capabilities** → Team を自分の Apple Developer アカウントに変更
2. **実機（iPhone）** を選択して ▶ Run

### 注意事項

- **実機必須**：AirPods の頭部モーション・心拍はシミュレータで取得できません
- **権限**：初回起動時にモーション / ヘルス / メディアの許可ダイアログが表示されます。すべて許可してください
- **Apple Music**：楽曲検索には Apple Music サブスクリプションが必要です

---

## 3. 環境変数（iOS）

`Othello/Othello/ENV.example.plist` をコピーして `ENV.plist` を作成し、値を埋めてください。

| キー | 説明 |
|---|---|
| `API_BASE_URL` | バックエンドの URL（ローカルは `http://localhost:3000`） |
| `MUSIXMATCH_API_KEY` | Musixmatch API キー（歌詞取得） |

> `ENV.plist` は `.gitignore` に含まれています。コミットしないでください。

---

## 4. バックエンドの本番デプロイ

> 担当者が別途設定します。詳細は [`docs/backend.md`](./backend.md) を参照。
