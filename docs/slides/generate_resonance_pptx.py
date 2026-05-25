"""
HowTune — How Resonance（共鳴マッチング）デッキ。
本編 (generate_pptx.py) と同じ Apple Keynote 風スタイル。
"""
from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN, MSO_ANCHOR
from pptx_utils import (
    _alpha,
    _line_alpha,
    add_slide,
    bar,
    configure,
    dot,
    glass,
    grad_card,
    grad_fill,
    kicker,
    mtxt,
    round_it,
    to_back,
    txt,
)

WHITE  = RGBColor(0xFF, 0xFF, 0xFF)
BLACK  = RGBColor(0x00, 0x00, 0x00)
GRAY   = RGBColor(0x8E, 0x8E, 0x93)
LGRAY  = RGBColor(0xB8, 0xB8, 0xBE)
BLUE   = RGBColor(0x0A, 0x84, 0xFF)
LBLUE  = RGBColor(0x64, 0xD2, 0xFF)
GREEN  = RGBColor(0x30, 0xD1, 0x58)
AMBER  = RGBColor(0xFF, 0x9F, 0x0A)
ORANGE = RGBColor(0xFF, 0x6A, 0x1A)
PURPLE = RGBColor(0xBF, 0x5A, 0xF2)
PINK   = RGBColor(0xFF, 0x37, 0x5F)
GLASS  = RGBColor(0x1C, 0x1C, 0x1E)
DBLUE  = RGBColor(0x06, 0x12, 0x24)
DRED   = RGBColor(0x2A, 0x08, 0x06)

W, H = Inches(13.333), Inches(7.5)
ML = Inches(1.0)
CW = W - ML * 2
OUT = "docs/slides/howtune_resonance.pptx"

prs = Presentation()
prs.slide_width, prs.slide_height = W, H
blank = prs.slide_layouts[6]
configure(
    presentation=prs,
    blank_layout=blank,
    width=W,
    height=H,
    margin_left=ML,
    content_width=CW,
    white=WHITE,
    black=BLACK,
    glass_fill=GLASS,
    default_gradient_start=DBLUE,
    default_gradient_end=BLACK,
    default_glass_alpha=45,
    default_glass_radius=14000,
    default_bar_height=Inches(0.07),
    default_bar_start=ORANGE,
    default_bar_end=PINK,
    default_kicker_color=ORANGE,
)

# 1 — TITLE
s = add_slide(DRED, BLACK)
txt(s, "How Resonance", ML, Inches(2.2), Inches(11.3), Inches(1.2), sz=64, bold=True)
bar(s, ML+Inches(0.05), Inches(3.6), Inches(3.6))
txt(s, "同じ瞬間に、火がつく。", ML, Inches(3.9), CW, Inches(0.8), sz=26, col=LGRAY)
txt(s, "曲の「この一点」で反応した人と、リアルタイムにつながる。", ML, Inches(4.7), CW, Inches(0.5), sz=16, col=GRAY)
txt(s, "HowTune  ·  Team Othello", ML, Inches(6.55), CW, Inches(0.45), sz=13, col=GRAY)

# 2 — THE MOMENT
s = add_slide()
kicker(s, "THE MOMENT")
txt(s, "一番動いた瞬間を、捉える。", ML, Inches(1.0), CW, Inches(0.9), sz=44, bold=True)
bar(s, ML+Inches(0.05), Inches(2.1), Inches(2.6))
txt(s, "AirPods の頭部モーションから、再生中に最も大きく動いた瞬間を記録。MLは回さない。", ML, Inches(2.4), CW, Inches(0.6), sz=17, col=LGRAY)
grad_card(s, ML, Inches(3.2), CW, Inches(1.5), RGBColor(0x06,0x1A,0x36), DBLUE, angle=0)
txt(s, "peak = max(interactionIntensity) → その playbackTime", ML, Inches(3.2), CW, Inches(1.5),
    sz=24, bold=True, col=LBLUE, align=PP_ALIGN.CENTER, anchor=MSO_ANCHOR.MIDDLE)
txt(s, "1回目は決めうちで「ここ、どうでしたか？」。スケール時に分類モデルへ寄せる前提。",
    ML, Inches(5.0), CW, Inches(0.6), sz=15, col=GRAY, align=PP_ALIGN.CENTER)

# 3 — ASK (2-stage)
s = add_slide()
kicker(s, "ASK → DEEPEN")
txt(s, "決めうち → AIで深掘り。", ML, Inches(1.0), CW, Inches(0.9), sz=44, bold=True)
bar(s, ML+Inches(0.05), Inches(2.1), Inches(2.6))
steps = [("01", "ピーク地点を提示", "「M:SS で一番動いていました」固定文", BLUE),
         ("02", "AIが深掘り", "Claude が文脈を踏まえ詳細に問う", PURPLE),
         ("03", "Howカード化", "コメント + タグで投稿", ORANGE)]
