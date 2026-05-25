# 要求内容

## 概要

リポジトリ全体を横断し、秘匿情報・不要コード・モック依存・品質リスクを確認して、直せる範囲をリファクタリングする。

## 背景

公開リポジトリ化やハッカソン提出に向けて、API キーや個人設定ファイルが git に含まれていないこと、モックだけで成立している実装がないこと、主要コードが保守しやすい状態であることを確認する必要がある。

## 実装対象の機能

### 1. 秘匿情報・git 管理チェック
- `.env`、`ENV.plist`、`GoogleService-Info.plist`、Xcode 個人設定の状態を確認する。
- tracked されている不要な個人設定ファイルを削除する。

### 2. モック依存の是正
- Chat API が環境変数未設定時に無条件でモックになる状態を改善する。
- backend 接続設定を `ENV.plist` から明示できるようにする。

### 3. backend 品質改善
- API キー未設定時の挙動を明示化する。
- chat history と入力値を正規化し、LLM 呼び出しに安全な形で渡す。

### 4. 不要コード整理
- 参照されていない SwiftUI コンポーネントを確認し、不要なら削除する。

## 受け入れ条件

- [ ] git tracked に `ENV.plist` / `.env` / `GoogleService-Info.plist` が含まれていない。
- [ ] git tracked の Xcode `xcuserdata` が削除されている。
- [ ] Chat API 接続先が `ENV.plist` で設定でき、モックは明示設定または Debug fallback に限定されている。
- [ ] backend が API key 未設定時に 503 を返せる。
- [ ] backend が history role/content を正規化して Anthropic API に渡す。
- [ ] 不要な未参照 SwiftUI ファイルが整理されている。
- [ ] iOS build と backend syntax check が通る。

## スコープ外

- 大規模な画面設計変更
- 新規テストターゲット作成
- 実機センサー連携の本実装

## 参照ドキュメント

- `docs/development-guidelines.md`
- `docs/architecture.md`
- `docs/frontend-spec.md`
