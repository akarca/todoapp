import SwiftUI
import TodoKit

struct DetailView: View {
    @Environment(AppStore.self) private var store
    @State private var selectedItemIDs: [UUID: UUID] = [:]
    @State private var newItemTitle = ""
    @State private var newItemVisible = false
    @FocusState private var newItemFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let list = store.selectedList {
                Text(list.title)
                    .font(.title2.bold())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                Divider()
                if newItemVisible {
                    newItemField
                }
                itemRows(list)
            } else {
                Spacer()
                Text("Create a list to get started")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(newItemShortcut)
    }

    private var newItemShortcut: some View {
        Button("New Item") {
            newItemTitle = ""
            newItemVisible = true
            DispatchQueue.main.async { newItemFocused = true }
        }
        .keyboardShortcut("n", modifiers: .command)
        .disabled(store.selectedListID == nil)
        .opacity(0)
        .frame(width: 0, height: 0)
    }

    private var newItemField: some View {
        TextField("New item — Enter to add, Esc to dismiss", text: $newItemTitle)
            .textFieldStyle(.roundedBorder)
            .focused($newItemFocused)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .onSubmit {
                if let listID = store.selectedListID {
                    store.addItem(listID: listID, title: newItemTitle)
                }
                newItemTitle = ""
            }
            .onExitCommand {
                newItemVisible = false
                newItemTitle = ""
            }
    }

    private var itemSelection: Binding<UUID?> {
        Binding(
            get: { store.selectedListID.flatMap { selectedItemIDs[$0] } },
            set: { newValue in
                if let listID = store.selectedListID {
                    selectedItemIDs[listID] = newValue
                }
            }
        )
    }

    private func itemRows(_ list: TodoList) -> some View {
        List(selection: itemSelection) {
            ForEach(list.displayedItems) { item in
                ItemRowView(
                    item: item,
                    isSelected: selectedItemIDs[list.id] == item.id,
                    onToggle: { store.toggleDone(listID: list.id, itemID: item.id) },
                    onMarkDone: { store.markDone(listID: list.id, itemID: item.id) },
                    onDelete: {
                        store.deleteItem(listID: list.id, itemID: item.id)
                        if selectedItemIDs[list.id] == item.id {
                            selectedItemIDs[list.id] = nil
                        }
                    }
                )
                .tag(Optional(item.id))
            }
        }
        .listStyle(.inset)
    }
}
