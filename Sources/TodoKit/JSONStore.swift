import Foundation

public struct JSONStore {
    public let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    public static var defaultStore: JSONStore {
        let dir = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("TodoApp", isDirectory: true)
        return JSONStore(fileURL: dir.appendingPathComponent("data.json"))
    }

    /// Returns [] when the file is missing or corrupt (v1 behavior, per spec).
    public func load() -> [TodoList] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        return (try? JSONDecoder().decode([TodoList].self, from: data)) ?? []
    }

    public func save(_ lists: [TodoList]) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(lists).write(to: fileURL, options: .atomic)
    }
}
