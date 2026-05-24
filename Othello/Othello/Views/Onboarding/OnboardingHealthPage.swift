import SwiftUI

struct OnboardingHealthPage: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var isRequesting = false

    var body: some View {
        ZStack {
            HowTuneDesign.background.ignoresSafeArea()

            VStack(spacing: 0) {
                progressIndicator(current: 2, total: 2)
                    .padding(.top, 60)
                    .padding(.horizontal, 32)

                Spacer()

                VStack(spacing: 28) {
                    ZStack {
                        Circle()
                            .fill(Color.pink.opacity(0.15))
                            .frame(width: 100, height: 100)
                        Image(systemName: "heart.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.pink)
                    }

                    VStack(spacing: 10) {
                        Text("心拍データの使用")
                            .font(.title2.bold())
                            .foregroundStyle(.white)
                        Text("Apple Watch の心拍数データを使い、音楽を聴いているときの感動の深さを可視化します。")
                            .font(.body)
                            .foregroundStyle(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 32)

                    VStack(spacing: 10) {
                        purposeCard(
                            icon: "cross.case.fill",
                            title: "読み取りのみ・書き込みなし",
                            body: "心拍数のみを読み取ります。How カード生成以外には使用しません。"
                        )
                        purposeCard(
                            icon: "lock.shield.fill",
                            title: "機微情報として管理",
                            body: "HealthKit の機微情報として扱い、端末外への送信は最小限にとどめます。"
                        )
                    }
                    .padding(.horizontal, 24)
                }

                Spacer()

                VStack(spacing: 14) {
                    if viewModel.permissionState.health == .authorized {
                        authorizedBadge(label: "心拍アクセスが許可されました")
                        completeButton
                    } else {
                        primaryButton(
                            label: "心拍を許可する",
                            icon: "heart",
                            isLoading: isRequesting
                        ) {
                            isRequesting = true
                            Task {
                                await viewModel.requestHealthPermission()
                                isRequesting = false
                            }
                        }

                        skipButton(label: "スキップして続ける") {
                            viewModel.completeOnboarding()
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var completeButton: some View {
        primaryButton(label: "HowTune をはじめる", icon: "music.note") {
            viewModel.completeOnboarding()
        }
    }
}

#Preview {
    OnboardingHealthPage(viewModel: OnboardingViewModel())
}