gap = Inches(0.4); cwd = (CW - gap*2)/3
for i,(n,t,d,c) in enumerate(steps):
    x = ML + i*(cwd+gap)
    glass(s, x, Inches(2.9), cwd, Inches(2.4))
    txt(s, n, x, Inches(3.15), cwd, Inches(0.4), sz=13, col=c, align=PP_ALIGN.CENTER)
    txt(s, t, x, Inches(3.6), cwd, Inches(0.6), sz=19, bold=True, align=PP_ALIGN.CENTER)
    bar(s, x+cwd/2-Inches(0.35), Inches(4.3), Inches(0.7), h=Inches(0.05), c1=c, c2=c)
    txt(s, d, x+Inches(0.2), Inches(4.5), cwd-Inches(0.4), Inches(0.8), sz=13, col=LGRAY, align=PP_ALIGN.CENTER, spacing=1.2)

# 4 — RESONANCE (showpiece)
s = add_slide(DRED, BLACK)
kicker(s, "RESONANCE", col=ORANGE)
txt(s, "同じ瞬間に、誰かが現れる。", ML, Inches(1.05), CW, Inches(0.9), sz=46, bold=True)
bar(s, ML+Inches(0.05), Inches(2.2), Inches(3.0))
mtxt(s, [
    ("分子がふわっと現れ、摩擦で熱を帯び、発火する——", 20, False, LGRAY),
    ("",),
    ("🔥 同じ瞬間に反応した人がリアルタイムに出現", 20, True, ORANGE),
    ("✦ 別の場所で反応した人も見える（違う解釈との出会い）", 18, False, LBLUE),
], ML, Inches(2.7), CW, Inches(2.4), spacing=1.5)
txt(s, "Firestore リアルタイム購読（ADR-0006）。how-cards を song_id で購読し ±2.5秒で同地点判定。",
    ML, Inches(5.6), CW, Inches(0.6), sz=14, col=GRAY)

# 5 — CONNECT (DM)
s = add_slide()
kicker(s, "CONNECT")
txt(s, "熱量が、つながる。", ML, Inches(1.0), CW, Inches(0.9), sz=46, bold=True)
bar(s, ML+Inches(0.05), Inches(2.1), Inches(2.6))
gap = Inches(0.5); cw2 = (CW-gap)/2
grad_card(s, ML, Inches(2.7), cw2, Inches(3.4), RGBColor(0x2A,0x10,0x06), DRED, angle=130)
txt(s, "🔥 同地点マッチ", ML+Inches(0.5), Inches(3.0), cw2-Inches(1), Inches(0.5), sz=20, bold=True, col=ORANGE)
mtxt(s, ["同じ瞬間に火がついた相手と", "そのままリアルタイム DM", "", "通常画面でも🔥マークで再会"],
     ML+Inches(0.5), Inches(3.7), cw2-Inches(1), Inches(2.2), dsz=16, spacing=1.5)
c2x = ML+cw2+gap
glass(s, c2x, Inches(2.7), cw2, Inches(3.4))
txt(s, "速さへのこだわり", c2x+Inches(0.5), Inches(3.0), cw2-Inches(1), Inches(0.5), sz=20, bold=True, col=LBLUE)
mtxt(s, ["楽観的更新（送信即反映）", "Firestore スナップショット購読", "参加者のみ read/write（rules）"],
     c2x+Inches(0.5), Inches(3.7), cw2-Inches(1), Inches(2.2), dsz=16, spacing=1.5)

# 6 — TECH / 非破壊
s = add_slide()
kicker(s, "ENGINEERING")
txt(s, "壊さず、足す。", ML, Inches(1.0), CW, Inches(0.9), sz=44, bold=True)
bar(s, ML+Inches(0.05), Inches(2.1), Inches(2.6))
tech = [(BLUE, "Peak Motion", "interactionIntensity ピーク（ML不使用）"),
        (PURPLE, "LLM 深掘り", "既存 Claude 経路を2回目に活用"),
        (ORANGE, "Realtime", "Firestore 購読 + 楽観的DM（ADR-0006）"),
        (GREEN, "非破壊統合", "optional 引数で既存挙動を不変に")]
gap = Inches(0.4); cwd = (CW-gap)/2; chd = Inches(1.5)
for i,(c,t,d) in enumerate(tech):
    ci, ri = i%2, i//2
    x = ML + ci*(cwd+gap); y = Inches(2.8) + ri*(chd+Inches(0.35))
    glass(s, x, y, cwd, chd)
    dot(s, x+Inches(0.4), y+Inches(0.38), c)
    txt(s, t, x+Inches(0.85), y+Inches(0.3), cwd-Inches(1), Inches(0.5), sz=17, bold=True, col=c)
    txt(s, d, x+Inches(0.42), y+Inches(0.85), cwd-Inches(0.7), Inches(0.5), sz=14, col=LGRAY)

# 7 — CLOSING
s = add_slide(DRED, BLACK)
txt(s, "同じ瞬間に、\n火がつく。", ML, Inches(2.1), CW, Inches(2.2), sz=58, bold=True, spacing=1.08)
bar(s, ML+Inches(0.05), Inches(4.7), Inches(3.6))
txt(s, "What ではなく How。曲のこの一点で、人とつながる。", ML, Inches(5.0), CW, Inches(0.6), sz=20, col=LGRAY)
txt(s, "HowTune  ·  Team Othello", ML, Inches(6.55), CW, Inches(0.45), sz=13, col=GRAY)

prs.save(OUT)
print("Saved: %s (%d slides)" % (OUT, len(prs.slides)))
