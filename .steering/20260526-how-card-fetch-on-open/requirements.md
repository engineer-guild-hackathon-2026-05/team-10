# Requirements

## Goal
Playback screen submissions must be visible from the artist feed as soon as the artist screen is opened.

## Requirements
- Confirm whether the user's submitted How card exists in Firestore.
- Ensure the artist feed fetches How cards using the submitted MusicKit song ID.
- When opening a feed from a dashboard comment, select the commented song immediately.
- Refresh dashboard data when returning to For You so newly posted comments can appear without a manual pull refresh.
- Preserve the existing main UI tone.

