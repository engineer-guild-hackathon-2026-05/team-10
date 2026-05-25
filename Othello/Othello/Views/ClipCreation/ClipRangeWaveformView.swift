import SwiftUI

struct ClipRangeWaveformView: View {
    let waveformData: [CGFloat]
    let totalDuration: Double
    let clipStart: Double
    let clipEnd: Double
    let onDrag: (Double, Double) -> Void

    @State private var isDraggingStart: Bool?

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let barCount = max(waveformData.count, 1)
            let gap: CGFloat = 2.5
            let barWidth = max((width - gap * CGFloat(barCount - 1)) / CGFloat(barCount), 1.5)
            let safeDuration = max(totalDuration, 1e-6)
            let clipStartX = CGFloat(clipStart / safeDuration) * width
            let clipEndX = CGFloat(clipEnd / safeDuration) * width
            let selectionWidth = max(0, clipEndX - clipStartX)
            let handleInset: CGFloat = 8
            let startHandleX = min(max(clipStartX, handleInset), max(width - handleInset, handleInset))
            let endHandleX = min(max(clipEndX, handleInset), max(width - handleInset, handleInset))

            ZStack {
                Color(red: 0.1, green: 0.1, blue: 0.12)

                Canvas { context, _ in
                    for (i, amplitude) in waveformData.enumerated() {
                        let x = CGFloat(i) * (barWidth + gap)
                        let barHeight = amplitude * height * 0.84
                        let y = (height - barHeight) / 2
                        let rect = CGRect(x: x, y: y, width: barWidth, height: barHeight)
                        let isSelected = x >= clipStartX && (x + barWidth) <= clipEndX
                        context.fill(
                            Path(roundedRect: rect, cornerRadius: barWidth / 2),
                            with: .color(isSelected ? .white : Color.white.opacity(0.22))
                        )
                    }
                }

                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(red: 0.55, green: 0.42, blue: 0.9).opacity(0.16))
                    .frame(width: selectionWidth, height: height)
                    .position(x: clipStartX + selectionWidth / 2, y: height / 2)

                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color(red: 0.72, green: 0.58, blue: 1.0), lineWidth: 2.5)
                    .frame(width: selectionWidth, height: height)
                    .position(x: clipStartX + selectionWidth / 2, y: height / 2)

                rangeHandle
                    .position(x: startHandleX, y: height / 2)
                rangeHandle
                    .position(x: endHandleX, y: height / 2)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard width > 0 else { return }
                        let rawRatio = Double(value.location.x / width)
                        guard rawRatio.isFinite else { return }
                        let ratio = rawRatio.clamped(to: 0...1)
                        let startRatio = (clipStart / safeDuration).clamped(to: 0...1)
                        let endRatio = (clipEnd / safeDuration).clamped(to: 0...1)

                        if isDraggingStart == nil {
                            isDraggingStart = abs(ratio - startRatio) <= abs(ratio - endRatio)
                        }

                        if isDraggingStart == true {
                            let nextStartRatio = min(ratio, endRatio - 0.05).clamped(to: 0...1)
                            onDrag(nextStartRatio, endRatio)
                        } else {
                            let nextEndRatio = max(ratio, startRatio + 0.05).clamped(to: 0...1)
                            onDrag(startRatio, nextEndRatio)
                        }
                    }
                    .onEnded { _ in
                        isDraggingStart = nil
                    }
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("クリップ範囲")
            .accessibilityValue(accessibilityValue)
            .accessibilityHint("上下にスワイプして範囲を前後に移動")
            .accessibilityAdjustableAction { direction in
                adjustRange(for: direction)
            }
        }
    }

    private var rangeHandle: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color.white)
            .frame(width: 6, height: 44)
            .shadow(color: Color.black.opacity(0.35), radius: 4, y: 1)
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .stroke(Color.black.opacity(0.18), lineWidth: 0.5)
            )
            .accessibilityHidden(true)
    }

    private var accessibilityValue: String {
        "\(formatTime(clipStart))から\(formatTime(clipEnd))"
    }

    private func adjustRange(for direction: AccessibilityAdjustmentDirection) {
        guard totalDuration > 0 else { return }

        let step = max(totalDuration * 0.01, 0.1)
        let start = clipStart.clamped(to: 0...totalDuration)
        let end = clipEnd.clamped(to: 0...totalDuration)
        let rangeDuration = max(end - start, step)
        let nextStart: Double
        let nextEnd: Double

        switch direction {
        case .increment:
            nextEnd = min(totalDuration, end + step)
            nextStart = max(0, nextEnd - rangeDuration)
        case .decrement:
            nextStart = max(0, start - step)
            nextEnd = min(totalDuration, nextStart + rangeDuration)
        @unknown default:
            return
        }

        onDrag(nextStart / totalDuration, nextEnd / totalDuration)
    }

    private func formatTime(_ seconds: Double) -> String {
        let clampedSeconds = max(0, seconds)
        let minutes = Int(clampedSeconds) / 60
        let secondsComponent = Int(clampedSeconds) % 60
        return String(format: "%d:%02d", minutes, secondsComponent)
    }
}
