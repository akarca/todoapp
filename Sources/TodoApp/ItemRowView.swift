import SwiftUI
import TodoKit

struct ItemRowView: View {
    let item: TodoItem
    let isSelected: Bool
    let onToggle: () -> Void
    let onMarkDone: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onToggle) {
                Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isDone ? Color.accentColor : Color.secondary)
            }
            .buttonStyle(.plain)

            Text(item.title)
                .strikethrough(item.isDone)
                .opacity(item.isDone ? 0.5 : 1)

            Spacer()

            if isSelected {
                Button("Mark as done", action: onMarkDone)
                    .disabled(item.isDone)
                Button("Delete", role: .destructive, action: onDelete)
            }
        }
        .padding(.vertical, 2)
    }
}
