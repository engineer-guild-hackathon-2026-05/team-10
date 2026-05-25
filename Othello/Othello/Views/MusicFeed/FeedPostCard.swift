import SwiftUI

struct FeedPostCard: View {
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
