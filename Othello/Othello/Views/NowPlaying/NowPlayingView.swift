import SwiftUI

enum NowPlayingTab {
    case playback, clip
}

struct NowPlayingView: View {
    let context: NowPlayingContext
    @Environment(\.dismiss) private var dismiss
    @State private var isPlaying: Bool = true
    @State private var playbackTime: TimeInterval
    @State private var activeTab: NowPlayingTab = .playback

    private var song: Song { context.song }

    private let lyrics: [(section: String, lines: [String])] = [
        ("Intro", ["ふと見上げた空に咲いた", "小さな花のように"]),
        ("Verse 1", ["風が運ぶ 街の音", "君と歩いた あの坂道"])
    ]

    init(context: NowPlayingContext) {
        self.context = context
        _playbackTime = State(initialValue: context.initialPlaybackTime)
    }

    init(song: Song) {
        self.init(context: NowPlayingContext(song: song))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 0) {
                topBar
                if activeTab == .playback {
                    playbackContent
                } else {
                    clipContent
                        .safeAreaInset(edge: .bottom, spacing: 0) {
                            nowPlayingFooterSpacer
                        }
                }
            }
            VStack {
                Spacer()
                nowPlayingFooter
            }
        }
        .preferredColorScheme(.dark)
    }

    private var nowPlayingFooterSpacer: some View {
        Color.clear.frame(height: 80)
    }

    // MARK: - 再生タブのコンテンツ

    private var playbackContent: some View {
        VStack(spacing: 0) {
            Spacer()
            vinylRecord
            songInfo
            playbackTimeline
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
            Text(context.hasHighlight ? "How区間 \(highlightRangeText)" : "Section 1・イントロ")
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

    private var playbackTimeline: some View {
        VStack(spacing: 8) {
            GeometryReader { geometry in
                let width = geometry.size.width
                let highlightStartX = width * highlightStartProgress
                let highlightWidth = width * max(0.02, highlightEndProgress - highlightStartProgress)
                let playheadX = width * playbackProgress

                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.12))
                        .frame(height: 5)
                    if context.hasHighlight {
                        Capsule()
                            .fill(Color(red: 1.0, green: 0.3, blue: 0.3).opacity(0.9))
                            .frame(width: highlightWidth, height: 5)
                            .offset(x: highlightStartX)
                    }
                    Circle()
                        .fill(.white)
                        .frame(width: 13, height: 13)
                        .shadow(color: .black.opacity(0.35), radius: 3, y: 1)
                        .offset(x: min(max(playheadX - 6.5, 0), max(width - 13, 0)))
                }
            }
            .frame(height: 16)

            HStack {
                Text(formatTime(playbackTime))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.white)
                Spacer()
                if context.hasHighlight {
                    Text("選択中 \(highlightRangeText)")
                        .font(.caption2.monospacedDigit().weight(.semibold))
                        .foregroundStyle(Color(red: 1.0, green: 0.3, blue: 0.3))
                }
                Spacer()
                Text(formatTime(duration))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.gray)
            }
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 10)
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

    private var duration: TimeInterval {
        max(TimeInterval(song.durationSeconds), 1)
    }

    private var playbackProgress: Double {
        min(max(playbackTime / duration, 0), 1)
    }

    private var highlightStart: TimeInterval {
        min(max(context.highlightStart ?? context.initialPlaybackTime, 0), duration)
    }

    private var highlightEnd: TimeInterval {
        let rawEnd = context.highlightEnd ?? max(highlightStart + 12, context.initialPlaybackTime)
        return min(max(rawEnd, highlightStart), duration)
    }

    private var highlightStartProgress: Double {
        min(max(highlightStart / duration, 0), 1)
    }

    private var highlightEndProgress: Double {
        min(max(highlightEnd / duration, highlightStartProgress), 1)
    }

    private var highlightRangeText: String {
        "\(formatTime(highlightStart)) - \(formatTime(highlightEnd))"
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let safeTime = max(0, Int(time.rounded()))
        return "\(safeTime / 60):\(String(format: "%02d", safeTime % 60))"
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


#Preview {
    NowPlayingView(song: Song(
        id: UUID(),
        title: "ライラック",
        artistName: "Mrs. GREEN APPLE",
        gradientColors: [Color(red: 0.85, green: 0.55, blue: 0.35), Color(red: 0.65, green: 0.35, blue: 0.5)],
        durationSeconds: 272
    ))
}
