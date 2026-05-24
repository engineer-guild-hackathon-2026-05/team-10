# HowTune TensorFlow Specs

- `01_sdd_prompt_motion_reaction_model.md`
- `02_training_data_collection_app_spec.md`

---

# 01_sdd_prompt_motion_reaction_model.md

```md
# SDD Prompt: HowTune Motion Reaction Model

あなたは、ハッカソン向けプロダクト **HowTune** のAI/ML設計を支援する、シニアMLエンジニア兼テックリードです。

## 目的

HowTuneは、音楽を聴いているユーザーのスマホ加速度データから、曲中のどの時間帯で身体反応が強まったかを検出し、その反応を起点にLLMがユーザーへ問いかけることで、ユーザーの「音楽の楽しみ方」を共有可能な形にするプロダクトです。

今回あなたに設計してほしいのは、以下のうち **1. 反応検出モデル** のみです。

1. スマホセンサーから身体反応を検出するTensorFlow.jsモデル
2. 反応箇所をもとに質問を生成するLLM
3. ユーザー回答からHowカードを生成するLLM

2と3は別途LLMで実装するため、ここでは扱いません。

---

## 背景仮説

音楽の楽しみ方は、曲名・アーティスト名・ジャンルのようなWhatだけでは表現しきれません。

ユーザーは次のようなHowを持っています。

- ベースラインで身体が動く
- サビ前の溜めでテンションが上がる
- チルい揺れに浸る
- 一瞬のフレーズに刺さる
- 曲終わりの余韻で静かになる

HowTuneでは、ユーザーに最初から言語化を求めるのではなく、スマホの動きから「ここで反応していたかもしれない」という候補を出し、そこから会話で掘ります。

---

## 作りたいモデル

### モデル名

`MotionReactionClassifier`

### モデルの役割

スマホの加速度時系列データから、短い時間窓ごとに音楽聴取中の身体反応状態を推定する。

### 入力

1〜3秒の時間窓から抽出した特徴量ベクトル。

```ts
type MotionFeatures = {
  meanMagnitude: number;
  stdMagnitude: number;
  meanDelta: number;
  maxDelta: number;
  energy: number;
  peakCount: number;
  rhythmRegularity: number;
  stillness: number;
  previousEnergyDiff: number;
  windowDurationSec: number;
};
```

### 出力

6軸のマルチラベルスコア。

```ts
type ListeningStateScores = {
  groove: number;      // ノリ。リズムに身体が同期している
  hype: number;        // 高揚。サビや展開でテンションが上がっている
  chill: number;       // チル。小さく心地よく揺れている
  immersion: number;   // 没入。動きは少ないが集中して聴いている可能性
  hit: number;         // 刺さり。一瞬の音・歌詞・展開に反応
  afterglow: number;   // 余韻。動いた後に静かになる
};
```

出力はsoftmaxの単一分類ではなく、sigmoidのマルチラベルにしてください。理由は、`groove` と `hype` のように同時成立する状態があるためです。

---

## 分類ラベル定義

### 1. groove / ノリ

リズムに合わせて周期的に身体が揺れている状態。

センサー特徴の例:

- 周期性が高い
- 中程度のenergyが継続
- peakCountが一定
- maxDeltaは極端に高くない

### 2. hype / 高揚

サビ、ドロップ、展開変化などでテンションが上がっている状態。

センサー特徴の例:

- energyが高い
- maxDeltaが高い
- stdMagnitudeが高い
- 短時間でpreviousEnergyDiffが大きい

### 3. chill / チル

大きくは動かないが、小さく心地よい揺れが続いている状態。

センサー特徴の例:

- energyは低〜中
- rhythmRegularityがやや高い
- maxDeltaは低い
- stillnessは高すぎない

### 4. immersion / 没入

身体はあまり動いていないが、静かに聴き入っている可能性がある状態。

センサー特徴の例:

- energyが低い
- peakCountが少ない
- stillnessが高い

注意: センサーだけでは「退屈」と区別できないため、これは断定せずLLM質問の起点として扱う。

### 5. hit / 刺さり

一瞬の音、歌詞、押韻、展開、ブレイクなどに短く反応した状態。

センサー特徴の例:

- maxDeltaが高い
- peakCountは少ない
- durationが短い
- previousEnergyDiffが大きい

### 6. afterglow / 余韻

直前まで動きがあった後、曲終盤や展開後に静かになる状態。

センサー特徴の例:

- 直前windowのenergyが高い
- 現windowのenergyが低い
- stillnessが高い
- 曲のsectionがoutroやpost-chorusなら補助情報として有効

---

## 非目標

以下は今回のモデルの責務ではありません。

- ユーザーが本当に楽しいかを断定する
- 曲のジャンルを分類する
- ベース、歌詞、押韻などの音楽的要因をセンサーだけで断定する
- SpotifyやApple Musicの音源解析を行う
- LLMの質問生成やHowカード生成をモデル内に含める

モデルはあくまで、LLM対話のための「身体反応候補」を出すものです。

---

## 推奨技術構成

- Frontend: Next.js
- Sensor capture: DeviceMotionEvent
- Backend: Node.js on Cloud Run
- ML: TensorFlow.js / `@tensorflow/tfjs-node`
- Training: Node.js script or local notebook
- Model format: TensorFlow.js LayersModel
- Storage: Firestore or Cloud Storage

---

## 実装してほしい成果物

以下のファイル構成を想定して、設計とコードを出してください。

```txt
packages/ml/
  src/
    features.ts
    model.ts
    train.ts
    evaluate.ts
    predict.ts
    schema.ts
  models/
    motion-reaction-v1/
      model.json
      weights.bin
  data/
    examples.jsonl
