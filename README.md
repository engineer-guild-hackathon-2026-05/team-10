# HowTune — Engineer Guild Hackathon 2026/05

> **1行ピッチ**：何を聴くかではなく、どう聴いているかでつながる。

AirPods の頭部モーションから「曲中のどこで身体が反応したか」を捉え、歌詞や曲中区間への How コメントで音楽の楽しみ方を言語化。同じ聴き方の人とつながる iOS アプリ。

## スクリーンショット

<!-- README先頭の見栄え兼SNS素材。Day2 終了までに最低1枚は貼る -->

| メイン画面 | 主要機能 |
|---|---|
| `docs/screenshot-main.png` を貼る | `docs/screenshot-feature.png` を貼る |

## チーム情報

| 項目 | 内容 |
|---|---|
| チーム名 | Othello |
| プロダクト名 | HowTune |
| 担当メンター | （記入） |

### メンバー

| GitHub | 氏名 | 大学 / 学部 | 担当役割 |
|---|---|---|---|
| @username | 氏名 | XX大学 XX学部 | PM |
| @username | 氏名 | XX大学 XX学部 | iOS |
| @username | 氏名 | XX大学 XX学部 | Backend |
| @username | 氏名 | XX大学 XX学部 | ML / Design |

担当役割の凡例：**PM** / **iOS** / **Backend** / **ML** / **Design** / その他

## プロダクト概要

既存の音楽サービスは「何を聴くか（What）」でつながる。しかし熱狂が本当に伝わるのは「どう聴いているか（How）」が共有されたときだ。HowTune は AirPods の頭部モーションから曲中の身体反応を検出し、歌詞や区間に対するコメントを「Howカード」として可視化。曲やジャンルではなく、**同じ聴き方をしている人**との出会いを生み出す。

### 解決したい課題

音楽の楽しみ方（How）をうまく言語化できないため、同じ聴き方をしている人と出会えない。

### ターゲットユーザー

- 音楽は好きだが「どこが好きか」を言語化できない一般リスナー
- 自分の聴き方を発信し、近い価値観の人とつながりたい人

### コア機能

- AirPods 頭部モーションの取得（曲中時刻に同期）
- 3状態スコア（groove / chill / neutral）の推定
- 反応地点や歌詞行に紐づく How コメント作成
- Howカードコメントの保存・編集・いいね
- 同じ How を持つ人・曲・リスナーの表示

## 提出ステータス（運営チェック用 — 各 Day 終了時に記入）

- [ ] **Day1 終了時**：テーマ確定（プロダクト名・解決課題・ターゲットを記入済み）
- [ ] **Day2 終了時**：MVP 動作（実機で動くデモ）
- [ ] **Day3 終了時**：提出完了（プレゼン資料 URL / デモ動画 URL / AI 活用ログ完成）

## 提出物チェックリスト（Day3 12:00 提出〆切）

- [ ] 動くデモ（実機 / TestFlight）
- [ ] ソースコード（このリポに push 済み）
- [ ] [`AI_USAGE_LOG.md`](./AI_USAGE_LOG.md)（AI 活用ログ、開発期間中の追記必須）
- [ ] プレゼン資料（PDF or Slides URL を記載）
- [ ] デモ動画（任意・1 分以内・URL 記載）

## デモ・関連リンク

| 種別 | URL |
|---|---|
| デモ（実機 / TestFlight） | （記入） |
| プレゼン資料 | （Google Slides / Notion / Speakerdeck） |
| デモ動画 | （YouTube / Loom） |
| 仕様書（source of truth） | [`docs/frontend-spec.md`](./docs/frontend-spec.md)（Notion ミラー） |

## 技術スタック

- **iOS アプリ（`Othello/`）**：Swift / SwiftUI（Xcode）
- **センサー**：CMHeadphoneMotionManager（AirPods 頭部）
- **音楽再生**：MusicKit
- **ML（`ai-recognition/`）**：TensorFlow で学習 → Core ML に変換し端末推論
- **バックエンド（`functions/`）**：Firebase Cloud Functions v2 + Express + Firestore Admin SDK
- **AI 対話**：HowChat に mock/legacy client が残る。Functions 本番 contract には未接続
- **データ**：Firestore
- **利用 AI ツール**：Codex / Claude Code

### 使用した外部 API / サービス

| サービス名 | 用途 | プラン | 備考 |
|---|---|---|---|
| Apple MusicKit | 楽曲情報・再生位置取得 | — | MVP は MusicKit 前提。Spotify は使用しない |
| Musixmatch | 時間同期歌詞または静的歌詞取得 | 要 API key | `ENV.plist` の `MUSIXMATCH_API_KEY` に設定 |

→ API キー・秘匿情報は `.env` / `ENV.plist`（`.gitignore` 対象）で管理し、git に含めない。

### MusicKit / Musixmatch 連携メモ

- MusicKit の `Song` から曲名・アーティスト名・アルバム名・ISRC・曲長を取り出し、Musixmatch の照合に使う。
- Musixmatch の `matcher.track.get` で `track_id` を解決し、`track.subtitle.get` で LRC 形式の時間同期歌詞を試す。
- 同期歌詞が取得できない場合は `track.lyrics.get` の静的歌詞へ fallback する。実機検証では Xcode コンソールの `[MusixmatchLyricsProvider]` ログで `status` / `hint` / 試行した ID を確認する。
- Spotify Web API は MVP では使用しない。

