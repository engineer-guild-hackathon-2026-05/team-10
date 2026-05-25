# Music Feed How Cards UI Design

- Add a dedicated optional Firestore lookup ID to `Song` so display metadata can change without changing the How card read query key.
- Keep `Song.firestoreSongID` write-oriented by preferring canonical MusicKit ID when it exists; use a separate read lookup property for MusicFeed queries.
- Populate that lookup ID from `HowCardComment.songID` when building `HomeDashboardComment`.
- Replace `UserSeedService` with a read-only `UserProfileService` for user profile lookups and remove launch-time user seed warmup.
- Adjust the artist card overlay padding and clipping so badge/play controls are contained by the card bounds.
