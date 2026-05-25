import SwiftUI

struct CircularArtworkView: View {
    let song: Song
    let size: CGFloat
    let isPlaying: Bool
    var showsCenterHole: Bool = false

    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            artwork
                .frame(width: size, height: size)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.12), lineWidth: 1))
                .rotationEffect(.degrees(rotation))

            if showsCenterHole {
                Circle()
                    .fill(Color.black.opacity(0.78))
                    .frame(width: max(34, size * 0.24), height: max(34, size * 0.24))
                    .overlay(Circle().stroke(Color.white.opacity(0.22), lineWidth: 1))
            }
        }
        .shadow(color: (song.gradientColors.first ?? .black).opacity(0.35), radius: size * 0.13, y: size * 0.06)
        .onAppear { updateRotation() }
        .onChange(of: isPlaying) { _, _ in updateRotation() }
    }

    @ViewBuilder
    private var artwork: some View {
        if let url = song.artworkURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .empty:
                    ProgressView()
                        .tint(.white.opacity(0.7))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(fallbackArtwork)
                case .failure:
                    fallbackArtwork
                @unknown default:
                    fallbackArtwork
                }
            }
        } else {
            fallbackArtwork
        }
    }

    private var fallbackArtwork: some View {
        ZStack {
            LinearGradient(
                colors: song.gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image(systemName: "music.note")
                .font(.system(size: max(16, size * 0.22), weight: .semibold))
                .foregroundStyle(.white.opacity(0.42))
        }
    }

    private func updateRotation() {
        guard isPlaying else { return }
        withAnimation(.linear(duration: 42).repeatForever(autoreverses: false)) {
            rotation = rotation == 0 ? 360 : rotation + 360
        }
    }
}
