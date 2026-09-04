import XCTest
import SwiftData
@testable import TodoKit

@MainActor
final class LegacyJSONImportTests: XCTestCase {
    private func makeContext() -> ModelContext {
        let schema = Schema([TodoList.self, TodoItem.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        let container = try! ModelContainer(for: schema, configurations: [configuration])
        return ModelContext(container)
    }

    private func tempFileURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
            .appendingPathComponent("data.json")
    }

    private func write(_ json: String, to url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(json.utf8).write(to: url)
    }

    func testImportsListsAndItemsFromLegacyJSON() throws {
        let listID = UUID()
        let itemID = UUID()
        let url = tempFileURL()
        try write("""
        [{"id":"\(listID.uuidString)","title":"Work","colorHex":"#EF9A9A","items":[
            {"id":"\(itemID.uuidString)","title":"Buy milk","isDone":true,"notes":"2%"}
        ]}]
        """, to: url)

        let context = makeContext()
        LegacyJSONImport.importIfNeeded(from: url, into: context)

        let lists = try context.fetch(FetchDescriptor<TodoList>())
        XCTAssertEqual(lists.count, 1)
        XCTAssertEqual(lists[0].id, listID)
        XCTAssertEqual(lists[0].title, "Work")
        XCTAssertEqual(lists[0].colorHex, "#EF9A9A")
        XCTAssertEqual(lists[0].items.count, 1)
        XCTAssertEqual(lists[0].items[0].id, itemID)
        XCTAssertTrue(lists[0].items[0].isDone)
        XCTAssertEqual(lists[0].items[0].notes, "2%")
    }

    func testMissingNotesAndIsDoneDefaultToEmptyAndFalse() throws {
        let url = tempFileURL()
        try write("""
        [{"id":"\(UUID().uuidString)","title":"Old","items":[
            {"id":"\(UUID().uuidString)","title":"Legacy"}
        ],"colorHex":null}]
        """, to: url)

        let context = makeContext()
        LegacyJSONImport.importIfNeeded(from: url, into: context)

        let lists = try context.fetch(FetchDescriptor<TodoList>())
        XCTAssertEqual(lists[0].items[0].notes, "")
        XCTAssertFalse(lists[0].items[0].isDone)
    }

    func testNoOpWhenStoreAlreadyHasData() throws {
        let context = makeContext()
        context.insert(TodoList(title: "Existing"))

        let url = tempFileURL()
        try write("""
        [{"id":"\(UUID().uuidString)","title":"Imported","items":[],"colorHex":null}]
        """, to: url)

        LegacyJSONImport.importIfNeeded(from: url, into: context)

        let lists = try context.fetch(FetchDescriptor<TodoList>())
        XCTAssertEqual(lists.count, 1)
        XCTAssertEqual(lists[0].title, "Existing")
    }

    func testNoOpWhenFileMissing() throws {
        let context = makeContext()
        LegacyJSONImport.importIfNeeded(from: tempFileURL(), into: context)
        let lists = try context.fetch(FetchDescriptor<TodoList>())
        XCTAssertTrue(lists.isEmpty)
    }
}
