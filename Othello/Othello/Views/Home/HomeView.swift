import SwiftUI
import CoreMotion

struct HomeView: View {
    @State private var isSensorAvailable = CMHeadphoneMotionManager().isDeviceMotionAvailable
    @State private var navigateToListening = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        headerSection
                        sensorStatusBadge
                        startListeningCard
                        howCardsPlaceholder
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 48)
                }
            }
            .preferredColorScheme(.dark)
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $navigateToListening) {
                ReactionDisplayView(isSensorAvailable: isSensorAvailable)
            }
        }
    }

    // MARK: - ヘッダー

    private var headerSection: some View {
        VStack(spacing: 6) {
            Text("HowTune")
                .font(.system(size: 34, weight: .black, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(red: 1.0, green: 0.3, blue: 0.3), Color(red: 1.0, green: 0.55, blue: 0.1)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            Text("あなたの「聴き方」を言語化する")
                .font(.subheadline)
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - センサーステータスバッジ

    private var sensorStatusBadge: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isSensorAvailable ? Color(red: 0.2, green: 0.9, blue: 0.4) : Color(red: 1.0, green: 0.55, blue: 0.1))
                .frame(width: 8, height: 8)
            Text(isSensorAvailable ? "AirPods 接続中 — 頭部モーション有効" : "センサーなし — 手動ラベルモード")
                .font(.caption.bold())
                .foregroundStyle(isSensorAvailable ? Color(red: 0.2, green: 0.9, blue: 0.4) : Color(red: 1.0, green: 0.55, blue: 0.1))
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            (isSensorAvailable ? Color(red: 0.2, green: 0.9, blue: 0.4) : Color(red: 1.0, green: 0.55, blue: 0.1))
                .opacity(0.08),
            in: RoundedRectangle(cornerRadius: 10)
        )
    }

    // MARK: - リスニング開始カード

    private var startListeningCard: some View {
        Button {
            navigateToListening = true
        } label: {
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.85, green: 0.15, blue: 0.2),
                                    Color(red: 0.6, green: 0.05, blue: 0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 72, height: 72)
                    Image(systemName: "waveform.path")
                        .font(.system(size: 30, weight: .medium))
                        .foregroundStyle(.white)
                }

                VStack(spacing: 6) {
                    Text("リスニングを開始")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                    Text("曲を再生しながら反応をリアルタイム検出")
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.center)
                }

                HStack(spacing: 6) {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.subheadline)
                    Text("はじめる")
                        .font(.subheadline.bold())
                }
                .foregroundStyle(Color(red: 1.0, green: 0.3, blue: 0.3))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .padding(.horizontal, 20)
            .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color(red: 1.0, green: 0.3, blue: 0.3).opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - How カード一覧プレースホルダー

    private var howCardsPlaceholder: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("あなたの How カード")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Text("近日実装予定")
                    .font(.caption.bold())
                    .foregroundStyle(.gray)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.07), in: Capsule())
            }

            VStack(spacing: 12) {
                ForEach(["groove", "immersion", "hit"], id: \.self) { tag in
                    howCardPlaceholderRow(tag: tag)
                }
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 16))
    }

    private func howCardPlaceholderRow(tag: String) -> some View {
        let titleWidths: [String: CGFloat] = ["groove": 140, "immersion": 120, "hit": 160]
        let subtitleWidths: [String: CGFloat] = ["groove": 80, "immersion": 100, "hit": 70]

        return HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.08))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "music.note")
                        .font(.subheadline)
                        .foregroundStyle(.gray.opacity(0.4))
                )

            VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: titleWidths[tag, default: 130], height: 10)
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.06))
                    .frame(width: subtitleWidths[tag, default: 80], height: 8)
            }

            Spacer()

            Text(tag)
                .font(.caption2.bold())
                .foregroundStyle(.gray)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.white.opacity(0.07), in: Capsule())
        }
    }
}

#Preview {
    HomeView()
}
