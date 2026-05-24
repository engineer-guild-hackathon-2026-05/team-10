import SwiftUI

struct AirPodsMotionStatusView: View {
    @StateObject private var viewModel = AirPodsMotionViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header
            latestSampleSection
            eventSection
            Spacer(minLength: 0)
        }
        .padding(20)
        .navigationTitle("AirPods Motion")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(viewModel.status.title)
                        .font(.title2.bold())
                    Text(viewModel.status.detail)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Circle()
                    .fill(statusColor)
                    .frame(width: 14, height: 14)
                    .accessibilityLabel(viewModel.status.title)
            }

            HStack(spacing: 12) {
                Button {
                    viewModel.isRecording ? viewModel.stop() : viewModel.start()
                } label: {
                    Label(viewModel.isRecording ? "停止" : "取得開始", systemImage: viewModel.isRecording ? "stop.fill" : "airpodspro")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    viewModel.stop()
                } label: {
                    Label("リセット", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }

            if viewModel.fallbackRequired {
                Text("AirPods頭部モーションが使えない場合は、本体モーションまたは手動ラベルへフォールバックします。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }

    private var latestSampleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("最新サンプル")
                .font(.headline)

            if let sample = viewModel.latestSample {
                VStack(spacing: 8) {
                    metricRow("曲中時刻", value: formatTime(sample.playbackTime))
                    metricRow("加速度", value: format(sample.accelerationMagnitude))
                    metricRow("回転速度", value: format(sample.rotationMagnitude))
                    metricRow("Pitch / Roll / Yaw", value: "\(format(sample.attitude.pitch)) / \(format(sample.attitude.roll)) / \(format(sample.attitude.yaw))")
                }
            } else {
                Text("まだ頭部モーションサンプルはありません。")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color.gray.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var eventSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("取得ログ")
                .font(.headline)

            if viewModel.events.isEmpty {
                Text("接続・切断・エラーはここに記録されます。")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewModel.events.prefix(5)) { event in
                    Text(event.message)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var statusColor: Color {
        switch viewModel.status {
        case .recording:
            return .green
        case .starting:
            return .orange
        case .failed, .unavailable, .unsupported:
            return .red
        case .disconnected:
            return .yellow
        case .idle, .stopped:
            return .secondary
        }
    }

    private func metricRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .monospacedDigit()
        }
        .font(.callout)
    }

    private func format(_ value: Double) -> String {
        String(format: "%.3f", value)
    }

    private func formatTime(_ value: TimeInterval?) -> String {
        guard let value else { return "--:--" }
        let minutes = Int(value) / 60
        let seconds = Int(value) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
