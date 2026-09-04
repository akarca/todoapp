import Foundation
import SwiftData

// Mirrors TodoKit's TodoItem/TodoList, but as SwiftData @Model classes so they
// can sync through CloudKit. SwiftData+CloudKit requires every relationship to
// be optional and every stored property to have a default value.

@Model
public final class TodoItem {
    public var id: UUID = UUID()
    public var title: String = ""
    public var isDone: Bool = false
    public var notes: String = ""
    public var list: TodoList?

    @Attribute(.externalStorage)
    public var photoData: Data?

    public init(id: UUID = UUID(), title: String, isDone: Bool = false, notes: String = "", photoData: Data? = nil) {
        self.id = id
        self.title = title
        self.isDone = isDone
        self.notes = notes
        self.photoData = photoData
    }
}

@Model
public final class TodoList {
    public var id: UUID = UUID()
    public var title: String = ""
    public var colorHex: String?

    @Relationship(deleteRule: .cascade, inverse: \TodoItem.list)
    public var items: [TodoItem]? = []

    public init(id: UUID = UUID(), title: String, colorHex: String? = nil) {
        self.id = id
        self.title = title
        self.colorHex = colorHex
    }

    /// Undone items first (insertion order), done items last.
    public var displayedItems: [TodoItem] {
        let all = items ?? []
        return all.filter { !$0.isDone } + all.filter { $0.isDone }
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
