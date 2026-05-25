import SwiftUI

struct LiveReactionScoreCard: View {
    let score: ReactionScore
    let eventCount: Int
    let classifierStatus: String
    let activityLabel: String?
    let airPodsStatus: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("リアルタイム反応")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(statusText)
                        .font(.caption)
                        .foregroundStyle(.gray)
                }

                Spacer()

                Text("\(eventCount)区間")
                    .font(.caption.bold())
                    .foregroundStyle(Color(red: 1.0, green: 0.3, blue: 0.3))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.08), in: Capsule())
            }

            VStack(spacing: 10) {
                ForEach(score.axes) { axis in
                    ReactionAxisBar(axis: axis, isCompact: true)
                }
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private var statusText: String {
        if let activityLabel {
            return "\(classifierStatus) / \(activityLabel) / \(airPodsStatus)"
        }
        return "\(classifierStatus) / \(airPodsStatus)"
    }
}
