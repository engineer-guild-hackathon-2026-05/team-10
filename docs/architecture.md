# 技術仕様書 (Architecture Design Document)

> 対象: **iOS ネイティブ（Xcode / SwiftUI）**。実コード構成は `Othello/`（iOSアプリ）/ `backend/` / `ai-recognition/` / `frontend/`。

## テクノロジースタック

### iOS アプリ（`Othello/`）

| 技術 | 用途 | 選定理由 |
|------|------|----------|
| Swift 5.9+ / SwiftUI | UI・アプリ全般 | iOS ネイティブ標準。宣言的 UI で高速開発 |
| Core Motion | iPhone 本体モーション取得 | 加速度・ジャイロの標準 API |
| CMHeadphoneMotionManager | AirPods 頭部モーション取得 | AirPods の加速度・姿勢を取得する唯一の手段 |
| HealthKit | 心拍取得 | 対応 AirPods の心拍をヘルスデータ経由で取得 |
| MusicKit | 楽曲再生・再生位置取得 | Apple Music の曲を再生位置付きで再生（DECISION-01） |
| AVFoundation | 音量取得・収集アプリのローカル音源再生 | 本番アプリは MusicKit、学習データ収集アプリはローカル音源にも対応 |
| Core ML | 端末上の反応スコア補助推論 | `ai-recognition/` の3状態モデル候補と特徴量から、iOS側で6軸 `ReactionScore` に展開（DECISION-02） |
| Keychain Services | 認証トークン保持 | 機微情報の安全な保存 |

### バックエンド（`backend/`）

| 技術 | 用途 | 選定理由 |
|------|------|----------|
| LLM プロキシ（Node.js or Python） | Claude API 中継 | API キーをクライアントに置かないため必須 |
| Anthropic SDK | Claude API 連携 | 問いかけ型の対話生成 |
| Firestore / CloudKit | データ永続化 | iOS SDK あり（DECISION-03） |
| Firebase Auth / Sign in with Apple | 認証 | iOS ネイティブで実装容易 |

### AI モデル（`ai-recognition/`）

| 技術 | 用途 | 選定理由 |
|------|------|----------|
| TensorFlow.js / Create ML | モーションからの3状態ラベル学習 | `ai-recognition/` のMVPは groove / chill / neutral で収集し、iOSの6軸表示へ接続 |
| coremltools / Create ML | TF / 収集データ → Core ML 変換 | 学習済みモデルを iOS に組み込み |

### 開発ツール

| 技術 | 用途 |
|------|------|
| Xcode | iOS ビルド・実機デバッグ |
| SwiftFormat / SwiftLint | コード整形・静的解析 |
| XCTest | ユニット・UI テスト |
| GitHub Actions | CI（ビルド・テスト） |

---

## アーキテクチャパターン

### 全体構成

```
┌──────────────────────────────────────────────────────────┐
│  iOS アプリ（Othello/ · SwiftUI）                         │
│  ┌─────────────────────────────────────────────────┐     │
│  │  View（SwiftUI）                                 │     │
│  │  - OnboardingView / ListeningView                │     │
│  │  - ReactionTimelineView / HowChatView            │     │
│  │  - HowCardView / CommunityView                   │     │
│  ├─────────────────────────────────────────────────┤     │
│  │  ViewModel（ObservableObject）                   │     │
│  ├─────────────────────────────────────────────────┤     │
│  │  Sensor / Player サービス                        │     │
│  │  - HeadphoneMotionService (CMHeadphoneMotion)    │     │
│  │  - DeviceMotionService (Core Motion)             │     │
│  │  - HeartRateService (HealthKit)                  │     │
│  │  - PlayerService (MusicKit)                      │     │
│  │  - ReactionClassifier (Core ML)                  │     │
│  └──────────────────┬──────────────────────────────┘     │
└─────────────────────┼────────────────────────────────────┘
                      │ HTTPS / SSE
┌─────────────────────▼────────────────────────────────────┐
│  バックエンド（backend/ · LLM プロキシ）                  │
│  - POST /sessions        セッション保存・解析結果保存       │
│  - POST /sessions/:id/chat   Claude API 中継（SSE）        │
│  - POST /sessions/:id/how-card   Howカード生成             │
│  - GET  /how-cards       Howタグ検索                       │
│            │                          │                    │
│  ┌─────────▼────────┐      ┌──────────▼───────────┐      │
│  │ Claude API       │      │ Firestore/CloudKit   │      │
│  └──────────────────┘      └──────────────────────┘      │
└──────────────────────────────────────────────────────────┘

  ai-recognition/（TF 学習）──coremltools──▶ Othello に .mlmodel 組み込み
```

### レイヤー責務（iOS アプリ）

#### View（SwiftUI）
- **責務**: 画面表示・ユーザー操作の受付
- **禁止**: センサー制御・ネットワーク・推論ロジックの直書き（ViewModel/Service 経由）

