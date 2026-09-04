import SwiftUI
import JustTodoKit

struct ContentView: View {
    @State private var sidebarCollapsed = false

    var body: some View {
        HSplitView {
            SidebarView(collapsed: $sidebarCollapsed)
                .frame(
                    minWidth: sidebarCollapsed ? 72 : 200,
                    idealWidth: sidebarCollapsed ? 72 : 220,
                    maxWidth: sidebarCollapsed ? 72 : 300
                )
            DetailView()
                .frame(minWidth: 480, maxWidth: .infinity, maxHeight: .infinity)
        }
        .animation(.default, value: sidebarCollapsed)
    }
}