## リポジトリ構成

```
team-10/
├── Othello/          # iOS ネイティブアプリ（Xcode / SwiftUI）
├── functions/        # Firebase Functions（本番 API）
├── backend/          # 旧 Express 実装（deprecated / 参照用）
├── ai-recognition/   # AIモデル（TensorFlow 学習 → Core ML 変換）
├── frontend/         # フロントエンド置き場（LP/管理画面・MVP未使用）
└── docs/             # ドキュメント（仕様は docs/frontend-spec.md が正）
```

## セットアップ

詳細な手順は **[`docs/setup.md`](./docs/setup.md)** を参照してください。

> 本番 API は Firebase Functions にデプロイ済みです。通常の実機確認ではローカル backend の起動は不要です。

```bash
cp Othello/Othello/ENV.example.plist Othello/Othello/ENV.plist
# API_BASE_URL と MUSIXMATCH_API_KEY を設定
```

`.env` に必要なキー：

| 変数名 | 説明 |
|---|---|
| `API_BASE_URL` | Functions API の URL |
| `MUSIXMATCH_API_KEY` | Musixmatch API キー |

### 2. iOS アプリを起動する

```bash
# リポジトリのクローン
git clone https://github.com/engineer-guild-hackathon-2026-05/team-10.git
cd team-10

# iOS アプリを Xcode で開く
open Othello/Othello.xcodeproj
# 署名チームを設定し、実機（iPhone）を選んで Run
```

- **実機必須**：AirPods の頭部モーションはシミュレータで取得できません（iPhone + 対応 AirPods が必要）
- **権限**：`Info.plist` に `NSMotionUsageDescription` が必要
- **MusicKit**：Apple Developer の App ID で MusicKit App Service を有効化し、プロビジョニングプロファイルを更新してから実機ビルドする
- **Musixmatch**：`Othello/Othello/ENV.example.plist` を `ENV.plist` にコピーし、`MUSIXMATCH_API_KEY` を設定する。`matcher.track.get` と `track.lyrics.get` が 401/402/403 を返す場合は API key・利用上限・契約プランを確認する


## ドキュメント

| ファイル | 内容 |
|---|---|
| [`docs/frontend-spec.md`](./docs/frontend-spec.md) | **仕様の source of truth**（Notion ミラー、SDD） |
| [`docs/product-requirements.md`](./docs/product-requirements.md) | プロダクト要求定義（PRD） |
| [`docs/architecture.md`](./docs/architecture.md) | アーキテクチャ設計 |
| [`docs/functional-design.md`](./docs/functional-design.md) | 機能設計 |
| [`docs/setup.md`](./docs/setup.md) | ローカル開発環境のセットアップ手順 |
| [`docs/data-model.md`](./docs/data-model.md) | データモデル設計（Firestore スキーマ・反応区間構造） |
| [`docs/repository-structure.md`](./docs/repository-structure.md) | リポジトリ構造 |
| [`docs/development-guidelines.md`](./docs/development-guidelines.md) | 開発ガイドライン |
| [`docs/glossary.md`](./docs/glossary.md) | 用語集 |

> Notion は git からの一方向ミラーです。**仕様の編集は git 側（`docs/`）で行ってください。**

## 既知の問題 / 未実装機能（Day3 審査員向け）

開発期間が短いため、Day3 提出時点で「ここまでやった／ここは諦めた」を正直に書く。
**正直に書くことは減点ではなく加点要素**（自己評価力として審査される）。

- 未実装：（記入）
- 既知の問題：（記入）

## 担当メンター・壁打ち履歴

| 日時 | メンター | 議論内容（要点） | 採用 / 一部採用 / 不採用 |
|---|---|---|---|
| Day1 14:00 |  |  |  |
| Day2 11:00 |  |  |  |

## AI 活用ログ

審査項目「AI 活用度」の根拠資料 → [`AI_USAGE_LOG.md`](./AI_USAGE_LOG.md)

開発期間中に最低 1 日 3 件以上の追記を目安に。

## 公開許諾（チーム全員合意のうえ記入 — Day3 終了時までに）

提出後の運営側での扱いに関するチーム全員合意です。**いずれも N で構いません（審査に一切影響なし）**。

| 項目 | 許諾 (Y/N) | 補足・条件 |
|---|---|---|
| ① このリポを **Public 化**してよい（コードがすべて公開される） | | |
| ② プロダクト名・スクリーンショット・1行ピッチを **HTV / Mercari の SNS・記事**で掲載してよい | | |
| ③ **スポンサー企業（Mercari, P&G 等）の広報・採用ページ**でプロダクト紹介してよい | | |

## 審査観点（参考）

審査は以下 8 項目で実施されます。実装中に意識すべきポイント：

1. 実用性
2. 創造性
3. UI / UX
4. 技術的挑戦
5. 将来性
6. 完成度
7. プレゼンテーション
8. AI 活用度（→ [`AI_USAGE_LOG.md`](./AI_USAGE_LOG.md) が根拠資料）

## 謝辞（任意）

スポンサー・メンター・運営への一言メッセージを残したい場合はここに記入。

## 運営連絡先

- Slack: `#eg-hackathon-2026-05`（または `#pjt_swe_event`）
- 緊急時: 運営メンバー（Mercari HQ 受付 → 運営呼び出し）
