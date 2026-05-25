# Recommended Comments Function Design

## Endpoint

`GET /recommended-comments?limit=12`

認証は既存の `middleware/auth.js` を使い、Firebase ID token を必須にする。レスポンスは Home dashboard がそのまま配列として扱えるように `{ "comments": [...] }` を返す。

## Ranking

Firestore から以下の2系統で候補を取得して merge する。

- `created_at desc`: 新しいコメント
- `likes desc`: いいね数が多いコメント

候補を document ID で dedupe し、Functions 側で以下のスコアにより並び替える。

```text
score = log2(likes + 1) * 2.4 + exp(-ageHours / 72) * 3 + freshBoost
```

これにより、直近の投稿は自然に上がり、古くてもいいねが多いコメントも候補に残る。Firestore query は単一 field order のみなので、新しい composite index は不要。

## Contract

serializer は既存の `serializeHowCard` を使う。`song_id` は MusicKit / Apple Music / iTunes の canonical ID として返し、legacy slug は `song_slug` に分離する。
