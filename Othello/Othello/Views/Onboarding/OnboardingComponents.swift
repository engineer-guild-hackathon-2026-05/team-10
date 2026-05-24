import SwiftUI

func progressIndicator(current: Int, total: Int) -> some View {
    HStack(spacing: 8) {
        ForEach(1...total, id: \.self) { i in
            Capsule()
                .fill(i <= current ? Color.indigo : Color.gray.opacity(0.3))
                .frame(height: 4)
        }
    }
}

func purposeCard(icon: String, title: String, body: String) -> some View {
    HStack(alignment: .top, spacing: 12) {
        Image(systemName: icon)
            .foregroundStyle(Color.indigo)
            .font(.title3)
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
            Text(body)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    .padding(16)
    .background(Color.indigo.opacity(0.08))
    .clipShape(RoundedRectangle(cornerRadius: 12))
}

func authorizedBadge(label: String) -> some View {
    Label(label, systemImage: "checkmark.circle.fill")
        .font(.subheadline)
        .foregroundStyle(.green)
}

func skipButton(label: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        Text(label)
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }
}
