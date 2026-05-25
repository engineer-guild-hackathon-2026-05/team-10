import SwiftUI

struct ContentView: View {
    @StateObject private var authVM = AuthViewModel()
    @StateObject private var onboardingVM = OnboardingViewModel()
    @State private var nowPlayingSong: Song? = Song(
        id: UUID(),
        title: "ライラック",
        artistName: "Mrs. GREEN APPLE",
        gradientColors: [Color(red: 0.85, green: 0.55, blue: 0.35), Color(red: 0.65, green: 0.35, blue: 0.5)],
        durationSeconds: 272
    )
    @State private var showNowPlaying: Bool = false

    var body: some View {
        if !authVM.isLoggedIn {
            LoginView(authVM: authVM)
        } else if onboardingVM.isOnboardingComplete {
            mainView
        } else {
            onboardingFlow
        }
    }

    private var onboardingFlow: some View {
        TabView(selection: $onboardingVM.currentPage) {
            OnboardingWelcomePage(currentPage: $onboardingVM.currentPage).tag(0)
            OnboardingMotionPage(viewModel: onboardingVM).tag(1)
            OnboardingHealthPage(viewModel: onboardingVM).tag(2)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .ignoresSafeArea()
        .animation(.easeInOut, value: onboardingVM.currentPage)
    }

    private var mainView: some View {
        ZStack(alignment: .bottom) {
            Color.black.ignoresSafeArea()

            ForYouView(nowPlayingSong: $nowPlayingSong)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            if nowPlayingSong != nil {
                GlobalMiniPlayerView(song: nowPlayingSong) {
                    showNowPlaying = true
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
        }
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: $showNowPlaying) {
            if let song = nowPlayingSong {
                NowPlayingView(song: song)
            }
        }
    }
}

// MARK: - Global Mini Player

struct GlobalMiniPlayerView: View {
    let song: Song?
    let onTap: () -> Void
    @State private var isPlaying: Bool = true

    var body: some View {
        if let song {
            playerContent(song: song)
        }
    }

    private func playerContent(song: Song) -> some View {
        HStack(spacing: 12) {
            // アルバムアート風アイコン
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.ultraThinMaterial)
                    .frame(width: 46, height: 46)
                Image(systemName: "music.note")
                    .font(.system(size: 20))
                    .foregroundStyle(.secondary)
            }

            Text(isPlaying ? song.title : "再生停止中")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .lineLimit(1)

            Spacer()

            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isPlaying.toggle()
                }
            } label: {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.title3)
                    .foregroundStyle(.primary)
                    .frame(width: 36, height: 36)
            }

            Button {} label: {
                Image(systemName: "forward.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .frame(width: 36, height: 36)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background {
            ZStack {
                // ガラス素材
                Capsule()
                    .fill(.ultraThinMaterial)
                // 曲のグラデーションをうっすら重ねる
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: song.gradientColors.map { $0.opacity(0.25) },
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                // 白の光沢ハイライト
                Capsule()
                    .strokeBorder(Color.white.opacity(0.35), lineWidth: 1)
            }
        }
        .contentShape(Capsule())
        .onTapGesture { onTap() }
    }
}

#Preview {
    ContentView()
}
