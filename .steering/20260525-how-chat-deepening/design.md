# 設計書

## アーキテクチャ概要

MLモデル訓練は不要。`MotionReactionScoreEstimator`（ルールベース、加速度/回転の四則演算）で6軸スコアを算出し、AIのコンテキストに渡す。

```
AirPods/iPhone
   ↓ CMHeadphoneMotionManager / CMMotionManager
AirPodsMotionViewModel (HomeView が @StateObject で保持)
   ↓ .latestSample (AirPodsMotionSample)
MotionReactionScoreEstimator.score(from:)   ← ルールベース、ML不要
   ↓ ReactionScore (groove/hype/chill/immersion/hit/afterglow 各0.0〜1.0)
reactionEvent(for: TimedLyricLine)  ← ReactionEvent.score に埋め込む
   ↓
ChatAPIClient.chat(event:messages:)
   ↓ ChatPayload { ..., scores: [String:Double], dominantAxis: String }
backend POST /sessions/:id/chat
   ↓ buildContextMessage に6軸スコアを追加
Claude API (system prompt: dominant軸ごとの問いかけアングル)
   ↓ question + choices (dominant軸に関連した選択肢)
HowChatViewModel (turnCount < 2 → 2ターンで done)
```

## コンポーネント設計

### 1. HomeView — AirPodsMotionViewModel のオーナーシップ移管

**現状**: `RealtimeReactionDisplayView` が `@StateObject private var motionViewModel` を持っている

**変更後**:
- `HomeView` が `@StateObject private var motionViewModel = AirPodsMotionViewModel()` を持つ
- `RealtimeReactionDisplayView(motionViewModel: motionViewModel, ...)` として渡す（`@ObservedObject`）

**責務**:
- 再生開始時に `motionViewModel.start()` を呼ぶ
- 再生停止時に `motionViewModel.stop()` を呼ぶ
- `reactionEvent(for:)` で `motionViewModel.latestSample` を参照してスコアを計算

**実装の要点**:
- AirPods 未接続時は `latestSample` が nil → `MotionReactionScoreEstimator` に渡せないのでフォールバック: `intensity = grooveLevel`（既存ロジック）、`tags = grooveTags(for:intensity)`
- AirPods 接続時: `MotionReactionScoreEstimator.score(from: latestSample)` → dominant 軸から tags、intensity = `score.intensity`

### 2. ReactionEvent — score フィールド追加

**変更**:
```swift
struct ReactionEvent: Identifiable {
    // 既存フィールドはそのまま
    let score: ReactionScore  // 追加。AirPods未使用時は ReactionScore.empty
}
```

**実装の要点**:
- `mockSamples()` は既存のままでよい（`score: .empty` を追加するだけ）

### 3. ChatAPIClient — ChatPayload 拡充

**変更**:
```swift
private struct ChatPayload: Encodable {
    // 既存フィールドはそのまま
    let scores: [String: Double]    // 追加: groove/hype/chill/immersion/hit/afterglow
    let dominantAxis: String?       // 追加: 最大スコアの軸名
}
```

**buildPayload の変更**:
```swift
ChatPayload(
    startTime: event.startTime,
    tags: event.tags.map(\.rawValue),
    intensity: event.intensity,
    lyric: event.lyricLine,
    history: ...,
    scores: event.score.asDictionary,   // 追加
    dominantAxis: event.score.dominant?.id  // 追加
)
```

**ReactionScore 拡張**:
```swift
extension ReactionScore {
    var asDictionary: [String: Double] {
        Dictionary(uniqueKeysWithValues: axes.map { ($0.id, $0.value) })
    }
}
```

### 4. backend/index.js — buildContextMessage + system prompt 改善

**buildContextMessage の変更**:
```javascript
function buildContextMessage({ startTime, tags, intensity, lyric, scores, dominantAxis }) {
  // 既存行に加えて:
  const dominantStr = dominantAxis ?? tags[0] ?? '不明';
  const scoreLines = scores ? Object.entries(scores)
    .filter(([, v]) => v > 0.1)
    .sort(([, a], [, b]) => b - a)
    .map(([k, v]) => `  ${k}: ${Math.round(v * 100)}%`)
    .join('\n') : '（スコアなし）';
  return [...既存行, `dominant軸: ${dominantStr}`, `6軸スコア:\n${scoreLines}`].join('\n');
}
```

