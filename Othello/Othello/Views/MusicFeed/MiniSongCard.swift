import SwiftUI

struct MiniSongCard: View {
    let context: NowPlayingContext
    let onTap: () -> Void
    @State private var isPlaying: Bool = false

    private var song: Song { context.song }

    var body: some View {
        Button {
            startPlayback()
        } label: {
            HStack(spacing: 12) {
                CircularArtworkView(song: song, size: 52, isPlaying: isPlaying)
                VStack(alignment: .leading, spacing: 3) {
                    Text(song.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                    Text(song.artistName)
                        .font(.caption)
                        .foregroundStyle(.gray)
                    if context.hasHighlight {
                        Text("How \(formatTime(context.highlightStart ?? context.initialPlaybackTime)) - \(formatTime(context.highlightEnd ?? context.initialPlaybackTime))")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(Color(red: 1.0, green: 0.3, blue: 0.3))
                    }
                }
                Spacer()
                playbackGlyph
            }
        }
        .buttonStyle(.plain)
        .padding(12)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
        .contentShape(RoundedRectangle(cornerRadius: 12))
    }

    private var playbackGlyph: some View {
        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
            .font(.system(size: 36))
            .foregroundStyle(LinearGradient(colors: song.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
    }

    private func startPlayback() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isPlaying.toggle()
        }
        onTap()
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let safeTime = max(0, Int(time.rounded()))
        return "\(safeTime / 60):\(String(format: "%02d", safeTime % 60))"
    }
}
