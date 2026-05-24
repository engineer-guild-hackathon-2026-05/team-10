import SwiftUI
#if canImport(AppKit) && !canImport(UIKit)
import AppKit
#endif

struct ContentView: View {
    @StateObject private var model = CollectorViewModel()

    var body: some View {
        NavigationStack {
            Group {
                switch model.phase {
                case .start:
                    StartScreen(model: model)
                case .recording:
                    RecordingScreen(model: model)
                case .review:
                    ReviewScreen(model: model)
                }
            }
            .navigationTitle("HowTune Collector")
        }
    }
}

private struct StartScreen: View {
    @ObservedObject var model: CollectorViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HeaderBlock(
                    title: "学習データ収集",
                    bodyText: "AirPodsの頭部モーションとラベルを保存します。未接続時はiPhoneモーションへフォールバックします。音声、位置情報、連絡先、マイクは使いません。"
                )

                SectionCard(title: "曲") {
                    VStack(spacing: 10) {
                        ForEach(DemoSong.catalog) { song in
                            let isSelected = model.selectedSong == song
                            Button {
                                model.selectedSong = song
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: isSelected ? "checkmark.circle.fill" : "music.note")
                                        .font(.title3)
                                        .foregroundStyle(isSelected ? .teal : .secondary)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(song.title)
                                            .font(.headline)
                                        Text(song.description)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                }
                                .padding(12)
                                .background(isSelected ? Color.teal.opacity(0.12) : AppColors.secondaryBackground)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Button {
                    model.startSession()
                } label: {
                    Label("セッション開始", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding()
        }
        .background(AppColors.groupedBackground)
    }
}

private struct RecordingScreen: View {
    @ObservedObject var model: CollectorViewModel

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SectionCard(title: model.selectedSong.title) {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text(formatTime(model.elapsed))
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .monospacedDigit()
                            Spacer()
                            Text(model.motion.statusText)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }

                        ProgressView(value: model.progress)
                            .tint(.teal)

                        HStack(spacing: 10) {
                            MetricPill(title: "magnitude", value: String(format: "%.2f", model.motion.currentMagnitude))
                            MetricPill(title: "samples", value: "\(model.motion.sampleCount)")
                            MetricPill(title: "labels", value: "\(model.labels.count)")
                        }
                    }
                }

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(ListeningLabel.primaryCases) { label in
                        Button {
                            model.addLabel(label)
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                Image(systemName: label.symbolName)
                                    .font(.title2)
                                Text(label.displayName)
                                    .font(.headline)
                                Text(label.hint)
                                    .font(.caption)
                                    .lineLimit(2)
                                    .foregroundStyle(.white.opacity(0.86))
                            }
                            .frame(maxWidth: .infinity, minHeight: 96, alignment: .leading)
                            .padding(14)
                            .foregroundStyle(.white)
                            .background(label.color)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }

