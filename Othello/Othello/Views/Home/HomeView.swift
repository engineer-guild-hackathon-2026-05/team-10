import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    @State private var navigateToReaction = false
    @State private var tappedLyric: String? = nil
    @State private var tappedLyricTranslation: String? = nil

    // 現在ハイライト中の歌詞インデックス（スクロール連動用のモック）
    @State private var currentLyricIndex: Int = 1

    private let lyrics: [(text: String, translation: String, howCount: Int, likeCount: Int)] = [
        ("深夜二時の改札を抜けて", "Through the late-night turnstile", 4, 82),
        ("コンビニの灯りに泳いだ", "Swimming in the convenience-store glow", 12, 341),
        ("君のメッセージは未読のまま", "Your message still unread", 3, 118),
        ("壊れた傘を畳んでいる", "Folding a broken umbrella", 1, 47),
        ("夜行性のアパートで", "In this nocturnal apartment", 2, 29),
    ]

    init(useManualMode: Bool, permissionState: PermissionState) {
        _viewModel = StateObject(wrappedValue: HomeViewModel(
            useManualMode: useManualMode,
            permissionState: permissionState
        ))
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // 背景だけsafeArea無視で全画面
                backgroundLayer
                    .ignoresSafeArea()

                // 歌詞エリア（上部〜中央）
                lyricsOverlay
                    .ignoresSafeArea(edges: .top)

                // 下部プレーヤーパネル（safeArea内＝タブバーより上に収まる）
                VStack(spacing: 0) {
                    Spacer()
                    playerPanel
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
    }

    // MARK: - 背景

    private var backgroundLayer: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // アルバムアートの代わりのグラデーション背景
            LinearGradient(
                colors: [
                    Color(red: 0.55, green: 0.05, blue: 0.12),
                    Color(red: 0.2, green: 0.03, blue: 0.08),
                    Color.black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // アルバムアートアイコン（背景として薄く）
            VStack {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.04))
                        .frame(width: 280, height: 280)
                    Image(systemName: "music.note")
                        .font(.system(size: 80))
                        .foregroundStyle(.white.opacity(0.08))
                }
                .padding(.top, 60)
                Spacer()
            }

            // 下部への暗転グラデーション
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.85)],
                startPoint: .center,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - 歌詞オーバーレイ

    private var lyricsOverlay: some View {
        VStack(spacing: 0) {
            // タイトルバー
            HStack {
                Spacer()
                Text("Lyrics")
                    .font(.subheadline.bold())
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
            }
            .padding(.top, 56)
            .padding(.bottom, 24)

            Spacer()

            // 歌詞リスト（中央付近に表示）
            VStack(spacing: 20) {
                ForEach(lyrics.indices, id: \.self) { idx in
                    let entry = lyrics[idx]
                    let isActive = idx == currentLyricIndex

                    Button {
                        withAnimation(.spring(duration: 0.3)) {
                            currentLyricIndex = idx
                        }
                        tappedLyric = entry.text
                        tappedLyricTranslation = entry.translation
                        navigateToReaction = true
                    } label: {
                        VStack(spacing: 6) {
                            Text(entry.text)
                                .font(isActive ? .title3.bold() : .body)
                                .foregroundStyle(isActive ? .white : .white.opacity(0.4))
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)

                            if isActive {
                                // Howカードバッジ（アクティブ行のみ）
                                HStack(spacing: 10) {
                                    howBadge(count: entry.howCount)
                                    likeBadge(count: entry.likeCount)
                                }
                                .transition(.opacity.combined(with: .scale))
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .animation(.easeInOut(duration: 0.25), value: currentLyricIndex)
                }
            }
            .padding(.horizontal, 32)

            Spacer()

            // 下部パネルの高さ分のスペーサー（センサーバー50 + プレーヤー220 + safeArea34 程度）
            Color.clear.frame(height: 310)
        }
    }

    private func howBadge(count: Int) -> some View {
        Button {
            // すでにtappedLyricはタップ済みなので遷移
            navigateToReaction = true
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "bubble.left.fill")
                    .font(.caption2)
                Text("\(count) How")
                    .font(.caption.bold())
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(red: 0.85, green: 0.15, blue: 0.2), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private func likeBadge(count: Int) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "heart.fill")
                .font(.caption2)
            Text("\(count)")
                .font(.caption.bold())
        }
        .foregroundStyle(.white.opacity(0.55))
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.1), in: Capsule())
    }

    // MARK: - 下部プレーヤーパネル

    private var playerPanel: some View {
        VStack(spacing: 0) {
            // センサー状態バー
            sensorStatusBar

            VStack(spacing: 12) {
                // 曲情報
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.mockTrackTitle)
                            .font(.headline.bold())
                            .foregroundStyle(.white)
                        Text(viewModel.mockTrackArtist)
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                    }
                    Spacer()
                    HStack(spacing: 16) {
                        Button {} label: {
                            Image(systemName: "heart")
                                .font(.title3)
                                .foregroundStyle(.gray)
                        }
                        Button {
                            tappedLyric = nil
                            tappedLyricTranslation = nil
                            navigateToReaction = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "bubble.left")
                                    .font(.caption)
                                Text("87")
                                    .font(.caption.bold())
                            }
                            .foregroundStyle(.gray)
                        }
                        .buttonStyle(.plain)
                    }
                }

                // シークバー
                VStack(spacing: 4) {
                    Slider(
                        value: .constant(
                            viewModel.mockTrackDuration > 0
                                ? viewModel.playbackTime / viewModel.mockTrackDuration
                                : 0
                        )
                    )
                    .tint(Color(red: 1.0, green: 0.3, blue: 0.3))
                    .disabled(true)

                    HStack {
                        Text(formatTime(viewModel.playbackTime))
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.gray)
                        Spacer()
                        Text("−\(formatTime(viewModel.mockTrackDuration - viewModel.playbackTime))")
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.gray)
                    }
                }

                // 再生コントロール
                HStack(spacing: 0) {
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
                    Button { viewModel.togglePlayback() } label: {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(red: 1.0, green: 0.45, blue: 0.45), Color(red: 0.85, green: 0.15, blue: 0.2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 64, height: 64)
                                .shadow(color: .red.opacity(0.5), radius: 12, y: 4)
                            Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                                .font(.title2)
                                .foregroundStyle(.white)
                                .offset(x: viewModel.isPlaying ? 0 : 2)
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
                .padding(.bottom, 4)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 12)
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: 0)
            )
            .background(Color.black.opacity(0.6))
        }
    }

    // MARK: - センサー状態バー

    private var sensorStatusBar: some View {
        HStack(spacing: 12) {
            sensorDot(icon: "airpods", color: viewModel.sensorStatus.headMotion.color)
            sensorDot(icon: "iphone", color: viewModel.sensorStatus.bodyMotion.color)
            sensorDot(icon: "heart.fill", color: viewModel.sensorStatus.heartRate.color)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.3))
    }

    private func sensorDot(icon: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(.gray)
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let t = max(0, time)
        return String(format: "%d:%02d", Int(t) / 60, Int(t) % 60)
    }
}

#Preview {
    HomeView(useManualMode: false, permissionState: PermissionState())
}
