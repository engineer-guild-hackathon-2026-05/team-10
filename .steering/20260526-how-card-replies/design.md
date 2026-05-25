# Howカード返信機能 設計

## Firestore

```text
how-cards/{cardId}
  reply_count: number

how-cards/{cardId}/replies/{replyId}
  body: string
  user_id: string
  created_at: timestamp
  updated_at: timestamp | absent
```

返信本文は `body` とし、Howカード本体の `comment` と区別する。親の `reply_count` は一覧表示用に非正規化する。

## Functions API

### GET /how-cards/:id/replies

- 認証必須
- query: `limit` 1〜100、未指定 50
- 親 Howカードが存在しない場合は 404
- `created_at` 昇順で返す
- `users/{user_id}.display_name` を参照し、`user_name` を付与する

Response:

```json
{
  "replies": [
    {
      "id": "reply123",
      "how_card_id": "card456",
      "body": "その聴き方わかる",
      "user_id": "uid123",
      "user_name": "Atsushi",
      "created_at": "2026-05-26T12:00:00.000Z",
      "updated_at": null
    }
  ]
}
```

### POST /how-cards/:id/replies

- 認証必須
- body: `{ "body": "..." }`
- `body` は 1〜180 文字
- transaction で親存在確認、返信作成、`reply_count` increment をまとめる

Response:

```json
{
  "reply": { "...": "..." },
  "reply_count": 1
}
```

## iOS

- `HowCardReply` を追加し、Functions response を decode する
- `FirebaseAPI` に `fetchHowCardReplies` / `createHowCardReply` を追加する
- `HowCardComment` に `replyCount` を追加し、`reply_count` を decode する
- `FeedPost.commentCount` は `HowCardComment.replyCount` 由来にする
- `HowCardRepliesViewModel` が読み込み・投稿・エラー状態を持つ
- `HowCardRepliesView` を sheet として表示し、元投稿・返信一覧・入力欄をまとめる

## UI

MusicFeed の投稿カードの吹き出しボタンを返信画面の入口にする。返信画面は bottom sheet とし、元投稿を上部に残したまま、返信一覧と入力欄を表示する。
