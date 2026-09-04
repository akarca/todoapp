import XCTest
@testable import TodoKit

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

    func testMarkDoneThenUntoggleKeepsStoredPosition() {
        let (store, _) = makeStore()
        store.addList(title: "A")
        let listID = store.lists[0].id
        store.addItem(listID: listID, title: "One")
        store.addItem(listID: listID, title: "Two")
        store.addItem(listID: listID, title: "Three")
        let ids = store.lists[0].items.map(\.id)

        store.markDone(listID: listID, itemID: ids[0])
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
}
