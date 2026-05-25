# ADR-0002: AI API キーをバックエンドプロキシで管理する

- **ステータス**: 置換済み（current: Functions 本番 contract には未接続）
- **決定日**: 2026-05-23
- **決定者**: Team 10

## 背景

HowChatView（AI対話画面）では、当初 Claude API を呼び出す必要があった。
iOS アプリから直接 Anthropic API を叩く実装も技術的には可能だが、API キーの扱いが問題になる。

2026-05-25 時点の現行実装では、HowChat は mock/legacy client として残っている。Firebase Functions 本番 API には `/sessions` 系 endpoint や Claude 連携は実装されていない。

## 検討した選択肢

| 選択肢 | メリット | デメリット |
|---|---|---|
| **バックエンドプロキシ（Node.js）** | API キーがクライアントに露出しない。モデル・プロンプトの差し替えが容易 | サーバーが必要 |
| iOS クライアントから直接呼び出し | 実装がシンプル | バイナリ解析で API キーが漏洩するリスク。モデル変更のたびにアプリ更新が必要 |
| Firebase Functions | サーバーレスで運用コスト低 | 冷起動レイテンシ。ローカル開発が面倒 |

## 決定

当時は **Node.js (Express) のバックエンドプロキシ**を採用した。

- `backend/index.js` に `POST /sessions/:id/chat` エンドポイントを実装
- API キーは `.env`（gitignore 対象）で管理し、コードにハードコードしない
- iOS クライアントは `API_BASE_URL` 環境変数でエンドポイントを指定。未設定時はモックレスポンスを返す

## 結果

- 旧 `backend/` には参照実装が残るが、本番 deploy 対象ではない。
- 現行本番 API は `functions/` を正とし、`/how-cards` と `/users/me` を提供する。
- LLM 連携を復活させる場合は、`functions/` 側に明示的に endpoint を追加し、API キーをクライアントバイナリへ含めない。
