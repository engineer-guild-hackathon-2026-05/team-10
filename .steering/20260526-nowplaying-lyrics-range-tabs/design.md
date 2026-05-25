# NowPlaying 歌詞 / 範囲選択タブ改善 Design

- `NowPlayingView` の ScrollView 内で、`circularVisualizer`、`songInfo`、`playbackControls` をタブ分岐の外へ移動する。
- タブごとの内容は `lyricsCard` と `ClipCreationInlineView` だけに分ける。
- `ClipCreationInlineView` から album art / song info / `ClipProgressControls` を削除し、範囲選択・コメント・投稿ボタンのみを表示する。
- フッターの segmented tab は共通 active style にし、ラベルを「歌詞」「範囲選択」にする。
- standalone の `ClipCreationView` でも重複する `ClipProgressControls` と旧ラベルの tab selector を削除し、未使用になった補助型も整理する。
