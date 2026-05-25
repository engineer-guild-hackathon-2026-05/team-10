# PR #89 review fixes and main merge

- [x] PR #89 のレビュー指摘と対象ブランチを確認する
- [x] `origin/main` を PR ブランチへ取り込み、コンフリクトを解消する
- [x] CodeRabbit の匿名チャット / Firebase Auth / lyric 上書き指摘を修正する
- [x] 影響範囲を検証する
- [x] AI_USAGE_LOG.md に作業ログを追記する

## 振り返り

- PR #89 の sessionID 管理を維持しながら、main 側の HowChat 深掘り・6軸スコア送信と統合した。
- 匿名 chat endpoint の契約に合わせ、Firebase ID token は Howカード作成など認証必須 API のみに送る構成へ戻した。
- `lyric` 未送信時に既存 Firestore 値を消さないよう、明示された場合だけ更新する形にした。
