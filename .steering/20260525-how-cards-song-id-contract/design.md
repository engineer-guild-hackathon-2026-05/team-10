# How Cards Song ID Contract Design

## API Contract

`how-cards` API の `song_id` は canonical music ID とする。Apple Music / MusicKit の `MusicItemID.rawValue` として使える値を想定し、今回の Functions では数値文字列を valid な曲 ID として扱う。

## Backward Compatibility

既存 Firestore document に以下のような形がある可能性がある。

```json
{
  "song_id": "radwimps-愛にできることはまだあるかい",
  "itunes_id": "xxxxxxxxxx"
}
```

この場合、serializer は response の `song_id` に `itunes_id` を返し、元の slug は `song_slug` として返す。

`itunes_id` がない legacy slug document は canonical ID を持たないため、`GET /how-cards` の一覧では返さない。client contract を壊す値を返すより、backend issue として data migration すべき状態に寄せる。

## Write Path

`POST /how-cards` / `PATCH /how-cards/:id` は以下の順で canonical ID を決める。

1. `song_id` が valid music ID ならそれを使う。
2. `itunes_id` が valid music ID ならそれを使う。
3. `music_kit_id` が valid music ID ならそれを使う。
4. どれも無ければ 400 を返す。

`song_id` が slug で、別途 `itunes_id` がある場合は `song_id` には canonical ID を保存し、slug は `song_slug` に保存する。

## Documentation

`functions/README.md`, `docs/backend.md`, `docs/data-model.md` に `song_id` の意味と `itunes_id` / `song_slug` の扱いを記載する。
