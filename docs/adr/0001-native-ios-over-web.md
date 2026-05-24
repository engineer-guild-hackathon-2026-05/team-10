# ADR-0001: Web ではなくネイティブ iOS を選択する

- **ステータス**: 採用済み
- **決定日**: 2026-05-22
- **決定者**: Team 10

## 背景

HowTune は「身体的な反応」を音楽体験のコアに置くプロダクトである。
ユーザーが音楽を聴いている最中のリアルタイムデータとして、以下を取得する必要があった。

- AirPods の頭部モーションセンサー（CoreMotion）
- Apple Watch / iPhone の心拍データ（HealthKit）
- Apple Music の再生位置（MusicKit）

## 検討した選択肢

| 選択肢 | メリット | デメリット |
|---|---|---|
| **ネイティブ iOS (SwiftUI)** | CoreMotion・HealthKit・MusicKit に直接アクセス可能 | 開発コストが高い |
| React Native | クロスプラットフォーム | CoreMotion の低レイヤーAPIへのアクセスが困難 |
| Progressive Web App | デプロイが容易 | センサーAPIへのアクセス不可 |

## 決定

**ネイティブ iOS (Swift / SwiftUI)** を採用する。

プロダクトの差別化軸である「身体的モメンタムの可視化」は、CoreMotion・HealthKit へのネイティブアクセスなしには実現不可能であると判断した。

## 結果

- AirPods の加速度・ジャイロスコープデータをリアルタイムで取得できる
- HealthKit 経由で心拍トレンドを取得できる
- MusicKit で Apple Music の再生位置と同期できる
- 開発期間がハッカソン期間（2日）に限られるため、チームの Swift 習熟度を最優先した
