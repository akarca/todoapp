import Foundation
import SwiftData

@Model
public final class TodoItem {
    public var id: UUID = UUID()
    public var title: String = ""
    public var isDone: Bool = false
    public var notes: String = ""
    public var list: TodoList?

    // SwiftData/CloudKit to-many relationships don't preserve assignment order,
    // so `TodoList.items` stamps this on every write and sorts by it on every read.
    var order: Int = 0

    public init(id: UUID = UUID(), title: String, isDone: Bool = false, notes: String = "") {
        self.id = id
        self.title = title
        self.isDone = isDone
        self.notes = notes
    }
}

@Model
public final class TodoList {
    public var id: UUID = UUID()
    public var title: String = ""
    public var colorHex: String?

    // CloudKit requires to-many relationships to be optional; `items` below hides
    // that behind the non-optional, order-preserving array API the rest of the app expects.
    @Relationship(deleteRule: .cascade, inverse: \TodoItem.list)
    private var itemsStorage: [TodoItem]? = []

    public var items: [TodoItem] {
        get { (itemsStorage ?? []).sorted { $0.order < $1.order } }
        set {
            for (index, item) in newValue.enumerated() { item.order = index }
            itemsStorage = newValue
        }
    }

    public init(id: UUID = UUID(), title: String, items: [TodoItem] = [], colorHex: String? = nil) {
        self.id = id
        self.title = title
        self.colorHex = colorHex
        for item in items { item.list = self }
        self.items = items
    }

    /// Undone items first (insertion order), done items last (stable).
    public var displayedItems: [TodoItem] {
        items.filter { !$0.isDone } + items.filter { $0.isDone }
    }

    /// Number of items not yet done.
    public var pendingCount: Int {
        items.filter { !$0.isDone }.count
    }
}

public enum PastelPalette {
    public static let colors: [String] = [
        "#EF9A9A", "#E57373", "#F48FB1", "#F06292", "#CE93D8",
        "#BA68C8", "#B39DDB", "#9FA8DA", "#90CAF9", "#64B5F6",
        "#81D4FA", "#4DD0E1", "#80DEEA", "#80CBC4", "#4DB6AC",
        "#A5D6A7", "#81C784", "#C5E1A5", "#DCE775", "#FFF176",
        "#FFE082", "#FFCC80", "#FFA726", "#FFAB91", "#F8BBD0",
        "#E1BEE7", "#BBDEFB", "#B2DFDB", "#C8E6C9", "#FFE0B2",
    ]

    public static func uniqueRandomHex(excluding used: Set<String> = []) -> String {
        let available = colors.filter { !used.contains($0) }
        let pool = available.isEmpty ? colors : available
        return pool.randomElement() ?? colors[0]
    }
}