**system prompt の改善**:
- dominant 軸ごとに問いかけのアングルを指定
- groove/hype → リズム・体の動き系の問い
- hit/immersion → 歌詞・感情・刺さった感覚系の問い
- chill/afterglow → 余韻・静寂・感情の残り系の問い
- 定型文を避けるため「dominant軸が groove なら体の動きについて、hit なら何が刺さったかを問いかける」とプロンプトで明示

### 5. HowChatViewModel — ターン数削減

```swift
// 変更前
guard turnCount < 3 else {
// 変更後
guard turnCount < 2 else {
```

### 6. ChatAPIClient.mockResponse — 動的選択肢

```swift
private func mockResponse(event: ReactionEvent, turn: Int) -> ChatResponse {
    let dominant = event.score.dominant?.id ?? event.tags.first?.rawValue ?? "groove"
    // dominant に応じて選択肢を切り替え
}
```

## データフロー

### lyric タップ → HowChat 起動
```
1. ユーザーが歌詞行をタップ
2. HomeView.reactionEvent(for: line) を呼ぶ
3. motionViewModel.latestSample があれば MotionReactionScoreEstimator.score(from:) でスコア計算
4. なければ grooveLevel + grooveTags() でフォールバック
5. ReactionEvent(score: calculatedScore, ...) を生成
6. HowChatView を sheet で表示
7. HowChatViewModel.start() → ChatAPIClient.chat(event:, messages:[])
8. backend に scores + dominantAxis を含む JSON を POST
9. Claude が dominant 軸ベースの問いかけを返す
10. 2ターン完了 → state = .done → HowCardCreationView へ
```

## エラーハンドリング戦略

- `latestSample` が nil（AirPods 未接続）→ 既存の grooveLevel フォールバックを維持
- `scores` が空 → バックエンドは既存ロジックで動作（スコアなし表示）
- Claude API エラー → 既存フォールバック（手動入力を促す）を維持

## テスト戦略

### 手動確認
- mockMode: タップ → dominant 軸が変わる選択肢が出ることを確認
- 実機（iPhone モーション）: 激しく動いた後タップ → groove/hype が高いスコアが出ることを確認

## ディレクトリ構造

変更ファイル:
```
Othello/Othello/
├── Models/ReactionEvent.swift                    # score: ReactionScore 追加
├── Features/ReactionDisplay/Models/ReactionScore.swift  # asDictionary 拡張追加
├── Features/AirPodsMotion/ViewModels/AirPodsMotionViewModel.swift  # 変更なし（既存）
├── Views/ReactionDisplay/RealtimeReactionDisplayView.swift  # @StateObject → @ObservedObject
├── Views/Home/HomeView.swift                     # motionViewModel 追加、reactionEvent 改善
└── Features/HowChat/
    ├── Services/ChatAPIClient.swift              # ChatPayload 拡充、mockResponse 動的化
    └── ViewModels/HowChatViewModel.swift         # turnCount < 3 → < 2
backend/
└── index.js                                      # buildContextMessage, systemPrompt 改善
```

## 実装の順序

1. `ReactionEvent` に `score` フィールド追加（モデル変更・影響範囲が小さい）
2. `ReactionScore.asDictionary` 拡張追加
3. `RealtimeReactionDisplayView` を `@ObservedObject` に変更
4. `HomeView` に `@StateObject motionViewModel` 追加、`reactionEvent` 改善
5. `ChatPayload` に `scores/dominantAxis` 追加
6. `mockResponse` を dominant 軸ベースに動的化
7. `HowChatViewModel` のターン数削減
8. `backend/index.js` の `buildContextMessage` + `systemPrompt` 改善

## パフォーマンス考慮事項

- `MotionReactionScoreEstimator.score(from:)` は純粋な四則演算。メインスレッドで呼んでも問題なし
- `latestSample` は常に最新1件のみ参照（O(1)）
