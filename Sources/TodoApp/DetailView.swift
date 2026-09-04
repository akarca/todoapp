import AppKit
import SwiftUI
import TodoKit

struct DetailView: View {
    @Environment(AppStore.self) private var store
    @State private var selectedItemIDs: [UUID: UUID] = [:]
    @State private var newItemTitle = ""
    @FocusState private var newItemFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let list = store.selectedList {
                HStack(spacing: 0) {
                    Text(list.title)
                        .font(.title2.bold())
                        .foregroundStyle(Color(red: 0x00 / 255, green: 0x62 / 255, blue: 0xC1 / 255))
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture {
                    NSApp.keyWindow?.makeFirstResponder(nil)
                    if let listID = store.selectedListID {
                        selectedItemIDs[listID] = nil
                    }
                }
                Divider()
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
            DispatchQueue.main.async { newItemFocused = true }
        }
        .keyboardShortcut("n", modifiers: .command)
        .disabled(store.selectedListID == nil)
        .opacity(0)
        .frame(width: 0, height: 0)
    }

    private var newItemField: some View {
        TextField("New item — Enter to add", text: $newItemTitle)
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
                let isSelected = selectedItemIDs[list.id] == item.id
                ItemRowView(
                    item: item,
                    isSelected: isSelected,
                    onToggle: { store.toggleDone(listID: list.id, itemID: item.id) },
                    onDelete: {
                        store.deleteItem(listID: list.id, itemID: item.id)
                        if selectedItemIDs[list.id] == item.id {
                            selectedItemIDs[list.id] = nil
                        }
                    },
                    onNotesChange: { notes in
                        store.setNotes(listID: list.id, itemID: item.id, notes: notes)
                    },
                    onTitleChange: { title in
                        store.setTitle(listID: list.id, itemID: item.id, title: title)
                    },
                    onDeselect: {
                        if selectedItemIDs[list.id] == item.id {
                            selectedItemIDs[list.id] = nil
                        }
                    }
                )
                .tag(Optional(item.id))
                .listRowSeparator(.hidden)
                .background(SelectionHighlightTuner(isEnabled: false))
            }
            newItemField
                .listRowSeparator(.hidden)
        }
        .listStyle(.inset)
    }
}
