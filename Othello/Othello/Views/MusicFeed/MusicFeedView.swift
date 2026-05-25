import SwiftUI

struct MusicFeedView: View {
    let artist: Artist
    let onSongTap: (Song) -> Void
    @StateObject private var viewModel: MusicFeedViewModel
    @State private var clipSong: Song?
    @Environment(\.dismiss) private var dismiss

    init(artist: Artist, onSongTap: @escaping (Song) -> Void) {
        self.artist = artist
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
            Text("Listening")
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
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.selectedSongIndex = index
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(LinearGradient(colors: song.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 24, height: 24)
                            Text(song.title)
                                .font(.subheadline)
                                .fontWeight(viewModel.selectedSongIndex == index ? .bold : .regular)
                                .foregroundStyle(viewModel.selectedSongIndex == index ? .white : Color.gray)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(
                            viewModel.selectedSongIndex == index
                                ? Color.white.opacity(0.12)
                                : Color.clear,
                            in: Capsule()
                        )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    private var feedList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.posts) { post in
                    FeedPostCard(post: post, onSongTap: {
                        clipSong = post.song
                        onSongTap(post.song)
                    })
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
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
            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(colors: song.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 52, height: 52)
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

#Preview {
    MusicFeedView(artist: Artist.mock[0], onSongTap: { _ in })
}
