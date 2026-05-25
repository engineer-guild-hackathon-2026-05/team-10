import SwiftUI

struct MusicFeedView: View {
    let artist: Artist
    let highlightedComment: HomeDashboardComment?
    let onSongTap: (Song) -> Void
    @ObservedObject private var playback: PlaybackViewModel
    @StateObject private var viewModel: MusicFeedViewModel
    @Environment(\.dismiss) private var dismiss

    init(
        artist: Artist,
        highlightedComment: HomeDashboardComment? = nil,
        onSongTap: @escaping (Song) -> Void,
        playback: PlaybackViewModel
    ) {
        self.artist = artist
        self.highlightedComment = highlightedComment
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
                if let highlightedComment {
                    HighlightedHowCardCommentCard(item: highlightedComment) {
                        onSongTap(highlightedComment.song)
                    }
                }

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

#Preview {
    MusicFeedView(artist: Artist.catalog[0], onSongTap: { _ in }, playback: PlaybackViewModel())
}
