from pptx import Presentation
from pptx.util import Inches, Pt, Emu
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN
from pptx.util import Inches, Pt

# Colors
BG       = RGBColor(0x0a, 0x0a, 0x0f)
WHITE    = RGBColor(0xFF, 0xFF, 0xFF)
DIM      = RGBColor(0xA0, 0xA0, 0xB0)
RED      = RGBColor(0xFF, 0x4D, 0x4D)
BLUE     = RGBColor(0x3D, 0xB8, 0xFF)
CARD_BG  = RGBColor(0x14, 0x14, 0x20)

W = Inches(13.33)
H = Inches(7.5)

prs = Presentation()
prs.slide_width  = W
prs.slide_height = H

blank_layout = prs.slide_layouts[6]  # completely blank

def add_slide():
    slide = prs.slides.add_slide(blank_layout)
    bg = slide.background.fill
    bg.solid()
    bg.fore_color.rgb = BG
    return slide

def txb(slide, text, x, y, w, h,
        size=24, bold=False, color=WHITE, align=PP_ALIGN.LEFT,
        italic=False, wrap=True):
    tf_box = slide.shapes.add_textbox(Inches(x), Inches(y), Inches(w), Inches(h))
    tf = tf_box.text_frame
    tf.word_wrap = wrap
    p = tf.paragraphs[0]
    p.alignment = align
    run = p.add_run()
    run.text = text
    run.font.size = Pt(size)
    run.font.bold = bold
    run.font.italic = italic
    run.font.color.rgb = color
    return tf_box

def multiline(slide, lines, x, y, w, h, size=20, color=WHITE, bold_first=False):
    """lines: list of (text, bold, color_override)"""
    tf_box = slide.shapes.add_textbox(Inches(x), Inches(y), Inches(w), Inches(h))
    tf = tf_box.text_frame
    tf.word_wrap = True
    first = True
    for item in lines:
        if isinstance(item, str):
            text, bold, col = item, False, color
        else:
            text = item[0]
            bold = item[1] if len(item) > 1 else False
            col  = item[2] if len(item) > 2 else color
        if first:
            p = tf.paragraphs[0]
            first = False
        else:
            p = tf.add_paragraph()
        p.space_before = Pt(2)
        run = p.add_run()
        run.text = text
        run.font.size = Pt(size)
        run.font.bold = bold
        run.font.color.rgb = col
    return tf_box

def divider(slide, y, color=RED):
    from pptx.util import Pt as UPt
    line = slide.shapes.add_shape(
        1,  # MSO_SHAPE_TYPE.LINE → use freeform workaround via connector
        Inches(0.6), Inches(y), Inches(12.13), Inches(0.01)
    )
    line.fill.solid()
    line.fill.fore_color.rgb = color
    line.line.color.rgb = color

def card_box(slide, x, y, w, h):
    box = slide.shapes.add_shape(1, Inches(x), Inches(y), Inches(w), Inches(h))
    box.fill.solid()
    box.fill.fore_color.rgb = CARD_BG
    box.line.color.rgb = RGBColor(0x30, 0x30, 0x50)
    box.line.width = Pt(1)
    return box

# ─────────────────────────────────────────────
# Slide 1: Title
# ─────────────────────────────────────────────
s = add_slide()
txb(s, "HowTune", 1, 1.8, 11, 1.8, size=72, bold=True, color=RED, align=PP_ALIGN.CENTER)
txb(s, "音楽は、どう聴くかだ。", 1, 3.7, 11, 0.8, size=28, color=DIM, align=PP_ALIGN.CENTER)
txb(s, "Engineer Guild Hackathon 2026/05 — Team 10", 1, 6.2, 11, 0.6, size=18, color=DIM, align=PP_ALIGN.CENTER)

