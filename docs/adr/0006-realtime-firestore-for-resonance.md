# ADR-0006: 共鳴マッチング・DM に Firestore 直リアルタイム購読を採用

- **ステータス**: 採用済み
- **決定日**: 2026-05-26
- **決定者**: Team 10

## 背景

How Resonance では「同じ瞬間に反応した他者がリアルタイムに現れる」「その相手と即時 DM できる」体験が価値の中心になる。
既存方針（ADR-0002）では iOS は Firestore に直接書き込まず Functions API 経由で how-cards を扱い、Firestore 直アクセスは `users/{uid}` の read/write のみに限定していた。

しかしマッチングと DM は**リアルタイム性**が体験の肝であり、ポーリングでは「ふっと現れて火がつく」UX が成立しない。

## 検討した選択肢

| 選択肢 | メリット | デメリット |
|---|---|---|
| **Firestore 直 `addSnapshotListener`（採用）** | 真のリアルタイム。実装が素直。FirebaseFirestore は既にリンク済み（UserProfileService に前例） | クライアントが Firestore を直接読む経路が増える。rules 設計が必要 |
| Functions API + ポーリング | 既存の Functions-only 方針を維持 | リアルタイムにならない。共鳴演出・DM の体験が死ぬ。ポーリング負荷 |
| Functions + WebSocket/SSE | リアルタイム化可能 | 実装コスト大。ハッカソン期間に間に合わない |

## 決定

**マッチング購読と DM は Firestore を直接 `addSnapshotListener` で購読する。**

- **読み取り（リアルタイム）**: iOS が直接 Firestore を購読
  - `how-cards`（同 `song_id` のマッチング）
  - `conversations/{cid}/messages`（DM）
- **書き込み**:
  - how-cards の作成は従来通り **Functions API 経由**（admin 権限・契約維持、ADR-0002 を踏襲）
  - DM メッセージは体験上の即時性が必須なので **Firestore 直書き込み**（楽観的更新）。`conversations` は参加者のみに rules で限定
- セキュリティは Firestore rules で担保（how-cards は認証済み read、conversations は参加 uid のみ read/write）

## 結果

- 「同じ瞬間に反応した人がリアルタイムに現れて火がつく」「即 DM できる」体験が技術的に成立する
- 既存の how-cards **書き込み**契約（Functions 経由）は壊さない＝ADR-0002 の方針と両立
- 直アクセスの増加分は rules で最小権限に絞り、漏洩面を限定する
- デモは Firestore に seed した mock ユーザーを実機が購読する構成で、複数実機が無くても成立する

## 関連
- ADR-0002（バックエンドプロキシで AI / 秘匿情報を扱う）: how-cards 書き込みは引き続き踏襲
- データモデル: `docs/data-model.md`（conversations は本 ADR で追加）
