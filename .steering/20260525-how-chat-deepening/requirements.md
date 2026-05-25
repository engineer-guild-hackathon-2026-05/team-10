# 要求内容

## 概要

実AirPodsモーション/iPhoneモーションから算出した6軸スコア（groove/hype/chill/immersion/hit/afterglow）を HowChat AI に渡し、定型文でない動きに基づいた深掘り問いかけを実現する。

## 背景

現在 HomeView の `grooveLevel` は `volume × 0.42 + sinusoid` という疑似スコアで動いており、
`ReactionDetectionViewModel`（実モーション → `ReactionScoringService` → 6軸スコア）は実装済みだが HomeView に未接続。

その結果 HowChat に渡る `ReactionEvent` が疑似データになり、AI の問いかけも選択肢固定の定型文になっている。

**grill 確定方針（frontend-spec.md §9.1）**:
- DEC-A: 主シグナルは頭部モーション（AirPods / iPhone フォールバック）
- DEC-D: コア体験「聴く → モーション → 6軸スコア → AI対話 → Howカード」を確実に完結

## 実装対象の機能

### 1. 実モーション接続
- `AirPodsMotionManager` のサンプルを `ReactionDetectionViewModel.ingest()` へ流す
- `reactionEvent(for: TimedLyricLine)` を疑似 groove ではなく `detectionVM.currentScore` から構築する
- `ReactionEvent` に `score: ReactionScore` フィールドを追加し、6軸値を保持する

### 2. ChatPayload 拡充
- `ChatAPIClient` の `ChatPayload` に `scores: [String: Double]` を追加
- dominant 軸（最大値の軸）を `dominantAxis` として別途送る
- バックエンドの `buildContextMessage` でスコアを文脈に含める

### 3. バックエンド system prompt 改善
- dominant 軸・スコア値を参照して軸固有の問いかけを生成する指示に変更
- groove → リズム・体の動き、hit → 歌詞・刺さった感覚、afterglow → 余韻・静寂、など軸ごとのアングルを持つ

### 4. ターン数削減 + mockResponse 改善
- `HowChatViewModel.submitReply`: `turnCount < 3` → `< 2`（2ターン上限）
- `ChatAPIClient.mockResponse`: dominant 軸に応じた動的な選択肢を返す

## 受け入れ条件

### 実モーション接続
- [ ] HomeView が `ReactionDetectionViewModel` を保持し、AirPods/本体モーションサンプルを `ingest()` へ渡している
- [ ] 歌詞タップ時に生成される `ReactionEvent.score` に実スコア（全ゼロでない）が入っている
- [ ] AirPods 未接続時は本体モーションにフォールバックして動作する

### ChatPayload 拡充
- [ ] `ChatPayload` の JSON に `scores` と `dominantAxis` が含まれる
- [ ] バックエンドのコンテキストメッセージに各軸スコアが出力される

### system prompt 改善
- [ ] 同じ曲・同じ地点でも dominant 軸が変わると問いかけの内容が変わる
- [ ] 問いかけが断定でなく確認形になっている（既存ルール維持）
- [ ] 選択肢が dominant 軸に関連したものになっている

### ターン数・mock 改善
- [ ] 2ターン後に `state = .done` になりHowカード生成に進む
- [ ] mockMode で dominant 軸別の選択肢が出る（groove/hit/chill で異なる）

## 成功指標

- デモで「歌詞タップ → 2回の問いかけ → Howカード生成」が60秒以内に完結する
- 同じ曲でもタップ位置（grooveが高い箇所 vs afterglowが高い箇所）で問いかけが変わる

## スコープ外

- AirPods 心拍の接続（DEC-B: 補助扱いのまま、今回は変更しない）
- ReactionDetectionViewModel の CoreML モデル精度向上
- HowChat UI の変更（ターン数カウンター表示など）
- バックエンドへの ReactionScore 完全送信（今回は dominant + scores の簡略形式）

## 参照ドキュメント

- `docs/product-requirements.md` §AI の役割定義
- `docs/functional-design.md` §UC-01 シーケンス図
- `docs/architecture.md` §レイヤー責務
- `docs/frontend-spec.md` §9.1 確定（grill 2026-05-24）
- GitHub Issue #71