# ─────────────────────────────────────────────
# Slide 2: Agenda
# ─────────────────────────────────────────────
s = add_slide()
txb(s, "アジェンダ", 0.6, 0.4, 8, 0.7, size=32, bold=True, color=WHITE)
divider(s, 1.25)
multiline(s, [
    ("1.  課題 — なぜ偏愛は伝わらないのか", True, WHITE),
    ("2.  解決策 — 歌詞 × How でつながる", False, DIM),
    ("3.  プロダクト体験 — コアフロー", False, DIM),
    ("4.  技術スタック", False, DIM),
    ("5.  MVP スコープ・今後の展望", False, DIM),
], 0.8, 1.5, 11, 5, size=24)

# ─────────────────────────────────────────────
# Slide 3: 課題
# ─────────────────────────────────────────────
s = add_slide()
txb(s, "音楽の「好き」は伝わらない", 0.6, 0.4, 11, 0.7, size=32, bold=True)
divider(s, 1.25)
txb(s, "今のプラットフォームでは What（何を聴くか）しか共有できない", 0.6, 1.4, 11, 0.6, size=20, color=DIM)
multiline(s, [
    ("同じ曲を好きでも、楽しみ方は人それぞれ：", False, WHITE),
    ("", False, WHITE),
    ("・歌詞の一節に心が止まる", False, DIM),
    ("・ベースラインが体を動かす", False, DIM),
    ("・サビ前の「溜め」で上がる", False, DIM),
    ("・余韻にいつまでも浸る", False, DIM),
], 0.8, 2.1, 5.5, 4, size=22)
card_box(s, 7.0, 2.0, 5.7, 2.8)
multiline(s, [
    ("その楽しみ方（How）を", False, WHITE),
    ("うまく言語化できない", True, RED),
    ("", False, WHITE),
    ("だから共有できず、", False, DIM),
    ("同じ聴き方の人と出会えない", True, WHITE),
], 7.3, 2.1, 5.1, 2.6, size=20)

# ─────────────────────────────────────────────
# Slide 4: ターゲット
# ─────────────────────────────────────────────
s = add_slide()
txb(s, "ターゲット", 0.6, 0.4, 8, 0.7, size=32, bold=True)
divider(s, 1.25)
card_box(s, 0.6, 1.5, 5.8, 3.5)
multiline(s, [
    ("田中音（22歳）大学生 / 音楽好き", True, WHITE),
    ("", False, WHITE),
    ("毎日1〜2時間音楽を聴く", False, DIM),
    ("「なぜ好きか」を説明できない", False, DIM),
    ("曲名以上の会話ができない", False, DIM),
], 0.9, 1.7, 5.2, 3.1, size=20)
card_box(s, 6.9, 1.5, 5.8, 3.5)
multiline(s, [
    ("鈴木聴（28歳）社会人 / 音楽マニア", True, WHITE),
    ("", False, WHITE),
    ("年500枚聴くヘビーリスナー", False, DIM),
    ("楽しみ方は言語化できる", False, DIM),
    ("でも語れる相手がいない", True, RED),
], 7.2, 1.7, 5.2, 3.1, size=20)
txb(s, "→ どちらも「同じ聴き方の人と出会えない」という共通課題", 0.6, 5.3, 12, 0.6, size=20, color=BLUE, bold=True)

# ─────────────────────────────────────────────
# Slide 5: 解決策
# ─────────────────────────────────────────────
s = add_slide()
txb(s, "歌詞を「鏡」にする", 0.6, 0.4, 11, 0.7, size=32, bold=True)
divider(s, 1.25)
card_box(s, 0.6, 1.5, 5.8, 3.8)
multiline(s, [
    ("従来の音楽 SNS", True, DIM),
    ("What 中心", False, DIM),
    ("", False, WHITE),
    ("曲・アーティスト・ジャンル", False, DIM),
    ("再生回数・いいね数が価値の指標", False, DIM),
], 0.9, 1.7, 5.2, 3.4, size=20)
card_box(s, 6.9, 1.5, 5.8, 3.8)
multiline(s, [
    ("HowTune", True, RED),
    ("How 中心", False, RED),
    ("", False, WHITE),
    ("この歌詞の、ここで、どう感じたか", True, WHITE),
    ("「1:18 のあの一節が刺さった」", False, DIM),
    ("が価値の指標", False, DIM),
], 7.2, 1.7, 5.2, 3.4, size=20)
txb(s, "音楽の熱狂が本当に伝わるのは「どう聴いているか」が共有されたとき", 0.6, 5.6, 12, 0.7, size=19, color=DIM, italic=True)

