import SwiftUI

/// 量子ゆらぎ → 収束 → 摩擦発熱 → 発火（🔥）のアーティスティック演出（FR-RES-05）。
/// Metal 非依存（Canvas + TimelineView）で確実にビルド。richMode で密度を変える。
struct QuantumIgnitionView: View {
    /// 演出開始時刻。マッチ確定時に更新するとリスタートする。
    var startDate: Date
    /// 発火後に表示する中心の絵文字。
    var symbol: String = "🔥"

    private let particles: [Particle]
    private let embers: [Ember]

    init(startDate: Date, symbol: String = "🔥") {
        self.startDate = startDate
        self.symbol = symbol
        var rng = SeededGenerator(seed: 0xA17C_2026_0526)
        self.particles = (0..<ResonanceVisualConfig.particleCount).map { _ in Particle(rng: &rng) }
        self.embers = (0..<ResonanceVisualConfig.emberCount).map { _ in Ember(rng: &rng) }
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            let elapsed = max(0, timeline.date.timeIntervalSince(startDate))
            let p = min(1.0, elapsed / ResonanceVisualConfig.cycleDuration)
            Canvas { ctx, size in
                draw(ctx: &ctx, size: size, progress: p, elapsed: elapsed)
            }
            .overlay(centerSymbol(progress: p))
        }
        .background(Color.black.opacity(0.0001)) // Canvas のヒットを安定させる
    }

    // MARK: - Drawing

    private func draw(ctx: inout GraphicsContext, size: CGSize, progress p: Double, elapsed: Double) {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let maxR = min(size.width, size.height) * 0.46
        ctx.blendMode = .plusLighter

        // フェーズ係数
        let appear = smooth(p, 0.0, 0.35)      // 量子ゆらぎ出現
        let converge = smooth(p, 0.30, 0.62)   // 中心へ収束
        let heat = smooth(p, 0.58, 0.80)       // 摩擦発熱
        let ignite = smooth(p, 0.78, 1.0)      // 発火

        // 量子粒子
        for particle in particles {
            let jitter = sin(elapsed * particle.wobbleSpeed + particle.phase) * (1 - converge) * 6
            let baseR = maxR * particle.radius
            let r = baseR * (1 - converge) + (maxR * 0.06) * converge
            let angle = particle.angle + elapsed * particle.spin * 0.3
            let pos = CGPoint(
                x: center.x + cos(angle) * (r + jitter),
                y: center.y + sin(angle) * (r + jitter)
            )
            let dotSize = particle.size * (0.6 + appear * 0.4)
            let temp = heat
            let color = blend(cold: Color(red: 0.55, green: 0.78, blue: 1.0),
                              hot: Color(red: 1.0, green: 0.72, blue: 0.32),
                              t: temp)
            let alpha = appear * (0.35 + 0.5 * converge) * (1 - ignite * 0.4)
            softDot(&ctx, at: pos, radius: dotSize, color: color.opacity(alpha))
        }

        // 中心コアのグロー（発熱→発火で増大）
        let coreAlpha = (converge * 0.5 + heat * 0.5)
        if coreAlpha > 0.01 {
            let coreR = maxR * (0.10 + heat * 0.22 + ignite * 0.20)
            let coreColor = blend(cold: Color(red: 0.6, green: 0.85, blue: 1.0),
                                  hot: Color(red: 1.0, green: 0.55, blue: 0.18),
                                  t: max(heat, ignite))
            ctx.fill(
                Path(ellipseIn: CGRect(x: center.x - coreR, y: center.y - coreR, width: coreR * 2, height: coreR * 2)),
                with: .radialGradient(
                    Gradient(colors: [coreColor.opacity(coreAlpha), .clear]),
                    center: center, startRadius: 0, endRadius: coreR
                )
            )
        }

        // 発火の火の粉
        if ignite > 0.01 {
            for ember in embers {
                let t = ignite
                let dist = maxR * ember.distance * t
                let rise = -maxR * 0.5 * t * ember.lift
                let angle = ember.angle
                let pos = CGPoint(
                    x: center.x + cos(angle) * dist + sin(elapsed * 3 + ember.phase) * 4,
                    y: center.y + sin(angle) * dist + rise
                )
                let emberColor = Color(red: 1.0, green: 0.5 - 0.3 * t, blue: 0.12)
                softDot(&ctx, at: pos, radius: ember.size * (1.1 - t * 0.5), color: emberColor.opacity((1 - t) * 0.9))
            }
        }
    }

    @ViewBuilder
    private func centerSymbol(progress p: Double) -> some View {
        let ignite = smooth(p, 0.80, 1.0)
        Text(symbol)
            .font(.system(size: 54))
            .scaleEffect(0.4 + ignite * 0.8)
            .opacity(ignite)
            .shadow(color: .orange.opacity(ignite), radius: 18)
    }

    private func softDot(_ ctx: inout GraphicsContext, at p: CGPoint, radius: CGFloat, color: Color) {
        let rect = CGRect(x: p.x - radius, y: p.y - radius, width: radius * 2, height: radius * 2)
        ctx.fill(
            Path(ellipseIn: rect),
            with: .radialGradient(Gradient(colors: [color, .clear]), center: p, startRadius: 0, endRadius: radius)
        )
    }

    // MARK: - Helpers

    /// 0..1 の区間 [a,b] を 0→1 に滑らかに写す（smoothstep）。
    private func smooth(_ x: Double, _ a: Double, _ b: Double) -> Double {
        guard b > a else { return x >= b ? 1 : 0 }
        let t = min(1, max(0, (x - a) / (b - a)))
        return t * t * (3 - 2 * t)
    }

    private func blend(cold: Color, hot: Color, t: Double) -> Color {
        let tt = min(1, max(0, t))
        let c = UIColor(cold), h = UIColor(hot)
        var c1 = (CGFloat(0), CGFloat(0), CGFloat(0), CGFloat(0))
        var h1 = (CGFloat(0), CGFloat(0), CGFloat(0), CGFloat(0))
        c.getRed(&c1.0, green: &c1.1, blue: &c1.2, alpha: &c1.3)
        h.getRed(&h1.0, green: &h1.1, blue: &h1.2, alpha: &h1.3)
        return Color(
            red: Double(c1.0 + (h1.0 - c1.0) * tt),
            green: Double(c1.1 + (h1.1 - c1.1) * tt),
            blue: Double(c1.2 + (h1.2 - c1.2) * tt)
        )
    }
}

