import SwiftUI

enum NowPlayingTab {
    case playback, clip
}

struct NowPlayingView: View {
    let song: Song
    @Environment(\.dismiss) private var dismiss
    @State private var isPlaying: Bool = true
    @State private var progress: Double = 0.32
    @State private var activeTab: NowPlayingTab = .playback

    private let lyrics: [(section: String, lines: [String])] = [
        ("Intro", ["ふと見上げた空に咲いた", "小さな花のように"]),
        ("Verse 1", ["風が運ぶ 街の音", "君と歩いた あの坂道"])
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                topBar
                if activeTab == .playback {
                    playbackContent
                } else {
                    clipContent
                }
                nowPlayingFooter
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - 再生タブのコンテンツ

    private var playbackContent: some View {
        VStack(spacing: 0) {
            Spacer()
            vinylRecord
            songInfo
            Spacer()
            sectionChip
            lyricsCard
            Spacer(minLength: 16)
        }
    }

    // MARK: - 切り抜きタブのコンテンツ

    private var clipContent: some View {
        ClipCreationInlineView(song: song)
    }

    private var topBar: some View {
        HStack {
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "waveform")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(Color.white.opacity(0.1), in: Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    private var vinylRecord: some View {
        ZStack {
            ForEach(Array(0..<8), id: \.self) { i in
                let ratio = Double(i) / 8.0
                let size = CGFloat(240 - i * 24)
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: song.gradientColors.map { $0.opacity(1.0 - ratio * 0.6) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 14
                    )
                    .frame(width: size, height: size)
            }
            Circle()
                .fill(Color(red: 0.15, green: 0.15, blue: 0.15))
                .frame(width: 36, height: 36)
            Circle()
                .fill(Color(red: 0.25, green: 0.25, blue: 0.25))
                .frame(width: 12, height: 12)
        }
        .frame(width: 260, height: 260)
        .rotationEffect(.degrees(isPlaying ? 360 : 0))
        .animation(
            isPlaying
                ? .linear(duration: 4).repeatForever(autoreverses: false)
                : .default,
            value: isPlaying
        )
        .padding(.vertical, 12)
    }

    private var songInfo: some View {
        VStack(spacing: 6) {
            Text(song.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            Text(song.artistName)
                .font(.subheadline)
                .foregroundStyle(.gray)
        }
        .padding(.bottom, 8)
    }

    private var sectionChip: some View {
        HStack {
            Text("● Section 1・イントロ")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(red: 0.3, green: 0.2, blue: 0.5), in: Capsule())
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    private var lyricsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("歌詞")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                Spacer()
                Button {} label: {
                    HStack(spacing: 4) {
                        Text("全文表示")
                            .font(.caption)
                            .foregroundStyle(Color(red: 0.5, green: 0.4, blue: 0.9))
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(Color(red: 0.5, green: 0.4, blue: 0.9))
                    }
                }
            }

            ForEach(Array(lyrics.enumerated()), id: \.offset) { _, section in
                VStack(alignment: .leading, spacing: 4) {
                    Text("[\(section.section)]")
                        .font(.caption)
                        .foregroundStyle(.gray)
                    ForEach(Array(section.lines.enumerated()), id: \.offset) { lineIndex, line in
                        Text(line)
                            .font(lineIndex == 0 ? .body.bold() : .body)
                            .foregroundStyle(lineIndex == 0 ? .white : Color.white.opacity(0.5))
                    }
                }
            }

        }
        .padding(16)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 16)
    }

    private func actionButtonAccent(icon: String, label: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(Color(red: 0.5, green: 0.4, blue: 0.9))
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color(red: 0.5, green: 0.4, blue: 0.9))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(red: 0.3, green: 0.2, blue: 0.5).opacity(0.3), in: Capsule())
    }

    // MARK: - フッター

    private var nowPlayingFooter: some View {
        HStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { activeTab = .playback }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "waveform")
                        .font(.subheadline)
                    Text("再生")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(activeTab == .playback ? .white : Color.gray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    activeTab == .playback ? Color.white.opacity(0.12) : Color.clear,
                    in: Capsule()
                )
            }

            Button {
                withAnimation(.easeInOut(duration: 0.2)) { activeTab = .clip }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "scissors")
                        .font(.subheadline)
                    Text("切り抜き")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(
                    activeTab == .clip
                        ? Color(red: 0.65, green: 0.5, blue: 1.0)
                        : Color.gray
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    activeTab == .clip
                        ? Color(red: 0.25, green: 0.18, blue: 0.45)
                        : Color.clear,
                    in: Capsule()
                )
            }
        }
        .padding(4)
        .background(Color(red: 0.1, green: 0.1, blue: 0.12), in: RoundedRectangle(cornerRadius: 30))
        .padding(.horizontal, 20)
        .padding(.bottom, 32)
    }
}

// MARK: - 切り抜きタブのインライン表示（NowPlayingView内）

private struct ClipCreationInlineView: View {
    let song: Song
    @StateObject private var viewModel: ClipCreationViewModel

    init(song: Song) {
        self.song = song
        self._viewModel = StateObject(wrappedValue: ClipCreationViewModel(song: song))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                albumArt
                songInfo
                playerControls
                waveformSection
                shareButton
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
    }

