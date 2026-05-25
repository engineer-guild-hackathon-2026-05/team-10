# Design

## Findings
- Firestore contains the recent submitted card as `すばらしい` with `song_id=1518522045` and `artist_id=radwimps`.
- `MusicFeedViewModel` always starts at song index `0`, even when the navigation was triggered from a specific dashboard comment.
- `ForYouView` only loads dashboard data once unless the user manually refreshes.

## Approach
- Initialize `MusicFeedViewModel` with an optional initial song and match it by Firestore/MusicKit lookup identifiers.
- Force dashboard refresh when For You appears, while keeping the current loading UI behavior quiet if comments are already present.
- Keep API access through `FirebaseAPI` and functions; do not add direct Firestore reads from iOS.