```

---

## データ形式

### 生センサーデータ

```ts
type MotionSample = {
  t: number;      // 曲開始からの秒数
  ax: number;
  ay: number;
  az: number;
  gx?: number;
  gy?: number;
  gz?: number;
};
```

### ラベル付き学習データ

```ts
type TrainingExample = {
  id: string;
  sessionId: string;
  songId: string;
  windowStart: number;
  windowEnd: number;
  features: number[];
  labels: {
    groove: 0 | 1;
    hype: 0 | 1;
    chill: 0 | 1;
    immersion: 0 | 1;
    hit: 0 | 1;
    afterglow: 0 | 1;
  };
  meta: {
    device?: string;
    userAgent?: string;
    songSection?: string;
    bpm?: number;
  };
};
```

---

## 特徴量抽出仕様

1. `magnitude = sqrt(ax^2 + ay^2 + az^2)` を計算
2. `delta = abs(magnitude[t] - magnitude[t-1])` を計算
3. 1〜3秒のsliding windowに分割
4. windowごとに以下を計算
   - meanMagnitude
   - stdMagnitude
   - meanDelta
   - maxDelta
   - energy = sum(delta^2)
   - peakCount
   - rhythmRegularity
   - stillness
   - previousEnergyDiff
   - windowDurationSec
5. セッション内正規化を行う

### rhythmRegularityの簡易実装

MVPではFFTまでやらず、peak間隔の分散から周期性を推定してください。

```txt
rhythmRegularity = 1 - normalizedVariance(peakIntervals)
```

ピークが少なすぎる場合は0にする。

---

## モデル構造

最初は軽量なDenseモデルでよい。

```ts
const model = tf.sequential();
model.add(tf.layers.dense({ inputShape: [10], units: 32, activation: 'relu' }));
model.add(tf.layers.dropout({ rate: 0.2 }));
model.add(tf.layers.dense({ units: 16, activation: 'relu' }));
model.add(tf.layers.dense({ units: 6, activation: 'sigmoid' }));
```

### loss

`binaryCrossentropy`

### metrics

- binaryAccuracy
- labelごとのprecision / recall / F1をevaluate.tsで算出

---

## 推論API仕様

### Endpoint

`POST /api/motion/predict`

### Request

```json
{
  "sessionId": "session_001",
  "songId": "song_001",
  "samples": [
    { "t": 0.1, "ax": 0.2, "ay": 1.1, "az": 9.7 }
  ]
}
```

### Response

```json
{
  "sessionId": "session_001",
  "songId": "song_001",
  "windows": [
    {
      "start": 72,
      "end": 75,
      "scores": {
        "groove": 0.82,
        "hype": 0.61,
        "chill": 0.08,
        "immersion": 0.14,
        "hit": 0.44,
        "afterglow": 0.02
      },
      "topLabels": ["groove", "hype"]
    }
  ],
  "reactionCandidates": [
    {
      "start": 72,
      "end": 81,
      "peakTime": 76.5,
      "primaryState": "groove",
      "scores": {
        "groove": 0.86,
        "hype": 0.72
      }
    }
  ]
}
```

---

## UX上の言い方

モデルの出力をユーザーに断定的に見せないでください。

悪い例:

- 「あなたはここで楽しかったです」
- 「ここでベースに反応しました」

良い例:

- 「1:16あたりで身体が反応していました」
- 「ここで少しノっていたように見えます」
- 「リズムに乗っていた感じですか？それとも展開で上がりましたか？」

---

## 評価方針

### MVP評価

- 反応がある区間を上位3つ出せるか
- ユーザーが「たしかにそこ反応した」と思えるか
- LLM質問の起点として自然か

### 定量評価

- Multi-label F1
- label別Precision / Recall
- Top-2 accuracy
- 人手ラベルとの時間窓IoU

### 目標値

ハッカソンMVPでは以下を目安にする。

- Top-2 accuracy: 0.65以上
- groove / hype / hit のF1: 0.60以上
- immersion / afterglow は参考値でOK

---

## 注意点

- iOSではDeviceMotionEventのpermissionが必要な場合がある
- HTTPS環境で動かす
- 端末差が大きいため、セッション内正規化を必須にする
- ユーザーがスマホを机に置く場合と手に持つ場合を区別する
- 「没入」と「退屈」はセンサーだけでは区別不能なので、LLM対話で確認する

---

## 出力してほしいもの

以下を順番に出力してください。

1. モデル設計の要約
2. データスキーマ
3. 特徴量抽出コード
4. TensorFlow.jsモデル定義コード
5. training script
6. evaluation script
7. prediction APIの実装例
8. モデル出力をLLMに渡すためのJSON例
9. ハッカソンでのデモシナリオ
10. リスクと割り切り
```

