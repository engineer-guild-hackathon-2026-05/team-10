# 開発ガイドライン (Development Guidelines)

> 対象: **iOS ネイティブ（Swift / SwiftUI）**。コードは `Othello/`、バックエンドは `backend/`、学習は `ai-recognition/`。

## コーディング規約（Swift）

### 命名規則

```swift
// ✅ 良い例
let motionFrames = recordHeadphoneMotion()
func extractFeatures(_ frames: [MotionFrame], windowSec: Double) -> [FeatureVector] { }
var isRecording = false
var hasReaction: Bool { !reactions.isEmpty }

// ❌ 悪い例
let data = record()
func calc(_ a: [Any]) -> Any { }
```

**原則**:
- 型（struct/class/enum/protocol）: PascalCase（`HowCard`, `HeartRateService`）
- 変数・関数: lowerCamelCase、関数は動詞始まり（`extract`, `classify`, `start`）
- 定数: lowerCamelCase（Swift 慣習。`static let maxSessionDurationSec = 600`）
- Bool: `is` / `has` / `should` で始める
- View: `〜View`、ViewModel: `〜ViewModel`、Service: `〜Service`

### コードフォーマット
- インデント: 4スペース（Swift 標準、SwiftFormat で自動整形）
- SwiftLint で静的解析
- 1行は概ね 120 文字以内

### コメント規約
**WHY が自明でない場合のみ書く**。コードを見れば分かることは書かない。

```swift
// ✅ 良い例: 非自明な制約を説明
// CMHeadphoneMotionManager は対応 AirPods 接続時のみ deviceMotion を返す
guard motionManager.isDeviceMotionAvailable else { fallbackToDeviceMotion(); return }

// ❌ 悪い例: コードを読めば分かる
// モーションを開始する
motionManager.startDeviceMotionUpdates()
```

### 型安全・Optional
```swift
// ✅ Optional は guard / if let で安全に展開
guard let session = currentSession else { return }

// ✅ 強制アンラップ(!)は避ける（テストコード除く）
// ❌ let x = optionalValue!
```

### 並行処理
- async/await を基本とする。センサーコールバックは `@MainActor` で UI 更新
- 重い特徴量抽出・推論は background で実行し、結果のみメインに戻す

### エラーハンドリング
```swift
enum HowTuneError: Error {
    case headphoneNotConnected
    case healthAuthorizationDenied
    case llmUnavailable
}

// 予期されるエラーは型で表現し、UI でフォールバックを用意する
do {
    try await heartRateService.requestAuthorization()
} catch {
    // 心拍を無効化してモーションのみで継続（P4: センサーを前提にしない）
    enableMotionOnlyMode()
}
```

**原則**:
- センサー/LLM の障害は必ずフォールバック（手動ラベル・本体モーション・デフォルト質問）
- エラーを握りつぶさない

### Claude API（backend 経由）
- **API キーは iOS アプリに置かない**。`backend/` のプロキシ経由で呼ぶ
- LLM の system プロンプトにユーザー入力を混入しない（プロンプトインジェクション対策）
- model は `claude-sonnet-4-6`、対話はストリーミング（SSE）

### プライバシー
- 心拍は HealthKit の機微情報。最小権限・明示同意・端末内処理優先
- 認証トークンは Keychain に保持（UserDefaults に生トークンを置かない）

---

## Git 運用ルール

### ブランチ戦略

```
main
  └─ feat/headphone-motion      ← 機能開発
  └─ feat/heart-rate
  └─ feat/how-chat
  └─ fix/airpods-disconnect     ← バグ修正
  └─ docs/update-spec           ← ドキュメント
```

**ブランチ名**: `feat/xxx` / `fix/xxx` / `docs/xxx` / `refactor/xxx`
**禁止**: `main` への直接 push（PR 経由）

### コミットメッセージ規約

```
<type>(<scope>): <subject>

Co-Authored-By: Claude <noreply@anthropic.com>
```

| Type | 用途 |
|------|------|
| `feat` | 新機能 |
| `fix` | バグ修正 |
| `docs` | ドキュメント |
| `refactor` | リファクタリング |
| `test` | テスト |
| `chore` | ビルド・設定 |

**例**:
```
feat(motion): AirPods 頭部モーションの記録を実装

- HeadphoneMotionService を追加
- CMHeadphoneMotionManager で姿勢・加速度を取得
- 未接続時は DeviceMotionService へフォールバック

Co-Authored-By: Claude <noreply@anthropic.com>
```

