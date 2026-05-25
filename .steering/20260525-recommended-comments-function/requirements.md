# Recommended Comments Function Requirements

## Goal

Home dashboard で使えるおすすめコメント一覧を Firebase Functions から取得できるようにする。

## Requirements

- `GET /recommended-comments` を追加する。
- Firebase ID token 認証を必須にする。
- response は `{ "comments": [...] }` とする。
- コメントは `how-cards` collection から取得する。
- 新しいコメントといいね数の多いコメントが混ざるように推薦する。
- 既存の `song_id` contract 修正を維持する。
- 追加 index なしで動くクエリ構成にする。
- Functions deploy が可能なら実行する。
- `AI_USAGE_LOG.md` に作業ログを残す。

## Non-Goals

- Personalized ranking はこの実装では扱わない。
- iOS Home dashboard の fetch 先変更は PR #80 の差分と分離する。
