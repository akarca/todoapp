import Foundation

public struct TodoItem: Identifiable, Codable, Equatable {
    public var id: UUID
    public var title: String
    public var isDone: Bool

    public init(id: UUID = UUID(), title: String, isDone: Bool = false) {
        self.id = id
        self.title = title
        self.isDone = isDone
    }
}

public struct TodoList: Identifiable, Codable, Equatable {
    public var id: UUID
    public var title: String
    public var items: [TodoItem]

    public init(id: UUID = UUID(), title: String, items: [TodoItem] = []) {
        self.id = id
        self.title = title
        self.items = items
    }

    /// Undone items first (insertion order), done items last (stable).
    public var displayedItems: [TodoItem] {
        items.filter { !$0.isDone } + items.filter { $0.isDone }
    }
}
