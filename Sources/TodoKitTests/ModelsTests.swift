import XCTest
@testable import TodoKit

final class ModelsTests: XCTestCase {
    func testDisplayedItemsPutDoneLastAndKeepInsertionOrder() {
        let items = [
            TodoItem(title: "A", isDone: false),
            TodoItem(title: "B", isDone: true),
            TodoItem(title: "C", isDone: false),
            TodoItem(title: "D", isDone: true),
        ]
        let list = TodoList(title: "L", items: items)
        XCTAssertEqual(list.displayedItems.map(\.title), ["A", "C", "B", "D"])
        XCTAssertEqual(list.items.map(\.title), ["A", "B", "C", "D"])
    }
}
