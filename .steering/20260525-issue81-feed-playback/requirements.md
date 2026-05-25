# Issue 81 Feed Playback Requirements

## Goal

MusicFeed / artist feed の曲再生操作では NowPlaying を自動で全画面表示せず、再生状態をグローバルミニプレイヤーに反映する。

## Acceptance Criteria

- MusicFeed 上の曲カード再生で画面は MusicFeed に留まる
- 再生中の曲は GlobalMiniPlayer に表示される
- GlobalMiniPlayer をタップした時だけ NowPlaying を開く
- Howカードコメントの再生開始位置は維持する
- 最新 `main` 起点のブランチで PR を作成する
