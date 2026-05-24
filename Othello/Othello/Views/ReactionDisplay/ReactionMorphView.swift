import SwiftUI

/// 6軸スコアが変形させる Calabi-Yau 断面風リアルタイム多様体ビジュアライザ
///
/// 設計原則「センサーは事実を捉える。AIは断面を差し出す。意味はユーザーが発見する。」
/// を視覚化したもの。外面はユーザーの身体反応の断面（高次元の投影）、
/// 内球はその鏡像——同じ多様体を別角度から切り取った断面。
///
/// Calabi-Yau quintic の特徴:
/// - 5回対称（quintic: z₁⁵+z₂⁵+...=0 の対称群）
/// - 面が自分自身を「貫通」するトポロジー（内外の貫通を内球で表現）
/// - 正則構造（holomorphic）に由来する螺旋的ねじれ
///
/// 実装:
/// - Catmull-Rom スプライン（addCurve）で全ラインを滑らか化
/// - 外面: 5葉 quintic 変形球（uSteps=60 で十分な解像度）
/// - 内面: 逆回転断面（同多様体の別 patch を近似）
/// - Fresnel エッジグロー: シルエット境界に集中する散乱光
/// - 虹彩色変化: 表面法線方向で色がシフト（ホロモーフィック構造の暗示）
struct ReactionMorphView: View {
    let score: ReactionScore
    let isActive: Bool

    private let uSteps = 60   // 5-fold × 12点/周期 = 十分な曲線解像度
    private let vSteps = 32