#### ViewModel（ObservableObject）
- **責務**: 画面状態の保持、Service の呼び出し、`@Published` での UI 更新
- **禁止**: API キーの保持、View への依存

#### Service レイヤー
- **HeadphoneMotionService / DeviceMotionService / HeartRateService**: センサー取得・時刻同期
- **PlayerService**: 再生・再生位置供給
- **ReactionClassifier / ReactionScoringService**: Core ML 推論候補と特徴量から6軸スコアを算出（学習データ収集は3状態から開始）
- **APIClient**: backend との HTTP/SSE 通信

#### バックエンド
- **責務**: Claude API キーの秘匿、LLM 中継、データ永続化
- **禁止**: クライアントに API キーを返す

---

## ディレクトリ構成（実態）

```
team-10/
├── Othello/                    # iOS ネイティブアプリ（Xcode / SwiftUI）
│   ├── Othello.xcodeproj
│   └── Othello/
│       ├── OthelloApp.swift    # @main エントリーポイント
│       ├── ContentView.swift
│       └── Assets.xcassets/
├── backend/                    # バックエンド（LLM プロキシ・データ API）
├── ai-recognition/             # AI モデル（TensorFlow 学習 → Core ML 変換）
├── frontend/                   # フロントエンド置き場（LP / 管理画面用・MVP未使用）
├── docs/                       # ドキュメント
├── .claude/                    # Claude Code 設定
└── .mcp.json
```

> 注: アプリのプロダクト名は HowTune、Xcode プロジェクト名・チーム名は Othello。

---

## データ永続化

データモデルの詳細（コレクション設計・スキーマ・反応区間構造）は **[`docs/data-model.md`](./data-model.md)** を参照。

---

## パフォーマンス要件

| 操作 | 目標 |
|------|------|
| センサー取得（本体/AirPods）| メインスレッドを阻害しない |
| Core ML 推論（1窓） | 端末上で即時（数十ms） |
| 反応検出 → 問いかけ提示 | 体感的に短い遅延 |
| Howカード生成（LLM 含む） | 10秒以内 |
| Howカード一覧（GET）| 2秒以内 |

---

## セキュリティアーキテクチャ

### データ保護
- **Claude API キー**: backend のみで保持（クライアント露出禁止）
- **認証トークン**: iOS Keychain に保持（localStorage 相当を使わない）
- **心拍データ**: HealthKit の機微情報。最小権限・明示同意・端末内処理優先
- **センサーデータ**: ユーザー ID に紐付け、他ユーザーからは参照不可

### 入力検証
- backend の全エンドポイントでスキーマ検証
- LLM へのプロンプトインジェクション対策：ユーザー入力を system プロンプトから分離

---

## スケーラビリティ設計

### 想定規模（ハッカソン期間）
- 同時ユーザー: 最大 20 名
- 1日のセッション数: 50〜100 件

### 機能拡張性
- 新しい聴取状態（Howカテゴリ）の追加: スコア型と Core ML モデルの出力次元を更新
- LLM モデル切り替え: backend のプロキシ設定で差し替え
- 新画面: SwiftUI View + ViewModel を追加

---

## テスト戦略

### ユニットテスト（XCTest）
- **対象**: 特徴量抽出、`ReactionClassifier` の入出力、APIClient のデコード
- **モック**: HealthKit / CMHeadphoneMotionManager はプロトコル抽象化してモック

### 統合テスト
- **対象**: センサー取得 → 特徴量 → Core ML 推論 の一連
- backend: LLM をモックして対話フローを検証

### E2Eテスト（手動）
- 実機（iPhone + AirPods）: 接続 → 再生 → モーション/心拍取得 → AI 対話 → Howカード

---

## 技術的制約

### センサー制約
- **CMHeadphoneMotionManager**: 対応 AirPods（Pro / 3rd 以降 / Max 等）必須。非対応機種では本体モーションにフォールバック
- **HealthKit 心拍**: 対応機種・ヘルス権限が必要。粒度が粗い場合はトレンド扱い（断定しない）
- **MusicKit**: Apple Music サブスクが必要な場合がある（DECISION-01）

### コスト制約
- Claude API: ハッカソン期間は Sonnet を使用
- バックエンドは最小構成

### パフォーマンス制約
- Core ML 推論は端末上。モデルサイズは端末ロードに収まる範囲
- LLM ストリーミング（SSE）で TTFB を短く保つ

---

## 主要依存（iOS）

| フレームワーク | 用途 |
|--------------|------|
| SwiftUI | UI |
| Combine / async-await | 非同期・状態管理 |
| CoreMotion | 本体・AirPods モーション |
| HealthKit | 心拍 |
| MusicKit | 再生・再生位置 |
| CoreML | 推論 |
