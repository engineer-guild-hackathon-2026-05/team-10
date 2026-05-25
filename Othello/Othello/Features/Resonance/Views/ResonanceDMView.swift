import SwiftUI

/// 同地点で反応した相手とのリアルタイム DM（FR-RES-06）。Apple ネイティブ調。
struct ResonanceDMView: View {
    let reactor: ResonanceReactor
    @StateObject private var chat: ResonanceChatService
    @State private var input: String = ""
    @FocusState private var focused: Bool

    init(reactor: ResonanceReactor) {
        self.reactor = reactor
        _chat = StateObject(wrappedValue: ResonanceChatService(otherUserId: reactor.userId))
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            messages
            Divider()
            inputBar
        }
        .navigationTitle(reactor.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { chat.start() }
        .onDisappear { chat.stop() }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Text("🔥")
            VStack(alignment: .leading, spacing: 2) {
                Text("\(reactor.spotLabel) で共鳴")
                    .font(.subheadline.weight(.semibold))
                Text(reactor.comment.isEmpty ? "同じ瞬間に反応しました" : reactor.comment)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    private var messages: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(chat.messages) { msg in
                        bubble(msg)
                            .id(msg.id)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
            .onChange(of: chat.messages.count) { _, _ in
                withAnimation { proxy.scrollTo(chat.messages.last?.id, anchor: .bottom) }
            }
        }
    }

    @ViewBuilder
    private func bubble(_ msg: ResonanceMessage) -> some View {
        let isMine = msg.senderId == chat.myUserId
        HStack {
            if isMine { Spacer(minLength: 48) }
            Text(msg.text)
                .font(.subheadline)
                .foregroundStyle(isMine ? .white : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(
                    isMine ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(Color(.secondarySystemBackground)),
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                )
                .opacity(msg.isPending ? 0.6 : 1.0)
            if !isMine { Spacer(minLength: 48) }
        }
        .frame(maxWidth: .infinity, alignment: isMine ? .trailing : .leading)
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("メッセージ", text: $input, axis: .vertical)
                .textFieldStyle(.plain)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(Color(.secondarySystemBackground), in: Capsule())
                .focused($focused)
                .lineLimit(1...4)

            Button {
                chat.send(input)
                input = ""
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.secondary : Color.accentColor)
            }
            .disabled(input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
}
