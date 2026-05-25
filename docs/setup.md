# セットアップ手順

## 前提条件

- macOS + Xcode 15 以上
- Node.js 20 以上（Functions を触る場合）
- iPhone 実機
- 頭部モーション対応 AirPods
- Apple Music を再生できる Apple ID / MusicKit 権限

HealthKit / 心拍連携は現行 MVP から削除済み。ヘルス権限や HealthKit capability は不要。

---

## 1. iOS アプリを起動する

```bash
git clone https://github.com/engineer-guild-hackathon-2026-05/team-10.git
cd team-10
open Othello/Othello.xcodeproj
```

Xcode で以下を設定してから Run:

1. **Signing & Capabilities** → Team を自分の Apple Developer アカウントに変更
2. 実機（iPhone）を選択
3. MusicKit を利用できる provisioning profile を使う

注意:

- AirPods 頭部モーションはシミュレータでは取得できない。
- 初回起動時は Firebase Auth でログインする。
- Apple Music の楽曲検索・再生には MusicKit 認証と Apple Music カタログ再生権限が必要。

---

## 2. iOS 環境値

`Othello/Othello/ENV.example.plist` をコピーして `ENV.plist` を作成し、値を埋める。

```bash
cp Othello/Othello/ENV.example.plist Othello/Othello/ENV.plist
```

| キー | 説明 |
|---|---|
| `API_BASE_URL` | Functions API の URL。通常は `https://asia-northeast1-egh-howtune.cloudfunctions.net/api` |
| `MUSIXMATCH_API_KEY` | Musixmatch API キー |
| `HOWTUNE_CHAT_MOCK` | HowChat を mock 応答にする場合は `true` |

`ENV.plist` は `.gitignore` 対象。コミットしない。

---

## 3. 本番 API

本番 API は Firebase Cloud Functions v2 の `functions/` からデプロイされる。通常の実機確認ではローカル backend の起動は不要。

Base URL:

```text
https://asia-northeast1-egh-howtune.cloudfunctions.net/api
```

動作確認:

```bash
curl https://asia-northeast1-egh-howtune.cloudfunctions.net/api/health
```

---

## 4. Functions を変更する場合

```bash
cd functions
npm install
npx firebase-tools deploy --only functions
```

本番 API の変更は `functions/` を正とする。`backend/` は deprecated な参照実装であり、編集しても本番には反映されない。

---

## 5. Musixmatch 連携

MusicKit の `Song` から曲名・アーティスト名・アルバム名・ISRC・曲長を取得し、Musixmatch 照合に使う。

現在の実装は以下の順で歌詞を取得する。

1. `matcher.track.get` で `track_id` を解決
2. `track.subtitle.get` で LRC 形式の時間同期歌詞を取得
3. 失敗時は `track.lyrics.get` の静的歌詞へ fallback

同期歌詞が取得できない場合も、静的歌詞または歌詞なし表示で体験を継続する。
