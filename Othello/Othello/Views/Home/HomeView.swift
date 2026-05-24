import SwiftUI
import MusicKit

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    @StateObject private var playback = PlaybackViewModel()
    @State private var showSearchSheet = false
    @State private var showReactionDisplay = false

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
        .fullScreenCover(isPresented: $showReactionDisplay) {
            ReactionDisplayView(isSensorAvailable: !viewModel.useManualMode)
        }
        .alert("再生位置が取得できません", isPresented: $playback.positionUnavailableAlertShown) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Apple Music の認証が必要です。このセッションでは反応の同期が無効になります。")
        }
    }

    // MARK: - アルバムアート + 曲名
    private var trackHeader: some View {
        HStack(alignment: .top, spacing: 16) {
            Button { showSearchSheet = true } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.6, green: 0.05, blue: 0.1), Color.black],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 110, height: 110)
                    if let artworkURL = playback.currentTrack?.artworkURL {
                        AsyncImage(url: artworkURL) { img in
                            img.resizable().scaledToFill()
                        } placeholder: {
                            Image(systemName: "music.note")
                                .font(.system(size: 36))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                        .frame(width: 110, height: 110)
                        .clipped()
                        .cornerRadius(8)
                    } else {
                        VStack(spacing: 6) {
                            Image(systemName: "music.note")
                                .font(.system(size: 36))
                                .foregroundStyle(.white.opacity(0.4))
                            Text("タップで選曲")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.3))
                        }
                    }
                }
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
        let duration = playback.currentTrack?.duration ?? viewModel.mockTrackDuration
        let time = playback.currentTrack != nil ? playback.playbackTime : viewModel.playbackTime
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
        let playing = playback.currentTrack != nil ? playback.isPlaying : viewModel.isPlaying
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
                    viewModel.togglePlayback()
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

            Button { showReactionDisplay = true } label: {
                Text("リスニング開始")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(red: 0.85, green: 0.15, blue: 0.2), in: Capsule())
            }
            .buttonStyle(.plain)
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
                lyricsSectionHeader("VERSE 1")
                LyricRow(lyric: "深夜二時の改札を抜けて", translation: "Through the late-night turnstile", howCount: 4, likeCount: 82, isHighlighted: false)
                LyricRow(lyric: "コンビニの灯りに泳いだ", translation: "Swimming in the convenience-store glow", howCount: 12, likeCount: 341, isHighlighted: true)
                LyricRow(lyric: "君のメッセージは未読のまま", translation: "Your message still unread", howCount: 3, likeCount: 118, isHighlighted: false)
                LyricRow(lyric: "壊れた傘を畳んでいる", translation: "Folding a broken umbrella", howCount: 1, likeCount: 47, isHighlighted: false)

                HStack(spacing: 8) {
                    ForEach(0..<3) { _ in
                        Circle().fill(Color.gray.opacity(0.4)).frame(width: 5, height: 5)
                    }
                    Text("INSTRUMENTAL")
                        .font(.caption2)
                        .foregroundStyle(.gray.opacity(0.6))
                        .kerning(1.5)
                }
                .padding(.vertical, 20)
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity, alignment: .leading)

                lyricsSectionHeader("PRE")
                LyricRow(lyric: "夜行性のアパートで", translation: "In this nocturnal apartment", howCount: 2, likeCount: 29, isHighlighted: false)
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
                    ContentUnavailableView(
                        "Apple Music の認証が必要です",
                        systemImage: "music.note.list",
                        description: Text("設定 → プライバシー → メディアと Apple Music で許可してください")
                    )
                    .foregroundStyle(.white)
                } else if playback.searchResults.isEmpty && !playback.searchQuery.isEmpty {
                    ContentUnavailableView.search(text: playback.searchQuery)
                        .foregroundStyle(.white)
                } else {
                    List(playback.searchResults) { track in
                        Button {
                            Task {
                                await playback.select(track: track)
                                showSearchSheet = false
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(track.title)
                                    .font(.body)
                                    .foregroundStyle(.white)
                                Text(track.artistName)
                                    .font(.caption)
                                    .foregroundStyle(.gray)
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
