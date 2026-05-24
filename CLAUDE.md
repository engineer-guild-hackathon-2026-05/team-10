# Claude Code — Team 10 プロジェクトルール

グローバルルール（`~/.claude/CLAUDE.md`）を継承しつつ、このリポ固有の規約を追加する。

## このプロジェクトについて

Engineer Guild Hackathon 2026/05 の Team 10 リポジトリ。
開発期間中は速度優先で、AI ツールを積極的に活用する。

## AI 活用ログ

**Claude を使って作業した際は必ず [`AI_USAGE_LOG.md`](./AI_USAGE_LOG.md) に記録する。**
審査項目「AI 活用度」の根拠資料になる。最低 1 日 3 件以上を目安に。

## ブランチ戦略

- `main` への直接コミット・プッシュは禁止
- 作業ブランチ → PR → マージの流れを守る
- ブランチ名は `feat/xxx` / `fix/xxx` / `docs/xxx` の形式

## コミット規約

- prefix: `feat` / `fix` / `docs` / `refactor` / `chore` / `test`
- 末尾に `Co-Authored-By: Claude <noreply@anthropic.com>` を付ける

## 秘匿情報

- API キーや認証情報は `.env`（`.gitignore` 対象）で管理
- 公開リポ化に備え、キーをコードにハードコードしない
