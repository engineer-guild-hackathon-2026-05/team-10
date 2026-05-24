import SwiftUI

/// 6軸スコアをCalabi-Yau断面風の極座標フーリエ曲線で可視化するキャンバス
/// - 各軸が異なる高調波（n=2〜7）を担当し、スコアで振幅が変化
/// - 同じ曲線を60°ずつ6枚重ねることでCalabi-Yau的な対称構造を生成
/// - blendMode(.plusLighter)で交差部が自然に発光
struct ReactionMorphView: View {
    let score: ReactionScore
    let isActive: Bool

    private static let harmonics: [Double]  = [2, 3, 4, 5, 6, 7]
    private static let phases: [Double]     = [0, .pi/6, .pi/3, .pi/2, 2*(.pi)/3, 5*(.pi)/6]
    private static let tagColors: [Color]   = [
        Color(red: 1.0, green: 0.3,  blue: 0.3),   // groove
        Color(red: 1.0, green: 0.55, blue: 0.1),   // hype
        Color(red: 0.2, green: 0.7,  blue: 1.0),   // chill
        Color(red: 0.6, green: 0.3,  blue: 1.0),   // immersion
        Color(red: 1.0, green: 0.2,  blue: 0.5),   // hit
        Color(red: 0.9, green: 0.75, blue: 0.3),   // afterglow
    ]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0/60.0, paused: false)) { timeline in
            Canvas { context, size in
                let t   = timeline.date.timeIntervalSinceReferenceDate
                let cx  = size.width  / 2
                let cy  = size.height / 2
                let center = CGPoint(x: cx, y: cy)
                let maxR   = min(size.width, size.height) * 0.40

                let scores: [Double] = [
                    isActive ? score.groove    : 0.18,
                    isActive ? score.hype      : 0.14,
                    isActive ? score.chill     : 0.20,
                    isActive ? score.immersion : 0.12,
                    isActive ? score.hit       : 0.16,
                    isActive ? score.afterglow : 0.10,
                ]

                let intensity     = min(scores.reduce(0, +) / 3.0, 1.0)
                let dominantIdx   = scores.indices.max(by: { scores[$0] < scores[$1] }) ?? 0
                let dominantColor = Self.tagColors[dominantIdx]
                let rotSpeed      = isActive ? (0.06 + intensity * 0.06) : 0.03

                // ── 背景グロー ────────────────────────────────────────
                let glowR = maxR * (0.5 + intensity * 0.5)
                let glowPath = Path(ellipseIn: CGRect(
                    x: cx - glowR, y: cy - glowR, width: glowR * 2, height: glowR * 2))
                var bgCtx = context
                bgCtx.addFilter(.blur(radius: 48))
                bgCtx.fill(glowPath, with: .color(dominantColor.opacity(0.18 + intensity * 0.14)))

                // ── 6枚の対称シート（Calabi-Yau断面） ─────────────────
                context.blendMode = .plusLighter

                for sheet in 0..<6 {
                    let baseRot = t * rotSpeed + Double(sheet) * (.pi / 3)
                    let sheetColor = Self.tagColors[sheet]
                    let alpha = 0.25 + scores[sheet] * 0.55

                    let path = makeMorphPath(
                        center: center, maxR: maxR,
                        scores: scores, rotation: baseRot, steps: 480
                    )

                    // グロー層（ぼかしコピー）
                    var glowCtx = context
                    glowCtx.addFilter(.blur(radius: 10))
                    glowCtx.stroke(path,
                        with: .color(sheetColor.opacity(alpha * 0.6)),
                        lineWidth: 1.8)

                    // 輪郭線
                    context.stroke(path,
                        with: .color(sheetColor.opacity(alpha)),
                        lineWidth: 0.9)
                }

                context.blendMode = .normal

                // ── 軌道上を漂うパーティクル ──────────────────────────
                for (i, s) in scores.enumerated() {
                    guard s > 0.05 else { continue }
                    let orbitR  = maxR * (0.55 + s * 0.35)
                    let angle   = t * (0.25 + Double(i) * 0.08) + Double(i) * .pi / 3
                    let px      = cx + cos(angle) * orbitR
                    let py      = cy + sin(angle) * orbitR
                    let pr      = 2.5 + s * 4.5

                    let dot = Path(ellipseIn: CGRect(x: px - pr, y: py - pr, width: pr*2, height: pr*2))

                    var dotGlow = context
                    dotGlow.addFilter(.blur(radius: 6))
                    dotGlow.fill(dot, with: .color(Self.tagColors[i].opacity(s * 0.7)))

                    context.fill(dot, with: .color(Self.tagColors[i].opacity(0.9)))
                }

                // ── 中心核 ────────────────────────────────────────────
                let coreR   = 4.0 + intensity * 7.0
                let corePath = Path(ellipseIn: CGRect(
                    x: cx - coreR, y: cy - coreR, width: coreR*2, height: coreR*2))

                var coreGlow = context
                coreGlow.addFilter(.blur(radius: 12))
                coreGlow.fill(corePath, with: .color(dominantColor.opacity(0.8)))

                context.fill(corePath, with: .color(.white.opacity(0.95)))
            }
        }
    }

    // MARK: - 極座標フーリエ曲線生成

    private func makeMorphPath(
        center: CGPoint,
        maxR: Double,
        scores: [Double],
        rotation: Double,
        steps: Int
    ) -> Path {
        var points = [CGPoint]()
        points.reserveCapacity(steps + 1)

        for i in 0...steps {
            let θ = Double(i) / Double(steps) * 2 * .pi + rotation
            var r = maxR * 0.32
            for j in 0..<6 {
                r += maxR * 0.11 * scores[j] * cos(Self.harmonics[j] * θ + Self.phases[j])
            }
            r = max(r, maxR * 0.04)
            points.append(CGPoint(x: center.x + r * cos(θ), y: center.y + r * sin(θ)))
        }

        var path = Path()
        path.move(to: points[0])
        // Catmull-Rom 風の滑らかな補間（3点ずつ quadCurve）
        for i in stride(from: 1, to: points.count - 1, by: 2) {
            path.addQuadCurve(to: points[i + 1 < points.count ? i + 1 : i],
                              control: points[i])
        }
        path.closeSubpath()
        return path
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        ReactionMorphView(
            score: ReactionScore(
                groove: 0.8, hype: 0.5, chill: 0.3,
                immersion: 0.9, hit: 0.6, afterglow: 0.4
            ),
            isActive: true
        )
        .frame(height: 340)
    }
}
