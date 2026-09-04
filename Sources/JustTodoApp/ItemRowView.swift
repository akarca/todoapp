import SwiftUI
import JustTodoKit

struct ItemRowView: View {
    let item: TodoItem
    let isSelected: Bool
    let onToggle: () -> Void
    let onDelete: () -> Void
    let onNotesChange: (String) -> Void
    let onTitleChange: (String) -> Void
    let onDeselect: () -> Void

    @FocusState private var focusedField: Field?

    private enum Field {
        case title, notes
    }

    private var deleteEnabled: Bool { isSelected }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Button(action: onToggle) {
                    Image(systemName: item.isDone ? "checkmark.square.fill" : "square")
                        .foregroundStyle(item.isDone ? Color.accentColor : Color.secondary)
                }
                .buttonStyle(.plain)

                TextField("Item", text: Binding(get: { item.title }, set: onTitleChange))
                    .textFieldStyle(.plain)
                    .font(.system(size: 15, weight: .medium))
                    .strikethrough(item.isDone)
                    .opacity(item.isDone ? 0.5 : 1)
                    .focused($focusedField, equals: .title)

                Spacer()

                Button(role: .destructive, action: onDelete) {
                    actionLabel("Delete", background: Color(red: 0xDC / 255, green: 0x26 / 255, blue: 0x26 / 255))
                }
                .buttonStyle(.plain)
                .disabled(!deleteEnabled)
                .opacity(deleteEnabled ? 1 : (isSelected ? 0.4 : 0))
            }

            if isSelected {
                notesEditor
            }
        }
        .padding(.vertical, 2)
        .onChange(of: focusedField) { _, field in
            if field == nil {
                DispatchQueue.main.async {
                    onDeselect()
                }
            }
        }
        .onChange(of: isSelected) { _, selected in
            if selected {
                DispatchQueue.main.async { focusedField = .title }
            }
        }
    }

    private func actionLabel(_ title: String, background: Color) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(background, in: RoundedRectangle(cornerRadius: 6))
    }

    private var notesEditor: some View {
        TextEditor(text: Binding(get: { item.notes }, set: onNotesChange))
            .font(.system(size: 13))
            .frame(height: 100)
            .focused($focusedField, equals: .notes)
            .scrollContentBackground(.hidden)
            .padding(6)
            .background(Color(nsColor: .textBackgroundColor))
            .overlay {
                if item.notes.isEmpty {
                    Text("Notes")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .padding(8)
                        .allowsHitTesting(false)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
            }
    }
}