# ─────────────────────────────────────────────
# Slide 6: AI は鏡であること
# ─────────────────────────────────────────────
s = add_slide()
txb(s, "AI は「断定」しない — 鏡であること", 0.6, 0.4, 12, 0.7, size=30, bold=True)
divider(s, 1.25)
card_box(s, 0.6, 1.5, 5.8, 3.5)
multiline(s, [
    ("❌  断定する AI", True, RGBColor(0xFF,0x66,0x66)),
    ("", False, WHITE),
    ("あなたはここで感動しました", False, DIM),
    ("あなたはベースが好きです", False, DIM),
    ("", False, WHITE),
    ("→ 断定は対話を閉じる", False, DIM),
], 0.9, 1.7, 5.2, 3.1, size=20)
card_box(s, 6.9, 1.5, 5.8, 3.5)
multiline(s, [
    ("✅  HowTune の AI", True, BLUE),
    ("", False, WHITE),
    ("ここで反応していましたね", False, WHITE),
    ("リズムに乗っていた感じ？", False, WHITE),
    ("それとも歌詞が刺さった？", False, WHITE),
    ("", False, WHITE),
    ("→ 問いかけが言語化を引き出す", True, BLUE),
], 7.2, 1.7, 5.2, 3.1, size=20)
txb(s, "センサーは事実を捉える。AI は断面を差し出す。意味はユーザーが発見する。", 0.6, 5.3, 12, 0.6, size=18, color=DIM, italic=True)

# ─────────────────────────────────────────────
# Slide 7: コアフロー
# ─────────────────────────────────────────────
s = add_slide()
txb(s, "コアフロー", 0.6, 0.4, 8, 0.7, size=32, bold=True)
divider(s, 1.25)
multiline(s, [
    ("🎵  曲を選んで再生する", False, WHITE),
    ("       ↓", False, DIM),
    ("📜  歌詞が時刻同期で流れる（Musixmatch API）", False, BLUE),
    ("       ↓", False, DIM),
    ("👆  「この歌詞だ」とタップする", True, WHITE),
    ("       ↓", False, DIM),
    ("🌊  Groove レベル（音量 × 盛り上がり）が自動記録", False, BLUE),
    ("       ↓", False, DIM),
    ("💬  AI が歌詞と Groove を起点に問いかける", False, WHITE),
    ("       ↓", False, DIM),
    ("🪪  対話が「Howカード」になる", True, RED),
    ("       ↓", False, DIM),
    ("🤝  同じ歌詞に同じ How で反応した人と出会う", False, WHITE),
], 1.5, 1.4, 10, 5.8, size=19)

# ─────────────────────────────────────────────
# Slide 8: 歌詞 × Groove UI
# ─────────────────────────────────────────────
s = add_slide()
txb(s, "歌詞 × Groove インターフェース", 0.6, 0.4, 11, 0.7, size=30, bold=True)
divider(s, 1.25)
card_box(s, 1.5, 1.5, 10, 4.5)
multiline(s, [
    ("▶  Blinding Lights — 1:18", True, WHITE),
    ("Groove 78%  ·  揺れ", False, BLUE),
    ("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━", False, RGBColor(0x30,0x30,0x50)),
    ("", False, WHITE),
    ("「 I said, ooh, I'm blinded by the lights 」", False, WHITE),
    ("", False, WHITE),
    ("💬 4 How        コメント        ✨ AIと深掘り →", False, BLUE),
], 1.9, 1.7, 9.2, 4.0, size=22)
txb(s, "→ 歌詞行をタップすると AI 対話が始まる", 0.6, 6.3, 12, 0.6, size=18, color=DIM)

