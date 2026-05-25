"""
HowTune — 統合プレゼンデッキ (6分 / 11スライド)
デザイン: Apple Style (black #000000, blue #0071E3, Inter font)
"""
from pptx import Presentation
from pptx.util import Inches, Pt, Emu
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN
from pptx.oxml.ns import qn
from lxml import etree

# ── Colors (Apple-style) ──────────────────────────────────────
BLACK   = RGBColor(0x00, 0x00, 0x00)
WHITE   = RGBColor(0xFF, 0xFF, 0xFF)
DIM     = RGBColor(0x88, 0x88, 0x99)
BLUE    = RGBColor(0x00, 0x71, 0xE3)   # Apple blue
LGRAY   = RGBColor(0x1C, 0x1C, 0x1E)   # card bg
BORDER  = RGBColor(0x38, 0x38, 0x3A)   # subtle border

W = Inches(13.33)
H = Inches(7.5)
MARGIN_L = Inches(1.1)
MARGIN_R = Inches(1.1)
CONTENT_W = W - MARGIN_L - MARGIN_R

prs = Presentation()
prs.slide_width  = W
prs.slide_height = H
blank_layout = prs.slide_layouts[6]

# ── Helpers ───────────────────────────────────────────────────

def add_slide():
    slide = prs.slides.add_slide(blank_layout)
    bg = slide.background.fill
    bg.solid()
    bg.fore_color.rgb = BLACK
    return slide

def txb(slide, text, x, y, w, h, *, size=18, bold=False, color=WHITE,
        align=PP_ALIGN.LEFT, font="Inter", wrap=True):
    tf = slide.shapes.add_textbox(x, y, w, h).text_frame
    tf.word_wrap = wrap
    p = tf.paragraphs[0]
    p.alignment = align
    run = p.add_run()
    run.text = text
    f = run.font
    f.name = font
    f.size = Pt(size)
    f.bold = bold
    f.color.rgb = color

def multiline(slide, lines, x, y, w, h, *, default_size=16, default_color=WHITE, font="Inter"):
    """lines: list of (text, size, bold, color) or just str"""
    from pptx.shapes.base import BaseShape
    tf = slide.shapes.add_textbox(x, y, w, h).text_frame
    tf.word_wrap = True
    first = True
    for item in lines:
        if isinstance(item, str):
            text, size, bold, color = item, default_size, False, default_color
        else:
            text = item[0]
            size = item[1] if len(item) > 1 else default_size
            bold = item[2] if len(item) > 2 else False
            color = item[3] if len(item) > 3 else default_color
        p = tf.paragraphs[0] if first else tf.add_paragraph()
        first = False
        run = p.add_run()
        run.text = text
        f = run.font
        f.name = font
        f.size = Pt(size)
        f.bold = bold
        f.color.rgb = color

def chapter_label(slide, text):
    txb(slide, text, MARGIN_L, Inches(0.45), Inches(6), Inches(0.35),
        size=11, bold=False, color=BLUE, font="Inter SemiBold")

def big_title(slide, text, y=Inches(1.05), w=None, size=52):
    txb(slide, text, MARGIN_L, y, w or CONTENT_W, Inches(1.5),
        size=size, bold=True, color=WHITE)

def body_text(slide, text, y=Inches(2.5), w=None, size=17):
    txb(slide, text, MARGIN_L, y, w or CONTENT_W, Inches(3.0),
        size=size, bold=False, color=WHITE)

def dim_text(slide, text, y, w=None, size=14):
    txb(slide, text, MARGIN_L, y, w or CONTENT_W, Inches(0.5),
        size=size, bold=False, color=DIM)

def divider(slide, y, color=BLUE, width=None):
    from pptx.util import Pt as _Pt
    from pptx.oxml import parse_xml
    line_w = width or Inches(1.2)
    line = slide.shapes.add_shape(
        1,  # MSO_SHAPE_TYPE.RECTANGLE
        MARGIN_L, y, line_w, Inches(0.025)
    )
    line.fill.solid()
    line.fill.fore_color.rgb = color
    line.line.fill.background()

def card_box(slide, x, y, w, h, bg=LGRAY):
    box = slide.shapes.add_shape(1, x, y, w, h)
    box.fill.solid()
    box.fill.fore_color.rgb = bg
    box.line.color.rgb = BORDER


