import SwiftUI

struct HighlightedHowCardCommentCard: View {
    let item: HomeDashboardComment
    let replyCount: Int
    let onSongTap: () -> Void
    let onReply: () -> Void
    @State private var isLiked = false

    init(
        item: HomeDashboardComment,
        replyCount: Int? = nil,
        onSongTap: @escaping () -> Void,
        onReply: @escaping () -> Void = {}
    ) {
        self.item = item
        self.replyCount = replyCount ?? item.howCard.replyCount
        self.onSongTap = onSongTap
        self.onReply = onReply
    }

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

            MiniSongCard(context: NowPlayingContext(song: item.song, howCardComment: item.howCard), onTap: onSongTap)

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
                Button(action: onReply) {
                    HStack(spacing: 6) {
                        Image(systemName: "bubble.left")
                            .foregroundStyle(.white)
                        Text("\(replyCount)")
                            .font(.subheadline)
                            .foregroundStyle(.white)
                    }
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
