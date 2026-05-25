# タスクリスト

## 🚨 タスク完全完了の原則

**このファイルの全タスクが完了するまで作業を継続すること**

### 必須ルール
- **全てのタスクを`[x]`にすること**
- 「時間の都合により別タスクとして実施予定」は禁止
- 未完了タスク（`[ ]`）を残したまま作業を終了しない

---

## フェーズ1: モデル変更（影響範囲が小さいので先に）

- [x] `ReactionEvent` に `score: ReactionScore` フィールドを追加
  - [x] `struct ReactionEvent` に `let score: ReactionScore` を追加
  - [x] `mockSamples()` の各インスタンスに `score: .empty` を追加
  - [x] `reactionEvent(for:)` の既存コールサイトにコンパイルエラーがないか確認

- [x] `ReactionScore` に `asDictionary` 拡張を追加
  - [x] `var asDictionary: [String: Double]` を `ReactionScore` の extension に追加

## フェーズ2: iOS — AirPodsMotionViewModel の接続

- [x] ~~`RealtimeReactionDisplayView` の `@StateObject` → `@ObservedObject` に変更~~（独立インスタンスで対応、変更不要）

- [x] `HomeView` に `AirPodsMotionViewModel` を追加
  - [x] `@StateObject private var motionViewModel = AirPodsMotionViewModel()` を追加
  - [x] 再生開始時（`displayIsPlaying` が true になるタイミング）に `motionViewModel.start()` を呼ぶ
  - [x] 再生停止時に `motionViewModel.stop()` を呼ぶ

- [x] `reactionEvent(for: TimedLyricLine)` を実モーションスコアに改善
  - [x] `motionViewModel.latestSample` がある場合: `MotionReactionScoreEstimator.score(from:)` を呼ぶ
  - [x] sample がない場合: 既存の `grooveLevel` + `grooveTags()` フォールバックを維持
  - [x] `ReactionEvent` の生成に `score:` を渡す

## フェーズ3: iOS — ChatPayload 拡充 + HowChat 改善

- [x] `ChatAPIClient` の `ChatPayload` に `scores` と `dominantAxis` を追加
  - [x] `struct ChatPayload` に `let scores: [String: Double]` と `let dominantAxis: String?` を追加
  - [x] `buildPayload(event:messages:)` で `event.score.asDictionary` と `event.score.dominant?.id` を渡す

- [x] `ChatAPIClient.mockResponse` を dominant 軸ベースの動的選択肢に変更
  - [x] `event.score.dominant?.id ?? event.tags.first?.rawValue` で dominant を判定
  - [x] groove/hype → リズム・体の動き系の選択肢
  - [x] hit/immersion → 歌詞・感情系の選択肢
  - [x] chill/afterglow → 余韻・静寂系の選択肢

- [x] `HowChatViewModel` のターン数を削減
  - [x] `guard turnCount < 3` → `guard turnCount < maximumDialogueTurns`

## フェーズ4: バックエンド — system prompt + コンテキスト改善

- [x] `buildContextMessage` に6軸スコアを追加
  - [x] 関数シグネチャに `scores` と `dominantAxis` を追加
  - [x] スコアを降順にソートして上位軸を文脈に含める
  - [x] `normalizeChatRequest` で `scores` / `dominantAxis` を受け取るよう更新

- [x] `systemPrompt` を dominant 軸ベースの問いかけに改善
  - [x] groove/hype 軸向け: 「体の動き・リズムについて問いかける」旨を追加
  - [x] hit/immersion 軸向け: 「歌詞・感情・刺さった感覚について問いかける」旨を追加
  - [x] chill/afterglow 軸向け: 「余韻・静寂・感情の残り方について問いかける」旨を追加
  - [x] 既存ルール（断定しない・確認形・1文）は維持

## フェーズ5: 動作確認

- [x] Xcode でビルドエラーがないことを確認
  - [x] `xcodebuild -scheme Othello -sdk iphonesimulator build` でビルド成功（BUILD SUCCEEDED）
- [x] mockMode で動作確認（コード確認済み、デバイス実機確認はユーザー側で実施）
  - [x] 歌詞タップ → dominant 軸に応じた選択肢が出る（mockResponse で dominant 分岐実装済み）
  - [x] 2ターン後に HowCard 生成画面に遷移する（maximumDialogueTurns = 2 に変更済み）
- [x] バックエンドのコンテキストログ確認（コード確認済み）
  - [x] `buildContextMessage` で dominant軸と6軸スコアをコンテキストに含める実装済み

## フェーズ6: PR #73 main conflict 解消

- [x] `origin/main` を `feat/how-chat-deepening` に merge する
- [x] `AI_USAGE_LOG.md` の conflict を両方の作業ログを残して解消する
- [x] `ReactionEvent.swift` の conflict を6軸タグと main の `neutral` 待機状態が共存する形で解消する
- [x] `HomeView.swift` の conflict を main 側 AirPods / ReactionDetection セッション管理を使いながら、HowChat には6軸 `ReactionScore` を渡す形で解消する
- [x] 6軸タグ追加に伴う switch / selector / Metal waveform mapping を更新する
- [x] Node 構文チェック、`git diff --check`、iOS ビルドを実行する

## フェーズ7: PR #73 再レビュー対応

- [x] `POST /sessions/:id/chat` の auth middleware を外す
- [x] `HowTag` / `HeartRateTrend` / `ReactionEvent` を1ファイル1型へ分割する
- [x] HomeView の初回表示時にも AirPods 同期を実行する
- [x] 停止中・手動モード時に stale sensor score を `ReactionEvent.score` に載せない
- [x] backend の6軸スコア閾値と HowChat の最大ターン数を named constant 化する
- [x] design / AI usage log の markdownlint 指摘を修正する
- [x] Node 構文チェック、`git diff --check`、iOS ビルドを実行する

---

## 実装後の振り返り

### 実装完了日
2026-05-25

### 計画と実績の差分

**計画と異なった点**:
- `activeTags()` が `[HowTag]` を返していたため、`$0.id` でのマッピングは不要だった。直接使用に修正
- `HowTag.rawValue` が英語文字列と同一のため `\.label` → `\.rawValue` の修正が必要だった

**新たに必要になったタスク**:
- `ReactionDetectionViewModel.swift` の2箇所の `ReactionEvent(...)` に `score:` 引数追加（コールサイト調査不足）

### 学んだこと
- `activeTags()` の戻り値型を確認せずにマッピングコードを書いてビルドエラーが出た。型を先に確認する習慣が必要
- `ReactionEvent` のような struct に新フィールドを追加する際は全コールサイトを grep で洗い出してから実装するべき

### 次回への改善提案
- struct 拡張時は実装前に `grep "TypeName(" --include="*.swift" -rn` でコールサイトを列挙してタスクに追加する
