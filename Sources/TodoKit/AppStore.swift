import Foundation
import Observation

@MainActor
@Observable
public final class AppStore {
    public private(set) var lists: [TodoList]
    public var selectedListID: UUID?
    public var saveError: String?

    @ObservationIgnored private let store: JSONStore

    private enum MutationKind {
        case addList, addItem, toggleDone, setNotes, setTitle, deleteItem
    }

    private static let undoLimit = 50
    private var undoStack: [[TodoList]] = []
    @ObservationIgnored private var lastUndoKind: MutationKind?
    @ObservationIgnored private var lastUndoTargetID: UUID?

    public var canUndo: Bool { !undoStack.isEmpty }

    private func pushUndo(kind: MutationKind, targetID: UUID) {
        if kind == .setTitle || kind == .setNotes,
           lastUndoKind == kind, lastUndoTargetID == targetID {
            return
        }
        undoStack.append(lists)
        if undoStack.count > Self.undoLimit {
            undoStack.removeFirst(undoStack.count - Self.undoLimit)
        }
        lastUndoKind = kind
        lastUndoTargetID = targetID
    }

    public func undo() {
        guard let previous = undoStack.popLast() else { return }
        lists = previous
        lastUndoKind = nil
        lastUndoTargetID = nil
        if let selected = selectedListID, !lists.contains(where: { $0.id == selected }) {
            selectedListID = lists.first?.id
        }
        persist()
    }

    public init(store: JSONStore = .defaultStore) {
        self.store = store
        self.lists = store.load()
        var filled = false
        for idx in lists.indices where lists[idx].colorHex == nil {
            lists[idx].colorHex = PastelPalette.uniqueRandomHex(excluding: Set(lists.compactMap(\.colorHex)))
            filled = true
        }
        self.selectedListID = lists.first?.id
        if filled { persist() }
    }

    public var selectedList: TodoList? {
        lists.first { $0.id == selectedListID }
    }

    public func addList(title: String) {
        guard let trimmed = Self.valid(title) else { return }
        let list = TodoList(
            title: trimmed,
            colorHex: PastelPalette.uniqueRandomHex(excluding: Set(lists.compactMap(\.colorHex)))
        )
        pushUndo(kind: .addList, targetID: list.id)
        lists.append(list)
        selectedListID = list.id
        persist()
    }

    public func addItem(listID: UUID, title: String) {
        guard let trimmed = Self.valid(title) else { return }
        guard let idx = lists.firstIndex(where: { $0.id == listID }) else { return }
        let item = TodoItem(title: trimmed)
        pushUndo(kind: .addItem, targetID: item.id)
        lists[idx].items.append(item)
        persist()
    }

    public func toggleDone(listID: UUID, itemID: UUID) {
        updateItem(.toggleDone, listID, itemID) { $0.isDone.toggle() }
    }

    public func setNotes(listID: UUID, itemID: UUID, notes: String) {
        updateItem(.setNotes, listID, itemID) { $0.notes = notes }
    }

    public func setTitle(listID: UUID, itemID: UUID, title: String) {
        guard title.trimmingCharacters(in: .whitespacesAndNewlines) != "" else { return }
        updateItem(.setTitle, listID, itemID) { $0.title = title }
    }

    public func deleteItem(listID: UUID, itemID: UUID) {
        guard let idx = lists.firstIndex(where: { $0.id == listID }),
              lists[idx].items.contains(where: { $0.id == itemID })
        else { return }
        pushUndo(kind: .deleteItem, targetID: itemID)
        lists[idx].items.removeAll { $0.id == itemID }
        persist()
    }

    private func updateItem(
        _ kind: MutationKind, _ listID: UUID, _ itemID: UUID,
        _ transform: (inout TodoItem) -> Void
    ) {
        guard let listIdx = lists.firstIndex(where: { $0.id == listID }),
              let itemIdx = lists[listIdx].items.firstIndex(where: { $0.id == itemID })
        else { return }
        pushUndo(kind: kind, targetID: itemID)
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