// MARK: - Particle models

private struct Particle {
    let angle: Double
    let radius: Double   // 0..1
    let size: CGFloat
    let phase: Double
    let wobbleSpeed: Double
    let spin: Double

    init(rng: inout SeededGenerator) {
        angle = rng.next01() * .pi * 2
        radius = 0.25 + rng.next01() * 0.75
        size = CGFloat(3 + rng.next01() * 5)
        phase = rng.next01() * .pi * 2
        wobbleSpeed = 1.5 + rng.next01() * 3
        spin = rng.next01() * 2 - 1
    }
}

private struct Ember {
    let angle: Double
    let distance: Double
    let size: CGFloat
    let phase: Double
    let lift: Double

    init(rng: inout SeededGenerator) {
        angle = rng.next01() * .pi * 2
        distance = 0.4 + rng.next01() * 0.6
        size = CGFloat(2 + rng.next01() * 4)
        phase = rng.next01() * .pi * 2
        lift = 0.5 + rng.next01()
    }
}

/// 決定的な擬似乱数（粒子配置を毎フレーム安定させる）。
private struct SeededGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed != 0 ? seed : 0x9E3779B97F4A7C15 }
    mutating func next01() -> Double {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return Double(state % 1_000_000) / 1_000_000.0
    }
}
