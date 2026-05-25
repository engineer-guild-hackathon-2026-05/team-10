# 設計: How Resonance

## アーキテクチャ概要

```
[AirPods] → AirPodsMotionViewModel(samples)
                │ interactionIntensity のピークを追跡
                ▼
        PeakMotionTracker → PeakMoment(playbackTime, intensity)
                │
                ▼ 1回目（決めうち固定文）
        HowResonancePromptBuilder.firstPrompt(peak) → 固定 question/choices
                │ ユーザー回答
                ▼ 2回目（LLM）
        ChatAPIClient.chat()（既存）→ 深掘り → コメント
                │
                ▼ Howカード投稿（既存 FirebaseAPI / Functions）
        how-cards/{id}: song_start/end, song_id, user_id ...
                │
                ▼ リアルタイム購読（新規・Firestore直）
        ResonanceMatchService（Firestore listener: how-cards where song_id==）
                │ ±2.5s で同地点/別地点を判定
                ▼
        ResonanceMatchView（同地点🔥 / 別地点）+ QuantumIgnitionView（演出）
                │ 🔥タップ
                ▼ リアルタイム DM（新規・Firestore直）
        ResonanceChatService（conversations/{id}/messages listener）
                │
                ▼
        ResonanceDMView（楽観的更新 + スナップショット購読）
```

## 新規コンポーネント

### iOS

| ファイル | 役割 |
|---|---|
| `Features/Resonance/Models/PeakMoment.swift` | ピーク地点（playbackTime, intensity） |
| `Features/Resonance/Services/PeakMotionTracker.swift` | samples からピークを抽出（純ロジック・テスト可） |
| `Features/Resonance/Services/HowResonancePromptBuilder.swift` | 1回目の決めうち問いかけ生成 |
| `Features/Resonance/Models/ResonanceReactor.swift` | マッチング相手（uid, displayName, spotSec, isSameSpot, comment） |
| `Features/Resonance/Services/ResonanceMatchService.swift` | Firestore `how-cards` 購読 → 同地点/別地点判定 |
| `Features/Resonance/ViewModels/ResonanceMatchViewModel.swift` | マッチ状態の保持・🔥判定 |
| `Features/Resonance/Views/ResonanceMatchView.swift` | 同地点🔥/別地点の表示 + 演出ホスト |
| `Features/Resonance/Views/QuantumIgnitionView.swift` | 量子→摩擦→発火の演出（Canvas/TimelineView、確実版） |
| `Features/Resonance/Models/ResonanceMessage.swift` | DM メッセージ（id, senderId, text, createdAt） |
| `Features/Resonance/Services/ResonanceChatService.swift` | `conversations/{id}/messages` 購読・送信（楽観的更新） |
| `Features/Resonance/ViewModels/ResonanceDMViewModel.swift` | DM 状態管理 |
| `Features/Resonance/Views/ResonanceDMView.swift` | DM 画面（Apple ネイティブ調） |

### Firestore（直アクセス・新規購読）

- 既存 `how-cards` をリアルタイム購読（read のみ）。書き込みは引き続き Functions 経由。
- 新規 `conversations/{conversationId}` + `conversations/{conversationId}/messages/{messageId}`
  - conversationId = ソートした uid ペア（`uidA__uidB`）で一意化。
  - message: `{ sender_id, text, created_at }`

### Firestore rules（追加）
- `how-cards`: 認証済みユーザーは read 可（マッチング購読用）。write は従来通り Functions(admin) のみ。
- `conversations/{cid}`: `request.auth.uid` が cid に含まれる場合のみ read/write。messages も同様。

### バックエンド/Functions
- 既存 `GET /how-cards?song_id=` / `POST /how-cards` をそのまま利用。新規エンドポイントは作らない（リアルタイムは Firestore 直購読で実現）。
- seed 用 Node スクリプト `functions/scripts/seed-resonance.js`（admin SDK）で mock how-cards 2件を投入。

## 同地点判定ロジック
- 自分の Howカード `[start, end]` と他者の `[start, end]` が **±2.5 秒のマージン込みで重なる**なら同地点（🔥）。
- それ以外は別地点。判定は `ResonanceMatchService` 内の純関数 `isSameSpot(_:_:margin:)`。

## 演出設計（QuantumIgnitionView・確実版）
- `TimelineView(.animation)` + `Canvas` で実装（Metal 非依存で確実にビルド）。
- フェーズ: ①量子ゆらぎ（粒子がランダムに出現・微振動）→ ②収束（粒子が中心へ）→ ③摩擦発熱（色温度上昇・グロー）→ ④発火（炎パーティクル放射 + 🔥）。
- `ResonanceVisualConfig.richMode`（Bool）でリッチ版/控えめ版を切替可能に。デフォルトは確実に動く範囲。

## 既存への接続（非破壊）
- `AirPodsMotionViewModel` に `peakMoment` 算出を**追加**（既存 API 不変）。
- HowChat への 1回目固定文は `HowResonancePromptBuilder` を新設して注入。既存 `ChatAPIClient.mockResponse`/backend は不変。
- マッチング/DM 画面は新規。既存画面からの導線は最小の追加（Howカード投稿完了後に `ResonanceMatchView` を提示）。

## データフロー（リアルタイム）
1. 投稿 → Functions が how-cards に書き込み
2. `ResonanceMatchService` が同 song_id の how-cards を `addSnapshotListener` で購読 → 変更が即時反映
3. seed 済みの2件（同地点1・別地点1）が現れる
4. 🔥タップ → conversationId を生成 → `ResonanceChatService` が messages を購読 → DM 開始
