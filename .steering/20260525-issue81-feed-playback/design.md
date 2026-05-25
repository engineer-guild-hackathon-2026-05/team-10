# Issue 81 Feed Playback Design

## Current Behavior

`ContentView` が `nowPlayingContext?.id` の変更を監視し、新しい context が入るたびに `showNowPlaying = true` を実行している。そのため MusicFeed で `onPlaybackContext` を呼ぶだけで全画面遷移する。

## Approach

- `nowPlayingContext` の変更時は AirPods capture の開始・停止だけを扱う
- `showNowPlaying = true` は `GlobalMiniPlayerView` の `onTap` に閉じ込める
- `nowPlayingContext` が `nil` になった場合は NowPlaying を閉じて空 cover を避ける

## Files

- `Othello/Othello/ContentView.swift`
- `AI_USAGE_LOG.md`
