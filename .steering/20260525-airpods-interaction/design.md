# 設計: AirPods 連動ビジュアライザー

## 実装方針

### MusicKit の制約

公式 API で確認できる範囲では、`ApplicationMusicPlayer` は `queue.currentEntry` と `playbackTime` を提供する。一方で Apple Music 再生中の raw audio samples / PCM buffer / spectrum は MusicKit から公開されていない。そのため、Home の波形は実音源 FFT ではなく、以下の入力を組み合わせた合成スペクトラムとして実装する。

- MusicKit の再生位置 (`playbackTime`)
- 選択曲 ID / タイトル / アーティストから作る seed
- 端末音量
- AirPods 頭部モーション intensity

### 波形生成

`AudioMotionSpectrumAnalyzer` を追加し、64 サンプルの合成 time-domain signal を生成する。複数の sine oscillator と beat envelope を重ね、`Accelerate/vDSP` の FFT で周波数成分へ変換する。変換結果を 64 点の円形波形 amplitude として使う。

### AirPods 連動

`AirPodsMotionSample` に `interactionIntensity` を追加する。加速度と回転速度から 0...1 の値を作り、Home の `AirPodsReactiveWaveformView` へ渡す。

`HomeView` は曲が再生中でプレビューではない場合に `AirPodsMotionViewModel.start(playbackPositionProvider:)` を呼ぶ。停止・画面離脱時は `stop()` する。

### 3状態分類と色

ai-recognition は MVP の分類対象を `groove/chill/neutral` に絞っている。iOS 側も6軸展開をやめ、`ReactionScore` と `HowTag` は同じ3状態だけを扱う。

Home 波形は AirPods の `interactionIntensity` から3状態を推定し、状態ごとの色だけで反応を示す。状態名のテキスト表示は行わない。

### Metal 波形・パーティクル描画

`AirPodsReactiveWaveformView` は iOS では `MTKView` を SwiftUI にブリッジし、`MetalWaveformRenderer` が波形リングとパーティクルを描画する。リングと sparkle は CPU 側で頂点列を生成し、shared `MTLBuffer` をローテーションして `setVertexBuffer` で渡す。

パーティクルは motion intensity が一定値を超えた時だけ発生させる。粒子は寿命・速度・角速度を持ち、波形リングの外側へ散る。色は `groove/chill/neutral` のパレットをゆっくり補間する。

MusicKit の PCM 制約により、FFT 入力は引き続き再生位置・曲 seed・音量相当値・AirPods motion から作る合成信号とする。Metal は合成済み amplitude の描画負荷を下げる目的で使う。
