import SwiftUI

struct GlobalMiniPlayerView: View {
    let song: Song?
    let onTap: () -> Void
    let onPlayPause: () -> Void
    @Binding var isPlaying: Bool

    var body: some View {
        if let song {
            playerContent(song: song)
        }
    }

    private func playerContent(song: Song) -> some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.ultraThinMaterial)
                        .frame(width: 46, height: 46)
                    Image(systemName: "music.note")
                        .font(.system(size: 20))
                        .foregroundStyle(.secondary)
                }

                Text(song.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Spacer()

                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isPlaying.toggle()
                    }
                    onPlayPause()
                } label: {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.title3)
                        .foregroundStyle(.primary)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
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
        }
        .buttonStyle(.plain)
        .contentShape(Capsule())
    }
}
