import SwiftUI
import AppKit
import TodoKit

@main
struct TodoAppMain: App {
    @State private var store = AppStore()
    @State private var showSaveError = false

    init() {
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate()
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
