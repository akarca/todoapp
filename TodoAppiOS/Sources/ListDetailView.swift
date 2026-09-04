import SwiftUI
import SwiftData

struct ListDetailView: View {
    @Bindable var list: TodoList
    @Environment(\.modelContext) private var context
    @State private var newItemTitle = ""

    var body: some View {
        List {
            ForEach(list.displayedItems) { item in
                NavigationLink(value: item) {
                    HStack {
                        Image(systemName: item.isDone ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(item.isDone ? .green : .secondary)
                        VStack(alignment: .leading) {
                            Text(item.title)
                                .strikethrough(item.isDone)
                                .foregroundStyle(item.isDone ? .secondary : .primary)
                            if !item.notes.isEmpty {
                                Text(item.notes)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
            }
            .onDelete(perform: deleteItems)
        }
        .navigationTitle(list.title)
        .navigationDestination(for: TodoItem.self) { item in
            ItemDetailView(item: item)
        }
        .safeAreaInset(edge: .bottom) {
            HStack {
                TextField("Yeni madde", text: $newItemTitle)
                    .textFieldStyle(.roundedBorder)
                Button("Ekle", action: addItem)
                    .disabled(newItemTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
            .background(.bar)
        }
    }

    private func addItem() {
        let trimmed = newItemTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let item = TodoItem(title: trimmed)
        item.list = list
        context.insert(item)
        newItemTitle = ""
    }

    private func deleteItems(at offsets: IndexSet) {
        let displayed = list.displayedItems
        for index in offsets { context.delete(displayed[index]) }
    }
}
