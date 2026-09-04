import XCTest
@testable import JustTodoKit

@MainActor
final class AppStoreTests: XCTestCase {
    private func makeStore() -> (AppStore, URL) {
        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent("data.json")
        return (AppStore(store: JSONStore(fileURL: fileURL)), fileURL)
    }

    func testAddListTrimsTitleAndSelectsIt() {
        let (store, _) = makeStore()
        store.addList(title: "  Work  ")
        XCTAssertEqual(store.lists.count, 1)
        XCTAssertEqual(store.lists[0].title, "Work")
        XCTAssertEqual(store.selectedListID, store.lists[0].id)
    }

    func testBlankTitlesRejected() {
        let (store, _) = makeStore()
        store.addList(title: "   ")
        XCTAssertTrue(store.lists.isEmpty)

        store.addList(title: "A")
        let listID = store.lists[0].id
        store.addItem(listID: listID, title: " \n ")
        XCTAssertTrue(store.lists[0].items.isEmpty)
    }

    func testToggleDoneThenUntoggleKeepsStoredPosition() {
        let (store, _) = makeStore()
        store.addList(title: "A")
        let listID = store.lists[0].id
        store.addItem(listID: listID, title: "One")
        store.addItem(listID: listID, title: "Two")
        store.addItem(listID: listID, title: "Three")
        let ids = store.lists[0].items.map(\.id)

        store.toggleDone(listID: listID, itemID: ids[0])
        XCTAssertEqual(store.lists[0].displayedItems.map(\.title), ["Two", "Three", "One"])

        store.toggleDone(listID: listID, itemID: ids[0])
        XCTAssertEqual(store.lists[0].items.map(\.id), ids)
    }

    func testToggleAndDelete() {
        let (store, _) = makeStore()
        store.addList(title: "A")
        let listID = store.lists[0].id
        store.addItem(listID: listID, title: "X")
        let itemID = store.lists[0].items[0].id

        store.toggleDone(listID: listID, itemID: itemID)
        XCTAssertTrue(store.lists[0].items[0].isDone)

        store.deleteItem(listID: listID, itemID: itemID)
        XCTAssertTrue(store.lists[0].items.isEmpty)
    }

    func testMutationsArePersistedAndReopenable() {
        let (store, fileURL) = makeStore()
        store.addList(title: "Work")
        store.addItem(listID: store.lists[0].id, title: "Buy milk")

        let reopened = AppStore(store: JSONStore(fileURL: fileURL))
        XCTAssertEqual(reopened.lists, store.lists)
    }

    func testListColorsUniqueForFirst30AndFromPalette() {
        let (store, _) = makeStore()
        for index in 0..<30 {
            store.addList(title: "List \(index)")
        }
        let colors = store.lists.map(\.colorHex)
        XCTAssertEqual(Set(colors).count, 30)
        for color in colors {
            XCTAssertNotNil(color)
            XCTAssertTrue(PastelPalette.colors.contains(color!))
        }
    }

    func testSetNotesPersists() {
        let (store, fileURL) = makeStore()
        store.addList(title: "A")
        store.addItem(listID: store.lists[0].id, title: "Item")
        let listID = store.lists[0].id
        let itemID = store.lists[0].items[0].id

        store.setNotes(listID: listID, itemID: itemID, notes: "long note")
        XCTAssertEqual(store.lists[0].items[0].notes, "long note")

        let reopened = AppStore(store: JSONStore(fileURL: fileURL))
        XCTAssertEqual(reopened.lists[0].items[0].notes, "long note")
    }

    func testSetTitleUpdatesAndRejectsBlank() {
        let (store, _) = makeStore()
        store.addList(title: "A")
        store.addItem(listID: store.lists[0].id, title: "Item")
        let listID = store.lists[0].id
        let itemID = store.lists[0].items[0].id

        store.setTitle(listID: listID, itemID: itemID, title: "Renamed")
        XCTAssertEqual(store.lists[0].items[0].title, "Renamed")

        store.setTitle(listID: listID, itemID: itemID, title: "   ")
        XCTAssertEqual(store.lists[0].items[0].title, "Renamed")
    }

    func testItemsWithoutNotesDecodeWithEmptyNotes() throws {
        let json = """
        [{"id":"\(UUID().uuidString)","title":"Old","items":[{"id":"\(UUID().uuidString)","title":"Legacy","isDone":false}],"colorHex":null}]
        """
        let lists = try JSONDecoder().decode([TodoList].self, from: Data(json.utf8))
        XCTAssertEqual(lists.count, 1)
        XCTAssertEqual(lists[0].items[0].notes, "")
    }

    // MARK: - Undo

    func testCanUndoFalseInitiallyAndTrueAfterMutation() {
        let (store, _) = makeStore()
        XCTAssertFalse(store.canUndo)
        store.addList(title: "A")
        XCTAssertTrue(store.canUndo)
    }

    func testUndoOnEmptyStackIsNoOp() {
        let (store, _) = makeStore()
        store.undo()
        XCTAssertTrue(store.lists.isEmpty)
        XCTAssertFalse(store.canUndo)
    }

    func testUndoRestoresStateBeforeAddItem() {
        let (store, _) = makeStore()
        store.addList(title: "A")
        let listID = store.lists[0].id
        store.addItem(listID: listID, title: "Buy milk")
        store.undo()
        XCTAssertTrue(store.lists[0].items.isEmpty)
    }

