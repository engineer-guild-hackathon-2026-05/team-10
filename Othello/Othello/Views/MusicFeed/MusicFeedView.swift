import SwiftUI

struct MusicFeedView: View {
    let artist: Artist
    let highlightedComment: HomeDashboardComment?
    let onSongTap: (Song) -> Void
    @StateObject private var viewModel: MusicFeedViewModel
    @State private var clipSong: Song?
    @Environment(\.dismiss) private var dismiss

    init(
        artist: Artist,
        highlightedComment: HomeDashboardComment? = nil,
        onSongTap: @escaping (Song) -> Void
    ) {
        self.artist = artist
        self.highlightedComment = highlightedComment
        self.onSongTap = onSongTap
        self._viewModel = StateObject(wrappedValue: MusicFeedViewModel(artist: artist))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                navigationBar
                songTabBar
                feedList
            }
        }
        .navigationBarHidden(true)
        .sheet(item: $clipSong) { song in
            ClipCreationView(song: song)
        }
        .preferredColorScheme(.dark)
    }

    private var navigationBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .foregroundStyle(.white)
                    .font(.title3)
            }
            Spacer()
            Text(artist.name)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            Spacer()
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.white)
                .font(.title3)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private var songTabBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(Array(artist.songs.enumerated()), id: \.element.id) { index, song in
                    songTabButton(index: index, song: song)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    private func songTabButton(index: Int, song: Song) -> some View {
        let isSelected: Bool = viewModel.selectedSongIndex == index
        let gradient = LinearGradient(colors: song.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
        let bgColor: Color = isSelected ? Color.white.opacity(0.12) : Color.clear
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.selectedSongIndex = index
            }
        } label: {
            HStack(spacing: 8) {
                Circle()
                    .fill(gradient)
                    .frame(width: 24, height: 24)
                Text(song.title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .bold : .regular)
                    .foregroundStyle(isSelected ? .white : Color.gray)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(bgColor, in: Capsule())
        }
    }

    private var feedList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if let highlightedComment {
                    HighlightedHowCardCommentCard(item: highlightedComment) {
                        onSongTap(highlightedComment.song)
                    }
                }

                ForEach(viewModel.posts) { post in
                    FeedPostCard(post: post, onSongTap: {
                        onSongTap(post.song)
                    })
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
}

private struct HighlightedHowCardCommentCard: View {
    let item: HomeDashboardComment
    let onSongTap: () -> Void
    @State private var isLiked = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Circle()
                    .fill(LinearGradient(colors: item.song.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 42, height: 42)
                    .overlay {
                        Text(String(item.artist.name.prefix(1)))
                            .font(.subheadline.weight(.heavy))
                            .foregroundStyle(.white)
                    }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 5) {
                        Text(item.artist.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption2)
                            .foregroundStyle(Color(red: 1.0, green: 0.3, blue: 0.3))
                    }
                    Text("Home dashboard · \(formatRange(start: item.howCard.songStart, end: item.howCard.songEnd))")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                Spacer()
                Text("選択中")
                    .font(.caption2.weight(.heavy))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(.white, in: Capsule())
            }

            Text(item.howCard.comment)
                .font(.subheadline)
                .foregroundStyle(Color.white.opacity(0.88))
                .fixedSize(horizontal: false, vertical: true)

            MiniSongCard(song: item.song, onTap: onSongTap)

            HStack(spacing: 20) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isLiked.toggle()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundStyle(isLiked ? Color(red: 1.0, green: 0.3, blue: 0.3) : .white)
                        Text("\(max(item.howCard.goods, 0) + (isLiked ? 1 : 0))")
                            .font(.subheadline)
                            .foregroundStyle(.white)
                    }
                }
                HStack(spacing: 6) {
                    Image(systemName: "bubble.left")
                        .foregroundStyle(.white)
                    Text("1")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                }
                Spacer()
                Image(systemName: "paperplane")
                    .foregroundStyle(.gray)
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.3, blue: 0.3).opacity(0.16),
                    Color.white.opacity(0.055)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(red: 1.0, green: 0.3, blue: 0.3).opacity(0.24), lineWidth: 1)
        )
    }

    private func formatRange(start: TimeInterval, end: TimeInterval) -> String {
        let safeEnd = end > start ? end : start
        return "\(formatTime(start))-\(formatTime(safeEnd))"
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let value = max(0, Int(time.rounded()))
        return String(format: "%d:%02d", value / 60, value % 60)
    }
}

// MARK: - Feed Post Card

private struct FeedPostCard: View {
    let post: FeedPost
    let onSongTap: () -> Void
    @State private var isLiked: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Circle()
                    .fill(post.avatarColor)
                    .frame(width: 40, height: 40)
                    .overlay {
                        Text(post.avatarLetter)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(post.userName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption2)
                            .foregroundStyle(Color(red: 1.0, green: 0.3, blue: 0.3))
                    }
                    Text("\(post.userHandle) · \(post.timeAgo)")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                Spacer()
                Image(systemName: "ellipsis")
                    .foregroundStyle(.gray)
                    .font(.subheadline)
            }

            Text(post.comment)
                .font(.subheadline)
                .foregroundStyle(Color.white.opacity(0.85))
                .lineLimit(3)

            MiniSongCard(song: post.song, onTap: onSongTap)

            HStack(spacing: 20) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isLiked.toggle()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundStyle(isLiked ? Color(red: 1.0, green: 0.3, blue: 0.3) : .white)
                        Text("\(post.likeCount + (isLiked ? 1 : 0))")
                            .font(.subheadline)
                            .foregroundStyle(.white)
                    }
                }
                HStack(spacing: 6) {
                    Image(systemName: "bubble.left")
                        .foregroundStyle(.white)
                    Text("\(post.commentCount)")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                }
                Spacer()
                Image(systemName: "paperplane")
                    .foregroundStyle(.gray)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Mini Song Card

private struct MiniSongCard: View {
    let song: Song
    let onTap: () -> Void
    @State private var isPlaying: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            MiniSongArtwork(song: song)
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
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isPlaying.toggle()
                }
                onTap()
            } label: {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(LinearGradient(colors: song.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct MiniSongArtwork: View {
    let song: Song

    var body: some View {
        ZStack {
            LinearGradient(colors: song.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)

            if let url = song.artworkURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        fallbackIcon
                    case .empty:
                        ProgressView()
                            .tint(.white.opacity(0.7))
                    @unknown default:
                        fallbackIcon
                    }
                }
            } else {
                fallbackIcon
            }
        }
        .frame(width: 52, height: 52)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var fallbackIcon: some View {
        Image(systemName: "music.note")
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(.white.opacity(0.42))
    }
}

#Preview {
    MusicFeedView(artist: Artist.mock[0], onSongTap: { _ in })
}
