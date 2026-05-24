# HowTune AI Recognition

`spec.md` に沿った MotionReactionClassifier と、学習データを集める Web クライアントです。

## 構成

```txt
packages/ml/
  src/features.ts      # 加速度サンプルから10次元特徴量を抽出
  src/model.ts         # TensorFlow.js LayersModel
  src/train.ts         # JSONLから学習してモデル保存
  src/evaluate.ts      # label別precision/recall/F1とTop-2 accuracy
  src/predict.ts       # /api/motion/predict と同じ推論レスポンス生成
  data/examples.jsonl  # seed学習データ
apps/collect-web/
  src/app/collect/*    # データ収集 UI
  src/app/api/*        # MVP用 file-backed API
apps/collect-ios/
  HowTuneCollector.xcodeproj # iPhone実機で動くSwiftUI収集アプリ
```

## mise / セットアップ

`ai-recognition/.mise.toml` で Node.js 20 を指定しています。親リポジトリの mise 設定とは分離して、このディレクトリ配下だけに効きます。

```bash
cd ai-recognition
mise install
npm install
```

## 学習・評価

```bash
npm run ml:train
npm run ml:evaluate
```

学習済みモデルは `packages/ml/models/motion-reaction-v1/` に `model.json` と `weights.bin` として保存されます。

## データ収集アプリ

### SwiftUI / iPhone実機 + AirPods

AirPods頭部モーションを収集する場合はこちらを使います。AirPodsが未接続または非対応の場合はiPhone本体モーションへフォールバックします。

```bash
open apps/collect-ios/HowTuneCollector.xcodeproj
```

XcodeでSigning Teamを設定して、iPhone実機と対応AirPodsを接続してRunしてください。セッション終了時に `Raw JSON`、`training_examples.jsonl`、Create ML向けの `recording.csv` / `annotations.csv`、GUI用の `CreateMLActivityData/<label>/*.csv` をiPhone内のDocumentsへ保存し、レビュー画面の共有ボタンからAirDropやFilesへ渡せます。

### Web / Next.js

```bash
npm run dev:collect
```

ブラウザで `http://localhost:3000/collect/start` を開きます。iOS の DeviceMotionEvent はユーザー操作から許可を求める必要があるため、開始前またはセッション画面で「センサー」を押してください。

MVPの保存先は `apps/collect-web/.data/collection-store.json` です。Cloud Run / Firestore へ載せ替える場合は `apps/collect-web/src/lib/store.ts` の実装を差し替えます。
