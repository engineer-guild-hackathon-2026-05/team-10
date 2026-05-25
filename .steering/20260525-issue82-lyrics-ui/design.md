# Issue 82 Lyrics UI Design

## Current Behavior

`NowPlayingView` の `lyricsCard` は角丸カードに全行を同じ body font で並べている。同期歌詞でも現在行の強弱がなく、Apple Music 的な追従感が弱い。

## Approach

- `lyricsCard` をカード背景なしの lyric surface に変更する
- `SynchronizedLyrics.isTimeSynced` の場合は `playback.playbackTime` から active line / index を求める
- `ScrollViewReader` で active line を中央付近へ自動スクロールする
- active / nearby / distant の opacity と font weight を分ける
- `StaticLyricsParser` で bracketed section labels を取り除く

## Files

- `Othello/Othello/Views/NowPlaying/NowPlayingView.swift`
- `Othello/Othello/Features/Lyrics/Services/StaticLyricsParser.swift`
- `AI_USAGE_LOG.md`