# ════════════════════════════════════════════════════════════════
# Slide 1 — Title
# ════════════════════════════════════════════════════════════════
s = add_slide()

txb(s, "HowTune",
    MARGIN_L, Inches(1.8), Inches(9), Inches(1.8),
    size=80, bold=True, color=WHITE)

txb(s, "何を聴くかではなく、どう聴いているかでつながる。",
    MARGIN_L, Inches(3.4), Inches(9), Inches(0.7),
    size=20, bold=False, color=DIM)

divider(s, Inches(4.3))

txb(s, "Engineer Guild Hackathon 2026/05  ·  Team Othello",
    MARGIN_L, Inches(4.55), Inches(8), Inches(0.45),
    size=13, bold=False, color=BLUE, font="Inter SemiBold")


# ════════════════════════════════════════════════════════════════
# Slide 2 — Problem: Labeling is not enough
# ════════════════════════════════════════════════════════════════
s = add_slide()
chapter_label(s, "CHAPTER 01 — THE PROBLEM")

big_title(s, "Labeling is not enough.")

body_text(s,
    "既存の音楽サービスは「What（曲名・ジャンル・再生回数）」でしか人を繋げません。\n"
    "しかし、本当に心が動く瞬間は、聴き方（How）の中にあります。",
    y=Inches(2.55), size=18)

# Two column cards
card_box(s, MARGIN_L, Inches(4.2), Inches(5.4), Inches(2.4))
txb(s, "既存サービス",
    MARGIN_L + Inches(0.3), Inches(4.35), Inches(4.8), Inches(0.45),
    size=14, bold=True, color=DIM)
multiline(s, [
    ("What 中心：曲名・ジャンル・再生回数", 15, False, WHITE),
    ("✗  「この瞬間の感動」は共有できない", 15, False, DIM),
    ("✗  同じ聴き方の人とは出会えない",    15, False, DIM),
], MARGIN_L + Inches(0.3), Inches(4.8), Inches(4.8), Inches(1.6))

card_box(s, MARGIN_L + Inches(5.8), Inches(4.2), Inches(5.4), Inches(2.4), bg=RGBColor(0x00, 0x18, 0x32))
txb(s, "HowTune",
    MARGIN_L + Inches(6.1), Inches(4.35), Inches(4.8), Inches(0.45),
    size=14, bold=True, color=BLUE, font="Inter SemiBold")
multiline(s, [
    ("How 中心：歌詞 × 反応 × 聴き方",          15, False, WHITE),
    ("✓  「1:18のあの一節が刺さった」を共有",    15, False, WHITE),
    ("✓  同じ波形を持つ見知らぬ人と出会える",    15, False, WHITE),
], MARGIN_L + Inches(6.1), Inches(4.8), Inches(4.8), Inches(1.6))


# ════════════════════════════════════════════════════════════════
# Slide 3 — Why Now: The Great Inversion
# ════════════════════════════════════════════════════════════════
s = add_slide()
chapter_label(s, "CHAPTER 02 — WHY NOW")

big_title(s, "The Great Inversion", size=54)

txb(s, "AIはスキルの希少価値をゼロに近づける",
    MARGIN_L, Inches(2.35), CONTENT_W, Inches(0.5),
    size=20, bold=False, color=DIM)

divider(s, Inches(3.05))

multiline(s, [
    ("旧時代の価値：「何を作れるか」（スキル） → AIが代替", 17, False, DIM),
    ("",),
    ("新時代の価値：「誰と・どう楽しむか」（コミュニティ・体験）", 19, True, WHITE),
], MARGIN_L, Inches(3.2), CONTENT_W, Inches(1.5))

txb(s, "HowTuneはこのパラダイムシフトのど真ん中にいる。",
    MARGIN_L, Inches(4.55), CONTENT_W, Inches(0.6),
    size=17, bold=False, color=BLUE, font="Inter SemiBold")

# Arrow visual: pyramid → circle
card_box(s, MARGIN_L, Inches(5.25), Inches(5.4), Inches(1.6))
multiline(s, [
    ("旧：ピラミッド型", 13, True, DIM),
    ("アーティストが頂点・ファンは消費者", 13, False, DIM),
], MARGIN_L + Inches(0.2), Inches(5.4), Inches(5.0), Inches(1.4))

