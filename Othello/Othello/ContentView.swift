import SwiftUI

struct ContentView: View {
    @StateObject private var authVM = AuthViewModel()
    @StateObject private var onboardingVM = OnboardingViewModel()
    @State private var nowPlayingContext: NowPlayingContext?
    @State private var showNowPlaying: Bool = false
    @State private var miniPlayerIsPlaying: Bool = true

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

            ForYouView(nowPlayingContext: $nowPlayingContext)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            if nowPlayingContext != nil {
                GlobalMiniPlayerView(song: nowPlayingContext?.song, onTap: {
                    showNowPlaying = true
                }, isPlaying: $miniPlayerIsPlaying)
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: nowPlayingContext?.id) { _, newContextID in
            if newContextID != nil { showNowPlaying = true }
        }
        .fullScreenCover(isPresented: $showNowPlaying) {
            if let context = nowPlayingContext {
                NowPlayingView(context: context)
            }
        }
    }
}

#Preview {
    ContentView()
}
