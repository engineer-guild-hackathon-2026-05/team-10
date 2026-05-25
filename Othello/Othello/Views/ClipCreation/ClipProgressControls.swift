import SwiftUI

struct ClipProgressControls: View {
    let currentTime: Double
    let totalDuration: Double
    let isPlaying: Bool
    let leadingButtonSize: CGFloat
    let playButtonSize: CGFloat
    let progressKnobSize: CGFloat
    let onTogglePlayback: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.4), lineWidth: 1.5)
                    .frame(width: leadingButtonSize, height: leadingButtonSize)
                Text("30")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }

            GeometryReader { geo in
                let width = geo.size.width
                let safeDuration = max(totalDuration, 1e-6)
                let progress = min(max(currentTime / safeDuration, 0), 1)

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.18))
                        .frame(height: 3)
                    Capsule()
                        .fill(Color.white)
                        .frame(width: width * progress, height: 3)
                    Circle()
                        .fill(Color.white)
                        .frame(width: progressKnobSize, height: progressKnobSize)
                        .offset(x: width * progress - progressKnobSize / 2)
                }
                .frame(maxHeight: .infinity)
            }
            .frame(height: 20)

            Button(action: onTogglePlayback) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: playButtonSize, height: playButtonSize)
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: playIconSize, weight: .bold))
                        .foregroundStyle(Color.black)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isPlaying ? "一時停止" : "再生")
        }
    }

    private var playIconSize: CGFloat {
        playButtonSize >= 52 ? 20 : 18
    }
}
