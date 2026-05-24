import SwiftUI

/// 1軸分のバーインジケーター
struct ReactionAxisBar: View {
    let axis: ReactionAxis
    var isCompact: Bool = false

    var body: some View {
        VStack(spacing: isCompact ? 4 : 6) {
            HStack(spacing: 4) {
                Text(axis.emoji)
                    .font(isCompact ? .caption : .body)
                Text(axis.label)
                    .font(isCompact ? .caption2 : .caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.white.opacity(0.85))
                Spacer()
                Text(Int(axis.value * 100).description + "%")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(axis.value > 0.1 ? axis.color : .gray.opacity(0.4))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.07))
                        .frame(height: isCompact ? 4 : 6)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [axis.color.opacity(0.8), axis.color],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * axis.value, height: isCompact ? 4 : 6)
                        .shadow(color: axis.color.opacity(axis.value > 0.5 ? 0.6 : 0), radius: 4)
                }
            }
            .frame(height: isCompact ? 4 : 6)
        }
    }
}
