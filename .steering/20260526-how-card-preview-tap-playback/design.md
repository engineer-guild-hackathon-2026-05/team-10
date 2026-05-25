# How Card Preview Tap Playback Design

- 対象コンポーネントは `MiniSongCard`。
- `Button` のラベル内部に背景、padding、`contentShape`、`maxWidth` を持たせ、カード全面をヒットテスト対象にする。
- 再生処理は既存の `startPlayback()` と `onTap` をそのまま使い、MusicKit / NowPlaying 連携の経路は変更しない。