                HStack(spacing: 12) {
                    Button {
                        model.addLabel(.noise)
                    } label: {
                        Label("ノイズ", systemImage: "exclamationmark.triangle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button(role: .destructive) {
                        model.finishSession()
                    } label: {
                        Label("終了", systemImage: "stop.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }

                Text("迷ったら押さなくてOK。押したラベルは終了後に消せます。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .background(AppColors.groupedBackground)
        .toolbar {
            Button("中止", role: .destructive) {
                model.reset()
            }
        }
    }
}

private struct ReviewScreen: View {
    @ObservedObject var model: CollectorViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HeaderBlock(
                    title: "保存完了",
                    bodyText: "Raw JSON、JSONL、Create ML向けCSVをアプリのDocumentsに保存しました。Filesアプリや共有からMacへ移せます。"
                )

                if let result = model.exportResult {
                    SectionCard(title: "書き出し") {
                        VStack(alignment: .leading, spacing: 12) {
                            ExportRow(title: "Raw JSON", url: result.rawJSONURL)
                            ExportRow(title: "Training JSONL", url: result.trainingJSONLURL)
                            ExportRow(title: "Create ML Recording CSV", url: result.recordingCSVURL)
                            ExportRow(title: "Create ML Annotations CSV", url: result.annotationsCSVURL)
                            ExportRow(title: "Create ML GUI Folder", url: result.createMLActivityDataURL)

                            HStack(spacing: 10) {
                                MetricPill(title: "examples", value: "\(result.examplesCount)")
                                MetricPill(title: "activity csv", value: "\(result.activityCSVCount)")
                            }

                            HStack {
                                ShareLink(item: result.rawJSONURL) {
                                    Label("Raw共有", systemImage: "square.and.arrow.up")
                                }
                                .buttonStyle(.bordered)

                                ShareLink(item: result.trainingJSONLURL) {
                                    Label("JSONL共有", systemImage: "square.and.arrow.up")
                                }
                                .buttonStyle(.borderedProminent)
                            }

                            HStack {
                                ShareLink(item: result.recordingCSVURL) {
                                    Label("記録CSV共有", systemImage: "waveform.path.ecg")
                                }
                                .buttonStyle(.bordered)

                                ShareLink(item: result.annotationsCSVURL) {
                                    Label("注釈CSV共有", systemImage: "tablecells")
                                }
                                .buttonStyle(.bordered)
                            }

                            ShareLink(item: result.createMLActivityDataURL) {
                                Label("GUI用フォルダ共有", systemImage: "folder")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }

                if let error = model.exportError {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                SectionCard(title: "タイムライン") {
                    VStack(alignment: .leading, spacing: 12) {
                        ReactionTimeline(
                            labels: model.labels,
                            duration: model.selectedSong.durationSec
                        )
                        SensorGraph(samples: model.collectedSession?.samples ?? [])
                    }
                }

                SectionCard(title: "ラベル") {
                    if model.labels.isEmpty {
                        ContentUnavailableView("ラベルなし", systemImage: "tag")
                    } else {
                        VStack(spacing: 12) {
                            ForEach(model.labels) { label in
                                LabelEditRow(label: label, model: model)
                            }
                        }
                    }
                }

                HStack {
                    Button {
                        model.saveAgain()
                    } label: {
                        Label("保存し直す", systemImage: "tray.and.arrow.down")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button {
                        model.reset()
                    } label: {
                        Label("次の収集", systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
        .background(AppColors.groupedBackground)
    }
}

private struct LabelEditRow: View {
    let label: LabelEvent
    @ObservedObject var model: CollectorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(label.label.displayName, systemImage: label.label.symbolName)
                    .foregroundStyle(label.label.color)
                    .font(.headline)
                Spacer()
                Button(role: .destructive) {
                    model.deleteLabel(label)
                } label: {
                    Image(systemName: "trash")
                }
            }

            Stepper(
                "開始 \(formatTime(label.startedAtSec))",
                value: Binding(
                    get: { label.startedAtSec },
                    set: { model.updateLabel(label, start: $0) }
                ),
                in: 0...model.selectedSong.durationSec,
                step: 0.1
            )

            Stepper(
                "終了 \(formatTime(label.endedAtSec))",
                value: Binding(
                    get: { label.endedAtSec },
                    set: { model.updateLabel(label, end: $0) }
                ),
                in: 0...model.selectedSong.durationSec,
                step: 0.1
            )
        }
        .padding(12)
        .background(AppColors.secondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct ReactionTimeline: View {
    let labels: [LabelEvent]
    let duration: TimeInterval

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppColors.secondaryGroupedBackground)

                ForEach(labels) { label in
                    let x = geometry.size.width * label.startedAtSec / max(duration, 0.1)
                    let width = max(10, geometry.size.width * (label.endedAtSec - label.startedAtSec) / max(duration, 0.1))
                    RoundedRectangle(cornerRadius: 6)
                        .fill(label.label.color)
                        .frame(width: width, height: 30)
                        .overlay {
                            Text(label.label.displayName)
                                .font(.caption2.weight(.bold))
                                .lineLimit(1)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 4)
                        }
                        .offset(x: x)
                }
            }
        }
        .frame(height: 82)
    }
}

private struct SensorGraph: View {
    let samples: [MotionSample]

    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let points = graphPoints(size: geometry.size)
                guard let first = points.first else { return }
                path.move(to: first)
                for point in points.dropFirst() {
                    path.addLine(to: point)
                }
            }
            .stroke(.teal, style: StrokeStyle(lineWidth: 3, lineJoin: .round))
            .background(AppColors.background)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .frame(height: 130)
    }

    private func graphPoints(size: CGSize) -> [CGPoint] {
        guard samples.count >= 2, let lastT = samples.last?.t, lastT > 0 else { return [] }
        let magnitudes = samples.map { sample in
            sqrt(sample.ax * sample.ax + sample.ay * sample.ay + sample.az * sample.az)
        }
        let minValue = magnitudes.min() ?? 0
        let maxValue = magnitudes.max() ?? 1
        let range = max(maxValue - minValue, 0.001)
        let stride = max(1, samples.count / 240)

        return samples.enumerated().compactMap { index, sample in
            guard index.isMultiple(of: stride) else { return nil }
            let value = magnitudes[index]
            let x = size.width * sample.t / lastT
            let y = size.height - size.height * (value - minValue) / range
            return CGPoint(x: x, y: y)
        }
    }
}

private struct SectionCard<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.headline)
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct HeaderBlock: View {
    let title: String
    let bodyText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.largeTitle.bold())
            Text(bodyText)
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }
}

private struct MetricPill: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.headline.monospacedDigit())
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(AppColors.secondaryGroupedBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct ExportRow: View {
    let title: String
    let url: URL

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            Text(url.lastPathComponent)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
        }
    }
}

private extension ListeningLabel {
    var symbolName: String {
        switch self {
        case .groove: "waveform"
        case .hype: "flame.fill"
        case .chill: "moon.fill"
        case .immersion: "scope"
        case .hit: "sparkles"
        case .afterglow: "hand.raised.fill"
        case .unknown: "questionmark.circle"
        case .noise: "exclamationmark.triangle"
        }
    }
}

private func formatTime(_ value: TimeInterval) -> String {
    let minutes = Int(value) / 60
    let seconds = Int(value) % 60
    let tenths = Int((value * 10).rounded()) % 10
    return "\(minutes):\(String(format: "%02d", seconds)).\(tenths)"
}

private enum AppColors {
    static var groupedBackground: Color {
        #if canImport(UIKit)
        Color(UIColor.systemGroupedBackground)
        #elseif canImport(AppKit)
        Color(NSColor.windowBackgroundColor)
        #else
        Color.gray.opacity(0.08)
        #endif
    }

    static var secondaryGroupedBackground: Color {
        #if canImport(UIKit)
        Color(UIColor.secondarySystemGroupedBackground)
        #elseif canImport(AppKit)
        Color(NSColor.controlBackgroundColor)
        #else
        Color.gray.opacity(0.14)
        #endif
    }

    static var secondaryBackground: Color {
        #if canImport(UIKit)
        Color(UIColor.secondarySystemBackground)
        #elseif canImport(AppKit)
        Color(NSColor.controlBackgroundColor)
        #else
        Color.gray.opacity(0.12)
        #endif
    }

    static var background: Color {
        #if canImport(UIKit)
        Color(UIColor.systemBackground)
        #elseif canImport(AppKit)
        Color(NSColor.textBackgroundColor)
        #else
        Color.white
        #endif
    }
}
