import Foundation
import Observation

@MainActor
@Observable
public final class AppStore {
    public private(set) var lists: [TodoList]
    public var selectedListID: UUID?
    public var saveError: String?

    @ObservationIgnored private let store: JSONStore

    public init(store: JSONStore = .defaultStore) {
        self.store = store
        self.lists = store.load()
        self.selectedListID = lists.first?.id
    }

    public var selectedList: TodoList? {
        lists.first { $0.id == selectedListID }
    }

    public func addList(title: String) {
        guard let trimmed = Self.valid(title) else { return }
        let list = TodoList(title: trimmed)
        lists.append(list)
        selectedListID = list.id
        persist()
    }

    public func addItem(listID: UUID, title: String) {
        guard let trimmed = Self.valid(title) else { return }
        guard let idx = lists.firstIndex(where: { $0.id == listID }) else { return }
        lists[idx].items.append(TodoItem(title: trimmed))
        persist()
    }

    public func toggleDone(listID: UUID, itemID: UUID) {
        updateItem(listID, itemID) { $0.isDone.toggle() }
    }

    public func markDone(listID: UUID, itemID: UUID) {
        updateItem(listID, itemID) { $0.isDone = true }
    }

    public func deleteItem(listID: UUID, itemID: UUID) {
        guard let idx = lists.firstIndex(where: { $0.id == listID }) else { return }
        lists[idx].items.removeAll { $0.id == itemID }
        persist()
    }

    private func updateItem(_ listID: UUID, _ itemID: UUID, _ transform: (inout TodoItem) -> Void) {
        guard let listIdx = lists.firstIndex(where: { $0.id == listID }),
              let itemIdx = lists[listIdx].items.firstIndex(where: { $0.id == itemID })
        else { return }
        transform(&lists[listIdx].items[itemIdx])
        persist()
    }

    private static func valid(_ title: String) -> String? {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func persist() {
        do {
            try store.save(lists)
            saveError = nil
        } catch {
            saveError = error.localizedDescription
        }
    }
}
