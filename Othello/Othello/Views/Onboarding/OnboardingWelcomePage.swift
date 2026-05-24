import SwiftUI

struct OnboardingWelcomePage: View {
    @Binding var currentPage: Int

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(.systemIndigo), Color(.systemPurple)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 24) {
                    Image(systemName: "headphones.circle.fill")
                        .font(.system(size: 96))
                        .foregroundStyle(.white)
                        .symbolEffect(.bounce, options: .repeating)

                    VStack(spacing: 8) {
                        Text("HowTune")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        Text("How でつながる音楽体験")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }

                Spacer()

                VStack(spacing: 20) {
                    featureRow(
                        icon: "figure.walk.motion",
                        title: "身体の反応を感知",
                        description: "AirPods や iPhone のモーションセンサーで、音楽への自然な反応を記録します"
                    )
                    featureRow(
                        icon: "heart.fill",
                        title: "心拍で感動を測る",
                        description: "Apple Watch の心拍データで、音楽体験の深さを可視化します"
                    )
                    featureRow(
                        icon: "person.2.fill",
                        title: "同じ「How」でつながる",
                        description: "聴き方の傾向が近い人と出会い、音楽体験を共有できます"
                    )
                }
                .padding(.horizontal, 32)

                Spacer()

                Button {
                    withAnimation { currentPage = 1 }
                } label: {
                    Text("はじめる")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.white)
                        .foregroundStyle(Color(.systemIndigo))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
    }

    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.75))
            }
        }
    }
}

#Preview {
    OnboardingWelcomePage(currentPage: .constant(0))
}
