# How Cards Song ID Contract Requirements

## Goal

`GET /how-cards` が返す `song_id` を、client が MusicKit / Apple Music / iTunes の曲 ID として安全に使える状態にする。

## Requirements

- issue #78 を修正する。
- `song_id` は MusicKit / Apple Music / iTunes の曲 ID として扱う。
- 既存 Firestore data に `itunes_id` がある場合は、それを canonical な `song_id` として返す。
- slug や表示用文字列は `song_id` ではなく `song_slug` / `song_title` など別フィールドに分離する。
- `POST /how-cards` / `PATCH /how-cards/:id` は Music ID なしの payload を reject する。
- 既存 endpoint path は増やさない。
- Functions deploy が可能なら実行する。
- `AI_USAGE_LOG.md` に作業ログを残す。

## Non-Goals

- Firestore の全既存 document migration はこのブランチでは行わない。
- iOS Home dashboard PR の差分はこのブランチに混ぜない。
