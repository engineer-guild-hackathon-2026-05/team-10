import SwiftUI
import Combine

struct SyncBeatCircularWaveformView: View {
    let isAnimating: Bool

    private let sampleCount = 60
    private let timer = Timer.publish(every: 1.0 / 30.0, on: .main, in: .common).autoconnect()

    @State private var amplitudes: [CGFloat] = []

    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                let rect = CGRect(origin: .zero, size: size)
                let center = CGPoint(x: rect.midX, y: rect.midY)
                let diameter = min(size.width, size.height)
                let shape = SyncBeatCircularWaveformShape(
                    kernel: [1],
                    amplitudes: amplitudes,
                    innerRadius: diameter * 0.37,
                    maxThickness: diameter * 0.075
                )
                let path = shape.path(in: rect)

                context.drawLayer { layerContext in
                    layerContext.addFilter(.blur(radius: 10))
                    layerContext.stroke(
                        path,
                        with: .color(Color.white.opacity(0.30)),
                        style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round)
                    )
                }

                let gradient = Gradient(colors: [
                    Color.red.opacity(0.82),
                    Color.orange.opacity(0.74),
                    Color.yellow.opacity(0.56),
                    Color.green.opacity(0.42),
                    Color.blue.opacity(0.66),
                    Color.purple.opacity(0.80)
                ])

                context.stroke(
                    path,
                    with: .linearGradient(
                        gradient,
                        startPoint: CGPoint(x: center.x, y: rect.minY),
                        endPoint: CGPoint(x: center.x, y: rect.maxY)
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
                )

                let outline = path.strokedPath(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                context.stroke(outline, with: .color(Color.white.opacity(0.36)))
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .onReceive(timer) { _ in
                if isAnimating {
                    updateSmoothAmplitudes()
                } else {
                    settleAmplitudes()
                }
            }
            .onAppear {
                initializeAmplitudes()
            }
        }
    }

    private func initializeAmplitudes() {
        amplitudes = (0..<sampleCount).map { _ in CGFloat.random(in: 0...0.7) }
    }

    private func updateSmoothAmplitudes() {
        if amplitudes.count != sampleCount {
            initializeAmplitudes()
        }

        var newAmplitudes = [CGFloat](repeating: 0, count: sampleCount)
        let blend: CGFloat = 0.65

        for index in 0..<sampleCount {
            let previous = amplitudes[index]
            let next = CGFloat.random(in: 0...0.8)
            newAmplitudes[index] = previous * (1 - blend) + next * blend
        }

        amplitudes = newAmplitudes
    }

    private func settleAmplitudes() {
        if amplitudes.count != sampleCount {
            amplitudes = Array(repeating: 0, count: sampleCount)
            return
        }

        amplitudes = amplitudes.map { $0 * 0.72 }
    }
}

private struct SyncBeatCircularWaveformShape: Shape {
    let kernel: [CGFloat]
    var amplitudes: [CGFloat]
    var innerRadius: CGFloat
    var maxThickness: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let count = amplitudes.count

        guard count >= 4 else {
            return path
        }

        let kernelCount = kernel.count
        let offset = kernelCount / 2
        var smoothed = [CGFloat](repeating: 0, count: count)

        for index in 0..<count {
            var sum: CGFloat = 0
            for kernelIndex in 0..<kernelCount {
                let wrappedIndex = (index + kernelIndex - offset + count) % count
                sum += amplitudes[wrappedIndex] * kernel[kernelIndex]
            }
            smoothed[index] = sum
        }

        let radii = smoothed.map { innerRadius + pow($0, 0.6) * maxThickness }
        let angleStep = 2.0 * .pi / CGFloat(count)
        let points = radii.enumerated().map { index, radius in
            let theta = CGFloat(index) * angleStep
            return CGPoint(
                x: center.x + cos(theta) * radius,
                y: center.y + sin(theta) * radius
            )
        }

        path.move(to: points[0])

        let tension: CGFloat = 1.0 / 6.0
        for index in 0..<count {
            let previousIndex = (index - 1 + count) % count
            let currentIndex = index
            let nextIndex = (index + 1) % count
            let nextNextIndex = (index + 2) % count

            let previous = points[previousIndex]
            let current = points[currentIndex]
            let next = points[nextIndex]
            let nextNext = points[nextNextIndex]

            let control1 = CGPoint(
                x: current.x + (next.x - previous.x) * tension,
                y: current.y + (next.y - previous.y) * tension
            )
            let control2 = CGPoint(
                x: next.x - (nextNext.x - current.x) * tension,
                y: next.y - (nextNext.y - current.y) * tension
            )

            path.addCurve(to: next, control1: control1, control2: control2)
        }

        path.closeSubpath()
        return path
    }
}
