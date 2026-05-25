# Howカード返信機能 要件

## 背景

MusicFeed の投稿 UI には返信数表示があるが、実装上は常に `0` で、返信一覧・投稿画面・Functions API・Firestore 永続化が存在しない。

## 目的

Howカードに対して、他のリスナーが短い返信を投稿し、同じ曲の一部分への聴き方について会話できるようにする。

## スコープ

- Functions に返信一覧取得・返信作成 API を追加する
- Firestore の `how-cards/{cardId}/replies/{replyId}` サブコレクションを設計・実装する
- `how-cards.reply_count` を非正規化し、Feed 上の返信数として返す
- iOS に返信一覧・投稿 UI を追加する
- MusicFeed の吹き出しボタンから返信画面を開けるようにする

## 非スコープ

- 返信の編集・削除
- 返信へのいいね
- リアルタイム購読
- push 通知

## 受け入れ条件

- `GET /how-cards/:id/replies` が Firebase ID token 必須で返信一覧を返す
- `POST /how-cards/:id/replies` が Firebase ID token 必須で返信を作成し、親 Howカードの `reply_count` を増やす
- 存在しない Howカードへの返信は 404 を返す
- iOS の MusicFeed で返信数を表示し、タップで返信画面を開ける
- 返信画面で既存返信を読み込み、新規返信を投稿できる
- Functions の構文チェックと iOS build が通る