    func testUndoRestoresStateBeforeAddList() {
        let (store, _) = makeStore()
        store.addList(title: "A")
        store.addList(title: "B")
        store.undo()
        XCTAssertEqual(store.lists.count, 1)
        XCTAssertEqual(store.lists[0].title, "A")
    }

    func testUndoRestoresToggleDoneState() {
        let (store, _) = makeStore()
        store.addList(title: "A")
        let listID = store.lists[0].id
        store.addItem(listID: listID, title: "Task")
        let itemID = store.lists[0].items[0].id
        store.toggleDone(listID: listID, itemID: itemID)
        store.undo()
        XCTAssertFalse(store.lists[0].items[0].isDone)
    }

    func testUndoRestoresDeletedItem() {
        let (store, _) = makeStore()
        store.addList(title: "A")
        let listID = store.lists[0].id
        store.addItem(listID: listID, title: "Task")
        let itemID = store.lists[0].items[0].id
        store.deleteItem(listID: listID, itemID: itemID)
        store.undo()
        XCTAssertEqual(store.lists[0].items.map(\.title), ["Task"])
        XCTAssertEqual(store.lists[0].items[0].id, itemID)
    }

    func testUndoIsPersisted() {
        let (store, fileURL) = makeStore()
        store.addList(title: "Work")
        store.addItem(listID: store.lists[0].id, title: "Buy milk")
        store.undo()
        let reopened = AppStore(store: JSONStore(fileURL: fileURL))
        XCTAssertEqual(reopened.lists[0].items.count, 0)
    }

    func testUndoAddListResetsSelectionToFirstRemaining() {
        let (store, _) = makeStore()
        store.addList(title: "A")
        store.addList(title: "B")
        XCTAssertEqual(store.selectedListID, store.lists[1].id)
        store.undo()
        XCTAssertEqual(store.selectedListID, store.lists[0].id)
        store.undo()
        XCTAssertTrue(store.lists.isEmpty)
        XCTAssertNil(store.selectedListID)
    }

    func testRapidSetTitleCollapsesIntoSingleUndoStep() {
        let (store, _) = makeStore()
        store.addList(title: "A")
        let listID = store.lists[0].id
        store.addItem(listID: listID, title: "Original")
        let itemID = store.lists[0].items[0].id

        store.setTitle(listID: listID, itemID: itemID, title: "O")
        store.setTitle(listID: listID, itemID: itemID, title: "Ok")
        store.setTitle(listID: listID, itemID: itemID, title: "OK")
        store.undo()
        XCTAssertEqual(store.lists[0].items[0].title, "Original")
    }

    func testRapidSetNotesCollapsesIntoSingleUndoStep() {
        let (store, _) = makeStore()
        store.addList(title: "A")
        let listID = store.lists[0].id
        store.addItem(listID: listID, title: "Item")
        let itemID = store.lists[0].items[0].id

        store.setNotes(listID: listID, itemID: itemID, notes: "n")
        store.setNotes(listID: listID, itemID: itemID, notes: "no")
        store.setNotes(listID: listID, itemID: itemID, notes: "note")
        store.undo()
        XCTAssertEqual(store.lists[0].items[0].notes, "")
    }

    func testEditsOnDifferentItemsAreSeparateUndoSteps() {
        let (store, _) = makeStore()
        store.addList(title: "A")
        let listID = store.lists[0].id
        store.addItem(listID: listID, title: "One")
        store.addItem(listID: listID, title: "Two")
        let firstID = store.lists[0].items[0].id
        let secondID = store.lists[0].items[1].id

        store.setTitle(listID: listID, itemID: firstID, title: "Renamed one")
        store.setTitle(listID: listID, itemID: secondID, title: "Renamed two")
        store.undo()
        XCTAssertEqual(store.lists[0].items[1].title, "Two")
        store.undo()
        XCTAssertEqual(store.lists[0].items[0].title, "One")
    }

    func testUndoBreaksCoalescingRun() {
        let (store, _) = makeStore()
        store.addList(title: "A")
        let listID = store.lists[0].id
        store.addItem(listID: listID, title: "Original")
        let itemID = store.lists[0].items[0].id

        store.setTitle(listID: listID, itemID: itemID, title: "X")
        store.undo()
        XCTAssertEqual(store.lists[0].items[0].title, "Original")

        store.setTitle(listID: listID, itemID: itemID, title: "Y")
        store.undo()
        XCTAssertEqual(store.lists[0].items[0].title, "Original")
    }

    func testUndoStackIsCappedAt50() {
        let (store, _) = makeStore()
        store.addList(title: "A") // pushes snapshot 1 (empty list)
        let listID = store.lists[0].id
        for index in 0..<60 { store.addItem(listID: listID, title: "Item \(index)") }
        // 61 snapshots pushed; cap keeps the newest 50 (oldest = list + 10 items).
        var undos = 0
        while store.canUndo { store.undo(); undos += 1 }
        XCTAssertEqual(undos, 50)
        XCTAssertEqual(store.lists[0].items.count, 10)
    }

    func testRejectedMutationsPushNoSnapshot() {
        let (store, _) = makeStore()
        store.addList(title: "A")
        let listID = store.lists[0].id
        store.addItem(listID: listID, title: "Item")
        // Exactly two snapshots exist: before addList and before addItem.
        store.setTitle(listID: listID, itemID: store.lists[0].items[0].id, title: "   ")
        store.addItem(listID: listID, title: " ")
        store.deleteItem(listID: listID, itemID: UUID())
        var undos = 0
        while store.canUndo { store.undo(); undos += 1 }
        XCTAssertEqual(undos, 2)
        XCTAssertTrue(store.lists.isEmpty)
    }
}
