---
marp: true
theme: uncover
paginate: true
size: 16:9
backgroundColor: #fafafa
---

<style>
section {
  font-family: 'Helvetica Neue', 'Hiragino Sans', 'Yu Gothic', sans-serif;
  font-size: 24px;
  padding: 50px 64px;
  background: #fafafa;
  color: #18181b;
  line-height: 1.6;
  text-align: left;
}
h1 { font-size: 46px; font-weight: 800; background: linear-gradient(135deg,#6366f1,#a855f7); -webkit-background-clip: text; -webkit-text-fill-color: transparent; }
h2 { font-size: 30px; font-weight: 700; border-bottom: 3px solid #6366f1; padding-bottom: 8px; }
strong { color: #6366f1; }
code { background:#eef2ff; color:#4f46e5; padding:2px 8px; border-radius:5px; font-size:0.85em; }
blockquote { border-left:5px solid #a855f7; background:#f5f3ff; padding:12px 22px; border-radius:0 10px 10px 0; }
table { font-size: 19px; }
th { background:#6366f1; color:#fff; }
td,th { padding:7px 12px; }
ul { line-height: 1.7; }
.tag { display:inline-block; background:#eef2ff; color:#4f46e5; padding:3px 14px; border-radius:999px; font-size:16px; font-weight:600; }
.muted { color:#a1a1aa; }
section.lead { text-align:center; }
section.lead h1 { font-size: 60px; }
</style>

<!-- _class: lead -->
<!-- _paginate: false -->

# Inception Deck
## HowTune

<span class="tag">Team Othello — Engineer Guild Hackathon 2026/05</span>

何を聴くかではなく、**どう聴いているか**でつながる

---

## ① なぜ我々はここにいるのか

- 音楽の熱狂が本当に伝わるのは「**何が好きか**」ではなく「**どう聴いているか**」が共有されたとき
- 既存の音楽 SNS / ストリーミングは **What（曲・アーティスト・ジャンル）** でしかつながれない
- 我々は **How（聴き方）でつながる**音楽体験を作るためにここにいる

---

## ② エレベーターピッチ

> **音楽の楽しみ方を言葉にできず、同じ聴き方の人と出会えない**音楽好きのための、
> **HowTune** という iOS アプリ。
> これは **AirPods のセンサーで身体反応を捉え、AI と対話して「How」を可視化**し、
> 同じ聴き方の人とつなげる。
> Spotify など What ベースのサービスと違って、
> **どう聴いているかでつながれる**。

---

## ③ パッケージデザイン（プロダクトの箱）

# HowTune 🎧

### 何を聴くかではなく、どう聴いているかでつながる

- 🎵 聴くだけで、あなたの「聴き方」が見える
- 🤖 AI があなたの反応を言葉にする
- 🤝 同じ "How" の人とつながる

<span class="muted">App Store の説明文・キャッチをここから作る</span>

---

## ④ やらないことリスト

| やる | やらない |
|---|---|
| iOS ネイティブ（iPhone + AirPods） | Android / Web |
| 聴き方（How）でつながる | DM・フォロー・完全SNSタイムライン |
| ルールベース反応検出 | 本格的な音源解析・高精度BPM |
| AI対話・Howカード | 教師データ収集アプリ（別仕様 002-） |
| （P1）歌詞・コミュニティ・心拍 | — |

---

## ⑤ 「ご近所さん」を探せ（関係者）

- **チーム Othello**: PM / iOS / Backend / ML / Design
- **メンター**（Day2 FB ×2）
- **スポンサー審査員**: メルカリ / P&G / Money Forward
- **プラットフォーム**: Apple（MusicKit / HealthKit / CoreMotion）
- **AI**: Anthropic Claude（claude-sonnet-4-6）

---

## ⑥ 解決策を描く（技術の全体像）

```
iPhone + AirPods (SwiftUI)
  ├ CMHeadphoneMotion … 頭部モーション
  ├ HealthKit … 心拍（補助）
  └ MusicKit … 再生・再生位置
        ↓ ルールベースで反応検出
   反応地点 → タイムライン可視化
        ↓ HTTPS
  backend (Node + Claude API)
   /chat（問いかけ）・/how-card（生成）
        ↓
   Firestore（保存・コミュニティ）※P1
```

ML は **ルールベース → データフライホイール**で進化（ADR-0003）

---

## ⑦ 夜も眠れなくなるような問題は何か（リスク）

- 🔴 **心拍のリアルタイム取得が不確実**（第三者アプリ制約）→ 補助に留める
- 🔴 **反応検出の精度**（ルールベース）→ デモのギャップで魅せ、精度はナラティブで
- 🟡 **認証フロー未検証**（Firebase Auth）→ まず認証なしで完成させる保険
- 🟡 **残り時間**（Day3 午前提出）→ 勝ち筋に集中、P1 は削る

---

## ⑧ 期間を見極める

- **ハッカソン3日間**: Day1（5/24）〜 Day3（5/26）
- **提出**: Day3 12:00
- **最終発表**: Day3 13:00〜（1チーム16分 = プレゼン6分＋質疑10分）
- 実質の開発時間は **Day2＋Day3午前**

---

## ⑨ 何を諦めるのか（トレードオフ）

| 優先する | 諦める |
|---|---|
| **デモ体験のギャップ** | 検出精度（ルールベースで割り切る） |
| **勝ち筋（画面を見ない）への集中** | 機能網羅 |
| **デモを必ず成立**（認証なし先行） | 完璧な認証・Firestore（P1） |
| **頭部モーション主体** | 心拍リアルタイム（補助） |

---

## ⑩ 何がどれだけ必要か（コスト・チーム）

- **チーム**: Team Othello（役割: PM / iOS / Backend / ML / Design）
- **API コスト**: Claude API（Sonnet）… <span class="muted">概算未定</span>
- **インフラ**: backend（ローカル / Cloud Run）, Firestore … <span class="muted">未定</span>
- **開発期間**: 3日間（実質 Day2＋Day3午前）

<span class="muted">※ 詳細コストは空白（未確定）</span>

---

<!-- _class: lead -->

# 何を聴くかではなく、
# **どう聴いているか**で。

🎧 **HowTune** — Team Othello
