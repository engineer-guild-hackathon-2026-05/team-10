# PR72 Review Fixes Requirements

## Goal

PR #72 の CodeRabbit review comments を確認し、現在の `feat/main-integration` ブランチで有効な指摘を修正する。

## Requirements

- 再生候補が一致しない場合に誤った曲へ遷移しない。
- Howカード投稿の二重送信と古い成功状態の残留を防ぐ。
- いいね再タップで重複送信しない。
- artwork fallback が空/不足した gradient colors でも安全に描画できる。
- loading/error 中に Community の空状態セクションを同時表示しない。
- seed 失敗時に再試行不能な状態へ固定しない。
- LRC parser は同時刻行の元順を保ち、正当な bracketed lyric heading を落とさない。
- user profile upsert は nullable email 契約と整合させる。
- read path の user seed は実際に差分がある場合だけ Firestore write する。
- MusicFeed のキャンセル済み load task が posts を上書きしない。
- AI_USAGE_LOG.md に作業ログを残す。

## Non-Goals

- 現在のブランチに存在しない `HowCardSeedService.swift` の設計変更は扱わない。
- 現在の `functions/README.md` に存在しない seed metadata 記述の修正は扱わない。
