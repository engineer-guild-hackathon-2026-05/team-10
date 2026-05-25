# Lyrics How Card Comments Design

- `NowPlayingView` の歌詞行を plain button 化し、タップ時に `LyricHowCardDraft` を作成する。
- `LyricHowCardDraft` は選択歌詞、`song_start`, `song_end`, 推定フラグを保持する。
- 時間同期ありの場合は `TimedLyricLine.startTime` と `endTime` を使い、末尾行など `endTime` がない時は短い範囲を補う。
- 時間同期なしの場合は、各行の非空白文字数を重みにして、累積文字数比から曲内の開始・終了秒を算出する。
- 投稿 UI は NowPlaying 内の sheet として実装し、選択歌詞、範囲、コメント入力、投稿状態を表示する。

