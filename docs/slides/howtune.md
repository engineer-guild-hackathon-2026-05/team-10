---
marp: true
theme: uncover
paginate: true
backgroundColor: #0a0a0f
color: #f0f0f5
size: 16:9
---

<style>
:root {
  --accent: #ff4d4d;
  --accent2: #3db8ff;
  --groove: #3db8ff;
  --dark: #0a0a0f;
  --card: #141420;
  --border: rgba(255,255,255,0.08);
}
section {
  font-family: 'Helvetica Neue', 'Hiragino Sans', 'Yu Gothic', sans-serif;
  font-size: 26px;
  padding: 52px 70px;
  background: var(--dark);
  color: #f0f0f5;
  line-height: 1.6;
}
h1 {
  font-size: 52px;
  font-weight: 900;
  letter-spacing: -0.02em;
  background: linear-gradient(135deg, var(--accent), var(--accent2));
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
}
h2 {
  font-size: 34px;
  font-weight: 800;
  color: #fff;
  border-bottom: 2px solid var(--accent);
  padding-bottom: 10px;
  margin-bottom: 28px;
}
h3 { font-size: 22px; color: var(--accent2); font-weight: 700; margin-bottom: 8px; }
strong { color: var(--accent); }
em { color: var(--accent2); font-style: normal; }
table { font-size: 20px; width: 100%; border-collapse: collapse; }
th { background: var(--accent); color: #fff; padding: 8px 14px; }
td { padding: 8px 14px; border-bottom: 1px solid var(--border); }
code {
  background: rgba(61,184,255,0.12); color: var(--accent2); padding: 2px 8px;
  border-radius: 5px; font-size: 0.85em;
}
blockquote {
  border-left: 4px solid var(--accent); background: rgba(255,77,77,0.08);
  padding: 14px 24px; font-style: normal; border-radius: 0 10px 10px 0;
  color: #f0f0f5;
}
section.lead h1 { font-size: 68px; }
section.lead { text-align: center; }
section.lead p { color: rgba(240,240,245,0.72); }
ul { line-height: 1.8; }
li { margin-bottom: 2px; }
.cols { display: flex; gap: 36px; }
.cols > div { flex: 1; }
.tag {
  display: inline-block; background: rgba(255,77,77,0.18); color: var(--accent);
  border: 1px solid rgba(255,77,77,0.4); padding: 4px 18px;
  border-radius: 999px; font-size: 18px; font-weight: 600;
}
.card {
  background: var(--card); border: 1px solid var(--border);
  border-radius: 16px; padding: 20px 24px; margin: 4px 0;
}
.groove-bar {
  height: 8px; border-radius: 4px;
  background: linear-gradient(90deg, var(--accent2), #a855f7, var(--accent));
  margin-top: 6px;
}
footer { color: rgba(240,240,245,0.32); font-size: 14px; }
</style>

<!-- _class: lead -->
<!-- _paginate: false -->

# HowTune

### 音楽は、どう聴くかだ。

<br>

<span class="tag">Engineer Guild Hackathon 2026/05 — Team 10</span>

---

## アジェンダ

1. **課題** — なぜ偏愛は伝わらないのか
2. **解決策** — 歌詞 × How でつながる
3. **プロダクト体験** — コアフロー
4. **技術スタック**
5. **MVP スコープ・今後の展望**

---

<!-- _class: lead -->

# 課題

---

## 音楽の「好き」は伝わらない

> 今のプラットフォームでは **What（何を聴くか）** しか共有できない

<br>

<div class="cols">
<div>

同じ曲を好きでも、楽しみ方は違う：

- 歌詞の一節に心が止まる
- ベースラインが体を動かす
- サビ前の「溜め」で上がる
- 余韻にいつまでも浸る

</div>
<div class="card">

### 問題
その楽しみ方（**How**）を<br>うまく言語化できない

だから共有できず、<br>
**同じ聴き方の人と出会えない**

</div>
</div>

---

## ターゲット

<div class="cols">
<div class="card">

### 田中音（22歳）
大学生 / 音楽好き

毎日1〜2時間音楽を聴く。<br>
「なぜ好きか」を説明できない。<br>
曲名以上の会話ができない。

</div>
<div class="card">

### 鈴木聴（28歳）
社会人 / 音楽マニア

年500枚聴くヘビーリスナー。<br>
楽しみ方は言語化できる。<br>
でも**語れる相手がいない**。

</div>
</div>

<br>

→ どちらも「**同じ聴き方の人と出会えない**」という共通課題

---

<!-- _class: lead -->

# 解決策

---

## 歌詞を「鏡」にする

<br>

<div class="cols">
<div>

### 従来の音楽 SNS
曲・アーティスト・ジャンル<br>（**What 中心**）

再生回数・いいね数<br>が価値の指標

</div>
<div>

### HowTune
**この歌詞の、ここで、どう感じたか**<br>（**How 中心**）

「1:18 のあの一節が刺さった」<br>が価値の指標

</div>
</div>

<br>

> 音楽の熱狂が本当に伝わるのは<br>**「どう聴いているか」が共有されたとき**

---

## AI は「断定」しない — 鏡であること

<br>

<div class="cols">
<div>

### ❌ 断定する AI
> あなたはここで感動しました
> あなたはベースが好きです

断定は対話を閉じる

</div>
<div>

### ✅ HowTune の AI
> ここで反応していましたね
> リズムに乗っていた感じ？
> それとも歌詞が刺さった？

**問いかけが言語化を引き出す**

</div>
</div>

<br>

*センサーは事実を捉える。AI は断面を差し出す。意味はユーザーが発見する。*

---

<!-- _class: lead -->

# プロダクト体験

---

## コアフロー

<br>

```
🎵  曲を選んで再生する
        ↓
📜  歌詞が時刻同期で流れる  ← Musixmatch API
        ↓
👆  「この歌詞だ」とタップする
        ↓
🌊  Groove レベル（音量 × 盛り上がり）が自動記録
        ↓
💬  AI が歌詞と Groove を起点に問いかける
        ↓
🪪  対話が「Howカード」になる
        ↓
🤝  同じ歌詞に同じ How で反応した人と出会う
```

---

## 歌詞 × Groove インターフェース

<div class="card">

**▶ Blinding Lights — 1:18**

<div class="groove-bar" style="width:78%"></div>
<div style="font-size:16px; color:rgba(240,240,245,0.5); margin-top:4px;">Groove 78% · 揺れ</div>

<br>

「*I said, ooh, I'm blinded by the lights*」

<br>

<div style="display:flex; gap:12px; font-size:18px;">
<span style="color:var(--accent)">💬 4 How</span>
<span style="color:rgba(240,240,245,0.5)">コメント</span>
<span style="color:var(--accent2); font-weight:700">✨ AIと深掘り →</span>
</div>

</div>

→ 歌詞行をタップすると AI 対話が始まる

---

## Howカード — 聴き方が、あなたを語る

<div class="card" style="max-width: 580px; margin: 0 auto;">

**🎵 Blinding Lights**

---

### 余韻に浸るリスナー

曲が終わっても世界に残り続けるタイプ。<br>
サビの後の静寂に、一番の意味を感じている。

<br>

`groove` `chill` `neutral`

📍 *1:18 — "ooh, I'm blinded by the lights"*

</div>

<br>

→ 同じ How の人 / 同じ歌詞に反応した人 を表示

---

<!-- _class: lead -->

# 技術スタック

---

## アーキテクチャ

```
   📱 iOS アプリ (SwiftUI / MusicKit)
      HomeView [歌詞 + Groove]
      HowChatView [AI 対話]
           │  HTTPS / SSE
           ▼
   ☁️  backend (Node.js + Express)
      POST /sessions/:id/chat   ← Claude API 中継
      POST /sessions/:id/how-card
      GET  /how-cards
           │
           ▼
      🔥  Firestore  +  🤖 Claude API (claude-sonnet-4-6)

   ai-recognition (Create ML / TF.js) → Core ML → iOS
```

---

## 技術選定

| レイヤー | 技術 | 選定理由 |
|---|---|---|
| iOS | SwiftUI + MusicKit | ネイティブ必須（ADR-0001） |
| 歌詞 | Musixmatch API | 時刻同期歌詞の取得 |
| Groove | 音量 + 本体モーション | AirPods 不要でデモできる（ADR-0005） |
| LLM | Claude claude-sonnet-4-6 | バックエンド経由でキー秘匿（ADR-0002） |
| ML | Create ML → Core ML | 端末推論、学習データ蓄積（ADR-0003） |
| DB | Firestore | iOS SDK・リアルタイム |

---

## データフライホイール

> AI 対話の回答が「暗黙のラベル」になる

```
音量 + モーション → Groove レベル（今）
    ↓ 歌詞タップで文脈付き反応を記録
AI 対話の回答 → ラベル付きデータが蓄積
    ↓
Create ML で精度向上 → より良い問いかけ
    ↓
より良い HowCard → より多くの共鳴
```

| フェーズ | モデル | 時期 |
|---|---|---|
| MVP | ルールベース Groove | 今 |
| Phase 1 | 学習モデル 32次元 | 〜6ヶ月 |
| Phase 2 | 個人最適化 128次元 | 〜1年 |

---

<!-- _class: lead -->

# MVP スコープ

---

## 作ったもの / 作らなかったもの

<div class="cols">
<div>

### ✅ P0（実装済み）
- 曲再生 × MusicKit
- 時刻同期歌詞（Musixmatch）
- 歌詞タップ → AI 対話
- Howカード生成・保存
- Groove レベル表示
- コミュニティ画面（ダミー）

</div>
<div>

### 🚫 スコープ外
- DM・フォロー・タイムライン
- Spotify 連携
- 歌詞コメントのリアルタイム同期
- AirPods 必須のセンサー精度
- 完全な認証フロー

</div>
</div>

---

## 将来の展望

- 🤝 **歌詞単位でのコミュニティ** — 同じ一節に反応した人と出会う
- 📊 **アーティスト向けインサイト** — どの歌詞で誰がどう反応したか
- 🎤 **ライブ会場での How 共有** — 同じ空間の集合的な感動を可視化
- 🧠 **高次元 How マッチング** — 歌詞 × 反応の潜在空間で「本当に同じ聴き方」の人と

<br>

> 歌詞は音楽の共通言語。<br>「この一節が刺さった」は、世界中どこへでも届く。

---

<!-- _class: lead -->

# 音楽は、どう聴くかだ。

### 歌詞が、あなたの How を語り始める。

<br>

**HowTune**

<span class="tag">Team 10 — Engineer Guild Hackathon 2026/05</span>
