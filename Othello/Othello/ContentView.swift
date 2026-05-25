import SwiftUI

struct ContentView: View {
    @StateObject private var authVM = AuthViewModel()
    @StateObject private var onboardingVM = OnboardingViewModel()
    @State private var selectedTab: Int = 0

    var body: some View {
        if !authVM.isLoggedIn {
            LoginView(authVM: authVM)
        } else if onboardingVM.isOnboardingComplete {
            mainTabView
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

    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            HomeView(useManualMode: onboardingVM.useManualMode, permissionState: onboardingVM.permissionState)
                .tabItem { Label("再生", systemImage: "waveform.path") }
                .tag(0)
            CommunityView()
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("ログアウト") { authVM.signOut() }
                            .foregroundStyle(HowTuneDesign.accent)
                    }
                }
                .tabItem { Label("コミュニティ", systemImage: "person.2.fill") }
                .tag(1)
        }
        .preferredColorScheme(.dark)
        .tint(Color(red: 1.0, green: 0.3, blue: 0.3))
        .toolbarBackground(Color.black.opacity(0.9), for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}

#Preview {
    ContentView()
}
