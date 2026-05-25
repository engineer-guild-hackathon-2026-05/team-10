# Issue 82 Lyrics UI Requirements

## Goal

NowPlaying の歌詞表示を Apple Music 風の没入型 UI に寄せ、同期歌詞がある場合は現在行を強調して追えるようにする。

## Acceptance Criteria

- 歌詞はカード枠ではなくフル幅に近いスクロール表示にする
- 同期歌詞では現在行を大きく明るく、周辺行を薄く表示する
- `[Intro]` / `[Verse 1]` などのセクション行を表示しない
- 歌詞なし・読み込み中・失敗時の fallback が画面になじむ
- 最新 `main` 起点のブランチで PR を作成する
