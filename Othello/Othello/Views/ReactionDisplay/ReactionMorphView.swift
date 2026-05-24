import SwiftUI

/// 6軸スコアが変形させるリアルタイム3Dワイヤーフレーム球体
/// - 球面上の格子を3D回転 → パースペクティブ投影
/// - 奥行きで輝度・線幅を変え、前面だけグローを乗せることで3D感を演出
/// - TimelineView + Canvas で GPU を使わず 60fps
struct ReactionMorphView: View {
    let score: ReactionScore
    let isActive: Bool

    private let uSteps = 28
    private let vSteps = 18

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
                let r  = min(size.width, size.height) * 0.37

                let s  = effectiveScores(time: t)
                let di = s.indices.max(by: { s[$0] < s[$1] }) ?? 0
                let mc = tagColors[di]
                let intensity = min(s.reduce(0, +) / 2.5, 1.0)

                // ── 3D 回転行列パラメータ ────────────────────────────
                let rx = t * 0.18
                let ry = t * 0.27
                let rz = sin(t * 0.11) * 0.22

                // ── 球面格子を生成・回転 ─────────────────────────────
                struct Line { var pts: [SIMD3<Double>]; var avgZ: Double }
                var lines = [Line]()

                for vi in 0...vSteps {
                    let v  = Double(vi) / Double(vSteps) * .pi - .pi / 2
                    var pts = [SIMD3<Double>]()
                    for ui in 0...uSteps {
                        let u = Double(ui) / Double(uSteps) * 2 * .pi
                        pts.append(rotate(surface(u: u, v: v, s: s), rx: rx, ry: ry, rz: rz))
                    }
                    lines.append(Line(pts: pts, avgZ: pts.map(\.z).reduce(0, +) / Double(pts.count)))
                }
                for ui in 0...uSteps {
                    let u  = Double(ui) / Double(uSteps) * 2 * .pi
                    var pts = [SIMD3<Double>]()
                    for vi in 0...vSteps {
                        let v = Double(vi) / Double(vSteps) * .pi - .pi / 2
                        pts.append(rotate(surface(u: u, v: v, s: s), rx: rx, ry: ry, rz: rz))
                    }
                    lines.append(Line(pts: pts, avgZ: pts.map(\.z).reduce(0, +) / Double(pts.count)))
                }
                lines.sort { $0.avgZ < $1.avgZ }

                // ── 背景グロー ────────────────────────────────────────
                let bgR = r * (0.65 + intensity * 0.45)
                var bg  = ctx; bg.addFilter(.blur(radius: 52))
                bg.fill(
                    Path(ellipseIn: CGRect(x: cx-bgR, y: cy-bgR, width: bgR*2, height: bgR*2)),
                    with: .color(mc.opacity(0.20 + intensity * 0.18))
                )

                // ── ワイヤーフレーム描画（奥行き別カラー）─────────────
                for line in lines {
                    let zn      = (line.avgZ + 1.8) / 3.6           // 0…1
                    let front   = line.avgZ > -0.1
                    let opacity = front ? (0.25 + zn * 0.75) : (0.04 + zn * 0.12)
                    let lw      = front ? (0.5  + zn * 1.8)  : 0.35
                    let color   = front ? mc : Color(white: 0.35)

                    let path = project(line.pts, cx: cx, cy: cy, r: r)

                    if front && zn > 0.55 {
                        var gl = ctx; gl.addFilter(.blur(radius: 7))
                        gl.stroke(path, with: .color(mc.opacity(opacity * 0.45)), lineWidth: lw * 2.2)
                    }
                    ctx.stroke(path, with: .color(color.opacity(opacity)), lineWidth: lw)
                }

