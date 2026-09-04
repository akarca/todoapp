import Foundation
import SwiftData

/// One-time import of data from the pre-SwiftData version of the app, which stored
/// everything as a plain JSON file (see git history for the old JSONStore). Safe to
/// call on every launch — it's a no-op once the SwiftData store has any lists.
public enum LegacyJSONImport {
    struct LegacyItem: Decodable {
        let id: UUID
        let title: String
        let isDone: Bool?
        let notes: String?
    }

    struct LegacyList: Decodable {
        let id: UUID
        let title: String
        let items: [LegacyItem]
        let colorHex: String?
    }

    public static var defaultLegacyFileURL: URL {
        FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("TodoApp", isDirectory: true)
            .appendingPathComponent("data.json")
    }

    static func importIfNeeded(from fileURL: URL, into context: ModelContext) {
        guard (try? context.fetchCount(FetchDescriptor<TodoList>())) == 0 else { return }
        guard let data = try? Data(contentsOf: fileURL),
              let legacyLists = try? JSONDecoder().decode([LegacyList].self, from: data)
        else { return }

        for legacyList in legacyLists {
            let list = TodoList(id: legacyList.id, title: legacyList.title, colorHex: legacyList.colorHex)
            context.insert(list)
            list.items = legacyList.items.map { legacyItem in
                let item = TodoItem(
                    id: legacyItem.id,
                    title: legacyItem.title,
                    isDone: legacyItem.isDone ?? false,
                    notes: legacyItem.notes ?? ""
                )
                item.list = list
                context.insert(item)
                return item
            }
        }
        try? context.save()
    }
}
