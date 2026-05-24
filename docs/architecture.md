# 技術仕様書 (Architecture Design Document)

## テクノロジースタック

### 言語・ランタイム

| 技術 | バージョン |
|------|-----------|
| Node.js | v20 LTS |
| TypeScript | 5.x |
| pnpm | 9.x |

### フレームワーク・ライブラリ

| 技術 | バージョン | 用途 | 選定理由 |
|------|-----------|------|----------|
| Next.js | 15 (App Router) | フロントエンド全般 | SSR/CSR 柔軟切替、Server Actions で API 簡素化 |
| Tailwind CSS | 4.x | スタイリング | 高速プロトタイピング、ユーティリティファースト |
| Express | 4.x | バックエンド API | シンプル、Cloud Run と相性良好 |
| TensorFlow.js | 4.x | ML 推論 | ブラウザ・Node.js 両対応、追加インフラ不要 |
| @anthropic-ai/sdk | latest | Claude API 連携 | 公式 SDK、ストリーミング対応 |
| Firebase Admin SDK | 12.x | Firestore / Auth | GCP エコシステムで Cloud Run と親和性高 |
| Zod | 3.x | スキーマバリデーション | TypeScript 型推論と統合 |

### インフラ・クラウド

| 技術 | 用途 | 選定理由 |
|------|------|----------|
| Google Cloud Run | バックエンドホスティング | コールドスタート許容、従量課金、スケールアウト容易 |
| Firebase Hosting | フロントエンドホスティング | CDN、Next.js SSR と Cloud Run の組み合わせ |
| Firestore | メインデータベース | リアルタイム同期、スキーマレス、Cloud Run と同リージョン |
| Cloud Storage | センサーデータ JSONL | 安価な大容量ストレージ |
| Firebase Auth | ユーザー認証 | Google OAuth をワンステップで実装 |

### 開発ツール

| 技術 | 用途 |
|------|------|
| ESLint + Prettier | コード品質・フォーマット統一 |
| Vitest | ユニット・統合テスト |
| Docker | ローカルエミュレーション |
| GitHub Actions | CI（型チェック + テスト） |

---

## アーキテクチャパターン

### 全体構成

```
┌──────────────────────────────────────────────────────────┐
│  クライアント（Next.js on Firebase Hosting + CDN）        │
│  ┌─────────────────────────────────────────────────┐     │
│  │  UIレイヤー                                      │     │
│  │  - SensorRecorder（DeviceMotionEvent）           │     │
│  │  - ReactionVisualizer（タイムライン）             │     │
│  │  - HowChatDialog（AI対話UI）                     │     │
│  │  - HowCardView（カード表示・シェア）              │     │
│  └──────────────────┬──────────────────────────────┘     │
└─────────────────────┼────────────────────────────────────┘
                      │ HTTPS / SSE
┌─────────────────────▼────────────────────────────────────┐
│  バックエンド（Node.js / Express on Cloud Run）           │
│  ┌────────────────────────────────────────────────┐      │
│  │  APIレイヤー                                    │      │
│  │  POST /sessions                                 │      │
│  │  POST /sessions/:id/chat                        │      │
│  │  POST /sessions/:id/how-card                    │      │
│  │  GET  /how-cards                                │      │
│  └──────────┬──────────────────┬──────────────────┘      │
│             │                  │                           │
│  ┌──────────▼──────┐  ┌────────▼────────────────┐       │
│  │ MotionAnalyzer  │  │ HowDialogOrchestrator   │       │
│  │ (TF.js 推論)    │  │ (Claude API 対話)        │       │
│  └──────────┬──────┘  └────────┬────────────────┘       │
│             │                  │                           │
│  ┌──────────▼──────────────────▼──────────────────┐      │
│  │  データレイヤー（Firestore / Cloud Storage）    │      │
│  └────────────────────────────────────────────────┘      │
└──────────────────────────────────────────────────────────┘
```

### レイヤー責務

#### UIレイヤー（Next.js）
- **責務**: センサー取得、ユーザー入力、結果表示、API 呼び出し
- **禁止**: ビジネスロジックの実装（Howタグ生成など）
- **センサー取得は Client Component のみ**（`"use client"`）

#### APIレイヤー（Express）
- **責務**: リクエストのバリデーション（Zod）、サービス呼び出し、レスポンス整形
- **禁止**: ML推論・LLM呼び出しのロジックを直接書く

#### サービスレイヤー
- **MotionAnalyzer**: 特徴量抽出 + TF.js 推論
- **HowDialogOrchestrator**: Claude API プロンプト管理 + 対話状態管理
- **責務**: ビジネスロジックの実装
- **禁止**: Firestore への直接アクセス（Repository 経由）

#### データレイヤー（Repository パターン）
- **SessionRepository**: セッション CRUD
- **HowCardRepository**: Howカード CRUD + タグ検索
- **責務**: Firestore クエリの実装のみ

---

## ディレクトリ構成

```
team-10/
├── apps/
│   ├── web/                  # Next.js フロントエンド
│   │   ├── app/              # App Router ページ
│   │   ├── components/       # UI コンポーネント
│   │   │   ├── sensor/       # SensorRecorder 等
│   │   │   ├── timeline/     # ReactionVisualizer
│   │   │   ├── chat/         # HowChatDialog
│   │   │   └── how-card/     # HowCardView
│   │   └── lib/              # フロント共通ロジック
│   └── api/                  # Express バックエンド
│       ├── routes/           # エンドポイント定義
│       ├── services/         # MotionAnalyzer, HowDialogOrchestrator
│       ├── repositories/     # Firestore アクセス
│       └── models/           # TF.js モデルファイル
├── packages/
│   └── shared/               # 共通型定義 (SensorFrame, HowCard 等)
├── .mcp.json
├── package.json              # pnpm workspace ルート
└── turbo.json                # Turborepo 設定
```

