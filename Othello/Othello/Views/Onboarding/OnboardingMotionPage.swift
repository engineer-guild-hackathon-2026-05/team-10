import SwiftUI

struct OnboardingMotionPage: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var isRequesting = false

    var body: some View {
        VStack(spacing: 0) {
            progressIndicator(current: 1, total: 2)
                .padding(.top, 60)
                .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 32) {
                Image(systemName: "figure.walk.motion")
                    .font(.system(size: 72))
                    .foregroundStyle(Color(.systemIndigo))

                VStack(spacing: 12) {
                    Text("モーションセンサーの使用")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("音楽を聴いているときの身体の動きを検知します。この情報はあなたの「聴き方」の特徴を分析するためだけに使用します。")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)

                purposeCard(
                    icon: "lock.shield.fill",
                    title: "プライバシーについて",
                    body: "モーションデータはデバイス上でのみ処理されます。外部サーバーに送信されることはありません。"
                )
                .padding(.horizontal, 24)

                if !viewModel.permissionState.airPodsAvailable {
                    airPodsUnavailableNote
                        .padding(.horizontal, 24)
                }
            }

            Spacer()

            VStack(spacing: 16) {
                if viewModel.permissionState.motion == .authorized {
                    authorizedBadge(label: "モーションが許可されました")
                    nextButton
                } else {
                    Button {
                        isRequesting = true
                        Task {
                            await viewModel.requestMotionPermission()
                            isRequesting = false
                        }
                    } label: {
                        Label(
                            isRequesting ? "確認中…" : "モーションを許可する",
                            systemImage: "figure.walk"
                        )
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(.systemIndigo))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .disabled(isRequesting)

                    skipButton(label: "スキップして手動モードへ進む") {
                        viewModel.proceedToManualMode()
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
    }

    private var nextButton: some View {
        Button {
            withAnimation { viewModel.currentPage = 2 }
        } label: {
            Text("次へ")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(.systemIndigo))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private var airPodsUnavailableNote: some View {
        HStack(spacing: 12) {
            Image(systemName: "airpods")
                .foregroundStyle(Color(.systemOrange))
            Text("AirPods が未接続か非対応のため、iPhone 本体のモーションセンサーを使用します")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(Color(.systemOrange).opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}


#Preview {
    OnboardingMotionPage(viewModel: OnboardingViewModel())
}
