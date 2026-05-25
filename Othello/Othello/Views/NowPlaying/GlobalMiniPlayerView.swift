import SwiftUI

struct GlobalMiniPlayerView: View {
    let song: Song?
    let onTap: () -> Void
    @ObservedObject var playback: PlaybackViewModel

    var body: some View {
        if let song {
            playerContent(song: song)
        }
    }

    private func playerContent(song: Song) -> some View {
        HStack(spacing: 12) {
            CircularArtworkView(song: song, size: 46, isPlaying: playback.isPlaying)

            Text(playback.isPlaying ? song.title : "再生停止中")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .lineLimit(1)

            Spacer()

            Button {
                Task { await playback.togglePlayback() }
            } label: {
                Image(systemName: playback.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title3)
                    .foregroundStyle(.primary)
                    .frame(width: 36, height: 36)
            }

            Button {} label: {
                Image(systemName: "forward.fill")
                    .font(.title3)
                    .foregroundStyle(.tertiary)
                    .frame(width: 36, height: 36)
            }
            .disabled(true)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background {
            ZStack {
                Capsule()
                    .fill(.ultraThinMaterial)
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: song.gradientColors.map { $0.opacity(0.25) },
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                Capsule()
                    .strokeBorder(Color.white.opacity(0.35), lineWidth: 1)
            }
        }
        .contentShape(Capsule())
        .onTapGesture { onTap() }
    }
}
