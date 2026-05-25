import SwiftUI

struct ClipCreationInlineView: View {
    let song: Song
    @StateObject private var viewModel: ClipCreationViewModel

    init(song: Song) {
        self.song = song
        self._viewModel = StateObject(wrappedValue: ClipCreationViewModel(song: song))
    }

    var body: some View {
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
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .alert("投稿エラー", isPresented: postErrorBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.postErrorMessage ?? "")
        }
    }

    private var albumArt: some View {
        CircularArtworkView(song: song, size: 180, isPlaying: viewModel.isPlaying, showsCenterHole: true)
    }

    private var songInfo: some View {
        VStack(spacing: 6) {
            Text(song.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
            Text(song.artistName)
                .font(.subheadline)
                .foregroundStyle(.gray)
        }
    }

    private var playerControls: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.4), lineWidth: 1.5)
                    .frame(width: 44, height: 44)
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
                        .frame(width: 14, height: 14)
                        .offset(x: w * progress - 7)
                    Circle()
                        .fill(Color(red: 1.0, green: 0.25, blue: 0.5))
                        .frame(width: 10, height: 10)
                        .offset(x: startX - 5)
                    Circle()
                        .fill(Color(red: 1.0, green: 0.25, blue: 0.5))
                        .frame(width: 10, height: 10)
                        .offset(x: endX - 5)
                }
                .frame(maxHeight: .infinity)
            }
            .frame(height: 20)

            Button { viewModel.togglePlayback() } label: {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 48, height: 48)
                    Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.black)
                }
            }
        }
    }

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

            InlineWaveformView(
                waveformData: viewModel.waveformData,
                totalDuration: viewModel.totalDuration,
                clipStart: viewModel.clipStart,
                clipEnd: viewModel.clipEnd
            ) { startRatio, endRatio in
                viewModel.updateClipRange(startRatio: startRatio, endRatio: endRatio)
            }
            .frame(height: 100)
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
                    .frame(minHeight: 82)
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

    private var shareButton: some View {
        Button {
            Task { await viewModel.postHowCard() }
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
            .padding(.vertical, 16)
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
}
