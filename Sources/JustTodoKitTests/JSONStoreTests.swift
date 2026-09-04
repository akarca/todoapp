import XCTest
@testable import JustTodoKit

final class JSONStoreTests: XCTestCase {
    private func tempFileURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent("data.json")
    }

    func testLoadReturnsEmptyWhenFileMissing() {
        XCTAssertTrue(JSONStore(fileURL: tempFileURL()).load().isEmpty)
    }

    func testSaveLoadRoundTrip() throws {
        let store = JSONStore(fileURL: tempFileURL())
        let lists = [TodoList(title: "Work", items: [
            TodoItem(title: "Buy milk"),
            TodoItem(title: "Ship it", isDone: true),
        ])]
        try store.save(lists)
        XCTAssertEqual(store.load(), lists)
    }

    func testLoadReturnsEmptyForCorruptFile() throws {
        let url = tempFileURL()
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("not json".utf8).write(to: url)
        XCTAssertTrue(JSONStore(fileURL: url).load().isEmpty)
    }
}
