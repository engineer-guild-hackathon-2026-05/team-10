# リポジトリ構造定義書 (Repository Structure Document)

## プロジェクト構造

pnpm workspace + Turborepo によるモノレポ構成。

```
team-10/
├── apps/
│   ├── web/                        # Next.js フロントエンド
│   └── api/                        # Express バックエンド（Cloud Run）
├── packages/
│   └── shared/                     # 共通型定義・ユーティリティ
├── docs/                           # プロジェクトドキュメント
├── .claude/                        # Claude Code 設定
├── .devcontainer/                  # Dev Container 設定
├── .steering/                      # 作業単位のステアリングファイル
├── .mcp.json                       # MCP サーバー設定
├── .gitignore
├── package.json                    # pnpm workspace ルート
├── turbo.json                      # Turborepo 設定
├── CLAUDE.md                       # Claude Code プロジェクトルール
└── AI_USAGE_LOG.md                 # AI 活用ログ
```

---

## ディレクトリ詳細

### apps/web/ (Next.js フロントエンド)

```
apps/web/
├── app/                            # App Router
│   ├── (auth)/                     # 認証フロー（ログイン）
│   │   └── login/page.tsx
│   ├── (main)/                     # メインレイアウト
│   │   ├── layout.tsx
│   │   ├── page.tsx                # ホーム（Howカード一覧）
│   │   ├── listen/page.tsx         # リスニング画面
│   │   ├── sessions/[id]/page.tsx  # セッション結果・AI対話
│   │   ├── how-cards/[id]/page.tsx # Howカード詳細
│   │   └── profile/page.tsx        # マイページ
│   ├── api/                        # Route Handlers（軽量なもののみ）
│   │   └── auth/[...nextauth]/route.ts
│   ├── globals.css
│   └── layout.tsx                  # ルートレイアウト
├── components/
│   ├── sensor/                     # センサー関連（Client Component）
│   │   ├── SensorRecorder.tsx      # DeviceMotionEvent ラッパー
│   │   └── SensorPermissionGate.tsx
│   ├── timeline/                   # 反応タイムライン
│   │   ├── ReactionTimeline.tsx
│   │   └── ReactionBar.tsx
│   ├── chat/                       # AI 対話 UI
│   │   ├── HowChatDialog.tsx
│   │   └── ChatBubble.tsx
│   ├── how-card/                   # Howカード
│   │   ├── HowCard.tsx
│   │   ├── HowCardGrid.tsx
│   │   └── HowCardShareButton.tsx
│   └── ui/                         # 汎用 UI（Button, Input 等）
├── lib/
│   ├── api-client.ts               # バックエンド API 呼び出し
│   ├── firebase.ts                 # Firebase クライアント初期化
│   └── sensor-utils.ts             # センサーデータ前処理
├── public/                         # 静的ファイル
├── package.json
├── next.config.ts
├── tsconfig.json
└── tailwind.config.ts
```

**命名規則**:
- コンポーネント: PascalCase（`HowCard.tsx`）
- ページ: `page.tsx`（App Router 規約）
- ユーティリティ: camelCase（`sensor-utils.ts`）

**依存関係**:
- 依存可能: `packages/shared`
- 禁止: `apps/api` への直接インポート（HTTP 経由のみ）

---

### apps/api/ (Express バックエンド)

```
apps/api/
├── src/
│   ├── routes/                     # エンドポイント定義
│   │   ├── sessions.ts             # POST /sessions, GET /sessions/:id
│   │   ├── chat.ts                 # POST /sessions/:id/chat
│   │   ├── how-cards.ts            # POST /sessions/:id/how-card, GET /how-cards
│   │   └── index.ts                # ルーター集約
│   ├── services/                   # ビジネスロジック
│   │   ├── MotionAnalyzer.ts       # TF.js 推論
│   │   └── HowDialogOrchestrator.ts # Claude API 対話管理
│   ├── repositories/               # Firestore アクセス
│   │   ├── SessionRepository.ts
│   │   └── HowCardRepository.ts
│   ├── models/                     # TF.js モデルファイル
│   │   └── motion-classifier/      # SavedModel 形式
│   ├── middleware/                  # Express ミドルウェア
│   │   ├── auth.ts                 # Firebase Auth 検証
│   │   └── validate.ts             # Zod バリデーション
│   ├── lib/
│   │   ├── firebase-admin.ts       # Firebase Admin 初期化
│   │   ├── anthropic.ts            # Anthropic SDK 初期化
│   │   └── tfjs.ts                 # TF.js モデルロード
│   └── index.ts                    # エントリーポイント
├── tests/
│   ├── unit/
│   │   ├── MotionAnalyzer.test.ts
│   │   └── HowDialogOrchestrator.test.ts
│   └── integration/
│       ├── sessions.test.ts
│       └── how-cards.test.ts
├── Dockerfile
├── package.json
└── tsconfig.json
```

**命名規則**:
- サービス・Repository: PascalCase（`MotionAnalyzer.ts`）
- ルートファイル: kebab-case（`how-cards.ts`）
- ミドルウェア: camelCase（`auth.ts`）

**依存関係**:
- 依存可能: `packages/shared`
- 禁止: `apps/web` へのインポート

