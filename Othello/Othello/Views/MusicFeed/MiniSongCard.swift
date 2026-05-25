import SwiftUI

struct MiniSongCard: View {
    let song: Song
    let onTap: () -> Void
    @State private var isPlaying: Bool = false

    var body: some View {
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
            }
            Spacer()
            playbackGlyph
        }
        .padding(12)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .onTapGesture {
            onTap()
        }
    }

    private var playbackGlyph: some View {
        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
            .font(.system(size: 36))
            .foregroundStyle(LinearGradient(colors: song.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
            .contentShape(Circle())
            .highPriorityGesture(
                TapGesture().onEnded {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isPlaying.toggle()
                    }
                    onTap()
                }
            )
    }
}
