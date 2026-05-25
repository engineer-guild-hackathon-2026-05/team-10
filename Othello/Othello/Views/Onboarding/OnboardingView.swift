import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()

    var body: some View {
        if viewModel.isOnboardingComplete {
            HomeView(useManualMode: viewModel.useManualMode, permissionState: viewModel.permissionState)
        } else {
            TabView(selection: $viewModel.currentPage) {
                OnboardingWelcomePage(currentPage: $viewModel.currentPage)
                    .tag(0)
                OnboardingMusicPage(viewModel: viewModel)
                    .tag(1)
                OnboardingMotionPage(viewModel: viewModel)
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()
            .animation(.easeInOut, value: viewModel.currentPage)
        }
    }
}

#Preview {
    OnboardingView()
}
