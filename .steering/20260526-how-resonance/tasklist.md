# タスクリスト: How Resonance

## 🚨 タスク完全完了の原則
全タスクが `[x]` になるまで継続。未完了を残して終了しない。

---

## フェーズ0: 準備
- [x] feat/how-chat-deepening から新ブランチ feat/how-resonance 作成
- [x] 最新 main をマージ（競合解決・ビルド通過）
- [x] steering ドキュメント作成（requirements/design/tasklist）
- [x] ADR 作成（Firestore 直リアルタイム購読の採用）→ ADR-0006

## フェーズ1: ピークモーション検出（FR-RES-01）
- [ ] `PeakMoment` モデル作成
- [ ] `PeakMotionTracker` 作成（samples → ピーク抽出の純関数）
- [ ] `AirPodsMotionViewModel` に `peakMoment` 算出を追加（既存API不変）
- [ ] ビルド確認

## フェーズ2: 1回目の決めうち問いかけ（FR-RES-02）
- [ ] `HowResonancePromptBuilder` 作成（固定 question/choices）
- [ ] ピーク地点の時刻フォーマット
- [ ] ビルド確認

## フェーズ3: 2回目LLM深掘り接続（FR-RES-03）
- [ ] 既存 HowChat の2ターン目が LLM になっていることを確認（変更不要なら明記）
- [ ] 1回目固定文 → 2回目LLM の接続確認

## フェーズ4: マッチング（FR-RES-04）
- [ ] `ResonanceReactor` モデル作成
- [ ] `ResonanceMatchService` 作成（Firestore how-cards 購読 + 同地点判定 `isSameSpot`）
- [ ] `ResonanceMatchViewModel` 作成
- [ ] `ResonanceMatchView` 作成（同地点🔥/別地点リスト）
- [ ] ビルド確認

## フェーズ5: 共鳴演出（FR-RES-05）
- [ ] `QuantumIgnitionView` 作成（Canvas/TimelineView: 量子→摩擦→発火）
- [ ] `ResonanceVisualConfig`（richMode 切替）
- [ ] マッチ出現時に演出再生 + 🔥
- [ ] ビルド確認

## フェーズ6: リアルタイムDM（FR-RES-06, 07）
- [ ] `ResonanceMessage` モデル作成
- [ ] `ResonanceChatService` 作成（messages 購読・楽観的送信）
- [ ] `ResonanceDMViewModel` 作成
- [ ] `ResonanceDMView` 作成（Apple ネイティブ調）
- [ ] 🔥タップ → DM 遷移
- [ ] ビルド確認

## フェーズ7: Firestore rules + seed
- [ ] Firestore rules に how-cards read / conversations read-write を追加
- [ ] `functions/scripts/seed-resonance.js`（mock how-cards 2件）
- [ ] seed 手順を docs に記載

## フェーズ8: 最終確認・成果物
- [ ] 全体ビルド通過（xcodebuild）
- [ ] AI_USAGE_LOG 追記
- [ ] スライド作成（HTML + PPTX）
- [ ] コミット・プッシュ

---

## 実装後の振り返り

### 実装完了日
{YYYY-MM-DD}

### 計画と実績の差分
**計画と異なった点**:
-
**新たに必要になったタスク**:
-

### 学んだこと
-

### 次回への改善提案
-
