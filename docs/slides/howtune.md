---
marp: true
theme: uncover
paginate: true
backgroundColor: #fafafa
color: #18181b
size: 16:9
---

<style>
:root {
  --accent: #6366f1;
  --accent2: #a855f7;
}
section {
  font-family: 'Helvetica Neue', 'Hiragino Sans', 'Yu Gothic', sans-serif;
  font-size: 26px;
  padding: 60px 70px;
  background: #fafafa;
  line-height: 1.6;
}
h1 {
  font-size: 52px;
  font-weight: 800;
  letter-spacing: -0.02em;
  background: linear-gradient(135deg, #6366f1, #a855f7);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
}
h2 {
  font-size: 34px;
  font-weight: 700;
  color: #18181b;
  border-bottom: 3px solid var(--accent);
  padding-bottom: 12px;
}
h3 { font-size: 26px; color: #6366f1; font-weight: 700; }
strong { color: #6366f1; }
table { font-size: 20px; }
th { background: #6366f1; color: #fff; }
td, th { padding: 8px 14px; }
code {
  background: #eef2ff; color: #4f46e5; padding: 2px 8px; border-radius: 5px;
  font-size: 0.85em;
}
blockquote {
  border-left: 5px solid #a855f7; background: #f5f3ff; padding: 14px 24px;
  font-style: normal; border-radius: 0 10px 10px 0;
}
section.lead h1 { font-size: 64px; }
section.lead { text-align: center; }
ul { line-height: 1.7; }
.cols { display: flex; gap: 36px; }
.cols > div { flex: 1; }
.tag {
  display: inline-block; background: #eef2ff; color: #4f46e5;
  padding: 4px 16px; border-radius: 999px; font-size: 18px; font-weight: 600;
}
footer { color: #a1a1aa; font-size: 14px; }
</style>

<!-- _class: lead -->
<!-- _paginate: false -->

# HowTune

### 音楽は、どう聴くかだ。

<br>

🎵 音楽の "How" でつながるコミュニティ

<br>

<span class="tag">Engineer Guild Hackathon 2026/05 — Team 10</span>

---

## アジェンダ

1. 🎯 **課題** — なぜ偏愛は広がらないのか
2. 💡 **解決策** — How でつながる
3. 🧩 **プロダクト** — HowTune の体験
4. 🏗️ **アーキテクチャ** — 技術構成
5. 🛠️ **開発体制** — リポジトリ・ガイドライン
6. 🚀 **MVP と今後**

---

<!-- _class: lead -->

# 🎯 課題

---

## 偏愛が広がらない理由

> 今のプラットフォームでは **What** しか共有できない

<br>

同じ曲を好きでも、楽しみ方は人それぞれ：

<div class="cols">
<div>

- 🎤 歌詞に刺さる
- 🎸 ベースラインが好き
- 🥁 グルーヴに乗る

</div>
<div>

- ⏸️ サビ前の溜めで上がる
- 🌙 余韻に浸る
- ✨ 一瞬の音にハッとする

</div>
</div>

<br>

**でも、その楽しみ方をうまく言語化できない。**
だから共有できず、同じ聴き方の人と一生出会えない。

---

## ターゲットユーザー

<div class="cols">
<div>

### 田中音さん（22）
大学生・音楽好き

- 毎日1〜2時間音楽を聴く
- 「なぜ好きか」を説明できない
- 曲名以上の会話ができない

</div>
<div>

### 鈴木聴さん（28）
社会人・音楽マニア

- 年500枚聴くヘビーリスナー
- 楽しみ方は言語化できる
- でも語れる相手がいない

</div>
</div>

<br>

→ どちらも **「同じ聴き方の人と出会えない」** という共通課題

---

<!-- _class: lead -->

# 💡 解決策

---

## What ではなく How でつながる

<div class="cols">
<div>

### 従来のSNS
**What 中心**

- 好きな曲
- 好きなアーティスト
- 好きなジャンル
- 再生履歴

</div>
<div>

### HowTune
**How 中心**

- どこでノるか
- どこで上がるか
- どこで刺さるか
- どこで余韻に浸るか

</div>
</div>

<br>

> 音楽の熱狂が本当に伝わるのは
> **「どう聴いているか」が共有されたとき**

---

## コア体験：3ステップ

<br>

### 1️⃣ 動く
ただ音楽を聴くだけ。センサーが身体の反応・モメンタムを記録し、波形として可視化する。

### 2️⃣ 問いかける
AIが波形を見て問いかける。「1:18、ここで何か感じましたか？」言語はその後についてくる。

### 3️⃣ つながる
同じ波形を持つ見知らぬ人と出会う。What ではなく、身体の共鳴でつながる。

---

<!-- _class: lead -->

# 🧩 プロダクト

---

## 体験フロー

```
🎵 聴く              ただ音楽を聴くだけ
   ↓
📲 動く              センサーが身体の反応・モメンタムを自動記録
   ↓
🧠 スコア推定        3状態ML候補を起点に、6軸スコアへ展開
                      ※ groove / chill / neutral → groove / hype / chill …
   ↓
🌊 見る              モメンタム波形が眼前に現れる（驚き）
   ↓
💬 問いかけられる    AIがスコアと波形を読んで問いかける（発見）
   ↓
🗣️ 答える           選択肢・自由入力・音声で答える
   ↓
🪪 言葉になる        「ベースの入りに反応する人」（Howカード）
   ↓
🤝 つながる          同じ波形を持つ見知らぬ人と出会う（共鳴）
```

---

## 聴取状態の6分類

| 状態 | English | 特徴 |
|---|---|---|
| 🕺 ノリ | Groove | リズムに合わせ規則的に揺れる |
| 🔥 高揚 | Hype | サビ・展開で急にテンションが上がる |
| 🌊 チル | Chill | 穏やかにゆっくり揺れる |
| 🧘 没入 | Immersion | 集中してほぼ動かない |
| ⚡ 刺さり | Hit | 一瞬に短く強く反応する |
| 🌅 余韻 | Afterglow | 盛り上がりの後、静かに浸る |

→ センサーから推定し、**AIとの対話の起点**にする

---

## AI は「断定」しない

<div class="cols">
<div>

### ❌ 悪い例
> あなたはここで楽しかったです
> あなたはベースが好きです

断定は対話を生まない

</div>
<div>

### ✅ HowTune
> ここで身体が反応していました
> ノっていた感じですか？
> リズム？それとも展開で上がった？

問いかけが言語化を促す

</div>
</div>

<br>

**AIの役割 = ユーザー自身の気づきを引き出すこと**

---

## 聴き方が、あなたを語る。

> 🎵 **Blinding Lights**
> ─────────────────────
> ### ベースの入りに反応する人
>
> メロディより先に、低音の重心やリズムの
> 入り方に反応するタイプ。曲が一段深くなる
> 瞬間に気持ちよさを感じている。
>
> `groove` `bass-driven`　📍 1:18 の瞬間

<br>

→ SNS シェア可能。**同じHowの人を見る** で繋がる

---

<!-- _class: lead -->

# 🏗️ アーキテクチャ

---

## 技術スタック

| レイヤー | 技術 |
|---|---|
| iOSアプリ | **SwiftUI** + MusicKit + Core Motion |
| バックエンド | **Express**（backend / Firebase Functions） |
| ML | **Core ML** + TensorFlow.js / Create ML（ai-recognition） |
| LLM | **Claude API**（claude-sonnet-4-6） |
| データベース | **Firestore** |
| 認証 | **Firebase Auth** / Sign in with Apple |

---

## システム構成

```
   📱 iOSアプリ (SwiftUI)
   Home / ReactionTimeline / HowChat
        │  HTTPS / SSE
        ▼
   ☁️ backend / Firebase Functions (Express)
   ┌─────────────┬──────────────────┐
   │ HowCard API │ HowDialogOrchestrator │
   │ Firestore   │ Claude API proxy      │
   └─────────────┴──────────────────┘
        │
        ▼
   🔥 Firestore

   ai-recognition ── Core ML model ──▶ iOSアプリ
```

---

## センサー解析アルゴリズム

5秒の時間窓ごとに特徴量を抽出 → 3状態候補を推定し、6軸スコアに展開

<div class="cols">
<div>

**抽出する特徴量**
- meanMagnitude
- maxDelta
- energy
- peakCount
- rhythmRegularity
- stillness

</div>
<div>

**判定ロジック例**
- 規則的な揺れ → Groove
- 急激な動き → Hype
- 静止 → Immersion
- 短いスパイク → Hit

</div>
</div>

<br>

→ MVPはルールベース、教師データ収集後にTF.jsモデルへ

---

## セキュリティ・配慮

- 🔑 **API キー**はサーバーサイドのみ（クライアント露出なし）
- 🛡️ **プロンプトインジェクション対策**：ユーザー入力を system プロンプトと分離
- 🔒 **Firestore セキュリティルール**：センサーデータは本人のみ閲覧可
- 📜 **DeviceMotionEvent** の利用目的をプライバシーポリシーに明記

---

<!-- _class: lead -->

# 🛠️ 開発体制

---

## リポジトリ構成（モノレポ）

```
team-10/
├── apps/
│   ├── web/        # Next.js フロントエンド
│   └── api/        # Express バックエンド
├── packages/
│   └── shared/     # 共通型定義 (SensorFrame, HowCard)
├── docs/           # 6つの永続ドキュメント
└── .claude/        # Claude Code 設定（agents/skills/commands）
```

pnpm workspace + Turborepo

---

## 開発ガイドライン

<div class="cols">
<div>

### コーディング
- TypeScript / `any` 禁止
- Zod でバリデーション
- コメントは **WHY のみ**

### Git
- `main` 直接 push 禁止
- `feat/` `fix/` `docs/`
- Squash merge

</div>
<div>

### テスト
- Vitest（ユニット70%）
- Firebase Emulator（統合）
- iOS/Android 手動E2E

### AI活用
- **必ず AI_USAGE_LOG.md に記録**
- 1日3件以上

</div>
</div>

---

<!-- _class: lead -->

# 🚀 MVP と今後

---

## MVP スコープ

<div class="cols">
<div>

### ✅ 作る（P0）
- 曲再生 × センサー取得
- 反応区間の検出
- AI 対話で言語化
- Howカード生成
- 同じHowの人を表示

</div>
<div>

### 🚫 作らない
- DM・フォロー
- 完全SNSタイムライン
- Spotify連携
- 独自歌詞DB
- 本格的な音源解析

</div>
</div>

---

## モデルの進化ロードマップ

| フェーズ | モデル | 必要データ | 状態 |
|---|---|---|---|
| **MVP（今）** | 3状態収集 + ルールベース6軸 | seed / 実機サンプル | ✅ 実装中 |
| **β版** | 学習モデル 16〜32次元 | 〜1,000セッション | 📅 〜6ヶ月 |
| **スケール** | 高次元埋め込み 128次元 | 10,000セッション〜 | 📅 1年〜 |

> 3状態は学習データを集めるための入口。6軸は「人間用のビューア」で、表示時に身体反応を解釈しやすい言葉へ射影する。
> **使えば使うほど賢くなる** — AI対話の回答が暗黙のラベルになる。

---

## 将来の展望

- 📊 **How別レコメンド** — 同じ聴き方の人が好む曲を推薦
- 🎤 **ライブ会場での反応共有** — 同じ空間の熱狂を可視化
- 🎼 **アーティスト向けファンインサイト** — ファンの聴き方を分析
- 🧠 **高次元Howマッチング** — 6軸を超えた潜在空間で「本当に同じ聴き方」の人と繋がる

---

<!-- _class: lead -->

# 音楽は、どう聴くかだ。

### 聴き方が、あなたを語る。

<br>

🎵 **HowTune**

<span class="tag">Team 10 — Engineer Guild Hackathon 2026/05</span>