---

## データ永続化戦略

### ストレージ方式

| データ種別 | ストレージ | フォーマット | 理由 |
|-----------|----------|-------------|------|
| ユーザー情報 | Firestore | ドキュメント | リアルタイム同期不要だが、一貫性が必要 |
| リスニングセッション | Firestore | ドキュメント + サブコレクション | セッション単位の更新が多い |
| センサーデータ（生データ）| Cloud Storage | JSONL | 大容量・追記のみ・ML 学習用 |
| Howカード | Firestore | ドキュメント | タグ検索・一覧取得が必要 |

### バックアップ戦略
- Firestore: 自動エクスポート（Cloud Scheduler で毎日 1 回 Cloud Storage へ）
- センサーデータ: Cloud Storage のバージョニング有効化

---

## パフォーマンス要件

### レスポンスタイム

| 操作 | 目標時間 | 測定環境 |
|------|---------|---------|
| センサーフレーム記録 | 100ms 間隔で欠損なし | iPhone 14 Safari |
| POST /sessions（解析含む） | 3秒以内 | Cloud Run tokyo リージョン |
| POST /chat（ストリーム開始） | 1秒以内（TTFB） | 同上 |
| GET /how-cards | 2秒以内 | 同上 |
| Howカード生成完了 | 10秒以内 | LLM 応答含む |

### リソース使用量

| リソース | 上限 | 理由 |
|---------|------|------|
| Cloud Run メモリ | 512MB | TF.js モデルロード + リクエスト処理 |
| Cloud Run CPU | 1 vCPU | 同時リクエスト 10 程度で十分 |
| Firestore 読み取り | 50,000 回/日 | ハッカソン期間の想定 |

---

## セキュリティアーキテクチャ

### データ保護
- **Claude API キー**: Cloud Run の環境変数で管理（Secret Manager 推奨だが MVP では `.env` + Cloud Run env）
- **Firebase 設定**: クライアント公開鍵（設計上公開して良い値のみ）
- **センサーデータ**: ユーザー ID に紐付け、他ユーザーからは参照不可（Firestore セキュリティルール）

### Firestore セキュリティルール

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }
    match /sessions/{sessionId} {
      allow read, write: if request.auth.uid == resource.data.userId;
    }
    match /howCards/{cardId} {
      allow read: if request.auth != null;   // 全ユーザーが閲覧可
      allow write: if request.auth.uid == resource.data.userId;
    }
  }
}
```

### 入力検証
- 全 API エンドポイントで Zod スキーマによる検証
- センサーデータは 1 セッション最大 10 分（36,000 フレーム）に制限
- LLM へのプロンプトインジェクション対策：ユーザー入力をシステムプロンプトから分離

---

## スケーラビリティ設計

### 想定規模（ハッカソン期間）
- 同時ユーザー: 最大 20 名
- 1日のセッション数: 50〜100 件
- Cloud Run の最大インスタンス: 5（コスト抑制）

### 機能拡張性
- 新しい聴取状態（Howカテゴリ）の追加: `ListeningStateScores` の型定義変更と分類ロジック更新のみ
- LLM モデルの切り替え: `HowDialogOrchestrator` の依存注入で差し替え可能
- フロントエンド新機能: Next.js App Router でページ追加

---

## テスト戦略

### ユニットテスト（Vitest）
- **対象**: `extractFeatures()`, `classifyWindow()`, `generateQuestion()`, Repository クラス
- **カバレッジ目標**: 70%（ハッカソン期間は優先機能のみ）
- **モック**: Firestore は `@firebase/rules-unit-testing`、Claude API は `msw`

### 統合テスト
- **対象**: `POST /sessions` → TF.js 推論 → Firestore 保存 の一連フロー
- **方法**: Firebase Emulator Suite でローカル実行

### E2Eテスト（手動）
- iPhone Safari: センサー許可 → 記録 → 対話 → Howカード表示
- Android Chrome: 同フロー

---

## 技術的制約

### センサー制約
- **iOS Safari**: DeviceMotionEvent は HTTPS + ユーザージェスチャー後にのみ許可（`requestPermission()` 必須）
- **Android Chrome**: 自動で取得可能（許可プロンプトなし）
- **デスクトップブラウザ**: センサーなし → モック値でフォールバック（デモ用）

### コスト制約
- Claude API: ハッカソン期間は Sonnet を使用（Opus はコスト高）
- Cloud Run: 最小インスタンス 0（コールドスタート許容）
- Firestore: 無料枠（50,000 読み取り/日）内に収める

### パフォーマンス制約
- TF.js モデルは Cloud Run 起動時に一度ロード（コールドスタート +2〜3 秒）
- LLM ストリーミングを使用しないと UX が悪化する（必須要件）

---

## 依存関係管理

| ライブラリ | 用途 | バージョン管理方針 |
|-----------|------|-------------------|
| next | フロントエンド | `^15.0.0`（マイナー更新許容） |
| @anthropic-ai/sdk | Claude API | `latest`（常に最新） |
| @tensorflow/tfjs-node | ML 推論 | `^4.0.0`（固定） |
| firebase-admin | Firestore / Auth | `^12.0.0`（マイナー更新許容） |
| zod | バリデーション | `^3.0.0`（マイナー更新許容） |
| express | API サーバー | `^4.0.0`（固定） |