---

# 02_training_data_collection_app_spec.md

```md
# Spec: HowTune Training Data Collection App

## 1. 概要

このアプリは、HowTuneの **MotionReactionClassifier** を学習するための教師データを収集するWebアプリです。

ユーザーはスマホで音楽を聴きながら、身体の反応に近い状態をボタンでラベル付けします。アプリは同時にスマホの加速度データを取得し、曲のタイムラインとラベルを紐づけて保存します。

---

## 2. 目的

### 解決したいこと

スマホの加速度データだけでは、身体反応がどの聴取状態に対応するか判断しにくい。

そのため、ユーザー自身にリアルタイムで状態ラベルを付けてもらい、以下を対応づける。

```txt
センサー時系列 + 曲中タイムスタンプ + ユーザーラベル
```

これにより、TensorFlow.jsで学習可能な教師データを作る。

---

## 3. 対象ユーザー

### Primary

- ハッカソン参加者
- チームメンバー
- 会場でテストに協力してくれる人

### Secondary

- 音楽好きの初期ユーザー
- 自分の音楽の楽しみ方を言語化したい人

---

## 4. 収集するラベル

MVPでは以下の6ラベルを収集する。

| ラベル | 表示名 | 説明 |
|---|---|---|
| groove | ノってる | リズムに身体が合っている |
| hype | 上がった | テンションが上がった |
| chill | チルい | ゆるく心地よく聴いている |
| immersion | 聴き入ってる | 静かに集中している |
| hit | 刺さった | 一瞬の音・歌詞・展開に反応した |
| afterglow | 余韻 | 反応後に味わっている |

### 補助ラベル

- unknown / わからない
- noise / 操作ミス・ノイズ
- phone_on_table / スマホを置いていた

---

## 5. 主要体験

### 5.1 セッション開始

ユーザーは以下を選択して開始する。

- 曲
- スマホの持ち方
  - 手に持つ
  - 机に置く
  - ポケットに入れる
- 利き手
- 音楽の聴き方の事前自己申告
  - 普段から身体を動かす
  - あまり動かない
  - 曲による

### 5.2 センサー許可

アプリはDeviceMotionEventの利用許可を要求する。

許可が取れない場合は、タップラベルだけのモードに切り替える。

### 5.3 音楽再生

アプリ内でサンプル曲を再生する。

MVPでは著作権リスクを避けるため、以下のどちらかにする。

1. 著作権フリー音源
2. チームが用意した短いデモ音源

### 5.4 リアルタイムラベル入力

曲を聴きながら、ユーザーは状態に近いボタンを押す。

ボタン例:

- ノってる
- 上がった
- チルい
- 聴き入ってる
- 刺さった
- 余韻

ボタンを押した時刻の前後を教師データ化する。

推奨window:

- `hit`: タップ前後1.5秒
- `hype`: タップ前2秒〜後5秒
- `groove`: 押している間、またはタップ前後5秒
- `chill`: 押している間、またはタップ前後5秒
- `immersion`: 押している間
- `afterglow`: タップ前2秒〜後6秒

### 5.5 セッション後確認

再生終了後に、反応区間をタイムラインで表示する。

ユーザーは以下を修正できる。

- ラベル削除
- ラベル変更
- 区間の開始・終了調整
- ノイズ区間の指定

---

## 6. 画面仕様

### 6.1 `/collect/start`

目的: セッション開始前の設定。

要素:

- 曲選択
- スマホの持ち方選択
- 普段の聴き方選択
- センサー許可ボタン
- 開始ボタン

### 6.2 `/collect/session/:sessionId`

目的: 音楽再生とセンサー・ラベル収集。

要素:

- 曲タイトル
- 再生・停止ボタン
- 経過時間
- 簡易波形またはタイムバー
- 6つのラベルボタン
- センサー取得状態
- 現在の加速度強度表示

UX:

- 片手で押しやすい大きなボタン
- 誤タップしても後で消せる
- ラベルボタンは色分け
- 「迷ったら押さなくてOK」と表示

### 6.3 `/collect/review/:sessionId`

目的: 収集データの確認・修正。

要素:

- タイムライン
- ラベル区間
- センサー強度グラフ
- ラベル編集
- 保存ボタン
- JSON exportボタン

### 6.4 `/admin/datasets`

目的: 開発者向けデータ確認。

要素:

- セッション一覧
- ユーザー数
- ラベル別件数
- データダウンロード
- ノイズ率

---

## 7. データスキーマ

### Collection: `sessions`

```ts
type Session = {
  id: string;
  userId: string;
  songId: string;
  startedAt: string;
  endedAt?: string;
  device: {
    userAgent: string;
    platform?: string;
    screenWidth?: number;
    screenHeight?: number;
  };
  listeningContext: {
    phonePosition: 'hand' | 'table' | 'pocket';
    dominantHand?: 'right' | 'left' | 'unknown';
    usualMovement: 'active' | 'still' | 'depends';
  };
};
```

### Collection: `motion_samples`

大量データになるため、Firestoreに直接細かく入れすぎない。MVPではsessionごとに圧縮して保存する。

```ts
type MotionSampleBatch = {
  sessionId: string;
  chunkIndex: number;
  samples: MotionSample[];
};

