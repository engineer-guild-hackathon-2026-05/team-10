import SwiftUI

struct ContentView: View {
    @StateObject private var authVM = AuthViewModel()
    @StateObject private var onboardingVM = OnboardingViewModel()
    @State private var nowPlayingSong: Song?
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

#Preview {
    ContentView()
}
