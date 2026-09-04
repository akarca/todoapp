import SwiftUI
import TodoKit

struct ContentView: View {
    var body: some View {
        HSplitView {
            SidebarView()
                .frame(minWidth: 200, idealWidth: 220, maxWidth: 300)
            DetailView()
                .frame(minWidth: 480, maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
