# リポジトリ構造定義書 (Repository Structure Document)

## プロジェクト構造（実態）

iOS ネイティブアプリ（`Othello/`）を中心に、バックエンド・AIモデルを並置する構成。

```
team-10/
├── Othello/                    # iOS ネイティブアプリ（Xcode / SwiftUI）
│   ├── Othello.xcodeproj
│   └── Othello/
│       ├── OthelloApp.swift    # @main
│       ├── ContentView.swift
│       └── Assets.xcassets/
├── backend/                    # バックエンド（LLM プロキシ・データ API）
├── ai-recognition/             # AI モデル（TensorFlow 学習 → Core ML 変換）
├── frontend/                   # フロントエンド置き場（LP/管理画面・MVP未使用）
├── docs/                       # プロジェクトドキュメント
├── .claude/                    # Claude Code 設定
├── .devcontainer/              # Dev Container 設定
├── .steering/                  # 作業単位のステアリングファイル
├── .mcp.json                   # MCP サーバー設定
├── .gitignore
├── CLAUDE.md                   # Claude Code プロジェクトルール
└── AI_USAGE_LOG.md             # AI 活用ログ
```

> プロダクト名は HowTune、Xcode プロジェクト名・チーム名は Othello。

---

## ディレクトリ詳細

### Othello/ (iOS アプリ)

推奨する内部構成（雛形から育てる想定）:

```
Othello/Othello/
├── OthelloApp.swift            # @main エントリーポイント
├── Views/                      # SwiftUI View
│   ├── Onboarding/             # 権限取得・AirPods 接続
│   ├── Listening/              # 再生・センサー取得・タイムライン
│   ├── Chat/                   # AI 対話
│   ├── HowCard/                # Howカード生成・編集・表示
│   └── Community/              # 同じHowの人・曲
├── ViewModels/                 # ObservableObject
├── Services/                   # センサー・再生・推論・通信
│   ├── HeadphoneMotionService.swift  # CMHeadphoneMotionManager
│   ├── DeviceMotionService.swift     # Core Motion
│   ├── HeartRateService.swift        # HealthKit
│   ├── PlayerService.swift           # MusicKit / AVFoundation
│   ├── ReactionClassifier.swift      # Core ML 推論
│   └── APIClient.swift               # backend 通信
├── Models/                     # struct（SensorFrame, HowCard 等）
├── ML/                         # .mlmodel（ai-recognition から変換）
├── Resources/
└── Assets.xcassets/
```

**命名規則（Swift）**:
- 型（struct/class/enum/protocol）: PascalCase（`HowCard`, `HeartRateService`）
- 変数・関数: lowerCamelCase（`sensorFrames`, `extractFeatures()`）
- View: `〜View`、ViewModel: `〜ViewModel`、Service: `〜Service`

---

### backend/ (バックエンド)

LLM プロキシとデータ API。言語は Node.js または Python（DECISION-04 で確定）。

```
backend/
├── src/
│   ├── routes/                 # /sessions, /chat, /how-cards
│   ├── services/               # Claude API 中継・Howカード生成
│   └── repositories/           # Firestore/CloudKit アクセス
└── README.md
```

**責務**: Claude API キーの秘匿、LLM 中継（SSE）、データ永続化。

---

### ai-recognition/ (AI モデル)

モーション+心拍特徴量から3状態スコア（groove / chill / neutral）を学習するコード。

```
ai-recognition/
├── data/                       # 教師データ（Create ML GUI用CSV 等）
├── train/                      # 学習スクリプト（Python / TensorFlow）
├── export/                     # coremltools で .mlmodel へ変換
└── README.md
```

**フロー**: TF で学習 → `coremltools` で Core ML 形式に変換 → `Othello/Othello/ML/` に組み込み。

---

### frontend/ (フロントエンド置き場)

MVP では未使用。将来の LP / 管理画面用プレースホルダ。

---

### docs/ (ドキュメント)

| ファイル | 内容 |
|---------|------|
| `frontend-spec.md` | **仕様の source of truth**（Notion ミラー、SDD） |
| `product-requirements.md` | PRD |
| `functional-design.md` | 機能設計書 |
| `architecture.md` | アーキテクチャ設計書 |
| `repository-structure.md` | 本ドキュメント |
| `development-guidelines.md` | 開発ガイドライン |
| `glossary.md` | 用語集 |
| `Thema.md` | ハッカソンテーマ・スケジュール |
| `share/build.mjs` | docs を共有用 HTML に変換するスクリプト |
| `slides/howtune.md` | Marp プレゼンスライドソース |

---

### .steering/ (作業ステアリング)

```
.steering/
└── YYYYMMDD-task-name/
    ├── requirements.md
    ├── design.md
    └── tasklist.md
```

---

## ファイル配置規則

| ファイル種別 | 配置先 | 命名規則 | 例 |
|------------|--------|---------|-----|
| SwiftUI View | `Othello/Othello/Views/[機能]/` | `〜View` PascalCase | `ListeningView.swift` |
| ViewModel | `Othello/Othello/ViewModels/` | `〜ViewModel` | `ListeningViewModel.swift` |
| Service | `Othello/Othello/Services/` | `〜Service` | `HeartRateService.swift` |
| モデル（struct） | `Othello/Othello/Models/` | PascalCase | `HowCard.swift` |
| Core ML モデル | `Othello/Othello/ML/` | PascalCase | `ReactionClassifier.mlmodel` |
| backend ルート | `backend/src/routes/` | kebab-case | `how-cards.ts` |
| 学習スクリプト | `ai-recognition/train/` | snake_case | `train_classifier.py` |

---

## 命名規則まとめ

| 対象 | 規則 | 例 |
|------|------|-----|
| Swift 型 | PascalCase | `HowCardView`, `HeartRateService` |
| Swift 変数・関数 | lowerCamelCase | `extractFeatures()` |
| backend ファイル | kebab-case | `how-cards.ts` |
| Python ファイル | snake_case | `train_classifier.py` |
| ディレクトリ | 機能名（PascalCase: Swift / kebab-case: backend） | `Views/`, `routes/` |
| ステアリング | `YYYYMMDD-task-name` | `20260524-add-chat-view` |

---

## 依存関係のルール

```
Othello (iOS)  ──HTTP/SSE──▶  backend  ──▶  Claude API / Firestore
                                  ▲
ai-recognition (TF) ──.mlmodel──┘（学習成果物を Othello に組み込み）
```

**禁止**:
- iOS アプリから Claude API キーを直接保持・呼び出し（必ず backend 経由）
- View からセンサー/ネットワークを直接制御（Service 経由）

---

## .gitignore 方針（追加すべき項目）

```gitignore
# Xcode
Othello/**/xcuserdata/
Othello/**/*.xcuserstate
Othello/build/
DerivedData/

# Python (ai-recognition)
ai-recognition/.venv/
ai-recognition/__pycache__/

# 環境変数
.env
.env.local
```

---

## スケーリング戦略

### 機能追加時の配置
1. **新しい画面**: `Othello/Othello/Views/[機能]/〜View.swift` + ViewModel
2. **新しいセンサー/連携**: `Othello/Othello/Services/〜Service.swift`
3. **新しい API**: `backend/src/routes/[機能]`
4. **モデル更新**: `ai-recognition/train/` で学習 → `export/` で変換 → `Othello/Othello/ML/`

### ファイルサイズ管理
- Swift 1ファイル 300〜400 行を目安。肥大化した View は子 View に分割
