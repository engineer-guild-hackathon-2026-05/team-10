import SwiftUI
import MusicKit

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    @StateObject private var playback = PlaybackViewModel()
    @StateObject private var lyrics = LyricsViewModel()
    @State private var showSearchSheet = false

    init(useManualMode: Bool, permissionState: PermissionState) {
        _viewModel = StateObject(wrappedValue: HomeViewModel(
            useManualMode: useManualMode,
            permissionState: permissionState
        ))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    trackHeader
                    trackMeta
                    seekBar
                    playbackControls
                    sensorStatusBar
                    lyricsSection
                }
            }
        }
        .preferredColorScheme(.dark)
        .task { await playback.onAppear() }
        .sheet(isPresented: $showSearchSheet) { searchSheet }
        .alert("再生位置が取得できません", isPresented: $playback.positionUnavailableAlertShown) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(playback.positionUnavailableMessage)
        }
    }

    // MARK: - アルバムアート + 曲名
    private var trackHeader: some View {
        HStack(alignment: .top, spacing: 16) {
            Button { showSearchSheet = true } label: {
                artworkView(
                    url: playback.currentTrack?.artworkURL,
                    size: 110,
                    placeholderText: "タップで選曲"
                )
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(playback.currentTrack?.albumTitle ?? "— アルバム —")
                    .font(.caption)
                    .foregroundStyle(.gray)
                Text(playback.currentTrack?.title ?? "曲を選んでください")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .lineLimit(2)
                Text(playback.currentTrack?.artistName ?? "アーティスト")
                    .font(.subheadline)
                    .foregroundStyle(.gray)

                if !playback.isPositionAvailable {
                    Label("同期無効", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                        .padding(.top, 4)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    // MARK: - いいね・Howカード数
    private var trackMeta: some View {
        HStack(spacing: 20) {
            HStack(spacing: 6) {
                Image(systemName: "heart")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                Text("8.4k")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
            }
            HStack(spacing: 6) {
                Image(systemName: "bubble.left")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                Text("87 Howカード")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
            }
            Spacer()
            Button {} label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }

    // MARK: - シークバー
    private var seekBar: some View {
        let duration = playback.currentTrack?.duration ?? 0
        let time = playback.playbackTime
        return VStack(spacing: 4) {
            Slider(value: .constant(duration > 0 ? time / duration : 0))
                .tint(Color(red: 1.0, green: 0.3, blue: 0.3))
                .disabled(true)

            HStack {
                Text(formatTime(time))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.gray)
                Spacer()
                Text("−\(formatTime(max(0, duration - time)))")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.gray)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    // MARK: - 再生コントロール
    private var playbackControls: some View {
        let playing = playback.isPlaying
        return HStack(spacing: 0) {
            Spacer()
            Button {} label: {
                Image(systemName: "shuffle")
                    .font(.title3)
                    .foregroundStyle(.gray)
            }
            Spacer()
            Button {} label: {
                Image(systemName: "backward.end.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
            }
            Spacer()
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
                                colors: [Color(red: 1.0, green: 0.45, blue: 0.45), Color(red: 0.85, green: 0.15, blue: 0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 72, height: 72)
                        .shadow(color: .red.opacity(0.5), radius: 12, y: 4)
                    Image(systemName: playing ? "pause.fill" : "play.fill")
                        .font(.title)
                        .foregroundStyle(.white)
                        .offset(x: playing ? 0 : 3)
                }
            }
            .buttonStyle(.plain)
            Spacer()
            Button {} label: {
                Image(systemName: "forward.end.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
            }
            Spacer()
            Button {} label: {
                Image(systemName: "repeat")
                    .font(.title3)
                    .foregroundStyle(.gray)
            }
            Spacer()
        }
        .padding(.vertical, 20)
    }

    // MARK: - センサー状態バー（コンパクト）
    private var sensorStatusBar: some View {
        HStack(spacing: 12) {
            sensorDot(icon: "airpods", label: viewModel.sensorStatus.headMotion.label, color: viewModel.sensorStatus.headMotion.color)
            sensorDot(icon: "iphone", label: viewModel.sensorStatus.bodyMotion.label, color: viewModel.sensorStatus.bodyMotion.color)
            sensorDot(icon: "heart.fill", label: viewModel.sensorStatus.heartRate.label, color: viewModel.sensorStatus.heartRate.color)
            Spacer()

            if !viewModel.isSessionActive {
                Button { viewModel.startSession() } label: {
                    Text("リスニング開始")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(red: 0.85, green: 0.15, blue: 0.2), in: Capsule())
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    playback.stop()
                    viewModel.endSession()
                } label: {
                    Text("終了")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.gray.opacity(0.4), in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.04))
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
    }

    // MARK: - 歌詞 × Howカード
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
                        .foregroundStyle(Color(red: 1.0, green: 0.3, blue: 0.3))
                    Text("タップで解説")
                        .font(.caption.bold())
                        .foregroundStyle(Color(red: 1.0, green: 0.3, blue: 0.3))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)

            Divider().overlay(Color.gray.opacity(0.3))

            VStack(spacing: 0) {
                if playback.currentTrack == nil {
                    emptyLyricsRow("曲を選ぶと、反応地点に対応する歌詞を表示できます。")
                } else if lyrics.state == .loading {
                    emptyLyricsRow("歌詞を取得中です。")
                } else if let message = lyrics.state.message {
                    emptyLyricsRow(message)
                } else if let loadedLyrics = lyrics.lyrics, !loadedLyrics.lines.isEmpty {
                    lyricsSectionHeader(loadedLyrics.providerName)
                    ForEach(visibleLyricLines(from: loadedLyrics.lines)) { line in
                        LyricRow(
                            lyric: line.text.isEmpty ? "♪" : line.text,
                            translation: formatTime(line.startTime),
                            howCount: 0,
                            likeCount: 0,
                            isHighlighted: line.contains(playback.playbackTime)
                        )
                    }
                } else {
                    emptyLyricsRow("この曲の時間同期歌詞はまだ取得されていません。")
                }
            }
        }
    }

    private func lyricsSectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.caption.bold())
            .foregroundStyle(.gray.opacity(0.6))
            .kerning(1.5)
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let t = max(0, time)
        return String(format: "%d:%02d", Int(t) / 60, Int(t) % 60)
    }

    private func visibleLyricLines(from lines: [TimedLyricLine]) -> [TimedLyricLine] {
        guard !lines.isEmpty else {
            return []
        }

        let currentIndex = lines.lastIndex(where: { $0.startTime <= playback.playbackTime }) ?? 0
        let lowerBound = max(0, currentIndex - 3)
        let upperBound = min(lines.count, currentIndex + 7)
        return Array(lines[lowerBound..<upperBound])
    }

    private func emptyLyricsRow(_ message: String) -> some View {
        Text(message)
            .font(.subheadline)
            .foregroundStyle(.gray)
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity, alignment: .leading)
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

    // MARK: - 検索シート
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
                        Button { playback.searchQuery = "" } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(.gray)
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
                } else if playback.searchResults.isEmpty && !playback.searchQuery.isEmpty {
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
                                artworkView(url: track.artworkURL, size: 48)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(track.title)
                                        .font(.body)
                                        .foregroundStyle(.white)
                                        .lineLimit(1)
                                    Text(track.artistName)
                                        .font(.caption)
                                        .foregroundStyle(.gray)
                                        .lineLimit(1)
                                }
                            }
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
                        .foregroundStyle(Color(red: 1.0, green: 0.3, blue: 0.3))
                }
            }
        }
        .presentationDetents([.medium, .large])
        .preferredColorScheme(.dark)
    }
}

#Preview {
    HomeView(useManualMode: false, permissionState: PermissionState())
}