                // ── 軌道パーティクル（3D楕円軌道） ───────────────────
                for (i, sv) in s.enumerated() {
                    guard sv > 0.07 else { continue }
                    let θ  = t * (0.38 + Double(i) * 0.10) + Double(i) * .pi / 3
                    let φ  = sin(t * 0.28 + Double(i) * 1.3) * .pi / 5
                    let or = r * (0.90 + sv * 0.28)
                    let px = cx + cos(θ) * cos(φ) * or
                    let py = cy + sin(θ) * cos(φ) * or * 0.65
                    let pr = 2.8 + sv * 5.5

                    var pg = ctx; pg.addFilter(.blur(radius: 6))
                    pg.fill(
                        Path(ellipseIn: CGRect(x: px-pr, y: py-pr, width: pr*2, height: pr*2)),
                        with: .color(tagColors[i].opacity(sv * 0.75))
                    )
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: px-pr*0.45, y: py-pr*0.45, width: pr*0.9, height: pr*0.9)),
                        with: .color(tagColors[i])
                    )
                }

                // ── スペキュラーハイライト（光源：右上奥） ───────────
                let sx = cx + r * 0.38, sy = cy - r * 0.36
                var sp = ctx; sp.addFilter(.blur(radius: 22))
                sp.fill(
                    Path(ellipseIn: CGRect(x: sx-18, y: sy-18, width: 36, height: 36)),
                    with: .color(.white.opacity(0.22 + intensity * 0.28))
                )

                // ── 中心核 ────────────────────────────────────────────
                let cr = 3.5 + intensity * 6.5
                var cp = ctx; cp.addFilter(.blur(radius: 10))
                cp.fill(
                    Path(ellipseIn: CGRect(x: cx-cr, y: cy-cr, width: cr*2, height: cr*2)),
                    with: .color(mc.opacity(0.9))
                )
                ctx.fill(
                    Path(ellipseIn: CGRect(x: cx-cr*0.45, y: cy-cr*0.45, width: cr*0.9, height: cr*0.9)),
                    with: .color(.white.opacity(0.95))
                )
            }
        }
    }

    // MARK: - 変形球面

    private func surface(u: Double, v: Double, s: [Double]) -> SIMD3<Double> {
        var r = 1.0
        r += s[0] * 0.30 * sin(2*u) * pow(cos(v), 2)
        r += s[1] * 0.26 * sin(3*u) * abs(sin(v))
        r += s[2] * 0.23 * cos(2*v)
        r += s[3] * 0.28 * sin(5*u) * cos(3*v)
        r += s[4] * 0.20 * cos(4*u) * sin(2*v)
        r += s[5] * 0.17 * sin(7*u) * cos(v)
        r = max(r, 0.18)
        return SIMD3(r * cos(v) * cos(u), r * cos(v) * sin(u), r * sin(v))
    }

    // MARK: - 3D回転

    private func rotate(_ p: SIMD3<Double>, rx: Double, ry: Double, rz: Double) -> SIMD3<Double> {
        var q = p
        let (cx, sx) = (cos(rx), sin(rx))
        (q.y, q.z)   = (q.y*cx - q.z*sx, q.y*sx + q.z*cx)
        let (cy, sy) = (cos(ry), sin(ry))
        (q.x, q.z)   = (q.x*cy + q.z*sy, -q.x*sy + q.z*cy)
        let (cz, sz) = (cos(rz), sin(rz))
        (q.x, q.y)   = (q.x*cz - q.y*sz, q.x*sz + q.y*cz)
        return q
    }

    // MARK: - パースペクティブ投影

    private func project(_ pts: [SIMD3<Double>], cx: Double, cy: Double, r: Double) -> Path {
        let fov = 3.4
        var path = Path()
        for (i, p) in pts.enumerated() {
            let scale = fov / (fov - p.z * 0.28)
            let x = cx + p.x * r * scale
            let y = cy - p.y * r * scale
            if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
            else       { path.addLine(to: CGPoint(x: x, y: y)) }
        }
        return path
    }

    // MARK: - スコア補正（最低限のアニメーション保証）

    private func effectiveScores(time t: Double) -> [Double] {
        let breath = 0.08 + sin(t * 0.7) * 0.04
        if isActive {
            return [
                max(score.groove    + breath, 0.10),
                max(score.hype      + breath, 0.08),
                max(score.chill     + breath, 0.10),
                max(score.immersion + breath, 0.08),
                max(score.hit       + breath, 0.07),
                max(score.afterglow + breath, 0.07),
            ]
        } else {
            return [
                0.14 + sin(t * 0.50) * 0.09,
                0.11 + sin(t * 0.40 + 1.0) * 0.08,
                0.17 + cos(t * 0.55) * 0.09,
                0.09 + sin(t * 0.35 + 2.0) * 0.07,
                0.13 + cos(t * 0.48 + 0.5) * 0.08,
                0.11 + sin(t * 0.42 + 3.0) * 0.07,
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
