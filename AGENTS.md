# AGENTS.md — Team 10 共通エージェントガイド

AI コーディングエージェント（**Codex / Jules / Cursor** 等）が共通で読むファイル。
Claude Code は `CLAUDE.md` も参照する。

## このプロジェクトについて

**HowTune** — 「何を聴くかではなく、どう聴いているか」でつながる iOS 音楽アプリ。
AirPods のモーション・心拍で曲中の身体反応を検出し、AI 対話で「聴き方（How）」を言語化、同じ How の人とつなげる。
Engineer Guild Hackathon 2026/05 の Team 10 リポジトリ。開発期間中は速度優先で、AI ツールを積極的に活用する。

## ディレクトリ構成

| パス | 内容 | 技術 | エージェント作業 |
|---|---|---|---|
| `Othello/` | iOS ネイティブアプリ | Swift / SwiftUI | ⚠️ **macOS + Xcode 必須。Linux VM では不可** |
| `backend/` | LLM プロキシ・データ API | Node.js / Express | ✅ |
| `functions/` | Firebase Functions | Node.js 20 | ✅ |
| `ai-recognition/` | 反応分類モデル | Python / TensorFlow | ✅ |
| `frontend/` | フロントエンド置き場 | （MVP 未使用） | — |
| `docs/` | ドキュメント（仕様は `docs/frontend-spec.md` が正） | Markdown | ✅ |

## セットアップ・検証コマンド（VM で実行）

### backend/
```bash
cd backend && npm install
npm run dev          # node --watch index.js → http://localhost:3000
```
- 環境変数: `ANTHROPIC_API_KEY`（`.env`）、`serviceAccountKey.json`（Firebase・gitignore）
- ⚠️ 起動時に `serviceAccountKey.json` を `require` するため、無いと起動しない
- 認証不要で叩けるのは `POST /sessions/:id/chat` のみ。他は Firebase ID トークン必須

### functions/
```bash
cd functions && npm install
npm run serve        # firebase emulators:start --only functions
```

### ai-recognition/
```bash
cd ai-recognition && python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt   # 存在する場合
```

### Othello/（iOS・エージェント作業不可）
**macOS + Xcode が必須**。Linux VM ではビルド・テストできない。
AirPods の頭部モーション・心拍は実機でのみ取得可能（シミュレータ不可）。

## コーディング規約

- **Swift**: MVVM。`struct` / `class` / `protocol` は型ごと 1 ファイル。Feature-based ディレクトリ（`Views/Listening/` 等）
- **コメント**: WHY が自明でない場合のみ書く
- **型安全**: `any`（TS）/ 強制アンラップ（Swift）を避ける

## ブランチ戦略

- `main` への直接コミット・プッシュは禁止
- 作業ブランチ → PR → マージの流れを守る
- ブランチ名は `feat/xxx` / `fix/xxx` / `docs/xxx` / `chore/xxx` の形式
- PR は CodeRabbit（日本語）が自動レビューする

## コミット規約

- prefix: `feat` / `fix` / `docs` / `refactor` / `chore` / `test`
- 末尾に `Co-Authored-By:` を付ける（使用したエージェント名）

## 秘匿情報

- API キーや認証情報は `.env`（`.gitignore` 対象）で管理
- 公開リポ化に備え、キーをコードにハードコードしない

## AI 活用ログ

作業したら [`AI_USAGE_LOG.md`](./AI_USAGE_LOG.md) に記録する。審査項目「AI 活用度」の根拠資料になる。最低 1 日 3 件以上を目安に。

## 参考ドキュメント

- 仕様（source of truth）: [`docs/frontend-spec.md`](./docs/frontend-spec.md)
- 設計決定記録: [`docs/adr/`](./docs/adr/)
- Claude Code 向けルール: [`CLAUDE.md`](./CLAUDE.md)
