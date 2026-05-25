# Lyrics How Card Comments Requirements

- 歌詞行をタップした時に、その歌詞に対する感想を Howカードとして投稿できる。
- 時間同期された歌詞では、選択行の `song_start` / `song_end` を実時間に対応させる。
- 時間同期されていない歌詞では、歌詞全体に対する選択行の文字数位置から曲内範囲を推定する。
- NowPlaying の既存トンマナを守り、歌詞表示・スクロール・再生操作を壊さない。
- 作業外の `project.pbxproj` 変更には触れない。

