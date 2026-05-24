import SwiftUI

struct RealtimeReactionDisplayView: View {
    @StateObject private var viewModel = ReactionDisplayViewModel()
    let isSensorAvailable: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    morphSection
                    if !isSensorAvailable {
                        sensorUnavailableNote
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                    }
                    axisLegend
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                }
            }
            .preferredColorScheme(.dark)
            .navigationTitle("リアルタイム反応")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                        .foregroundStyle(Color(red: 1.0, green: 0.3, blue: 0.3))
                }
                ToolbarItem(placement: .primaryAction) {
                    sessionToggleButton
                }
            }
            .onDisappear { viewModel.stopSession() }
            .fullScreenCover(isPresented: $viewModel.showTimeline) {
                ReactionTimelineView(
                    trackTitle: "— 曲タイトル —",
                    trackArtist: "— アーティスト —",
                    duration: 268
                )
            }
        }
    }

    // MARK: - モーフ可視化セクション

    private var morphSection: some View {
        ZStack {
            ReactionMorphView(score: viewModel.score, isActive: viewModel.isSessionActive)
                .frame(height: 340)

            // 中央オーバーレイ：ドミナントステート
            VStack(spacing: 6) {
                if viewModel.isSessionActive, let dominant = viewModel.score.dominant {
                    Text(dominant.emoji)
                        .font(.system(size: 44))
                        .transition(.scale.combined(with: .opacity))
                    Text(dominant.label)
                        .font(.title3.bold())
                        .foregroundStyle(dominant.color)
                        .transition(.opacity)
                } else if viewModel.isSessionActive {
                    ProgressView().tint(.gray)
                    Text("検出中…")
                        .font(.caption)
                        .foregroundStyle(.gray)
                        .padding(.top, 4)
                } else {
                    Text("🎧")
                        .font(.system(size: 36))
                        .opacity(0.5)
                    Text("開始で可視化")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
            }
            .animation(.spring(duration: 0.4), value: viewModel.score.dominant?.id)
            .animation(.easeInOut(duration: 0.3), value: viewModel.isSessionActive)
        }
    }

    // MARK: - 6軸凡例（コンパクト）

    private var axisLegend: some View {
        let axes: [(String, String, Color)] = [
            ("🎵", "groove",    Color(red: 1.0, green: 0.3,  blue: 0.3)),
            ("🔥", "hype",      Color(red: 1.0, green: 0.55, blue: 0.1)),
            ("❄️", "chill",     Color(red: 0.2, green: 0.7,  blue: 1.0)),
            ("🎧", "immersion", Color(red: 0.6, green: 0.3,  blue: 1.0)),
            ("💫", "hit",       Color(red: 1.0, green: 0.2,  blue: 0.5)),
            ("✨", "afterglow", Color(red: 0.9, green: 0.75, blue: 0.3)),
        ]
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 10) {
            ForEach(Array(axes.enumerated()), id: \.offset) { _, axis in
                HStack(spacing: 5) {
                    Text(axis.0).font(.caption)
                    Text(axis.1)
                        .font(.caption2.bold())
                        .foregroundStyle(axis.2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.top, 8)
    }

    private var dominantStateCard: some View {
        VStack(spacing: 12) {
            if viewModel.isSessionActive, let dominant = viewModel.score.dominant {
                Text(dominant.emoji)
                    .font(.system(size: 56))
                    .transition(.scale.combined(with: .opacity))
                Text(dominant.label)
                    .font(.title2.bold())
                    .foregroundStyle(dominant.color)
                    .transition(.opacity)
                Text("いまの状態")
                    .font(.caption)
                    .foregroundStyle(.gray)
            } else if viewModel.isSessionActive {
                ProgressView()
                    .tint(.gray)
                Text("反応を検出中…")
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .padding(.top, 4)
            } else {
                Image(systemName: "waveform.path")
                    .font(.system(size: 40))
                    .foregroundStyle(.gray.opacity(0.4))
                Text("リスニング開始で\nリアルタイム反応を表示")
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 130)
        .padding(20)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
        .animation(.spring(duration: 0.4), value: viewModel.score.dominant?.id)
        .animation(.easeInOut(duration: 0.3), value: viewModel.isSessionActive)
    }

    private var axesPanelCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("6軸スコア")
                .font(.caption.bold())
                .foregroundStyle(.gray.opacity(0.6))
                .kerning(1.2)
                .padding(.bottom, 4)

            if viewModel.isSessionActive {
                VStack(spacing: 14) {
                    ForEach(viewModel.score.axes) { axis in
                        ReactionAxisBar(axis: axis)
                    }
                }
            } else {
                VStack(spacing: 14) {
                    ForEach(ReactionScore.empty.axes) { axis in
                        ReactionAxisBar(axis: ReactionAxis(
                            id: axis.id,
                            label: axis.label,
                            emoji: axis.emoji,
                            value: 0,
                            color: axis.color
                        ))
                    }
                }
                .opacity(0.3)
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
        .animation(.easeInOut(duration: 0.15), value: viewModel.score)
    }

    private var sensorUnavailableNote: some View {
        HStack(spacing: 10) {
            Image(systemName: "hand.tap.fill")
                .foregroundStyle(Color(red: 1.0, green: 0.55, blue: 0.1))
            VStack(alignment: .leading, spacing: 2) {
                Text("手動ラベルモード")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                Text("センサーが使えないため、ボタンで反応を記録します")
                    .font(.caption2)
                    .foregroundStyle(.gray)
            }
        }
        .padding(14)
        .background(Color(red: 1.0, green: 0.55, blue: 0.1).opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }

    private var sessionToggleButton: some View {
        Button {
            if viewModel.isSessionActive {
                viewModel.stopSession()
            } else {
                viewModel.startSession(sensorAvailable: isSensorAvailable)
            }
        } label: {
            Text(viewModel.isSessionActive ? "終了" : "開始")
                .font(.subheadline.bold())
                .foregroundStyle(viewModel.isSessionActive ? .white : Color(red: 1.0, green: 0.3, blue: 0.3))
        }
    }
}

#Preview {
    RealtimeReactionDisplayView(isSensorAvailable: true)
}
