# HowTune Collector iOS

SwiftUI版の学習データ収集アプリです。AirPodsの頭部モーションを `CMHeadphoneMotionManager` で直接読み、セッション終了時に以下をアプリのDocumentsへ保存します。AirPodsが未接続または非対応の場合はiPhone本体モーションへフォールバックします。

- `CreateMLActivityData/<label>/<sessionId>_<label>_*.csv`

## 開き方

1. Xcodeで `HowTuneCollector.xcodeproj` を開く
2. `HowTuneCollector` targetを選ぶ
3. Signing & Capabilities で自分のTeamを選ぶ
4. iPhone実機を接続してRun

このリポ環境ではXcode本体が選択されていなかったため、`xcodebuild`での実機ビルド確認は未実施です。Swiftの静的typecheckは通しています。

## 使い方

1. AirPodsを接続し、曲を選ぶ
2. セッション開始
3. 音を聴きながら `ノってる` / `チルい` / `neutral` のいずれかを押す
4. 終了
5. レビュー画面でラベルを確認
6. `GUI用フォルダ共有` でAirDropやFilesへ渡す

保存済みファイルはアプリDocumentsの `HowTuneExports` に入ります。`UIFileSharingEnabled` と `LSSupportsOpeningDocumentsInPlace` を有効にしているため、FinderやFiles経由でも取り出せます。Create ML GUIでActivity Classificationを学習する場合は、`HowTuneExports/CreateMLActivityData` フォルダをTraining Dataに指定します。

MVPの収集精度を上げるため、曲パターンもラベルと同じ3種類に絞っています。

| 曲パターン | 目的 |
|---|---|
| Groove Track | `ノってる` を集める |
| Neutral Track | 大きな反応がない `neutral` を集める |
| Chill Track | `チルい` を集める |

## 収集データ

- AirPods頭部モーションの加速度・重力込みの `ax/ay/az`
- AirPods頭部モーションの回転速度 `gx/gy/gz`
- AirPods頭部姿勢の `pitch/roll/yaw`
- 取得元 `source`（`headphone_motion` / `device_motion` / `accelerometer`）
- 曲中時刻 `t`
- 押したラベルと前後window

Create ML GUI向けには、押したラベル区間から5秒の固定長windowを切り出して以下のフォルダ構成も生成します。5秒未満の短い断片は学習に使わないため出力しません。

```text
CreateMLActivityData/
  groove/
    session_..._groove_start12300_001.csv
  chill/
    session_..._chill_start22000_001.csv
  neutral/
    session_..._neutral_start30000_001.csv
```

GUIでは `CreateMLActivityData` を選び、Featuresに `ax,ay,az,gx,gy,gz,pitch,roll,yaw` を指定します。

マイク音声、位置情報、連絡先、写真、実名は取得しません。
