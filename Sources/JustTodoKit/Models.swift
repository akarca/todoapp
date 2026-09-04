import Foundation

public struct TodoItem: Identifiable, Codable, Equatable {
    public var id: UUID
    public var title: String
    public var isDone: Bool
    public var notes: String

    public init(id: UUID = UUID(), title: String, isDone: Bool = false, notes: String = "") {
        self.id = id
        self.title = title
        self.isDone = isDone
        self.notes = notes
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, isDone, notes
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        isDone = try container.decodeIfPresent(Bool.self, forKey: .isDone) ?? false
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
    }
}

public struct TodoList: Identifiable, Codable, Equatable {
    public var id: UUID
    public var title: String
    public var items: [TodoItem]
    public var colorHex: String?

    public init(id: UUID = UUID(), title: String, items: [TodoItem] = [], colorHex: String? = nil) {
        self.id = id
        self.title = title
        self.items = items
        self.colorHex = colorHex
    }

    /// Undone items first (insertion order), done items last (stable).
    public var displayedItems: [TodoItem] {
        items.filter { !$0.isDone } + items.filter { $0.isDone }
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
