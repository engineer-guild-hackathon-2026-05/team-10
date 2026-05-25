# タスクリスト

## フェーズ1: 全体確認

- [x] git tracked / ignored の秘匿ファイル状態を確認する
- [x] Swift / backend のモック依存と未参照ファイルを確認する

## フェーズ2: リファクタリング

- [x] tracked Xcode 個人設定ファイルを削除する
- [x] ChatAPIClient の backend 接続設定と mock 判定を整理する
- [x] ENV.example.plist に chat backend 設定を追加する
- [x] backend の API key guard / 入力正規化 / history 正規化を実装する
- [x] 未参照 SwiftUI コンポーネントを削除する
- [x] 実行時の暗黙モック反応をプレビュー用サンプルと実データ経路に分離する
- [x] Howカード投稿ボタンの TODO / 無反応状態を解消する

## フェーズ3: 検証

- [x] backend syntax check を実行する
- [x] iOS xcodebuild を実行する
- [x] 秘匿ファイルと tracked 個人設定ファイルの状態を再確認する
- [x] AI_USAGE_LOG.md と振り返りを更新する

---

## 実装後の振り返り

### 実装完了日

2026-05-24

### 計画と実績の差分

**計画と異なった点**:
- ChatAPIClient / backend だけでなく、リアルタイム反応画面にも実行時モック依存が残っていたため、AirPods motion sample からスコア推定する経路を追加した。

**新たに必要になったタスク**:
- Howカード投稿ボタンが TODO のまま無反応だったため、既存画面と同じ投稿完了フィードバックを追加した。

### 学んだこと

**技術的な学び**:
- Xcode の filesystem synchronized root group では、未参照 Swift ファイルの削除後も xcodebuild で stale object が掃除され、参照切れなく確認できる。

**プロセス上の改善点**:
- 秘匿ファイル確認は `git check-ignore` と `git ls-files --deleted` を併用すると、ignored かつ過去 tracked のファイルを切り分けやすい。

### 次回への改善提案
- 実行時サンプルデータと Preview 用サンプルデータは命名と注入経路を分け、デモ用データが本番 UI に混ざらないようにする。