txb(s, "→", MARGIN_L + Inches(5.6), Inches(5.8), Inches(0.6), Inches(0.6),
    size=28, bold=True, color=BLUE, align=PP_ALIGN.CENTER)

card_box(s, MARGIN_L + Inches(6.4), Inches(5.25), Inches(5.4), Inches(1.6), bg=RGBColor(0x00, 0x18, 0x32))
multiline(s, [
    ("新：円環型エコシステム", 13, True, BLUE),
    ("ファンの「How」が価値の源泉になる", 13, False, WHITE),
], MARGIN_L + Inches(6.6), Inches(5.4), Inches(5.0), Inches(1.4))


# ════════════════════════════════════════════════════════════════
# Slide 4 — Solution: Lyrics × AI
# ════════════════════════════════════════════════════════════════
s = add_slide()
chapter_label(s, "CHAPTER 03 — SOLUTION")

big_title(s, "歌詞を「鏡」にする。", size=58)

txb(s, "身体が動いた瞬間に歌詞をタップ → AIが問いかける → How が言語化される",
    MARGIN_L, Inches(2.45), CONTENT_W, Inches(0.6),
    size=17, bold=False, color=DIM)

divider(s, Inches(3.2))

# Flow steps
steps = [
    ("01", "歌詞タップ",      "「この一節だ」と感じた瞬間にタップ"),
    ("02", "Groove 記録",    "音量 × モーションで盛り上がりを自動算出"),
    ("03", "AI 問いかけ",    "Claude がリズム・歌詞を起点に質問。断定しない"),
    ("04", "How カード",      "対話の結果が一生モノの「聴き方カード」に"),
    ("05", "マッチング",      "同じ歌詞・同じ How に反応した人と出会う"),
]
step_w = Inches(2.2)
for i, (num, title, desc) in enumerate(steps):
    x = MARGIN_L + i * (step_w + Inches(0.12))
    card_box(s, x, Inches(3.45), step_w, Inches(2.9))
    txb(s, num, x + Inches(0.2), Inches(3.6), step_w - Inches(0.3), Inches(0.4),
        size=11, bold=False, color=BLUE, font="Inter SemiBold")
    txb(s, title, x + Inches(0.2), Inches(3.95), step_w - Inches(0.3), Inches(0.45),
        size=16, bold=True, color=WHITE)
    txb(s, desc, x + Inches(0.2), Inches(4.45), step_w - Inches(0.3), Inches(1.7),
        size=13, bold=False, color=DIM)


# ════════════════════════════════════════════════════════════════
# Slide 5 — AI: Mirror Principle
# ════════════════════════════════════════════════════════════════
s = add_slide()
chapter_label(s, "CHAPTER 04 — AI DESIGN PHILOSOPHY")

big_title(s, "AIは断定しない。\n鏡であること。", size=48)

txb(s, "センサーは事実を捉える。AIは断面を差し出す。意味はユーザーが発見する。",
    MARGIN_L, Inches(3.05), CONTENT_W, Inches(0.55),
    size=15, bold=False, color=DIM)

divider(s, Inches(3.7))

# Two panels
card_box(s, MARGIN_L, Inches(3.9), Inches(5.2), Inches(2.7))
txb(s, "❌  断定する AI", MARGIN_L + Inches(0.3), Inches(4.05), Inches(4.6), Inches(0.45),
    size=15, bold=True, color=RGBColor(0xFF, 0x3B, 0x30))
multiline(s, [
    ("「あなたはここで感動しました」", 15, False, DIM),
    ("「あなたはベースが好きです」", 15, False, DIM),
    ("→ 断定は対話を閉じる", 14, False, DIM),
], MARGIN_L + Inches(0.3), Inches(4.55), Inches(4.6), Inches(2.0))

card_box(s, MARGIN_L + Inches(5.6), Inches(3.9), Inches(5.2), Inches(2.7), bg=RGBColor(0x00, 0x18, 0x32))
txb(s, "✅  HowTune の AI", MARGIN_L + Inches(5.9), Inches(4.05), Inches(4.6), Inches(0.45),
    size=15, bold=True, color=BLUE, font="Inter SemiBold")
