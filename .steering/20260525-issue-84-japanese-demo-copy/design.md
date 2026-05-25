# Issue #84 Japanese Demo Copy Design

## 方針

- `Artist.catalog` のデモデータを日本語タイトル・日本語タグ・日本語の反応数表示に差し替える
- 公式英語タイトルに見える曲でも、今回のデモ catalog では日本語タイトルの曲を優先して選ぶ
- `HomeDashboardViewModel` の fallback は表示用の最終手段なので日本語化する

## 変更対象

- `Othello/Othello/Models/Artist.swift`
  - `listeningCount`
  - `tag`
  - `Song.title`
- `Othello/Othello/ViewModels/HomeDashboardViewModel.swift`
  - artist fallback
  - song fallback
  - 長い numeric ID の表示用ラベル

## 検証

- `rg` で Issue #84 に挙がった英語 placeholder が残っていないことを確認
- `xcodebuild` で iOS build を確認
- `git diff --check` で whitespace を確認