# ─────────────────────────────────────────────
# Slide 9: Howカード
# ─────────────────────────────────────────────
s = add_slide()
txb(s, "Howカード — 聴き方が、あなたを語る", 0.6, 0.4, 12, 0.7, size=30, bold=True)
divider(s, 1.25)
card_box(s, 2.5, 1.5, 8.3, 4.6)
multiline(s, [
    ("🎵  Blinding Lights", False, DIM),
    ("", False, WHITE),
    ("余韻に浸るリスナー", True, WHITE),
    ("", False, WHITE),
    ("曲が終わっても世界に残り続けるタイプ。", False, DIM),
    ("サビの後の静寂に、一番の意味を感じている。", False, DIM),
    ("", False, WHITE),
    ("#余韻派   #immersion   #afterglow", False, BLUE),
    ("", False, WHITE),
    ("📍 1:18 — \"ooh, I'm blinded by the lights\"", False, DIM),
], 2.9, 1.7, 7.5, 4.2, size=20)
txb(s, "→ 同じ How の人 / 同じ歌詞に反応した人を表示", 0.6, 6.3, 12, 0.6, size=18, color=DIM)

# ─────────────────────────────────────────────
# Slide 10: アーキテクチャ
# ─────────────────────────────────────────────
s = add_slide()
txb(s, "アーキテクチャ", 0.6, 0.4, 8, 0.7, size=32, bold=True)
divider(s, 1.25)
card_box(s, 0.6, 1.4, 12.13, 4.8)
multiline(s, [
    ("📱  iOS アプリ (SwiftUI / MusicKit)", True, WHITE),
    ("      HomeView [歌詞 + Groove]  /  HowChatView [AI 対話]", False, DIM),
    ("                │  HTTPS / SSE", False, DIM),
    ("                ▼", False, DIM),
    ("☁️  backend (Node.js + Express)", True, BLUE),
    ("      POST /sessions/:id/chat  ← Claude API 中継", False, DIM),
    ("      POST /sessions/:id/how-card  /  GET /how-cards", False, DIM),
    ("                │", False, DIM),
    ("                ▼", False, DIM),
    ("🔥  Firestore   +   🤖  Claude API (claude-sonnet-4-6)", True, WHITE),
    ("", False, WHITE),
    ("ai-recognition (Create ML / TF.js)  →  Core ML  →  iOS", False, DIM),
], 1.0, 1.6, 11.3, 4.4, size=18)

# ─────────────────────────────────────────────
# Slide 11: 技術選定
# ─────────────────────────────────────────────
s = add_slide()
txb(s, "技術選定", 0.6, 0.4, 8, 0.7, size=32, bold=True)
divider(s, 1.25)
rows = [
    ("iOS",    "SwiftUI + MusicKit",         "ネイティブ必須（ADR-0001）"),
    ("歌詞",   "Musixmatch API",              "時刻同期歌詞の取得"),
    ("Groove", "音量 + 本体モーション",       "AirPods 不要でデモできる（ADR-0005）"),
    ("LLM",    "Claude claude-sonnet-4-6",  "バックエンド経由でキー秘匿（ADR-0002）"),
    ("ML",     "Create ML → Core ML",        "端末推論・学習データ蓄積（ADR-0003）"),
    ("DB",     "Firestore",                   "iOS SDK・リアルタイム"),
]
y = 1.5
for layer, tech, reason in rows:
    txb(s, layer,   0.6, y, 1.8, 0.45, size=18, bold=True, color=BLUE)
    txb(s, tech,    2.5, y, 4.0, 0.45, size=18, color=WHITE)
    txb(s, reason,  6.6, y, 6.1, 0.45, size=16, color=DIM)
    y += 0.55

