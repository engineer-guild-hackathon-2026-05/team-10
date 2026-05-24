# HowTune Collector iOS

SwiftUI版の学習データ収集アプリです。iPhone上でCoreMotionを直接読み、セッション終了時に以下をアプリのDocumentsへ保存します。

- `<sessionId>_raw.json`
- `<sessionId>_training_examples.jsonl`

## 開き方

1. Xcodeで `HowTuneCollector.xcodeproj` を開く
2. `HowTuneCollector` targetを選ぶ
3. Signing & Capabilities で自分のTeamを選ぶ
4. iPhone実機を接続してRun

このリポ環境ではXcode本体が選択されていなかったため、`xcodebuild`での実機ビルド確認は未実施です。Swiftの静的typecheckは通しています。

## 使い方

1. 曲とスマホの持ち方を選ぶ
2. セッション開始
3. 音を聴きながら `ノってる` / `上がった` / `刺さった` などを押す
4. 終了
5. レビュー画面でラベルを確認
6. `Raw共有` または `JSONL共有` でAirDropやFilesへ渡す

保存済みファイルはアプリDocumentsの `HowTuneExports` に入ります。`UIFileSharingEnabled` と `LSSupportsOpeningDocumentsInPlace` を有効にしているため、FinderやFiles経由でも取り出せます。

## 収集データ

- 加速度・重力込みの `ax/ay/az`
- DeviceMotionの回転速度 `gx/gy/gz`
- 曲中時刻 `t`
- 押したラベルと前後window

マイク音声、位置情報、連絡先、写真、実名は取得しません。

