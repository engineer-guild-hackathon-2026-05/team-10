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

    private let lyrics: [String] = [
        "ふと見上げた空に咲いた",
        "小さな花のように",
        "風が運ぶ 街の音",
        "君と歩いた あの坂道"
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
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                circularVisualizer
                    .padding(.top, 8)
                songInfo
                playbackControls
                lyricsCard
                    .padding(.top, 24)
                Color.clear.frame(height: 104)
            }
        }
    }

    // MARK: - 切り抜きタブのコンテンツ

    private var clipContent: some View {
        ClipCreationInlineView(song: song)
    }

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.1), in: Circle())
            }
            .accessibilityLabel("戻る")

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    private var circularVisualizer: some View {
        ZStack {
            AirPodsReactiveWaveformView(
                isAnimating: playback.isPlaying,
                playbackTime: playback.playbackTime,
                audioLevel: waveformAudioLevel,
                motionIntensity: airPods.recentInteractionIntensity,
                trackSeed: waveformTrackSeed,
                reactionState: waveformReactionState
            )
            .frame(width: 264, height: 264)

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

    private var lyricsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(lyrics.enumerated()), id: \.offset) { _, line in
                Text(line)
                    .font(.body)
                    .foregroundStyle(.white)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 16)
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let seconds = max(0, Int(time))
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    private var waveformAudioLevel: Double {
        guard playback.isPlaying else {
            return 0.18
        }

        let pulse = 0.58
            + 0.20 * sin(playback.playbackTime * 2.4)
            + 0.12 * sin(playback.playbackTime * 5.2)
        return min(max(pulse, 0.12), 1.0)
    }

    private var waveformTrackSeed: Int {
        [song.firestoreSongID, song.title, song.artistName]
            .joined(separator: "|")
            .unicodeScalars
            .reduce(17) { partialResult, scalar in
                partialResult &* 31 &+ Int(scalar.value)
            }
    }

    private var waveformReactionState: HowTag {
        guard playback.isPlaying else { return .neutral }
        return airPods.recentInteractionIntensity > 0.28 ? .groove : .neutral
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
