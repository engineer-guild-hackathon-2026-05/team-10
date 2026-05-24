import SwiftUI

struct OnboardingHealthPage: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var isRequesting = false

    var body: some View {
        VStack(spacing: 0) {
            progressIndicator(current: 2, total: 2)
                .padding(.top, 60)
                .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 32) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(Color(.systemPink))

                VStack(spacing: 12) {
                    Text("心拍データの使用")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Apple Watch の心拍数データを使い、音楽を聴いているときの感動の深さを可視化します。")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)

                purposeCard(
                    icon: "cross.case.fill",
                    title: "HealthKit について",
                    body: "読み取るのは心拍数のみです。データはあなたの「How Card」生成のみに使用します。書き込みは行いません。"
                )
                .padding(.horizontal, 24)
            }

            Spacer()

            VStack(spacing: 16) {
                if viewModel.permissionState.health == .authorized {
                    authorizedBadge(label: "心拍アクセスが許可されました")
                    completeButton
                } else {
                    Button {
                        isRequesting = true
                        Task {
                            await viewModel.requestHealthPermission()
                            isRequesting = false
                        }
                    } label: {
                        Label(
                            isRequesting ? "確認中…" : "心拍を許可する",
                            systemImage: "heart"
                        )
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(.systemPink))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(isRequesting)

                    skipButton(label: "スキップして続ける") {
                        viewModel.completeOnboarding()
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
    }

    private var completeButton: some View {
        Button {
            viewModel.completeOnboarding()
        } label: {
            Text("HowTune をはじめる")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(.systemIndigo))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

#Preview {
    OnboardingHealthPage(viewModel: OnboardingViewModel())
}
