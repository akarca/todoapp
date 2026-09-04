import SwiftUI
import AppKit
import SwiftData
import TodoKit

@main
struct TodoAppMain: App {
    private let modelContainer: ModelContainer
    @State private var store: AppStore
    @State private var showSaveError = false

    init() {
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate()

        let schema = Schema([TodoList.self, TodoItem.self])
        let cloudConfiguration = ModelConfiguration(
            schema: schema,
            cloudKitDatabase: .private("iCloud.org.yuix.TodoApp")
        )
        let container: ModelContainer
        if let cloudContainer = try? ModelContainer(for: schema, configurations: [cloudConfiguration]) {
            container = cloudContainer
        } else {
            // Falls back to a local-only store when the process has no iCloud
            // entitlement — e.g. running via `swift run` instead of the signed
            // TodoAppMac.app, which is the only target that carries it.
            let localConfiguration = ModelConfiguration(schema: schema)
            guard let localContainer = try? ModelContainer(for: schema, configurations: [localConfiguration]) else {
                fatalError("Could not create ModelContainer")
            }
            container = localContainer
        }
        modelContainer = container
        _store = State(initialValue: AppStore(modelContext: container.mainContext))
    }

    var body: some Scene {
        Window("Todo", id: "main") {
            ContentView()
                .environment(store)
                .frame(minWidth: 700, minHeight: 450)
                .alert("Could not save", isPresented: $showSaveError) {
                    Button("OK", role: .cancel) { store.saveError = nil }
                } message: {
                    Text(store.saveError ?? "")
                }
                .onChange(of: store.saveError) { _, value in
                    if value != nil { showSaveError = true }
                }
        }
        .modelContainer(modelContainer)
        .commands {
            CommandGroup(replacing: .undoRedo) {
                Button("Undo") { store.undo() }
                    .keyboardShortcut("z", modifiers: .command)
                    .disabled(!store.canUndo)
            }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 900, height: 600)
    }
}
