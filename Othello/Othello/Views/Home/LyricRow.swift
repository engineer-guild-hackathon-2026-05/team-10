import SwiftUI

struct LyricRow: View {
    let lyric: String
    let translation: String?
    let howCount: Int
    let likeCount: Int
    let isHighlighted: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(lyric)
                    .font(.body)
                    .foregroundStyle(isHighlighted ? .white : Color.white.opacity(0.85))
                    .fontWeight(isHighlighted ? .semibold : .regular)
                if let translation {
                    Text(translation)
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                // コメント（How）バッジ
                HStack(spacing: 4) {
                    Image(systemName: "bubble.left")
                        .font(.caption2)
                    Text("\(howCount)")
                        .font(.caption.bold())
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isHighlighted ? Color(red: 0.85, green: 0.15, blue: 0.2) : Color.white.opacity(0.12), in: Capsule())

                // いいね数
                HStack(spacing: 4) {
                    Image(systemName: "heart")
                        .font(.caption2)
                    Text("\(likeCount)")
                        .font(.caption)
                }
                .foregroundStyle(.gray)
            }
            .frame(minWidth: 56)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(isHighlighted ? Color.white.opacity(0.04) : Color.clear)
        .contentShape(Rectangle())
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 0) {
            LyricRow(lyric: "深夜二時の改札を抜けて", translation: "Through the late-night turnstile", howCount: 4, likeCount: 82, isHighlighted: false)
            LyricRow(lyric: "コンビニの灯りに泳いだ", translation: "Swimming in the convenience-store glow", howCount: 12, likeCount: 341, isHighlighted: true)
            LyricRow(lyric: "君のメッセージは未読のまま", translation: "Your message still unread", howCount: 3, likeCount: 118, isHighlighted: false)
        }
    }
    .preferredColorScheme(.dark)
}