multiline(s, [
    ("「ここで反応していましたね」", 15, False, WHITE),
    ("「リズムに乗っていた感じ？」", 15, False, WHITE),
    ("「それとも歌詞が刺さった？」", 15, False, WHITE),
    ("→ 問いかけが言語化を引き出す", 14, True, BLUE),
], MARGIN_L + Inches(5.9), Inches(4.55), Inches(4.6), Inches(2.0))


# ════════════════════════════════════════════════════════════════
# Slide 6 — Technology Stack
# ════════════════════════════════════════════════════════════════
s = add_slide()
chapter_label(s, "CHAPTER 05 — TECHNOLOGY")

big_title(s, "Apple Ecosystem × Claude API", size=46)

txb(s, "iOS ネイティブに一本化（ADR-0001）。センサーからモデルまでオンデバイス優先。",
    MARGIN_L, Inches(2.35), CONTENT_W, Inches(0.5),
    size=16, bold=False, color=DIM)

divider(s, Inches(3.0))

rows = [
    ("iOS / UI",       "SwiftUI + MusicKit",           "ネイティブ必須、Apple Music 連携"),
    ("歌詞",            "Musixmatch API",                "時刻同期歌詞（ADR-0004 解決）"),
    ("Groove センサー", "音量 + 本体モーション",         "AirPods 不要でデモ可（ADR-0005）"),
    ("LLM",             "Claude claude-sonnet-4-6",      "バックエンド経由でキー秘匿（ADR-0002）"),
    ("ML",              "Create ML → Core ML",           "端末推論、対話がラベルに（データフライホイール）"),
    ("DB",              "Firestore + Node.js",           "iOS SDK・リアルタイム同期"),
]
col_x = [MARGIN_L, MARGIN_L + Inches(2.0), MARGIN_L + Inches(5.0)]
col_w = [Inches(1.8), Inches(2.8), Inches(5.3)]
y = Inches(3.2)
row_h = Inches(0.52)
for i, (layer, tech, reason) in enumerate(rows):
    bg = RGBColor(0x0A, 0x0A, 0x0A) if i % 2 == 0 else BLACK
    card_box(s, MARGIN_L, y + i * row_h, CONTENT_W, row_h, bg=bg)
    txb(s, layer, col_x[0] + Inches(0.1), y + i*row_h + Inches(0.1),
        col_w[0], row_h, size=13, bold=False, color=DIM)
    txb(s, tech,  col_x[1], y + i*row_h + Inches(0.1),
        col_w[1], row_h, size=13, bold=True, color=WHITE)
    txb(s, reason,col_x[2], y + i*row_h + Inches(0.1),
        col_w[2], row_h, size=12, bold=False, color=DIM)


# ════════════════════════════════════════════════════════════════
# Slide 7 — Data Flywheel
# ════════════════════════════════════════════════════════════════
s = add_slide()
chapter_label(s, "CHAPTER 06 — DATA STRATEGY")

big_title(s, "対話がデータになる。\nデータが精度になる。", size=48)

txb(s, "AI 対話の回答が暗黙のラベルとなり、モデルが使えば使うほど賢くなる設計。",
    MARGIN_L, Inches(2.9), CONTENT_W, Inches(0.5),
    size=16, bold=False, color=DIM)

divider(s, Inches(3.5))

# Flywheel steps
fw = [
    ("音量 + モーション", "Groove レベルをリアルタイム算出"),
    ("歌詞タップ",        "文脈付きの反応ポイントを記録"),
    ("AI 対話の回答",     "暗黙のラベルとして蓄積"),
    ("Create ML 学習",   "Groove 精度が向上"),
    ("より良い HowCard", "より多くの共鳴 → ユーザー増加"),
]
fw_w = Inches(2.15)
fw_y = Inches(3.7)
for i, (title, desc) in enumerate(fw):
    x = MARGIN_L + i * (fw_w + Inches(0.08))
    card_box(s, x, fw_y, fw_w, Inches(2.6))
    txb(s, f"0{i+1}", x + Inches(0.2), fw_y + Inches(0.15), fw_w, Inches(0.35),
        size=11, bold=False, color=BLUE, font="Inter SemiBold")
    txb(s, title, x + Inches(0.2), fw_y + Inches(0.5), fw_w - Inches(0.3), Inches(0.55),
        size=15, bold=True, color=WHITE)
    txb(s, desc, x + Inches(0.2), fw_y + Inches(1.1), fw_w - Inches(0.3), Inches(1.3),
        size=13, bold=False, color=DIM)
    if i < 4:
        txb(s, "→", x + fw_w - Inches(0.05), fw_y + Inches(0.9), Inches(0.25), Inches(0.4),
            size=18, bold=True, color=BLUE, align=PP_ALIGN.CENTER)

