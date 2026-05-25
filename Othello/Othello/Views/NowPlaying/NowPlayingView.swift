import SwiftUI

enum NowPlayingTab {
    case playback, clip
}

struct NowPlayingView: View {
    let song: Song
    @ObservedObject var playback: PlaybackViewModel
    @ObservedObject var airPods: AirPodsMotionViewModel
    @Environment(\.dismiss) private var dismiss
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
            circularVisualizer
            songInfo
            playbackControls
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
            airPodsStatusPill
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(Color.white.opacity(0.1), in: Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    private var circularVisualizer: some View {
        ZStack {
            SyncBeatCircularWaveformView(isAnimating: playback.isPlaying)
                .opacity(0.45)
                .frame(width: 260, height: 260)

            SyncBeatCircularWaveformView(isAnimating: playback.isPlaying)
                .frame(width: 228, height: 228)

            CircularArtworkView(song: song, size: 154, isPlaying: playback.isPlaying, showsCenterHole: true)
        }
        .frame(width: 282, height: 282)
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

    private var playbackControls: some View {
        VStack(spacing: 10) {
            let duration = song.duration
            let progress = duration > 0 ? min(max(playback.playbackTime / duration, 0), 1) : 0

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.14))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 1.0, green: 0.3, blue: 0.3), Color(red: 0.18, green: 0.68, blue: 1.0)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: proxy.size.width * progress)
                }
            }
            .frame(height: 6)

            HStack {
                Text(formatTime(playback.playbackTime))
                Spacer()
                Button {
                    Task { await playback.togglePlayback() }
                } label: {
                    Image(systemName: playback.isPlaying ? "pause.fill" : "play.fill")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.black)
                        .frame(width: 44, height: 44)
                        .background(Color.white, in: Circle())
                        .offset(x: playback.isPlaying ? 0 : 2)
                }
                .buttonStyle(.plain)
                Spacer()
                Text(formatTime(duration))
            }
            .font(.caption.monospacedDigit())
            .foregroundStyle(.white.opacity(0.64))
        }
        .padding(.horizontal, 28)
        .padding(.top, 10)
    }

    private var airPodsStatusPill: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(airPods.isRecording ? Color.green : Color.white.opacity(0.34))
                .frame(width: 7, height: 7)
            Text(airPods.status.title)
                .font(.caption.bold())
                .foregroundStyle(.white.opacity(0.82))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color.white.opacity(0.10), in: Capsule())
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

    private func formatTime(_ time: TimeInterval) -> String {
        let seconds = max(0, Int(time))
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
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
    ), playback: PlaybackViewModel(), airPods: AirPodsMotionViewModel())
}
