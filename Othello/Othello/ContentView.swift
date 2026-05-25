import SwiftUI

struct ContentView: View {
    @StateObject private var authVM = AuthViewModel()
    @StateObject private var onboardingVM = OnboardingViewModel()
    @StateObject private var playback = PlaybackViewModel()
    @StateObject private var airPods = AirPodsMotionViewModel()
    @State private var nowPlayingSong: Song?
    @State private var showNowPlaying: Bool = false
    @State private var didWarmHowCards = false

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

            ForYouView(nowPlayingSong: $nowPlayingSong, playback: playback)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            if nowPlayingSong != nil {
                GlobalMiniPlayerView(song: nowPlayingSong, onTap: {
                    showNowPlaying = true
                }, playback: playback)
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
        }
        .preferredColorScheme(.dark)
        .task {
            await playback.onAppear()
            await warmHowCardSeedIfNeeded()
        }
        .onChange(of: nowPlayingSong?.id) { _, newValue in
            if newValue != nil {
                airPods.start(playbackPositionProvider: playback.playbackPositionProvider())
            } else {
                airPods.stop()
            }
        }
        .alert("再生位置が取得できません", isPresented: $playback.positionUnavailableAlertShown) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(playback.positionUnavailableMessage)
        }
        .onChange(of: nowPlayingSong) { _, newSong in
            if newSong != nil { showNowPlaying = true }
        }
        .fullScreenCover(isPresented: $showNowPlaying) {
            if let song = nowPlayingSong {
                NowPlayingView(song: song, playback: playback, airPods: airPods)
            }
        }
    }

    private func warmHowCardSeedIfNeeded() async {
        guard !didWarmHowCards else { return }
        didWarmHowCards = true

        do {
            _ = try await FirebaseAPI.shared.fetchHowCards(limit: 1)
        } catch {
            #if DEBUG
            print("[HowCards] seed warmup failed: \(error)")
            #endif
        }
    }
}

#Preview {
    ContentView()
}
