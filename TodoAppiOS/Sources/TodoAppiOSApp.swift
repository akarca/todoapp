import SwiftUI
import SwiftData

@main
struct TodoAppiOSApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([TodoList.self, TodoItem.self])
        let configuration = ModelConfiguration(
            schema: schema,
            cloudKitDatabase: .private("iCloud.com.serdar.TodoApp")
        )
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ListsView()
        }
        .modelContainer(sharedModelContainer)
    }
}
