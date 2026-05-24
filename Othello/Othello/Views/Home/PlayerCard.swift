import SwiftUI

struct PlayerCard: View {
    let trackTitle: String
    let trackArtist: String
    let playbackTime: TimeInterval
    let trackDuration: TimeInterval
    let isPlaying: Bool
    let onTogglePlayback: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            // アルバムアート（プレースホルダー）
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [Color.indigo.opacity(0.3), Color.purple.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .aspectRatio(1, contentMode: .fit)

                Image(systemName: "music.note")
                    .font(.system(size: 64))
                    .foregroundStyle(.indigo.opacity(0.6))
            }
            .frame(maxWidth: 200)

            // 曲名・アーティスト名
            VStack(spacing: 4) {
                Text(trackTitle)
                    .font(.title3.bold())
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text(trackArtist)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            // 再生位置スライダー
            VStack(spacing: 4) {
                Slider(value: .constant(trackDuration > 0 ? playbackTime / trackDuration : 0))
                    .tint(.indigo)
                    .disabled(true)

                HStack {
                    Text(formatTime(playbackTime))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(formatTime(trackDuration))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }

            // 再生/一時停止ボタン
            Button(action: onTogglePlayback) {
                ZStack {
                    Circle()
                        .fill(Color.indigo)
                        .frame(width: 64, height: 64)
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .offset(x: isPlaying ? 0 : 2)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [.indigo, .purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        PlayerCard(
            trackTitle: "感電",
            trackArtist: "米津玄師",
            playbackTime: 42,
            trackDuration: 268,
            isPlaying: true,
            onTogglePlayback: {}
        )
        .padding()
    }
}
