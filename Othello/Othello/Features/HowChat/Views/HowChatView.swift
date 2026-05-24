import SwiftUI

struct HowChatView: View {
    @StateObject private var vm: HowChatViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var pulseScale: CGFloat = 1.0

    init(event: ReactionEvent) {
        _vm = StateObject(wrappedValue: HowChatViewModel(event: event))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 0) {
                    reactionHeader(event: vm.event)
                    Divider().overlay(Color.white.opacity(0.08))
                    messageList
                    Divider().overlay(Color.white.opacity(0.08))
                    inputArea
                }
            }
            .preferredColorScheme(.dark)
            .navigationTitle("この瞬間について")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                        .foregroundStyle(Color(red: 1.0, green: 0.3, blue: 0.3))
                }
            }
        }
        .presentationDetents([.large])
        .preferredColorScheme(.dark)
        .onAppear { vm.start() }
    }

    // MARK: - 反応地点ヘッダー（可視化）

    @ViewBuilder
    private func reactionHeader(event: ReactionEvent) -> some View {
        let dominant = event.tags.first
        let color = dominant?.color ?? .white

        VStack(spacing: 12) {
            HStack(alignment: .center, spacing: 16) {
                // モメンタムパルス
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 64, height: 64)
                        .scaleEffect(pulseScale)
                        .animation(
                            .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                            value: pulseScale
                        )
                    Circle()
                        .fill(color.opacity(0.3))
                        .frame(width: 44, height: 44)
                    Text(dominant.map { tagEmoji($0) } ?? "🎵")
                        .font(.system(size: 22))
                }
                .onAppear { pulseScale = 1.18 }

                VStack(alignment: .leading, spacing: 4) {
                    Text(formatTime(event.startTime))
                        .font(.caption.monospacedDigit().bold())
                        .foregroundStyle(.gray)

                    if let lyric = event.lyricLine {
                        Text(lyric)
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                            .lineLimit(2)
                    }

                    HStack(spacing: 6) {
                        ForEach(event.tags, id: \.self) { tag in
                            Text(tag.label)
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(tag.color.opacity(0.8), in: Capsule())
                        }
                        // 強度バー
                        intensityBar(value: event.intensity, color: color)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)

            // 心拍トレンド
            HStack(spacing: 6) {
                Image(systemName: event.heartRateTrend.systemImage)
                    .font(.caption)
                    .foregroundStyle(event.heartRateTrend.color)
                Text("心拍 \(event.heartRateTrend.label)")
                    .font(.caption)
                    .foregroundStyle(.gray)
                Spacer()
                Text("強度 \(Int(event.intensity * 100))%")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.gray)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 10)
        }
        .background(Color.white.opacity(0.03))
    }

    // MARK: - 強度バー

    private func intensityBar(value: Double, color: Color) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.1)).frame(height: 4)
                Capsule().fill(color).frame(width: geo.size.width * value, height: 4)
            }
        }
        .frame(width: 60, height: 4)
    }

    // MARK: - メッセージ一覧

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(vm.messages) { msg in
                        messageBubble(msg)
                            .id(msg.id)
                    }
                    if vm.state == .loading {
                        typingIndicator
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .onChange(of: vm.messages.count) { _ in
                withAnimation { proxy.scrollTo(vm.messages.last?.id) }
            }
            .onChange(of: vm.state) { _ in
                withAnimation { proxy.scrollTo(vm.messages.last?.id) }
            }
        }
    }

    @ViewBuilder
    private func messageBubble(_ msg: HowChatMessage) -> some View {
        HStack(alignment: .bottom, spacing: 8) {
            if msg.sender == .ai {
                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundStyle(Color(red: 1.0, green: 0.3, blue: 0.3))
                    .frame(width: 20)
                Text(msg.text + (msg.isStreaming ? "▋" : ""))
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer(minLength: 40)
            } else {
                Spacer(minLength: 40)
                Text(msg.text)
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color(red: 1.0, green: 0.3, blue: 0.3).opacity(0.85), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring(duration: 0.35), value: msg.id)
    }

    private var typingIndicator: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.caption)
                .foregroundStyle(Color(red: 1.0, green: 0.3, blue: 0.3))
                .frame(width: 20)
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 6, height: 6)
                        .opacity(vm.state == .loading ? 1 : 0.3)
                        .animation(.easeInOut(duration: 0.5).repeatForever().delay(Double(i) * 0.15), value: vm.state)
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            Spacer()
        }
    }

    // MARK: - 入力エリア

    @ViewBuilder
    private var inputArea: some View {
        if vm.state == .done {
            doneState
        } else {
            VStack(spacing: 10) {
                if !vm.choices.isEmpty {
                    choiceButtons
                }
                freeInputRow
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.black)
        }
    }

    private var choiceButtons: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(vm.choices) { choice in
                    Button {
                        vm.selectChoice(choice)
                    } label: {
                        Text(choice.label)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.1), in: Capsule())
                            .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
                    }
                    .disabled(vm.state == .loading)
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private var freeInputRow: some View {
        HStack(spacing: 10) {
            TextField("自由に入力…", text: $vm.freeInputText)
                .font(.subheadline)
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 22))
                .disabled(vm.state == .loading)

            Button {
                vm.submitFreeInput()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(
                        vm.freeInputText.isEmpty || vm.state == .loading
                            ? Color.gray.opacity(0.4)
                            : Color(red: 1.0, green: 0.3, blue: 0.3)
                    )
            }
            .disabled(vm.freeInputText.isEmpty || vm.state == .loading)
        }
    }

    private var doneState: some View {
        VStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(Color(red: 1.0, green: 0.3, blue: 0.3))
            Text("対話完了 — Howカードを生成できます")
                .font(.caption)
                .foregroundStyle(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }

    // MARK: - Helpers

    private func formatTime(_ t: TimeInterval) -> String {
        String(format: "%d:%02d", Int(t) / 60, Int(t) % 60)
    }

    private func tagEmoji(_ tag: HowTag) -> String {
        switch tag {
        case .groove:    return "🎵"
        case .hype:      return "🔥"
        case .chill:     return "❄️"
        case .immersion: return "🎧"
        case .hit:       return "💫"
        case .afterglow: return "✨"
        }
    }
}

// MARK: - Preview

#Preview {
    HowChatView(event: ReactionEvent.mockSamples(trackDuration: 200)[1])
}