---

### packages/shared/ (共通型定義)

```
packages/shared/
├── src/
│   ├── types/
│   │   ├── sensor.ts               # SensorFrame, ListeningStateScores
│   │   ├── session.ts              # ListeningSession, ReactionSpan
│   │   ├── how-card.ts             # HowCard
│   │   └── user.ts                 # User
│   ├── schemas/                    # Zod スキーマ（API 入出力共有）
│   │   ├── session-schema.ts
│   │   └── how-card-schema.ts
│   └── index.ts                    # re-export
├── package.json
└── tsconfig.json
```

**方針**: 型定義と Zod スキーマのみ。ロジックは含めない。

---

### docs/ (ドキュメント)

| ファイル | 内容 |
|---------|------|
| `product-requirements.md` | PRD |
| `functional-design.md` | 機能設計書 |
| `architecture.md` | アーキテクチャ設計書 |
| `repository-structure.md` | 本ドキュメント |
| `development-guidelines.md` | 開発ガイドライン |
| `glossary.md` | 用語集 |
| `Thema.md` | ハッカソンテーマ・スケジュール |

---

### .steering/ (作業ステアリング)

```
.steering/
└── 20260524-initial-setup/         # 日付-タスク名
    ├── requirements.md
    ├── design.md
    └── tasklist.md
```

**命名規則**: `YYYYMMDD-task-name`（kebab-case）

---

## ファイル配置規則

### ソースファイル

| ファイル種別 | 配置先 | 命名規則 | 例 |
|------------|--------|---------|-----|
| Next.js ページ | `apps/web/app/` | `page.tsx` | `listen/page.tsx` |
| React コンポーネント | `apps/web/components/[機能]/` | PascalCase | `HowCard.tsx` |
| API ルート | `apps/api/src/routes/` | kebab-case | `how-cards.ts` |
| サービスクラス | `apps/api/src/services/` | PascalCase | `MotionAnalyzer.ts` |
| Repository クラス | `apps/api/src/repositories/` | PascalCase | `HowCardRepository.ts` |
| 共通型定義 | `packages/shared/src/types/` | camelCase | `how-card.ts` |

### テストファイル

| テスト種別 | 配置先 | 命名規則 | 例 |
|-----------|--------|---------|-----|
| ユニットテスト | `apps/api/tests/unit/` | `[対象].test.ts` | `MotionAnalyzer.test.ts` |
| 統合テスト | `apps/api/tests/integration/` | `[機能].test.ts` | `sessions.test.ts` |
| コンポーネントテスト | `apps/web/__tests__/` | `[対象].test.tsx` | `HowCard.test.tsx` |

### 設定ファイル

| ファイル種別 | 配置先 | 備考 |
|------------|--------|------|
| 環境変数 | `.env`（各 apps/ 直下） | `.gitignore` 対象 |
| TypeScript 設定 | `tsconfig.json`（各パッケージ）| ルートから継承 |
| ESLint 設定 | ルート `eslint.config.js` | モノレポ共通 |
| Prettier 設定 | ルート `.prettierrc` | モノレポ共通 |

---

## 命名規則まとめ

| 対象 | 規則 | 例 |
|------|------|-----|
| コンポーネント | PascalCase | `HowChatDialog.tsx` |
| サービス / Repository | PascalCase | `MotionAnalyzer.ts` |
| API ルートファイル | kebab-case | `how-cards.ts` |
| 型定義ファイル | camelCase | `sensor.ts` |
| ディレクトリ | kebab-case | `how-card/`, `motion-classifier/` |
| テストファイル | `[対象].test.ts` | `MotionAnalyzer.test.ts` |
| ステアリング | `YYYYMMDD-task-name` | `20260524-add-chat-ui` |

---

## 依存関係のルール

```
apps/web  ──→  packages/shared  ←──  apps/api
   │                                     │
   └── HTTP API のみ ─────────────────→ ┘
```

**禁止される依存**:
- `apps/web` → `apps/api`（直接インポート禁止、HTTP 経由のみ）
- `apps/api` → `apps/web`
- `packages/shared` → `apps/*`

---

## .gitignore 追加設定

```gitignore
# pnpm / Turborepo
.turbo/
pnpm-lock.yaml    # lock ファイルはコミット対象にする（削除しないこと）

# TF.js モデル（大容量 → Git LFS 推奨、またはCloud Storageで管理）
apps/api/src/models/*/

# ビルド成果物
apps/web/.next/
apps/api/dist/

# 環境変数
.env
.env.local
.env.*.local
```

---

## スケーリング戦略

### 機能追加時の配置方針

1. **新しい画面**: `apps/web/app/(main)/[feature]/page.tsx`
2. **新しい API エンドポイント**: `apps/api/src/routes/[feature].ts` + サービス追加
3. **新しい共通型**: `packages/shared/src/types/[entity].ts`
4. **新しい Howタグ種別**: `ListeningStateScores` に追加 → `classifyWindow()` 更新

### ファイルサイズ管理

- 1ファイル 300 行以下を目安
- `HowDialogOrchestrator.ts` が肥大化した場合 → `prompt-builder.ts` と `dialog-state.ts` に分割
