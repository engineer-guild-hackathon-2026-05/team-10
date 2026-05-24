import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()

    var body: some View {
        if viewModel.isOnboardingComplete {
            Text("メイン画面（実装予定）")
                .font(.title2)
                .foregroundStyle(.secondary)
        } else {
            TabView(selection: $viewModel.currentPage) {
                OnboardingWelcomePage(currentPage: $viewModel.currentPage)
                    .tag(0)
                OnboardingMotionPage(viewModel: viewModel)
                    .tag(1)
                OnboardingHealthPage(viewModel: viewModel)
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
