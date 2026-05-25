# PR #99 レビュー対応タスクリスト

## 対象
- PR #99 `feat/how-resonance`
- base: `main`

## タスク
- [x] PR #99 のレビューコメントと対象ブランチを確認する
- [x] `origin/main` を取り込み、`AI_USAGE_LOG.md` の conflict を解消する
- [x] Firestore DM rules の schema / timestamp 指摘を修正する
- [x] Resonance の購読・送信エラー処理と入力 validation を修正する
- [x] PeakMoment / QuantumIgnitionView / steering design / AI_USAGE_LOG のレビュー指摘を修正する
- [x] スライド生成 helper の重複と `gradient_angle` 例外処理を整理する
- [x] 構文チェック、diff check、iOS build で検証する
- [ ] commit / push 後に PR 状態を確認する

## 検証予定
- `python -m py_compile docs/slides/generate_resonance_pptx.py docs/slides/generate_sdd_pptx.py docs/slides/pptx_utils.py`
- `git diff --check`
- iOS Simulator 向け `xcodebuild`
