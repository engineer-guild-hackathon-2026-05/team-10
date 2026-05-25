import SwiftUI

struct InlineWaveformView: View {
    let waveformData: [CGFloat]
    let totalDuration: Double
    let clipStart: Double
    let clipEnd: Double
    let onDrag: (Double, Double) -> Void

    @State private var isDraggingStart: Bool = true

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let barCount = waveformData.count
            let gap: CGFloat = 2.5
            let barWidth = (width - gap * CGFloat(barCount - 1)) / CGFloat(barCount)
            let safeDuration = max(totalDuration, 1e-6)
            let clipStartX = CGFloat(clipStart / safeDuration) * width
            let clipEndX = CGFloat(clipEnd / safeDuration) * width

            ZStack {
                Color(red: 0.1, green: 0.1, blue: 0.12)

                Canvas { context, _ in
                    for (i, amplitude) in waveformData.enumerated() {
                        let x = CGFloat(i) * (barWidth + gap)
                        let barH = amplitude * height * 0.88
                        let y = (height - barH) / 2
                        let rect = CGRect(x: x, y: y, width: max(barWidth, 1.5), height: barH)
                        let inRange = x >= clipStartX && (x + barWidth) <= clipEndX
                        context.fill(
                            Path(roundedRect: rect, cornerRadius: barWidth / 2),
                            with: .color(inRange ? .white : Color.white.opacity(0.22))
                        )
                    }
                }

                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(
                        Color(red: 0.55, green: 0.42, blue: 0.9),
                        lineWidth: 2.5
                    )
                    .frame(width: max(0, clipEndX - clipStartX), height: height)
                    .position(x: clipStartX + (clipEndX - clipStartX) / 2, y: height / 2)
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let ratio = Double(value.location.x / width).clamped(to: 0...1)
                        let startRatio = clipStart / safeDuration
                        let endRatio = clipEnd / safeDuration
                        if value.translation == .zero {
                            isDraggingStart = ratio < (startRatio + endRatio) / 2
                        }
                        if isDraggingStart {
                            onDrag(min(ratio, endRatio - 0.05), endRatio)
                        } else {
                            onDrag(startRatio, max(ratio, startRatio + 0.05))
                        }
                    }
            )
        }
    }
}
