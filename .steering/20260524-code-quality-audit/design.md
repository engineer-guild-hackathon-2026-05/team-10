# 設計書

## アーキテクチャ概要

既存構成を維持し、危険度の高い設定・境界部分を重点的に改善する。

```
iOS SwiftUI
  ├─ ENV.plist / ProcessInfo
  └─ ChatAPIClient
        ↓
backend Express
  ├─ request validation
  ├─ Anthropic client guard
  └─ normalized messages
```

## コンポーネント設計

### ChatAPIClient

**責務**:
- backend chat endpoint への HTTP 呼び出し。
- Debug/Preview 用 mock response の限定利用。

**実装の要点**:
- `API_BASE_URL` を `EnvironmentValueProvider` から読む。
- `HOWTUNE_CHAT_MOCK` が true の時、または Debug で base URL がない時だけ mock を使う。
- Release 相当では base URL 未設定をエラーにする。

### backend/index.js

**責務**:
- LLM API キーの秘匿。
- リクエストから会話文脈を作り、Anthropic に渡す。

**実装の要点**:
- API key 未設定時は起動は許すが `/sessions/:id/chat` で 503 を返す。
- body の型・範囲・文字列長を正規化する。
- user-provided context を system prompt ではなく user message 側へ置く。
- history の role を `user` / `assistant` のみに制限し、最初の message が user になるようにする。

### 不要ファイル整理

**責務**:
- git に含めるべきでない個人ファイルと未参照 UI を削除する。

**実装の要点**:
- `.gitignore` で無視済みでも tracked なら削除差分にする。
- PBXFileSystemSynchronizedRootGroup のため、削除した Swift file は自動的にビルド対象から外れる。

## テスト戦略

- `node --check backend/index.js`
- `xcodebuild -project Othello/Othello.xcodeproj -scheme Othello -destination 'generic/platform=iOS Simulator' -derivedDataPath /private/tmp/OthelloDerivedData build`
- `git ls-files` と `git check-ignore` による秘匿ファイル確認

## 依存ライブラリ

新規依存は追加しない。
