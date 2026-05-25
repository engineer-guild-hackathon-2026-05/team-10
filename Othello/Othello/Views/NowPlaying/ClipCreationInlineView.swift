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
                shareButton
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
    }

    private var albumArt: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(LinearGradient(
                colors: song.gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
            .frame(width: 180, height: 180)
            .shadow(color: (song.gradientColors.first ?? .clear).opacity(0.4), radius: 20, y: 8)
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

    private var shareButton: some View {
        Button {} label: {
            HStack(spacing: 8) {
                Image(systemName: "square.and.arrow.up")
                    .font(.body.weight(.semibold))
                Text("この切り抜きをシェア")
                    .font(.body.weight(.semibold))
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 16))
        }
    }
}
