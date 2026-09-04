import SwiftUI
import TodoKit

struct SidebarView: View {
    @Environment(AppStore.self) private var store
    @State private var newTitle = ""

    var body: some View {
        @Bindable var store = store
        VStack(alignment: .leading, spacing: 0) {
            TextField("New List", text: $newTitle)
                .textFieldStyle(.roundedBorder)
                .padding(10)
                .onSubmit {
                    store.addList(title: newTitle)
                    newTitle = ""
                }
            Divider()
            List(selection: $store.selectedListID) {
                ForEach(store.lists) { list in
                    Text(list.title)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .tag(Optional(list.id))
                }
            }
            .listStyle(.sidebar)
        }
    }
}
