# Selected How Card State Design

- `MusicFeedView` に選択中カードIDの `@State` を持たせる。
- Home dashboard から遷移した highlighted card と feed post は別の選択ID prefix を持たせ、表示位置が正しく移動するようにする。
- `play(post:)` / `play(comment:)` の再生成功後に選択IDを更新する。
- `FeedPostCard` と `HighlightedHowCardCommentCard` は `isSelected` を受け取り、選択中の時だけ badge と軽い accent stroke を表示する。

