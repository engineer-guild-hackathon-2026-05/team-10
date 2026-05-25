import SwiftUI

struct ClipCreationView: View {
    let song: Song
    @StateObject private var viewModel: ClipCreationViewModel
    @Environment(\.dismiss) private var dismiss

    init(song: Song) {
        self.song = song
        self._viewModel = StateObject(wrappedValue: ClipCreationViewModel(song: song))
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 28) {
                        albumArt
                        songInfo
                        playerControls
                        waveformSection
                        commentSection
                        shareButton
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .padding(.bottom, 110)
                }
                tabSelector
            }
            .navigationTitle("切り抜きを作成")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(Color.white.opacity(0.12), in: Circle())
                    }
                    .accessibilityLabel("戻る")
                }
            }
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .alert("投稿エラー", isPresented: postErrorBinding) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.postErrorMessage ?? "")
            }
            .preferredColorScheme(.dark)
        }
    }

    // MARK: - Album Art

    private var albumArt: some View {
        CircularArtworkView(song: song, size: 220, isPlaying: viewModel.isPlaying, showsCenterHole: true)
    }

    // MARK: - Song Info

    private var songInfo: some View {
        VStack(spacing: 6) {
            Text(song.title)
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            Text(song.artistName)
                .font(.subheadline)
                .foregroundStyle(.gray)
        }
    }

    // MARK: - Player Controls

    private var playerControls: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.4), lineWidth: 1.5)
                    .frame(width: 50, height: 50)
                Text("30")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }

            GeometryReader { geo in
                let w = geo.size.width
                let safeDuration = max(viewModel.totalDuration, 1e-6)
                let progress = viewModel.currentTime / safeDuration
                let startX = CGFloat(viewModel.clipStart / safeDuration) * w
                let endX = CGFloat(viewModel.clipEnd / safeDuration) * w
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 3)
                    Capsule()
                        .fill(Color.white)
                        .frame(width: w * progress, height: 3)
                    Circle()
                        .fill(Color.white)
                        .frame(width: 16, height: 16)
                        .offset(x: w * progress - 8)
                    Circle()
                        .fill(Color(red: 1.0, green: 0.25, blue: 0.5))
                        .frame(width: 11, height: 11)
                        .offset(x: startX - 5.5)
                    Circle()
                        .fill(Color(red: 1.0, green: 0.25, blue: 0.5))
                        .frame(width: 11, height: 11)
                        .offset(x: endX - 5.5)
                }
                .frame(maxHeight: .infinity)
            }
            .frame(height: 20)

            Button { viewModel.togglePlayback() } label: {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 52, height: 52)
                    Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color.black)
                }
            }
        }
    }

    // MARK: - Waveform Section

    private var waveformSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("好きな部分を選ぶ")
                    .font(.caption)
                    .foregroundStyle(.gray)
                Spacer()
                Text("\(viewModel.clipStartFormatted) – \(viewModel.clipEndFormatted)")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }

            WaveformView(
                waveformData: viewModel.waveformData,
                totalDuration: viewModel.totalDuration,
                clipStart: viewModel.clipStart,
                clipEnd: viewModel.clipEnd
            ) { startRatio, endRatio in
                viewModel.updateClipRange(startRatio: startRatio, endRatio: endRatio)
            }
            .frame(height: 110)
            .clipShape(RoundedRectangle(cornerRadius: 14))

            HStack {
                Text("枠をドラッグして範囲を調整")
                    .font(.caption2)
                    .foregroundStyle(.gray)
                Spacer()
                Text("\(viewModel.clipDurationSeconds)s")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color(red: 0.3, green: 0.2, blue: 0.55), in: Capsule())
            }
        }
    }

    // MARK: - Comment

    private var commentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("コメント")
                    .font(.caption)
                    .foregroundStyle(.gray)
                Spacer()
                Text("\(viewModel.commentText.count)/140")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.gray)
            }

            ZStack(alignment: .topLeading) {
                if viewModel.commentText.isEmpty {
                    Text("この曲のここが好き")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.32))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 13)
                }

                TextEditor(text: $viewModel.commentText)
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .frame(minHeight: 88)
                    .onChange(of: viewModel.commentText) { _, newValue in
                        if newValue.count > 140 {
                            viewModel.commentText = String(newValue.prefix(140))
                        }
                    }
            }
            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )

            if viewModel.postedCardID != nil {
                Label("Howカードを投稿しました", systemImage: "checkmark.circle.fill")
                    .font(.caption.bold())
                    .foregroundStyle(Color.green)
            }
        }
    }

    // MARK: - Share Button

    private var shareButton: some View {
        Button {
            Task {
                if await viewModel.postHowCard() {
                    dismiss()
                }
            }
        } label: {
            HStack(spacing: 8) {
                if viewModel.isPosting {
                    ProgressView()
                        .tint(.black)
                    Text("投稿中")
                        .font(.body.weight(.semibold))
                } else {
                    Image(systemName: "square.and.arrow.up")
                        .font(.body.weight(.semibold))
                    Text("この切り抜きをシェア")
                        .font(.body.weight(.semibold))
                }
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
        }
        .disabled(viewModel.isPosting)
    }

    private var postErrorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.postErrorMessage != nil },
            set: { if !$0 { viewModel.postErrorMessage = nil } }
        )
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: 0) {
            // 再生タブ（非アクティブ）
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.selectedTab = .playback
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "waveform")
                        .font(.subheadline)
                    Text("再生")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(viewModel.selectedTab == .playback ? .white : .gray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(
                    viewModel.selectedTab == .playback
                        ? Color.white.opacity(0.08)
                        : Color.clear,
                    in: Capsule()
                )
            }

            // 切り抜きタブ（アクティブ）
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewModel.selectedTab = .clip
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "scissors")
                        .font(.subheadline)
                    Text("切り抜き")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(viewModel.selectedTab == .clip ? Color(red: 0.65, green: 0.5, blue: 1.0) : .gray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(
                    viewModel.selectedTab == .clip
                        ? Color(red: 0.25, green: 0.18, blue: 0.45)
                        : Color.clear,
                    in: Capsule()
                )
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 5)
        .background(Color(red: 0.1, green: 0.1, blue: 0.12), in: RoundedRectangle(cornerRadius: 30))
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 16)
        .background(Color.black)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.white.opacity(0.07))
                .frame(height: 0.5)
        }
    }
}


#Preview {
    ClipCreationView(song: Song(
        id: UUID(),
        title: "ライラック",
        artistName: "Mrs. GREEN APPLE",
        gradientColors: [
            Color(red: 0.75, green: 0.5, blue: 0.85),
            Color(red: 0.95, green: 0.65, blue: 0.4)
        ],
        durationSeconds: 272
    ))
}