    private let tagColors: [Color] = [
        Color(red: 1.0, green: 0.30, blue: 0.30),
        Color(red: 1.0, green: 0.55, blue: 0.10),
        Color(red: 0.2, green: 0.70, blue: 1.00),
        Color(red: 0.6, green: 0.30, blue: 1.00),
        Color(red: 1.0, green: 0.20, blue: 0.50),
        Color(red: 0.9, green: 0.75, blue: 0.30),
    ]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: false)) { tl in
            Canvas { ctx, size in
                let t  = tl.date.timeIntervalSinceReferenceDate
                let cx = size.width  / 2
                let cy = size.height / 2
                let r  = min(size.width, size.height) * 0.38

                let s  = effectiveScores(time: t)
                let di = s.indices.max(by: { s[$0] < s[$1] }) ?? 0
                let mc = tagColors[di]
                let intensity = min(s.reduce(0, +) / 2.5, 1.0)

                // ── 回転（遅め・有機的な揺動） ──────────────────────
                let rx = t * 0.10 + sin(t * 0.055) * 0.13
                let ry = t * 0.15 + cos(t * 0.045) * 0.10
                let rz = sin(t * 0.07) * 0.14

                // ── 内側 patch の逆回転（別方向から切った断面） ───────
                let rxM = -(t * 0.08 + sin(t * 0.055) * 0.09)
                let ryM = -(t * 0.13 + cos(t * 0.045) * 0.07)

                // ── 格子生成 ─────────────────────────────────────────
                struct GridLine { var pts: [SIMD3<Double>]; var avgZ: Double }
                var lines = [GridLine]()

                // 緯線: 5-fold の葉が浮き上がるよう 2本おきで密に
                for vi in stride(from: 0, through: vSteps, by: 2) {
                    let v = Double(vi) / Double(vSteps) * .pi - .pi / 2
                    var pts = [SIMD3<Double>]()
                    for ui in 0...uSteps {
                        let u = Double(ui) / Double(uSteps) * 2 * .pi
                        pts.append(rotate(surface(u: u, v: v, s: s), rx: rx, ry: ry, rz: rz))
                    }
                    lines.append(GridLine(pts: pts, avgZ: pts.map(\.z).reduce(0,+) / Double(pts.count)))
                }

                // 経線: 5葉ごとに主経線 + その間に細い補助線
                for ui in stride(from: 0, through: uSteps - 1, by: 3) {
                    let u = Double(ui) / Double(uSteps) * 2 * .pi
                    var pts = [SIMD3<Double>]()
                    for vi in 0...vSteps {
                        let v = Double(vi) / Double(vSteps) * .pi - .pi / 2
                        pts.append(rotate(surface(u: u, v: v, s: s), rx: rx, ry: ry, rz: rz))
                    }
                    lines.append(GridLine(pts: pts, avgZ: pts.map(\.z).reduce(0,+) / Double(pts.count)))
                }

                lines.sort { $0.avgZ < $1.avgZ }

                // ── 背景グロー ────────────────────────────────────────
                let bgR = r * (0.90 + intensity * 0.28)
                var bg = ctx
                bg.addFilter(.blur(radius: 70))
                bg.fill(
                    Path(ellipseIn: CGRect(x: cx-bgR, y: cy-bgR, width: bgR*2, height: bgR*2)),
                    with: .color(mc.opacity(0.09 + intensity * 0.11))
                )

                // ── 内側 CY patch（別角度の断面 = CY の自己交差を暗示） ─
                // 5葉の別 patch を示すため少し多めに描く
                let mirrorScale = 0.44
                for vi in stride(from: 0, through: vSteps, by: 4) {
                    let v = Double(vi) / Double(vSteps) * .pi - .pi / 2
                    var pts = [SIMD3<Double>]()
                    for ui in 0...uSteps {
                        let u = Double(ui) / Double(uSteps) * 2 * .pi
                        var p = rotate(surface(u: u, v: v, s: s), rx: rxM, ry: ryM, rz: rz * 0.35)
                        p *= mirrorScale
                        pts.append(p)
                    }
                    let avgZ = pts.map(\.z).reduce(0,+) / Double(pts.count)
                    let zn   = (avgZ + 1.0) / 2.0
                    // 虹彩色：内 patch は補色方向にシフト
                    let irisColor = iridescent(base: mc, shift: 0.6, zn: zn)
                    let path = splinePath(pts, cx: cx, cy: cy, r: r)
                    ctx.stroke(path, with: .color(irisColor.opacity(0.07 + zn * 0.12)), lineWidth: 0.55)
                }

                // ── Fresnel エッジグロー ──────────────────────────────
                for line in lines where abs(line.avgZ) < 0.52 && abs(line.avgZ) > 0.04 {
                    let edge = 1.0 - abs(line.avgZ) / 0.52
                    let path = splinePath(line.pts, cx: cx, cy: cy, r: r)
                    var fr = ctx
                    fr.addFilter(.blur(radius: 9))
                    fr.stroke(path, with: .color(mc.opacity(edge * 0.45)), lineWidth: 3.2)
                }

                // ── 外面ワイヤーフレーム（虹彩色 + Catmull-Rom） ─────
                for line in lines {
                    let zn      = (line.avgZ + 1.8) / 3.6
                    let front   = line.avgZ > -0.05
                    let opacity = front ? (0.11 + zn * 0.58) : (0.02 + zn * 0.05)
                    let lw      = front ? (0.32 + zn * 1.25) : 0.20
                    // 虹彩色: 奥行きで hue がわずかにシフト → ホロモーフィック感
                    let lineColor = front ? iridescent(base: mc, shift: zn * 0.25, zn: zn)
                                          : Color(white: 0.26)

                    let path = splinePath(line.pts, cx: cx, cy: cy, r: r)

                    if front && zn > 0.55 {
                        var gl = ctx
                        gl.addFilter(.blur(radius: 4.5))
                        gl.stroke(path, with: .color(mc.opacity(opacity * 0.28)), lineWidth: lw * 3.0)
                    }
                    ctx.stroke(path, with: .color(lineColor.opacity(opacity)), lineWidth: lw)
                }

                // ── 軌道パーティクル（屈折光の散乱点） ───────────────
                for (i, sv) in s.enumerated() {
                    guard sv > 0.06 else { continue }
                    let θ  = t * (0.30 + Double(i) * 0.08) + Double(i) * .pi / 3
                    let φ  = sin(t * 0.20 + Double(i) * 1.3) * .pi / 4
                    let or = r * (0.96 + sv * 0.20)
                    let px = cx + cos(θ) * cos(φ) * or
                    let py = cy + sin(θ) * cos(φ) * or * 0.60
                    let pr = 1.6 + sv * 3.8

                    var pg = ctx
                    pg.addFilter(.blur(radius: 5))
                    pg.fill(
                        Path(ellipseIn: CGRect(x: px-pr, y: py-pr, width: pr*2, height: pr*2)),
                        with: .color(tagColors[i].opacity(sv * 0.60))
                    )
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: px-pr*0.38, y: py-pr*0.38, width: pr*0.76, height: pr*0.76)),
                        with: .color(tagColors[i].opacity(0.88))
                    )
                }

                // ── スペキュラー（ガラス球の一次・二次反射） ─────────
                let sx1 = cx + r * 0.28, sy1 = cy - r * 0.30
                var sp1 = ctx
                sp1.addFilter(.blur(radius: 14))
                sp1.fill(
                    Path(ellipseIn: CGRect(x: sx1-22, y: sy1-18, width: 44, height: 36)),
                    with: .color(.white.opacity(0.28 + intensity * 0.22))
                )
                let sx2 = cx - r * 0.20, sy2 = cy + r * 0.26
                var sp2 = ctx
                sp2.addFilter(.blur(radius: 22))
                sp2.fill(
                    Path(ellipseIn: CGRect(x: sx2-12, y: sy2-12, width: 24, height: 24)),
                    with: .color(mc.opacity(0.13 + intensity * 0.13))
                )

                // ── 中心核（焦点：内と外をつなぐ点） ─────────────────
                let cr = 2.2 + intensity * 4.5
                var cp = ctx
                cp.addFilter(.blur(radius: 8))
                cp.fill(
                    Path(ellipseIn: CGRect(x: cx-cr, y: cy-cr, width: cr*2, height: cr*2)),
                    with: .color(mc.opacity(0.80))
                )
                ctx.fill(
                    Path(ellipseIn: CGRect(x: cx-cr*0.38, y: cy-cr*0.38, width: cr*0.76, height: cr*0.76)),
                    with: .color(.white.opacity(0.88))
                )
            }
        }
    }

    // MARK: - Catmull-Rom → Cubic Bezier スプライン

    private func splinePath(_ pts3D: [SIMD3<Double>], cx: Double, cy: Double, r: Double) -> Path {
        guard pts3D.count >= 2 else { return Path() }

        let fov = 3.6
        let proj: (SIMD3<Double>) -> CGPoint = { p in
            let sc = fov / (fov - p.z * 0.25)
            return CGPoint(x: cx + p.x * r * sc, y: cy - p.y * r * sc)
        }

        let pts = pts3D.map(proj)
        var path = Path()
        path.move(to: pts[0])

        for i in 1..<pts.count {
            let p0 = i > 1             ? pts[i - 2] : pts[i - 1]
            let p1 = pts[i - 1]
            let p2 = pts[i]
            let p3 = i < pts.count - 1 ? pts[i + 1] : pts[i]

            let cp1 = CGPoint(x: p1.x + (p2.x - p0.x) / 6.0,
                              y: p1.y + (p2.y - p0.y) / 6.0)
            let cp2 = CGPoint(x: p2.x - (p3.x - p1.x) / 6.0,
                              y: p2.y - (p3.y - p1.y) / 6.0)
            path.addCurve(to: p2, control1: cp1, control2: cp2)
        }
        return path
    }

    // MARK: - Calabi-Yau quintic 変形球面

    /// CY quintic (n=5) の特徴的な多葉形状を近似する変形球面。
    /// - 5回対称の主葉: `cos(5u)·cos²(v)` — 赤道方向に5つの膨らみ
    /// - 螺旋ねじれ: `sin(5u + 2v)` — ホロモーフィック構造を暗示
    /// - 二次細部: `cos(10u)·cos(2v)` — 葉間の折れ込み（自己交差の痕跡）
    /// - 6軸スコアが各成分の振幅を変調
    private func surface(u: Double, v: Double, s: [Double]) -> SIMD3<Double> {
        let n = 5.0

        // CY quintic の基底形状（スコア非依存）
        var radius = 1.0
        radius += 0.38 * cos(n * u) * pow(cos(v), 2)          // 5葉の主成分
        radius += 0.16 * sin(n * u + 2 * v)                    // 螺旋ねじれ
        radius -= 0.10 * cos(2 * n * u) * cos(2 * v)          // 葉間の折れ込み

        // 6軸スコアによる変調（基底形状を"呼吸"させる）
        radius += s[0] * 0.14 * sin(2*u) * pow(cos(v), 2)     // groove: 水平脈動
        radius += s[1] * 0.12 * sin(n*u) * abs(sin(v))        // hype:   縦方向の突出
        radius += s[2] * 0.16 * cos(2*v) * (1 + 0.2*cos(u))  // chill:  極付近の静けさ
        radius += s[3] * 0.11 * sin(n*u) * cos(2*v)           // immersion: 深い没入の歪み
        radius += s[4] * 0.09 * cos(2*u + v) * sin(v)        // hit:    衝撃の跳ね返り
        radius += s[5] * 0.08 * cos(u) * cos(2*v + .pi/5)    // afterglow: 余韻の揺らぎ

        let rr = max(radius, 0.18)
        return SIMD3(rr * cos(v) * cos(u), rr * cos(v) * sin(u), rr * sin(v))
    }

    // MARK: - 虹彩色（ホロモーフィック構造の視覚的暗示）

    /// 奥行き (zn) と shift に応じて hue を微小にシフトさせる。
    /// CY 多様体の複素構造が視点方向で「違う色の断面」を見せることを暗示。
    private func iridescent(base: Color, shift: Double, zn: Double) -> Color {
        guard let resolved = UIColor(base).cgColor.components, resolved.count >= 3 else { return base }
        let r = resolved[0], g = resolved[1], b = resolved[2]
        let mix = shift * 0.18
        return Color(
            red:   min(max(Double(r) + mix * sin(zn * .pi), 0), 1),
            green: min(max(Double(g) + mix * cos(zn * .pi * 0.7), 0), 1),
            blue:  min(max(Double(b) + mix * sin(zn * .pi * 1.3 + 1.0), 0), 1)
        )
    }

    // MARK: - 3D 回転

    private func rotate(_ p: SIMD3<Double>, rx: Double, ry: Double, rz: Double) -> SIMD3<Double> {
        var q = p
        let (cxr, sxr) = (cos(rx), sin(rx))
        (q.y, q.z) = (q.y*cxr - q.z*sxr, q.y*sxr + q.z*cxr)
        let (cyr, syr) = (cos(ry), sin(ry))
        (q.x, q.z) = (q.x*cyr + q.z*syr, -q.x*syr + q.z*cyr)
        let (czr, szr) = (cos(rz), sin(rz))
        (q.x, q.y) = (q.x*czr - q.y*szr, q.x*szr + q.y*czr)
        return q
    }

    // MARK: - スコア補正（最低限のアニメーション保証）

    private func effectiveScores(time t: Double) -> [Double] {
        let breath = 0.06 + sin(t * 0.62) * 0.04
        if isActive {
            return [
                max(score.groove    + breath, 0.08),
                max(score.hype      + breath, 0.07),
                max(score.chill     + breath, 0.08),
                max(score.immersion + breath, 0.07),
                max(score.hit       + breath, 0.06),
                max(score.afterglow + breath, 0.06),
            ]
        } else {
            return [
                0.12 + sin(t * 0.46) * 0.08,
                0.09 + sin(t * 0.37 + 1.0) * 0.07,
                0.15 + cos(t * 0.50) * 0.08,
                0.08 + sin(t * 0.32 + 2.0) * 0.06,
                0.11 + cos(t * 0.43 + 0.5) * 0.07,
                0.09 + sin(t * 0.39 + 3.0) * 0.06,
            ]
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack {
            ReactionMorphView(
                score: ReactionScore(
                    groove: 0.85, hype: 0.60, chill: 0.20,
                    immersion: 0.95, hit: 0.70, afterglow: 0.40
                ),
                isActive: true
            )
            .frame(height: 360)
        }
    }
}