    private var albumArt: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(LinearGradient(
                colors: song.gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
            .frame(width: 180, height: 180)
            .shadow(color: (song.gradientColors.first ?? .clear).opacity(0.4), radius: 20, y: 8)
    }

    private var songInfo: some View {
        VStack(spacing: 6) {
            Text(song.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            Text(song.artistName)
                .font(.subheadline)
                .foregroundStyle(.gray)
        }
    }

    private var playerControls: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.4), lineWidth: 1.5)
                    .frame(width: 44, height: 44)
                Text("30")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }

            GeometryReader { geo in
                let w = geo.size.width
                let progress = viewModel.currentTime / viewModel.totalDuration
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 3)
                    Capsule()
                        .fill(Color.white)
                        .frame(width: w * progress, height: 3)
                    Circle()
                        .fill(Color.white)
                        .frame(width: 14, height: 14)
                        .offset(x: w * progress - 7)
                    Circle()
                        .fill(Color(red: 1.0, green: 0.25, blue: 0.5))
                        .frame(width: 10, height: 10)
                        .offset(x: w * 0.33 - 5)
                    Circle()
                        .fill(Color(red: 1.0, green: 0.25, blue: 0.5))
                        .frame(width: 10, height: 10)
                        .offset(x: w * 0.60 - 5)
                }
                .frame(maxHeight: .infinity)
            }
            .frame(height: 20)

            Button { viewModel.togglePlayback() } label: {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 48, height: 48)
                    Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.black)
                }
            }
        }
    }

    private var waveformSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("好きな部分を選ぶ")
                    .font(.caption)
                    .foregroundStyle(.gray)
                Spacer()
                Text("\(viewModel.clipStartFormatted) – \(viewModel.clipEndFormatted)")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }

            InlineWaveformView(
                waveformData: viewModel.waveformData,
                totalDuration: viewModel.totalDuration,
                clipStart: viewModel.clipStart,
                clipEnd: viewModel.clipEnd
            ) { startRatio, endRatio in
                viewModel.updateClipRange(startRatio: startRatio, endRatio: endRatio)
            }
            .frame(height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 14))

            HStack {
                Text("枠をドラッグして範囲を調整")
                    .font(.caption2)
                    .foregroundStyle(.gray)
                Spacer()
                Text("\(viewModel.clipDurationSeconds)s")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color(red: 0.3, green: 0.2, blue: 0.55), in: Capsule())
            }
        }
    }

    private var shareButton: some View {
        Button {} label: {
            HStack(spacing: 8) {
                Image(systemName: "square.and.arrow.up")
                    .font(.body.weight(.semibold))
                Text("この切り抜きをシェア")
                    .font(.body.weight(.semibold))
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
        }
    }
}

// MARK: - Waveform View（インライン用）

private struct InlineWaveformView: View {
    let waveformData: [CGFloat]
    let totalDuration: Double
    let clipStart: Double
    let clipEnd: Double
    let onDrag: (Double, Double) -> Void

    @State private var isDraggingStart: Bool = true

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let barCount = waveformData.count
            let gap: CGFloat = 2.5
            let barWidth = (width - gap * CGFloat(barCount - 1)) / CGFloat(barCount)
            let clipStartX = CGFloat(clipStart / totalDuration) * width
            let clipEndX = CGFloat(clipEnd / totalDuration) * width

            ZStack {
                Color(red: 0.1, green: 0.1, blue: 0.12)

                Canvas { context, _ in
                    for (i, amplitude) in waveformData.enumerated() {
                        let x = CGFloat(i) * (barWidth + gap)
                        let barH = amplitude * height * 0.88
                        let y = (height - barH) / 2
                        let rect = CGRect(x: x, y: y, width: max(barWidth, 1.5), height: barH)
                        let inRange = x >= clipStartX && (x + barWidth) <= clipEndX
                        context.fill(
                            Path(roundedRect: rect, cornerRadius: barWidth / 2),
                            with: .color(inRange ? .white : Color.white.opacity(0.22))
                        )
                    }
                }

                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(
                        Color(red: 0.55, green: 0.42, blue: 0.9),
                        lineWidth: 2.5
                    )
                    .frame(width: max(0, clipEndX - clipStartX), height: height)
                    .position(x: clipStartX + (clipEndX - clipStartX) / 2, y: height / 2)
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let ratio = Double(value.location.x / width).clamped(to: 0...1)
                        let startRatio = clipStart / totalDuration
                        let endRatio = clipEnd / totalDuration
                        if value.translation == .zero {
                            isDraggingStart = ratio < (startRatio + endRatio) / 2
                        }
                        if isDraggingStart {
                            onDrag(min(ratio, endRatio - 0.05), endRatio)
                        } else {
                            onDrag(startRatio, max(ratio, startRatio + 0.05))
                        }
                    }
            )
        }
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

#Preview {
    NowPlayingView(song: Song(
        id: UUID(),
        title: "ライラック",
        artistName: "Mrs. GREEN APPLE",
        gradientColors: [Color(red: 0.85, green: 0.55, blue: 0.35), Color(red: 0.65, green: 0.35, blue: 0.5)],
        durationSeconds: 272
    ))
}
