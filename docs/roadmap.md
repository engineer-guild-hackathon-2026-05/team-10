# HowTune ロードマップ / バックログ

「次に何をやるか」の**単一の入り口**。詳細は各 ADR / steering / issue へリンク。

最終更新: 2026-07-04

## 現在地

- **iOS**: ダーク/ライトの OS ネイティブ追従 完了（PR #7 マージ済み）
- **Web ダッシュボード**: Phase 1（本人向け・Firestore 直読み）完了 → ブランチ `feat/web-dashboard-phase1`

## ✅ 完了

- [x] ダーク/ライト OS ネイティブ追従（steering: `20260704-adaptive-color-scheme`）
- [x] Web ダッシュボード Phase 1（ADR-0007 / steering: `20260704-web-dashboard-phase1`）

## ⬜ 次にやること（優先度順）

### Web ダッシュボード

- [ ] Phase 1 を personal 内で PR → マージ
- [ ] **Firebase Hosting にデプロイ**（実 URL で見られるように）
- [ ] **Phase 2**: Cloud Functions で `song_insights` 集計（匿名化・k-匿名性）← B2B の土台
- [ ] **Phase 3**: アーティスト認証・曲所有権・反応ヒートマップ（B2B インサイト）

### iOS 小物

- [ ] 一時ログアウトボタン → 正式な設定画面のログアウトに昇格
- [ ] 実機（iPhone + AirPods）での最終確認

### ドキュメント整備

- [ ] ダーク/ライト対応を ADR 化（steering はあるが ADR 無し）
- [ ] PRD / `architecture.md` / `repository-structure.md` に `web/` を新サーフェスとして追記

## 💡 アイデア（将来）

- Spotify 連携（[issue #110](https://github.com/engineer-guild-hackathon-2026-05/team-10/issues/110)）

## 📁 記録の置き場所（どこに何を書くか）

| 種類                 | 置き場所                                                         |
| -------------------- | ---------------------------------------------------------------- |
| アーキテクチャ決定   | `docs/adr/NNNN-*.md`                                             |
| 機能ごとの設計・進捗 | `.steering/YYYYMMDD-機能名/`（requirements / design / tasklist） |
| 戦略・全体像         | `docs/*.md`, `docs/*.html`                                       |
| プロダクト要求       | `docs/product-requirements.md`（PRD）                            |
| アイデア             | GitHub issue（チームリポジトリ側）                               |
| 次にやること全体     | **このファイル（`docs/roadmap.md`）**                            |