### PR プロセス

**作成前チェック**:
- [ ] Xcode でビルドが通る
- [ ] SwiftLint エラーなし
- [ ] XCTest 通過

**PR テンプレート**:
```markdown
## 概要
[変更内容の1行サマリー]

## 変更内容
- [変更点]

## テスト
- [ ] ユニットテスト追加
- [ ] 実機（iPhone + AirPods）で動作確認

## AI 活用ログ
- [ ] AI_USAGE_LOG.md に追記済み
```

**マージ方針**: Squash merge

---

## テスト戦略

| 種別 | 対象 | ツール |
|------|------|--------|
| ユニット | 特徴量抽出、ReactionClassifier、APIClient のデコード | XCTest |
| 統合 | センサー → 特徴量 → Core ML 推論 | XCTest |
| backend | LLM をモックした対話・カード生成 | （backend のテスト framework） |
| E2E（手動） | 実機 AirPods 接続 → 再生 → 取得 → 対話 → Howカード | 手動 |

### ユニットテスト例

```swift
import XCTest
@testable import Othello

final class ReactionClassifierTests: XCTestCase {
    func test_extractFeatures_steadyRhythm_highRhythmRegularity() {
        let frames = makeRhythmicFrames(durationSec: 2)
        let features = ReactionClassifier().extractFeatures(frames, [], windowSec: 2)
        XCTAssertGreaterThan(features[0].rhythmRegularity, 0.7)
    }
}
```

### モック方針
- HealthKit / CMHeadphoneMotionManager は **protocol で抽象化**してモック注入
- backend / Claude API はスタブレスポンス

---

## コードレビュー基準

**機能性**:
- [ ] frontend-spec の受け入れ条件（AC）を満たすか
- [ ] AirPods 未接続・権限拒否・心拍非対応のフォールバックがあるか
- [ ] LLM 障害時のフォールバックがあるか

**可読性**:
- [ ] 命名が具体的か（`data` より `motionFrames`）
- [ ] コメントは WHY のみか

**セキュリティ・プライバシー**:
- [ ] Claude API キーをアプリに埋め込んでいないか（backend 経由か）
- [ ] 心拍データを最小権限・端末内処理で扱っているか
- [ ] トークンを Keychain に保持しているか

**レビューコメント例**:
```
[必須] AirPods 切断時に deviceMotion が nil になりクラッシュします。
DeviceMotionService へのフォールバックを入れてください（P4 準拠）。

[提案] この特徴量計算は ReactionClassifier に寄せると View が薄くなります。
```

---

## 開発環境セットアップ

### 必要なツール

| ツール | 用途 |
|--------|------|
| Xcode 15+ | iOS ビルド・実機デバッグ |
| iPhone + 対応 AirPods | センサー実機テスト（必須） |
| SwiftLint / SwiftFormat | 静的解析・整形 |
| （backend）Node.js or Python | LLM プロキシ |
| （ai-recognition）Python + TensorFlow | モデル学習 |

### セットアップ手順

```bash
# 1. クローン
git clone https://github.com/engineer-guild-hackathon-2026-05/team-10.git
cd team-10

# 2. iOS アプリを開く
open Othello/Othello.xcodeproj
# Xcode で署名チームを設定し、実機を選んで Run

# 3. backend（例）
cd backend && (依存インストール・起動)

# 4. ai-recognition（学習）
cd ai-recognition && python -m venv .venv && source .venv/bin/activate && pip install -r requirements.txt
```

### 実機テストの要点
- **Info.plist に権限文言が必須**: `NSMotionUsageDescription` / `NSHealthShareUsageDescription`
- AirPods の頭部モーションは対応機種でのみ取得可。シミュレータでは取得不可なので実機必須
- 心拍は対応 AirPods + ヘルス権限が必要

### AI 活用ログの記録
**Claude を使った作業は必ず `AI_USAGE_LOG.md` に記録**。最低 1 日 3 件以上。

```markdown
| 日時 | 担当 | 利用ツール | 用途 | 効果 |
|------|------|-----------|------|------|
| 5/24 14:00 | @username | Claude Code | HeadphoneMotionService 設計 | CMHeadphoneMotion の使い方を整理 |
```
