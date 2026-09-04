import Foundation
import Observation
import SwiftData

@MainActor
@Observable
public final class AppStore {
    public private(set) var lists: [TodoList]
    public var selectedListID: UUID?
    public var saveError: String?

    @ObservationIgnored private let modelContext: ModelContext

    private enum MutationKind {
        case addList, addItem, toggleDone, setNotes, setTitle, deleteItem
    }

    private struct ItemSnapshot {
        let id: UUID
        let title: String
        let isDone: Bool
        let notes: String
    }

    private struct ListSnapshot {
        let id: UUID
        let title: String
        let colorHex: String?
        let items: [ItemSnapshot]
    }

    private static let undoLimit = 50
    private var undoStack: [[ListSnapshot]] = []
    @ObservationIgnored private var lastUndoKind: MutationKind?
    @ObservationIgnored private var lastUndoTargetID: UUID?

    public var canUndo: Bool { !undoStack.isEmpty }

    private func snapshot() -> [ListSnapshot] {
        lists.map { list in
            ListSnapshot(
                id: list.id,
                title: list.title,
                colorHex: list.colorHex,
                items: list.items.map { item in
                    ItemSnapshot(id: item.id, title: item.title, isDone: item.isDone, notes: item.notes)
                }
            )
        }
    }

    private func pushUndo(kind: MutationKind, targetID: UUID) {
        if kind == .setTitle || kind == .setNotes,
           lastUndoKind == kind, lastUndoTargetID == targetID {
            return
        }
        undoStack.append(snapshot())
        if undoStack.count > Self.undoLimit {
            undoStack.removeFirst(undoStack.count - Self.undoLimit)
        }
        lastUndoKind = kind
        lastUndoTargetID = targetID
    }

    public func undo() {
        guard let previous = undoStack.popLast() else { return }
        restore(previous)
        lastUndoKind = nil
        lastUndoTargetID = nil
        if let selected = selectedListID, !lists.contains(where: { $0.id == selected }) {
            selectedListID = lists.first?.id
        }
        persist()
    }

    private func restore(_ snapshot: [ListSnapshot]) {
        var existingLists = Dictionary(uniqueKeysWithValues: lists.map { ($0.id, $0) })
        var rebuilt: [TodoList] = []
        for listSnap in snapshot {
            let list: TodoList
            if let existing = existingLists.removeValue(forKey: listSnap.id) {
                list = existing
                list.title = listSnap.title
                list.colorHex = listSnap.colorHex
            } else {
                list = TodoList(id: listSnap.id, title: listSnap.title, colorHex: listSnap.colorHex)
                modelContext.insert(list)
            }
            restoreItems(listSnap.items, into: list)
            rebuilt.append(list)
        }
        for leftover in existingLists.values {
            modelContext.delete(leftover)
        }
        lists = rebuilt
    }

    private func restoreItems(_ snapshot: [ItemSnapshot], into list: TodoList) {
        var existingItems = Dictionary(uniqueKeysWithValues: list.items.map { ($0.id, $0) })
        var rebuilt: [TodoItem] = []
        for itemSnap in snapshot {
            let item: TodoItem
            if let existing = existingItems.removeValue(forKey: itemSnap.id) {
                item = existing
                item.title = itemSnap.title
                item.isDone = itemSnap.isDone
                item.notes = itemSnap.notes
            } else {
                item = TodoItem(id: itemSnap.id, title: itemSnap.title, isDone: itemSnap.isDone, notes: itemSnap.notes)
                item.list = list
                modelContext.insert(item)
            }
            rebuilt.append(item)
        }
        for leftover in existingItems.values {
            modelContext.delete(leftover)
        }
        list.items = rebuilt
    }

    public init(modelContext: ModelContext, legacyImportURL: URL? = LegacyJSONImport.defaultLegacyFileURL) {
        self.modelContext = modelContext
        if let legacyImportURL {
            LegacyJSONImport.importIfNeeded(from: legacyImportURL, into: modelContext)
        }

        let descriptor = FetchDescriptor<TodoList>()
        self.lists = (try? modelContext.fetch(descriptor)) ?? []

        var filled = false
        for list in lists where list.colorHex == nil {
            list.colorHex = PastelPalette.uniqueRandomHex(excluding: Set(lists.compactMap(\.colorHex)))
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
        modelContext.insert(list)
        lists.append(list)
        selectedListID = list.id
        persist()
    }

    public func addItem(listID: UUID, title: String) {
        guard let trimmed = Self.valid(title) else { return }
        guard let list = lists.first(where: { $0.id == listID }) else { return }
        let item = TodoItem(title: trimmed)
        pushUndo(kind: .addItem, targetID: item.id)
        item.list = list
        list.items.append(item)
        modelContext.insert(item)
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
        guard let list = lists.first(where: { $0.id == listID }),
              let item = list.items.first(where: { $0.id == itemID })
        else { return }
        pushUndo(kind: .deleteItem, targetID: itemID)
        list.items.removeAll { $0.id == itemID }
        modelContext.delete(item)
        persist()
    }

    private func updateItem(
        _ kind: MutationKind, _ listID: UUID, _ itemID: UUID,
        _ transform: (TodoItem) -> Void
    ) {
        guard let list = lists.first(where: { $0.id == listID }),
              let item = list.items.first(where: { $0.id == itemID })
        else { return }
        pushUndo(kind: kind, targetID: itemID)
        transform(item)
        persist()
    }

    private static func valid(_ title: String) -> String? {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func persist() {
        do {
            try modelContext.save()
            saveError = nil
        } catch {
            saveError = error.localizedDescription
        }
    }
}
