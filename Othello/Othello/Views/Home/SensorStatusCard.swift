import SwiftUI

struct SensorStatusCard: View {
    let sensorStatus: SensorStatusBundle
    let isSessionActive: Bool
    let useManualMode: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if useManualMode {
                HStack(spacing: 6) {
                    Image(systemName: "hand.tap.fill")
                        .font(.caption)
                    Text("手動ラベルモード")
                        .font(.caption.bold())
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.8), in: Capsule())
            }

            Text("センサー状態")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.bottom, 2)

            SensorStatusRow(
                icon: "airpods",
                label: "AirPods 頭部モーション",
                statusLabel: isSessionActive ? sensorStatus.headMotion.label : "停止",
                statusColor: isSessionActive ? sensorStatus.headMotion.color : .yellow,
                statusImage: isSessionActive ? sensorStatus.headMotion.systemImage : "pause.circle.fill"
            )

            Divider()

            SensorStatusRow(
                icon: "heart.fill",
                label: "心拍（HealthKit）",
                statusLabel: isSessionActive ? sensorStatus.heartRate.label : "停止",
                statusColor: isSessionActive ? sensorStatus.heartRate.color : .yellow,
                statusImage: isSessionActive ? sensorStatus.heartRate.systemImage : "pause.circle.fill",
                iconColor: .pink
            )
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct SensorStatusRow: View {
    let icon: String
    let label: String
    let statusLabel: String
    let statusColor: Color
    let statusImage: String
    var iconColor: Color = .indigo

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
                .frame(width: 20)

            Text(label)
                .font(.subheadline)
                .foregroundStyle(.primary)

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: statusImage)
                    .foregroundStyle(statusColor)
                    .font(.caption)
                Text(statusLabel)
                    .font(.caption.bold())
                    .foregroundStyle(statusColor)
            }
        }
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [.indigo, .purple],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()

        VStack(spacing: 16) {
            SensorStatusCard(
                sensorStatus: .initial,
                isSessionActive: false,
                useManualMode: false
            )
            SensorStatusCard(
                sensorStatus: SensorStatusBundle(
                    headMotion: .connected,
                    bodyMotion: .acquiring,
                    heartRate: .unauthorized
                ),
                isSessionActive: true,
                useManualMode: true
            )
        }
        .padding()
    }
}