# ─────────────────────────────────────────────
# Slide 12: データフライホイール
# ─────────────────────────────────────────────
s = add_slide()
txb(s, "データフライホイール", 0.6, 0.4, 10, 0.7, size=32, bold=True)
divider(s, 1.25)
multiline(s, [
    ("音量 + モーション  →  Groove レベル（今）", False, WHITE),
    ("    ↓  歌詞タップで文脈付き反応を記録", False, DIM),
    ("AI 対話の回答  →  ラベル付きデータが蓄積", False, BLUE),
    ("    ↓", False, DIM),
    ("Create ML で精度向上  →  より良い問いかけ", False, WHITE),
    ("    ↓", False, DIM),
    ("より良い HowCard  →  より多くの共鳴", True, RED),
], 0.8, 1.5, 7, 4, size=21)
rows2 = [
    ("MVP",     "ルールベース Groove",   "今"),
    ("Phase 1", "学習モデル 32次元",     "〜6ヶ月"),
    ("Phase 2", "個人最適化 128次元",    "〜1年"),
]
y = 1.8
for phase, model, timing in rows2:
    txb(s, phase,  8.0, y, 2.0, 0.45, size=18, bold=True, color=BLUE)
    txb(s, model,  10.1, y, 2.8, 0.45, size=17, color=WHITE)
    txb(s, timing, 10.1, y+0.35, 2.8, 0.35, size=15, color=DIM)
    y += 1.1

# ─────────────────────────────────────────────
# Slide 13: MVP スコープ
# ─────────────────────────────────────────────
s = add_slide()
txb(s, "MVP スコープ", 0.6, 0.4, 8, 0.7, size=32, bold=True)
divider(s, 1.25)
card_box(s, 0.6, 1.5, 5.8, 4.5)
multiline(s, [
    ("✅  作ったもの（P0）", True, RGBColor(0x4D,0xFF,0x91)),
    ("", False, WHITE),
    ("・曲再生 × MusicKit", False, WHITE),
    ("・時刻同期歌詞（Musixmatch）", False, WHITE),
    ("・歌詞タップ → AI 対話", False, WHITE),
    ("・Howカード生成・保存", False, WHITE),
    ("・Groove レベル表示", False, WHITE),
    ("・コミュニティ画面（ダミー）", False, WHITE),
], 0.9, 1.7, 5.2, 4.1, size=20)
card_box(s, 6.9, 1.5, 5.8, 4.5)
multiline(s, [
    ("🚫  スコープ外", True, DIM),
    ("", False, WHITE),
    ("・DM・フォロー・タイムライン", False, DIM),
    ("・Spotify 連携", False, DIM),
    ("・AirPods 必須のセンサー精度", False, DIM),
    ("・完全な認証フロー", False, DIM),
    ("・歌詞コメントのリアルタイム同期", False, DIM),
], 7.2, 1.7, 5.2, 4.1, size=20)

# ─────────────────────────────────────────────
# Slide 14: クロージング
# ─────────────────────────────────────────────
s = add_slide()
txb(s, "音楽は、どう聴くかだ。", 1, 1.6, 11, 1.2, size=48, bold=True, color=WHITE, align=PP_ALIGN.CENTER)
txb(s, "歌詞が、あなたの How を語り始める。", 1, 2.9, 11, 0.8, size=26, color=DIM, align=PP_ALIGN.CENTER)
txb(s, "HowTune", 1, 4.5, 11, 0.9, size=38, bold=True, color=RED, align=PP_ALIGN.CENTER)
txb(s, "Team 10 — Engineer Guild Hackathon 2026/05", 1, 5.6, 11, 0.6, size=18, color=DIM, align=PP_ALIGN.CENTER)

# ─────────────────────────────────────────────
out = "docs/slides/howtune_editable.pptx"
prs.save(out)
print(f"Saved: {out}  ({prs.slides.__len__()} slides)")
