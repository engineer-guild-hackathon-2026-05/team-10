# 開発ガイドライン (Development Guidelines)

> 対象: **iOS ネイティブ（Swift / SwiftUI）**。コードは `Othello/`、本番バックエンドは `functions/`、学習は `ai-recognition/`。

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

### ファイル構成（MVVM）

- **MVVM** を採用する。`struct` / `class` / `protocol` は**型ごとに 1 ファイル**で区切る（1ファイル1型を基本）
- **Feature-based なディレクトリ設計**にする（`Views/Listening/`・`Views/Chat/` のように機能単位でまとめる）
- 例: `HeartRateService.swift`（protocol + 実装）、`ListeningView.swift` / `ListeningViewModel.swift`

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
    case apiUnavailable
}

// 予期されるエラーは型で表現し、UI でフォールバックを用意する
do {
    try await headphoneMotionService.start()
} catch {
    // AirPods が使えない場合も手動選択で体験を継続する
    enableManualReactionMode()
}
```

**原則**:
- センサー/API の障害は必ずフォールバック（手動ラベル・デフォルト表示）
- エラーを握りつぶさない

### Functions API
- Howカードコメントは Firestore へ直接書き込まず、Firebase ID token 付きで `functions/` の API を呼ぶ
- `users/{uid}` はログイン中ユーザー自身のみ、Firestore rules の範囲内で iOS から read/write してよい
- `backend/` は deprecated な参照実装。新規 API は `functions/` に追加する
- HowChat の mock/legacy client は現行 Functions 本番 contract ではない
- LLM 連携を本番化する場合は Functions 側に endpoint を追加し、API key をクライアントへ含めない

### プライバシー
- HealthKit / 心拍連携は現行 MVP から削除済み。ヘルスデータを取得しない
- 認証トークンは Keychain に保持（UserDefaults に生トークンを置かない）

---

## Git 運用ルール

### ブランチ戦略

```
main
  └─ feat/headphone-motion      ← 機能開発
  └─ docs/sync-current-implementation
  └─ feat/how-chat
  └─ fix/airpods-disconnect     ← バグ修正
  └─ docs/update-spec           ← ドキュメント
```

**ブランチ名**: `feat/xxx` / `fix/xxx` / `docs/xxx` / `refactor/xxx`
**禁止**: `main` への直接 push（PR 経由）

### コミットメッセージ規約

```
<type>(<scope>): <subject>

Co-Authored-By: Codex <noreply@anthropic.com>
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
- 未接続時は手動リアクション選択へフォールバック

Co-Authored-By: Codex <noreply@anthropic.com>
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
| Functions | HowCard API・users API | Node test / Firebase emulator |
| E2E（手動） | 実機 AirPods 接続 → 再生 → 取得 → Howコメント投稿 | 手動 |

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
- CMHeadphoneMotionManager は **protocol で抽象化**してモック注入
- Functions API はスタブレスポンスまたは Firebase emulator

---

## コードレビュー基準

**機能性**:
- [ ] frontend-spec の受け入れ条件（AC）を満たすか
- [ ] AirPods 未接続・権限拒否時のフォールバックがあるか
- [ ] Functions API 障害時のフォールバックがあるか

**可読性**:
- [ ] 命名が具体的か（`data` より `motionFrames`）
- [ ] コメントは WHY のみか

**セキュリティ・プライバシー**:
- [ ] API キーを git に含めていないか
- [ ] HealthKit / 心拍データを取得していないか
- [ ] トークンを Keychain に保持しているか

**レビューコメント例**:
```
[必須] AirPods 切断時に deviceMotion が nil になりクラッシュします。
手動モードへのフォールバックを入れてください（P4 準拠）。

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
| Node.js 20 / Firebase CLI | Functions 開発・デプロイ |
| （ai-recognition）Python + TensorFlow | モデル学習 |

### セットアップ手順

```bash
# 1. クローン
git clone https://github.com/engineer-guild-hackathon-2026-05/team-10.git
cd team-10

# 2. iOS アプリを開く
open Othello/Othello.xcodeproj
# Xcode で署名チームを設定し、実機を選んで Run

# 3. Functions
cd functions && npm install
firebase emulators:start --only functions,firestore

# 4. ai-recognition（学習）
cd ai-recognition && python -m venv .venv && source .venv/bin/activate && pip install -r requirements.txt
```

### 実機テストの要点
- **Info.plist に権限文言が必須**: `NSMotionUsageDescription`
- AirPods の頭部モーションは対応機種でのみ取得可。シミュレータでは取得不可なので実機必須
- HealthKit / 心拍連携は現行 MVP から削除済み

### AI 活用ログの記録
**AI ツールを使った作業は必ず `AI_USAGE_LOG.md` に記録**。最低 1 日 3 件以上。

```markdown
| 日時 | 担当 | 利用ツール | 用途 | 効果 |
|------|------|-----------|------|------|
| 5/24 14:00 | @username | Codex | HeadphoneMotionService 設計 | CMHeadphoneMotion の使い方を整理 |
```