type MotionSample = {
  t: number;
  ax: number;
  ay: number;
  az: number;
  gx?: number;
  gy?: number;
  gz?: number;
};
```

### Collection: `labels`

```ts
type LabelEvent = {
  id: string;
  sessionId: string;
  label: 'groove' | 'hype' | 'chill' | 'immersion' | 'hit' | 'afterglow' | 'noise' | 'unknown';
  startedAtSec: number;
  endedAtSec: number;
  source: 'realtime_button' | 'review_edit';
  confidence?: 1 | 2 | 3;
};
```

### Export形式: `training_examples.jsonl`

```json
{"id":"ex_001","sessionId":"s_001","songId":"song_001","windowStart":72,"windowEnd":75,"features":[0.1,0.2,0.3],"labels":{"groove":1,"hype":0,"chill":0,"immersion":0,"hit":1,"afterglow":0},"meta":{"phonePosition":"hand","songSection":"chorus"}}
```

---

## 8. API仕様

### `POST /api/collect/session`

セッションを作成する。

Request:

```json
{
  "songId": "song_001",
  "phonePosition": "hand",
  "usualMovement": "depends"
}
```

Response:

```json
{
  "sessionId": "session_001"
}
```

### `POST /api/collect/motion`

センサーデータをチャンク単位で保存する。

Request:

```json
{
  "sessionId": "session_001",
  "chunkIndex": 0,
  "samples": [
    { "t": 0.1, "ax": 0.2, "ay": 1.1, "az": 9.7 }
  ]
}
```

### `POST /api/collect/label`

ラベルイベントを保存する。

Request:

```json
{
  "sessionId": "session_001",
  "label": "groove",
  "startedAtSec": 72.0,
  "endedAtSec": 78.0,
  "source": "realtime_button"
}
```

### `POST /api/collect/review`

レビュー後の修正済みラベルを保存する。

### `GET /api/admin/export?format=jsonl`

特徴量抽出済みの学習データをJSONLで返す。

---

## 9. 特徴量生成仕様

サーバー側で以下を行う。

1. sessionのmotion samplesを取得
2. label eventsを取得
3. 1〜3秒windowを作る
4. windowごとに特徴量を抽出
5. label overlapに基づいてmulti-hot labelを付与
6. JSONLでexport

### ラベル付与ルール

windowとlabel eventの重なりが50%以上なら1。

```txt
overlap(window, labelEvent) / windowDuration >= 0.5
```

`hit` は短いラベルなので、重なりが30%以上でも1にしてよい。

---

## 10. 学習データ収集計画

### 最小目標

- 被験者: 10人
- 曲数: 3曲
- 1人あたり: 3セッション
- 合計: 30セッション
- 1セッション: 60〜90秒

### 期待データ量

3秒window / stride 1秒の場合:

```txt
30 sessions × 70 windows = 2,100 examples
```

ハッカソンMVPとしては十分。

### ラベル偏り対策

- hype / grooveに偏りやすい
- immersion / afterglowは少なくなりやすい
- チル系の曲を必ず1曲入れる
- 曲終盤で余韻ラベルを押してもらう説明を入れる

---

## 11. サンプル曲設計

MVPでは3タイプの曲を用意する。

### Track A: Groove track

目的: grooveを集める。

特徴:

- BPM 90〜110
- ベースとドラムがわかりやすい
- 継続的なリズム

### Track B: Hype / Drop track

目的: hypeとhitを集める。

特徴:

- サビ前の溜め
- ドロップ
- 急な展開変化

### Track C: Chill / Afterglow track

目的: chill, immersion, afterglowを集める。

特徴:

- ゆっくり
- 音数少なめ
- 余韻がある

---

## 12. プライバシーと同意

### 収集するもの

- 加速度データ
- 曲中時刻
- ユーザーが押したラベル
- 端末情報の一部

### 収集しないもの

- 位置情報
- マイク音声
- 連絡先
- 顔写真
- 実名

### 同意文言

> このアプリは、音楽を聴いているときのスマホの動きと、あなたが押したラベルを研究・開発目的で保存します。マイク音声や位置情報は取得しません。データはHowTuneの反応検出モデル改善にのみ使います。

---

## 13. 成功条件

### 機能面

- スマホでセンサー許可が取れる
- 曲再生とセンサー時刻が同期する
- ラベルボタンを押すと時刻付きで保存される
- セッション後に修正できる
- JSONLでexportできる

### データ面

- 30セッション以上集まる
- 各ラベル100window以上集まる
- noise率が20%以下

### モデル接続面

- exportデータを`train.ts`に食わせられる
- 学習後、`predict.ts`で6軸スコアが出る

---

## 14. MVPで捨てるもの

- Spotify連携
- Apple Music連携
- 本物の歌詞同期
- 高精度なBPM解析
- ユーザー認証の厳密化
- リアルタイム推論
- 複雑なダッシュボード

---

## 15. 実装優先順位

### P0

- センサー取得
- 音楽再生
- ラベルボタン
- センサー・ラベル保存
- JSON export

### P1

- レビュー画面
- ラベル修正
- 特徴量抽出
- label別件数表示

### P2

- 管理画面
- 曲ごとの集計
- 端末差分析
- データ品質スコア

---

## 16. デモシナリオ

1. 審査員がスマホでアプリを開く
2. センサー許可を出す
3. 60秒のサンプル曲を再生する
4. 聴きながら「ノってる」「上がった」「刺さった」を押す
5. 終了後、タイムラインに反応ラベルが表示される
6. Exportされたデータがモデル学習に使われることを示す
7. 学習済みモデルで別セッションの反応を予測する

---

## 17. リスク

| リスク | 対策 |
|---|---|
| センサー許可が取れない | タップラベルのみモードを用意 |
| ラベルが主観的 | 主観を前提にし、LLM対話の起点にする |
| 被験者が少ない | チーム内・会場で短時間セッションを回す |
| ラベル偏り | 曲タイプを分ける |
| スマホの持ち方で差が出る | phonePositionを必ず保存 |
| 音源著作権 | 自作または著作権フリー音源に限定 |

---

## 18. 開発メモ

- iOSではセンサー許可はユーザー操作から呼ぶ
- HTTPS必須
- `HTMLAudioElement.currentTime` または `AudioContext.currentTime` を使って曲中時刻を記録する
- センサー取得頻度は20〜60Hz程度で十分
- 保存は1秒ごとではなく数秒ごとにchunk化する
- Firestoreに生データを細かく書き込みすぎない
```