# Phase table
card_box(s, MARGIN_L, Inches(6.45), CONTENT_W, Inches(0.72), bg=LGRAY)
multiline(s, [
    ("MVP（今）: ルールベース Groove  →  Phase 1（〜6ヶ月）: 学習モデル 32次元  →  Phase 2（〜1年）: 個人最適化 128次元", 14, False, DIM),
], MARGIN_L + Inches(0.3), Inches(6.57), CONTENT_W - Inches(0.5), Inches(0.5))


# ════════════════════════════════════════════════════════════════
# Slide 8 — Business Model
# ════════════════════════════════════════════════════════════════
s = add_slide()
chapter_label(s, "CHAPTER 07 — BUSINESS MODEL")

big_title(s, "アーティスト・リスナー・\nプラットフォームのプラスサム", size=42)

divider(s, Inches(3.0))

biz = [
    ("B2B\nSaaS",        "#0071E3", "アーティスト向けインサイト",
     "身体反応ヒートマップ\n「1:18にGroove集中」\nSpotify にないデータで差別化"),
    ("プレミアム\nマッチング", "#34C759", "セレンディピティマッチング",
     "同曲・同瞬間に反応した\n見知らぬ人との出会い\n（Premium 解禁）"),
    ("チップ\n循環",      "#FF9F0A", "P2Pチップ + アーティスト支援",
     "チップ送付者を「発見者」\nとして可視化\nマージン 10%"),
]
biz_w = Inches(3.5)
for i, (tag, color_hex, title, body) in enumerate(biz):
    r, g, b = int(color_hex[1:3],16), int(color_hex[3:5],16), int(color_hex[5:7],16)
    col = RGBColor(r, g, b)
    x = MARGIN_L + i * (biz_w + Inches(0.4))
    card_box(s, x, Inches(3.2), biz_w, Inches(3.7))
    txb(s, tag, x + Inches(0.25), Inches(3.35), biz_w - Inches(0.4), Inches(0.7),
        size=13, bold=True, color=col, font="Inter SemiBold")
    txb(s, title, x + Inches(0.25), Inches(4.1), biz_w - Inches(0.4), Inches(0.55),
        size=16, bold=True, color=WHITE)
    txb(s, body, x + Inches(0.25), Inches(4.7), biz_w - Inches(0.4), Inches(1.9),
        size=14, bold=False, color=DIM)


# ════════════════════════════════════════════════════════════════
# Slide 9 — MVP Status + Team
# ════════════════════════════════════════════════════════════════
s = add_slide()
chapter_label(s, "CHAPTER 08 — TEAM & MVP")

big_title(s, "実装済み、動いている。", size=52)

txb(s, "Team Othello — PM / iOS / Backend / ML・Design の4名",
    MARGIN_L, Inches(2.45), CONTENT_W, Inches(0.5),
    size=16, bold=False, color=DIM)

divider(s, Inches(3.1))

# Built / Not built
card_box(s, MARGIN_L, Inches(3.3), Inches(5.4), Inches(3.5))
txb(s, "✅  実装済み（P0）",
    MARGIN_L + Inches(0.3), Inches(3.45), Inches(5.0), Inches(0.45),
    size=15, bold=True, color=RGBColor(0x34, 0xC7, 0x59))
multiline(s, [
    ("曲再生 × MusicKit", 14, False, WHITE),
    ("時刻同期歌詞（Musixmatch）", 14, False, WHITE),
    ("歌詞タップ → AI 対話（Claude API）", 14, False, WHITE),
    ("Howカード生成・Firestore 保存", 14, False, WHITE),
    ("Groove レベル表示（音量ベース）", 14, False, WHITE),
    ("コミュニティ画面", 14, False, WHITE),
], MARGIN_L + Inches(0.3), Inches(3.95), Inches(5.0), Inches(2.7))

