# ADR-0005: AirPods センサーを補助機能に降格し、音量ベース Groove メーターをメイン指標にする

- **ステータス**: 採用済み
- **決定日**: 2026-05-25
- **決定者**: Team 10

## 背景

初期設計（ADR-0001・`frontend-spec.md`）では AirPods の頭部モーション（CMHeadphoneMotionManager）と心拍（HealthKit）をプロダクトのコア差別化軸として位置づけていた。

しかし実装・実機検証を通じて以下の問題が明らかになった：

- `CMHeadphoneMotionManager` の対応機種が限定的で、ハッカソン参加者全員が対応 AirPods を持っているわけではない
- HealthKit 心拍の取得粒度が粗く、曲中の秒単位の変化を反映できない
- 「AirPods を付けながら音楽を聴く → 頭を振る → センサー取得」というデモ前提が、会場での発表に適さない（発表者が AirPods をつけ続ける必要がある）
- MVP のコア体験（歌詞 × AI 対話 → HowCard）は AirPods なしでも完全に成立する

## 検討した選択肢

| 選択肢 | メリット | デメリット |
|---|---|---|
| **音量ベース Groove メーター（採用）** | AirPods 不要。誰でも体験できる。実装が確実 | 身体反応の精度は低い |
| AirPods を必須のまま維持 | 差別化ナラティブを維持できる | デモ失敗リスクが高い |
| AirPods をオプション扱い（今回の決定に近い） | 両立できる | UI・フローの複雑度が上がる |

## 決定

**AirPods センサーを「利用可能であれば補助として使う」位置づけに降格する。**

MVP のメイン Groove 指標は以下の計算式で算出する：

```swift
// grooveLevel: 0.0 〜 1.0
let pulse = 0.58
    + 0.20 * sin(playbackTime * 2.4)   // 低周期の揺らぎ
    + 0.12 * sin(playbackTime * 5.2)   // 高周波の揺らぎ
let grooveLevel = min(max(Double(outputVolume) * 0.42 + pulse * 0.58, 0.08), 1.0)
```

- **音量（outputVolume）**: ユーザーが音楽にのめり込むほど音量を上げる行動と相関
- **再生時刻の sine 波**: 曲の展開に連動した疑似的な盛り上がり表現

AirPods が接続されている場合は `HeadphoneMotionService` がバックグラウンドで取得を試み、
将来の高精度版で Groove 計算に組み込む（フライホイール設計、ADR-0003 参照）。

## 結果

- AirPods の有無に関係なく全員がデモを体験できる（FR-ONB-03 / P4 準拠）
- `grooveInsightSection` の Groove % バー + 音量表示が常に動作する
- センサー状態バー（`sensorStatusBar`）は残し、AirPods 接続状態を可視化する
- HowCard 生成フローは AirPods に依存しないため、発表当日のリスクを排除できる

## 影響する仕様

- `frontend-spec.md`: 対象プラットフォーム節の「AirPods の頭部モーション・心拍が主シグナル」という記述を修正
- `product-requirements.md`: コア機能の筆頭から AirPods を外し「iPhone 本体モーション + 音量」をメインに
- `frontend-spec.md` NFR-01: AirPods を必須機種として列挙しない（あれば使う）

## 将来への接続

AirPods センサーは捨てない。データフライホイール（ADR-0003）の高精度フェーズで：

```
音量ベース Groove（MVP）
  → AirPods 頭部モーション補完（Phase 1）
  → 個人校正モデル（Phase 2）
```

という段階的な精度向上パスを維持する。
