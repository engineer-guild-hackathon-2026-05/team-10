import SwiftUI
import MusicKit

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    @StateObject private var playback = PlaybackViewModel()
    @StateObject private var lyrics = LyricsViewModel()
    @State private var showSearchSheet = false
    @State private var showReactionDisplay = false
    @State private var navigateToReaction = false
    @State private var tappedLyric: String?
    @State private var tappedLyricTranslation: String?

    private let accent = Color(red: 1.0, green: 0.3, blue: 0.3)
    private let deepRed = Color(red: 0.85, green: 0.15, blue: 0.2)

    init(useManualMode: Bool, permissionState: PermissionState) {
        _viewModel = StateObject(wrappedValue: HomeViewModel(
            useManualMode: useManualMode,
            permissionState: permissionState
        ))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                playerBackdrop

                ScrollView {
                    VStack(spacing: 18) {
                        nowPlayingCard
                        sensorStatusBar
                        lyricsSection
                    }
                    .padding(.top, 18)
                    .padding(.bottom, 120)
                }
            }
            .preferredColorScheme(.dark)
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $navigateToReaction) {
                ReactionDisplayView(
                    isSensorAvailable: viewModel.sensorStatus.headMotion == .connected,
                    lyric: tappedLyric,
                    lyricTranslation: tappedLyricTranslation
                )
            }
        }
        .task { await playback.onAppear() }
        .sheet(isPresented: $showSearchSheet) { searchSheet }
        .fullScreenCover(isPresented: $showReactionDisplay) {
            RealtimeReactionDisplayView(isSensorAvailable: !viewModel.useManualMode)
        }
        .alert("再生位置が取得できません", isPresented: $playback.positionUnavailableAlertShown) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(playback.positionUnavailableMessage)
        }
    }

    private var playerBackdrop: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let url = playback.currentTrack?.artworkURL {
                AsyncImage(url: url) { phase in
                    if case .success(let image) = phase {
                        image
                            .resizable()
                            .scaledToFill()
                            .blur(radius: 34)
                            .opacity(0.34)
                            .ignoresSafeArea()
                    }
                }
            }

            LinearGradient(
                colors: [
                    Color.black.opacity(0.2),
                    Color(red: 0.17, green: 0.04, blue: 0.06).opacity(0.64),
                    Color.black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }

    private var nowPlayingCard: some View {
        ZStack {
            cardArtworkBackground
            cardGradient

            VStack(spacing: 0) {
                cardHeader
                Spacer(minLength: 18)
                heroLyrics
                Spacer(minLength: 18)
                trackIdentity
                playbackTimeline
                playbackControls
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 506)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color.white.opacity(0.16), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.32), radius: 22, y: 16)
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private var cardArtworkBackground: some View {
        if let url = playback.currentTrack?.artworkURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .scaleEffect(1.04)
                case .empty:
                    artworkFallback
                default:
                    artworkFallback
                }
            }
        } else {
            artworkFallback
        }
    }

    private var artworkFallback: some View {
        LinearGradient(
            colors: [
                Color(red: 0.6, green: 0.05, blue: 0.1),
                Color(red: 0.18, green: 0.04, blue: 0.07),
                Color(red: 0.05, green: 0.05, blue: 0.07)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var cardGradient: some View {
        LinearGradient(
            colors: [
                Color.black.opacity(0.16),
                Color.black.opacity(0.22),
                Color.black.opacity(0.58),
                Color.black.opacity(0.9)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var cardHeader: some View {
        HStack {
            Button {
                showSearchSheet = true
            } label: {
                Image(systemName: "music.note.list")
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(Color.black.opacity(0.24), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("曲を選ぶ")

            Spacer()

            Text("Lyrics")
                .font(.headline.bold())
                .foregroundStyle(.white)

            Spacer()

            Button {
                showReactionDisplay = true
            } label: {
                Image(systemName: "waveform.path.ecg")
                    .font(.headline.bold())
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(Color.black.opacity(0.24), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("リアルタイム反応")
        }
    }

    @ViewBuilder
    private var heroLyrics: some View {
        if playback.currentTrack == nil {
            VStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.78))
                Text("曲を選んでください")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                Text("Apple Music から曲を選ぶと歌詞とHowカードを表示します。")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 12)
        } else if lyrics.state == .loading {
            VStack(spacing: 12) {
                ProgressView()
                    .tint(.white)
                Text("歌詞を取得中です")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
        } else if let message = lyrics.state.message {
            Text(message)
                .font(.headline)
                .foregroundStyle(.white.opacity(0.82))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
        } else if let loadedLyrics = lyrics.lyrics, !loadedLyrics.lines.isEmpty {
            VStack(spacing: 11) {
                ForEach(Array(heroLyricLines(from: loadedLyrics).enumerated()), id: \.element.id) { index, line in
                    Button {
                        openHowCard(for: line)
                    } label: {
                        HStack(spacing: 8) {
                            Text(line.text.isEmpty ? "♪" : line.text)
                                .font(index == 1 ? .title3.bold() : .body.weight(.medium))
                                .foregroundStyle(index == 1 ? .white : .white.opacity(0.72))
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)

                            commentBadge(count: howCount(for: index))
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        } else {
            Text("この曲の歌詞はまだ取得されていません。")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.82))
                .multilineTextAlignment(.center)
        }
    }

    private var trackIdentity: some View {
        VStack(spacing: 5) {
            Text(playback.currentTrack?.title ?? "未選択")
                .font(.title2.bold())
                .foregroundStyle(.white)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            Text(playback.currentTrack?.artistName ?? "Apple Music")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.72))
                .lineLimit(1)
        }
        .padding(.bottom, 14)
    }

    private var playbackTimeline: some View {
        let duration = playback.currentTrack?.duration ?? 0
        let progress = duration > 0 ? min(max(playback.playbackTime / duration, 0), 1) : 0
        let activeIndex = Int(progress * 34)

        return HStack(alignment: .center, spacing: 6) {
            Text(formatTime(playback.playbackTime))
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.white.opacity(0.68))
                .frame(width: 38, alignment: .leading)

            HStack(alignment: .center, spacing: 3) {
                ForEach(0..<35, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(index <= activeIndex ? accent : Color.white.opacity(0.58))
                        .frame(width: 3, height: waveformHeight(at: index))
                }
            }
            .frame(maxWidth: .infinity)

            Text(formatTime(max(0, duration - playback.playbackTime)))
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.white.opacity(0.68))
                .frame(width: 38, alignment: .trailing)
        }
        .padding(.bottom, 16)
    }

    private var playbackControls: some View {
        HStack(spacing: 18) {
            iconControl("shuffle") {}
            iconControl("backward.end.fill") {}

            Button {
                if playback.currentTrack != nil {
                    Task { await playback.togglePlayback() }
                } else {
                    showSearchSheet = true
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [accent, deepRed],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 68, height: 68)
                        .shadow(color: accent.opacity(0.45), radius: 12, y: 5)
                    Image(systemName: playback.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title.bold())
                        .foregroundStyle(.white)
                        .offset(x: playback.isPlaying ? 0 : 3)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(playback.isPlaying ? "一時停止" : "再生")

            iconControl("forward.end.fill") {}
            iconControl("repeat") {}
        }
    }

    private func iconControl(_ systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white.opacity(0.84))
                .frame(width: 38, height: 38)
                .background(Color.white.opacity(0.14), in: Circle())
        }
        .buttonStyle(.plain)
    }

    private var sensorStatusBar: some View {
        HStack(spacing: 12) {
            sensorDot(icon: "airpods", label: viewModel.sensorStatus.headMotion.label, color: viewModel.sensorStatus.headMotion.color)
            sensorDot(icon: "iphone", label: viewModel.sensorStatus.bodyMotion.label, color: viewModel.sensorStatus.bodyMotion.color)
            sensorDot(icon: "heart.fill", label: viewModel.sensorStatus.heartRate.label, color: viewModel.sensorStatus.heartRate.color)
            Spacer()

            Button { showReactionDisplay = true } label: {
                Text("リスニング開始")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(deepRed, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding(.horizontal, 20)
    }

    private func sensorDot(icon: String, label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(.gray)
        }
        .accessibilityLabel(label)
    }

    private var lyricsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("歌詞 × Howカード")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.caption)
                    Text("タップで解説")
                        .font(.caption.bold())
                }
                .foregroundStyle(accent)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)

            Divider().overlay(Color.gray.opacity(0.3))

            VStack(spacing: 0) {
                if playback.currentTrack == nil {
                    emptyLyricsRow("曲を選ぶと、歌詞に紐づくHowカードを確認できます。")
                } else if lyrics.state == .loading {
                    emptyLyricsRow("歌詞を取得中です。")
                } else if let message = lyrics.state.message {
                    emptyLyricsRow(message)
                } else if let loadedLyrics = lyrics.lyrics, !loadedLyrics.lines.isEmpty {
                    ForEach(Array(visibleLyricLines(from: loadedLyrics).enumerated()), id: \.element.id) { index, line in
                        LyricRow(
                            lyric: line.text.isEmpty ? "♪" : line.text,
                            translation: loadedLyrics.isTimeSynced ? formatTime(line.startTime) : nil,
                            howCount: howCount(for: index),
                            likeCount: likeCount(for: index),
                            isHighlighted: loadedLyrics.isTimeSynced && line.contains(playback.playbackTime),
                            onHowTap: { openHowCard(for: line) }
                        )
                    }
                } else {
                    emptyLyricsRow("この曲の歌詞はまだ取得されていません。")
                }
            }
        }
        .background(Color.black.opacity(0.14))
    }

    private func heroLyricLines(from lyrics: SynchronizedLyrics) -> [TimedLyricLine] {
        let lines = visibleLyricLines(from: lyrics)
        guard !lines.isEmpty else { return [] }

        if lyrics.isTimeSynced {
            return Array(lines.prefix(4))
        } else {
            return Array(lines.prefix(4))
        }
    }

    private func visibleLyricLines(from lyrics: SynchronizedLyrics) -> [TimedLyricLine] {
        let lines = lyrics.lines

        guard !lines.isEmpty else {
            return []
        }

        guard lyrics.isTimeSynced else {
            return lines
        }

        let currentIndex = lines.lastIndex(where: { $0.startTime <= playback.playbackTime }) ?? 0
        let lowerBound = max(0, currentIndex - 3)
        let upperBound = min(lines.count, currentIndex + 7)
        return Array(lines[lowerBound..<upperBound])
    }

    private func openHowCard(for line: TimedLyricLine) {
        tappedLyric = line.text.isEmpty ? "♪" : line.text
        tappedLyricTranslation = nil
        navigateToReaction = true
    }

    private func commentBadge(count: Int) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "bubble.left.fill")
                .font(.caption2)
            Text("\(count)")
                .font(.caption.bold())
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(Color.black.opacity(0.32), in: Capsule())
        .overlay(Capsule().stroke(Color.white.opacity(0.16), lineWidth: 1))
    }

    private func emptyLyricsRow(_ message: String) -> some View {
        Text(message)
            .font(.subheadline)
            .foregroundStyle(.gray)
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func searchEmptyState(title: String, systemImage: String, description: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(.gray)
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
            Text(description)
                .font(.subheadline)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }

    private var searchSheet: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.gray)
                    TextField("曲名・アーティスト名で検索", text: $playback.searchQuery)
                        .foregroundStyle(.white)
                        .submitLabel(.search)
                        .onSubmit { Task { await playback.search() } }
                    if !playback.searchQuery.isEmpty {
                        Button {
                            playback.searchQuery = ""
                            playback.searchResults = []
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.gray)
                        }
                    }
                }
                .padding(12)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                if playback.authorizationStatus != .authorized {
                    searchEmptyState(
                        title: "Apple Music の認証が必要です",
                        systemImage: "music.note.list",
                        description: "設定 → プライバシー → メディアと Apple Music で許可してください"
                    )
                } else if playback.searchResults.isEmpty && playback.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    searchEmptyState(
                        title: "曲を検索",
                        systemImage: "music.note.list",
                        description: "再生したい曲名かアーティスト名を入力してください"
                    )
                } else if playback.searchResults.isEmpty {
                    searchEmptyState(
                        title: "検索結果がありません",
                        systemImage: "magnifyingglass",
                        description: "\(playback.searchQuery) に一致する曲が見つかりませんでした"
                    )
                } else {
                    List(playback.searchResults) { track in
                        Button {
                            Task {
                                let selectedTrack = await playback.select(track: track) ?? track
                                await lyrics.loadLyrics(for: LyricsTrackQuery(playbackTrack: selectedTrack))
                                showSearchSheet = false
                            }
                        } label: {
                            HStack(spacing: 12) {
                                artworkView(url: track.artworkURL, size: 50)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(track.title)
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(.white)
                                        .lineLimit(1)
                                    Text(track.artistName)
                                        .font(.caption)
                                        .foregroundStyle(.gray)
                                        .lineLimit(1)
                                }
                                Spacer()
                                Image(systemName: "play.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(accent)
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(Color.clear)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }

                Spacer()
            }
            .background(Color.black.ignoresSafeArea())
            .navigationTitle("曲を選ぶ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { showSearchSheet = false }
                        .foregroundStyle(accent)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .preferredColorScheme(.dark)
    }

    private func artworkView(url: URL?, size: CGFloat, placeholderText: String? = nil) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.6, green: 0.05, blue: 0.1), Color.black],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            if let url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        artworkPlaceholder(text: placeholderText, size: size, failed: true)
                    case .empty:
                        ProgressView()
                            .tint(.white.opacity(0.7))
                    @unknown default:
                        artworkPlaceholder(text: placeholderText, size: size, failed: false)
                    }
                }
            } else {
                artworkPlaceholder(text: placeholderText, size: size, failed: false)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func artworkPlaceholder(text: String?, size: CGFloat, failed: Bool) -> some View {
        VStack(spacing: 6) {
            Image(systemName: failed ? "photo.badge.exclamationmark" : "music.note")
                .font(.system(size: size >= 80 ? 36 : 18))
                .foregroundStyle(.white.opacity(0.4))
            if let text {
                Text(text)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.3))
            }
        }
    }

    private func waveformHeight(at index: Int) -> CGFloat {
        let values: [CGFloat] = [9, 16, 24, 18, 29, 21, 14, 27, 32, 19, 25, 16, 34, 23, 18, 29, 38, 26, 21, 30, 18, 24, 32, 20, 14, 29, 22, 34, 24, 18, 28, 33, 16, 23, 20]
        return values[index % values.count]
    }

    private func howCount(for index: Int) -> Int {
        [4, 12, 3, 1, 2, 0, 5, 1][index % 8]
    }

    private func likeCount(for index: Int) -> Int {
        [82, 341, 118, 47, 29, 16, 74, 22][index % 8]
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let t = max(0, time)
        return String(format: "%d:%02d", Int(t) / 60, Int(t) % 60)
    }
}

#Preview {
    HomeView(useManualMode: false, permissionState: PermissionState())
}