card_box(s, MARGIN_L + Inches(5.8), Inches(3.3), Inches(5.4), Inches(3.5))
txb(s, "🚫  スコープ外",
    MARGIN_L + Inches(6.1), Inches(3.45), Inches(5.0), Inches(0.45),
    size=15, bold=True, color=DIM)
multiline(s, [
    ("DM・フォロー・タイムライン", 14, False, DIM),
    ("Spotify 連携", 14, False, DIM),
    ("完全な認証フロー", 14, False, DIM),
    ("AirPods 必須センサー精度", 14, False, DIM),
    ("教師データ収集アプリ（別仕様）", 14, False, DIM),
], MARGIN_L + Inches(6.1), Inches(3.95), Inches(5.0), Inches(2.7))


# ════════════════════════════════════════════════════════════════
# Slide 10 — Competitive Differentiation
# ════════════════════════════════════════════════════════════════
s = add_slide()
chapter_label(s, "CHAPTER 09 — DIFFERENTIATION")

big_title(s, "誰もやっていない、\n3つの掛け合わせ。", size=48)

divider(s, Inches(3.05))

table_rows = [
    ("",                 "Spotify", "Last.fm", "Apple Music", "HowTune"),
    ("How の言語化",      "✗",       "✗",       "✗",           "✓"),
    ("歌詞 × 反応",       "✗",       "✗",       "✗",           "✓"),
    ("AI 対話 + HowCard", "✗",       "✗",       "✗",           "✓"),
    ("身体反応マッチング", "✗",       "✗",       "✗",           "✓"),
]
row_h = Inches(0.58)
col_xs = [MARGIN_L, MARGIN_L+Inches(3.8), MARGIN_L+Inches(5.8), MARGIN_L+Inches(7.8), MARGIN_L+Inches(9.65)]
col_ws = [Inches(3.5), Inches(1.8), Inches(1.8), Inches(1.8), Inches(1.5)]

for ri, row in enumerate(table_rows):
    y = Inches(3.15) + ri * row_h
    bg = RGBColor(0x00, 0x18, 0x32) if ri == 0 else (LGRAY if ri % 2 == 1 else BLACK)
    card_box(s, MARGIN_L, y, CONTENT_W, row_h, bg=bg)
    for ci, cell in enumerate(row):
        color = BLUE if (ri == 0) else (RGBColor(0x34, 0xC7, 0x59) if cell == "✓" else DIM)
        bold = ri == 0 or ci == 0
        txb(s, cell, col_xs[ci] + Inches(0.15), y + Inches(0.1),
            col_ws[ci], row_h, size=14, bold=bold, color=color, align=PP_ALIGN.CENTER if ci > 0 else PP_ALIGN.LEFT)


# ════════════════════════════════════════════════════════════════
# Slide 11 — Closing Vision
# ════════════════════════════════════════════════════════════════
s = add_slide()

txb(s, "音楽は、どう聴くかだ。",
    MARGIN_L, Inches(1.6), CONTENT_W, Inches(1.5),
    size=62, bold=True, color=WHITE)

txb(s, "歌詞が、あなたの How を語り始める。",
    MARGIN_L, Inches(3.1), CONTENT_W, Inches(0.8),
    size=22, bold=False, color=DIM)

divider(s, Inches(4.0))

multiline(s, [
    ("Phase 1（〜6ヶ月）：アーティスト向け反応ヒートマップ（B2B）", 15, False, DIM),
    ("Phase 2（〜1年）：チップ循環 + Fan-to-Earn エコシステム",     15, False, DIM),
    ("Phase 3（〜2年）：ライブ会場リアルタイム共感 × 個人最適化 How マッチング", 15, False, DIM),
], MARGIN_L, Inches(4.2), CONTENT_W, Inches(1.5))

txb(s, "HowTune  ·  Team Othello  ·  Engineer Guild Hackathon 2026/05",
    MARGIN_L, Inches(6.45), CONTENT_W, Inches(0.5),
    size=13, bold=False, color=BLUE, font="Inter SemiBold")


# ════════════════════════════════════════════════════════════════
# Save
# ════════════════════════════════════════════════════════════════
out = "docs/slides/howtune_final.pptx"
prs.save(out)
print(f"Saved: {out}  ({len(prs.slides)} slides)")
