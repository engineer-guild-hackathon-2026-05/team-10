# タスクリスト

## フェーズ1: 調査と設計

- [x] MusicKit / Core Motion / Accelerate の実装可能範囲を確認する
- [x] `SyncBeat` 命名の残存箇所と Home 波形構成を確認する
- [x] 実装方針を requirements/design に記録する

## フェーズ2: 波形・モーション実装

- [x] `SyncBeatCircularWaveformView` を `AirPodsReactiveWaveformView` に置き換える
- [x] vDSP FFT ベースの `AudioMotionSpectrumAnalyzer` を追加する
- [x] AirPods サンプルから UI 用の movement intensity を算出する
- [x] Home 再生状態と AirPods モーション取得を接続する
- [x] AirPods の動きに応じたパーティクル描画を追加する
- [x] AirPods の動きに応じて波形色を3状態で切り替える
- [x] iOS の `ReactionScore` / `HowTag` を `groove/chill/neutral` に整理する
- [x] 6軸分類前提の docs を3状態分類へ更新する

## フェーズ3: 仕上げと検証

- [x] `SyncBeat` 命名が iOS 実装から消えていることを確認する
- [x] Xcode ビルドを実行して修正する
- [x] AI_USAGE_LOG.md に今回の作業を追記する
- [x] 実装後の振り返りを記録する

## 振り返り

- MusicKit は再生状態や `playbackTime` は扱える一方、Apple Music ストリームのPCMやスペクトラムをアプリに渡すAPIではないため、実音声FFTではなく再生時刻・トラック種・モーションを使った vDSP FFT 表現にした。
- AirPods のモーションは `CMHeadphoneMotionManager` 経由で取得し、直近サンプルの強度を波形の大きさ、色、パーティクル量へ反映する構成にした。
- 6軸分類を廃止し、iOS 実装、docs、`ai-recognition` のメタデータを `groove` / `chill` / `neutral` の3状態へそろえた。
- 波形とパーティクルは Metal 描画へ移行し、頂点バッファ経由でリングと sparkle を描画する構成にした。MusicKit の PCM 制約により、スペクトラム自体は引き続き再生時刻・トラック種・モーションから生成している。
