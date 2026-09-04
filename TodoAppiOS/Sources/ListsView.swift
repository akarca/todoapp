import SwiftUI
import SwiftData

struct ListsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \TodoList.title) private var lists: [TodoList]
    @State private var newListTitle = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(lists) { list in
                    NavigationLink(value: list) {
                        HStack {
                            Circle()
                                .fill(Color(hex: list.colorHex ?? "#CCCCCC"))
                                .frame(width: 10, height: 10)
                            Text(list.title)
                            Spacer()
                            let remaining = (list.items ?? []).filter { !$0.isDone }.count
                            if remaining > 0 {
                                Text("\(remaining)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .onDelete(perform: deleteLists)
            }
            .navigationTitle("Listelerim")
            .navigationDestination(for: TodoList.self) { list in
                ListDetailView(list: list)
            }
            .safeAreaInset(edge: .bottom) {
                HStack {
                    TextField("Yeni liste", text: $newListTitle)
                        .textFieldStyle(.roundedBorder)
                    Button("Ekle", action: addList)
                        .disabled(newListTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
                .background(.bar)
            }
        }
    }

    private func addList() {
        let trimmed = newListTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let usedColors = Set(lists.compactMap(\.colorHex))
        let list = TodoList(title: trimmed, colorHex: PastelPalette.uniqueRandomHex(excluding: usedColors))
        context.insert(list)
        newListTitle = ""
    }

    private func deleteLists(at offsets: IndexSet) {
        for index in offsets { context.delete(lists[index]) }
    }
}
