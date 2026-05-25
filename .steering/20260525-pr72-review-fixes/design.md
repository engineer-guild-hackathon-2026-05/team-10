# PR72 Review Fixes Design

## Approach

CodeRabbit の指摘を、現在の `feat/main-integration` の実装に対して再検証し、有効なものだけを最小差分で修正する。

## Key Changes

- `PlaybackViewModel.bestMatch` は title/artist match または title match のみを返す。
- `ClipCreationViewModel.postHowCard` は `isPosting` guard と `postedCardID` reset を持つ。
- `MusicFeedView.play` は playback track が解決できた時だけ `onSongTap` する。
- `FeedPostCard` は未いいねからいいね済みに遷移する初回だけ `onLike` を呼ぶ。
- `CircularArtworkView` は 0/1/2+ colors を分岐して描画する。
- `CommunityView` は loading/error 時に list sections を描画しない。
- `StaticLyricsParser` は parse order を保持して同時刻 tie-break に使い、LRC metadata tag だけを除外する。
- `FirebaseAPI` と Functions users route は nullable email を許容する。
- `UserSeedService` は差分がある時のみ `updated_at` を含めて write する。
- `MusicFeedViewModel` は `CancellationError` を通常エラーに落とさない。
