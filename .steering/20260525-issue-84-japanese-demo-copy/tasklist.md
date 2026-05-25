# Issue #84 Japanese Demo Copy Tasklist

- [x] Issue #84 の要件を確認する
- [x] 最新 `main` から作業ブランチを作成する
- [x] 対象ファイルと英語 placeholder を調査する
- [x] `Artist.catalog` のデモ曲タイトル・タグ・反応数表示を日本語中心に差し替える
- [x] `HomeDashboardViewModel` の fallback 文言を日本語化する
- [x] `AI_USAGE_LOG.md` を更新する
- [x] `rg` / `git diff --check` / `xcodebuild` で検証する
- [x] commit / push / PR 作成を行う

## 振り返り

- 実装完了日: 2026-05-25
- 実績: デモ固定データと fallback 表示だけを日本語化し、MusicKit 実データの正式タイトルはそのまま扱う方針を維持した。
- 検証: Issue #84 の英語 placeholder 検索、`git diff --check`、iOS Simulator 向け `xcodebuild` が通過した。
