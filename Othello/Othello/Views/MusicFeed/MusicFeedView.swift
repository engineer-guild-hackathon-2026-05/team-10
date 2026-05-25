import SwiftUI

struct MusicFeedView: View {
    let artist: Artist
    let onSongTap: (Song) -> Void
    @ObservedObject private var playback: PlaybackViewModel
    @StateObject private var viewModel: MusicFeedViewModel
    @Environment(\.dismiss) private var dismiss

    init(artist: Artist, onSongTap: @escaping (Song) -> Void, playback: PlaybackViewModel) {
        self.artist = artist
        self.onSongTap = onSongTap
        self.playback = playback
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
        .task(id: viewModel.selectedSong?.firestoreSongID) {
            await viewModel.loadPosts()
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
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                        .padding(.vertical, 24)
                } else if let errorMessage = viewModel.errorMessage {
                    feedStatusMessage(errorMessage, systemImage: "wifi.exclamationmark")
                } else if viewModel.posts.isEmpty {
                    feedStatusMessage("この曲のHowカードはまだありません", systemImage: "music.note.list")
                }

                ForEach(viewModel.posts) { post in
                    FeedPostCard(post: post, onSongTap: {
                        play(post: post)
                    }, onLike: {
                        like(post: post)
                    })
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    private func feedStatusMessage(_ message: String, systemImage: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(.gray)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }

    private func play(post: FeedPost) {
        Task {
            guard let track = await playback.select(song: post.song) else { return }
            let resolvedSong = Song(playbackTrack: track, fallback: post.song)
            onSongTap(resolvedSong)
        }
    }

    private func like(post: FeedPost) {
        guard let cardID = post.cardID else { return }
        Task {
            try? await FirebaseAPI.shared.incrementGoods(cardID: cardID)
        }
    }
}

// MARK: - Feed Post Card

private struct FeedPostCard: View {
    let post: FeedPost
    let onSongTap: () -> Void
    let onLike: () -> Void
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
                    guard !isLiked else { return }
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isLiked = true
                    }
                    onLike()
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
    MusicFeedView(artist: Artist.catalog[0], onSongTap: { _ in }, playback: PlaybackViewModel())
}
