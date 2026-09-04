import AppKit
import SwiftUI
import TodoKit

struct SidebarView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.colorScheme) private var colorScheme
    @Binding var collapsed: Bool
    @State private var newTitle = ""
    @State private var addingList = false
    @FocusState private var newTitleFocused: Bool

    var body: some View {
        @Bindable var store = store
        VStack(alignment: .leading, spacing: 0) {
            List(selection: $store.selectedListID) {
                ForEach(store.lists) { list in
                    listRow(list)
                        .tag(Optional(list.id))
                }
                if addingList {
                    newTitleRow
                } else {
                    addButtonRow
                }
            }
            .listStyle(.sidebar)
            .scrollContentBackground(colorScheme == .light ? .hidden : .automatic)
            .safeAreaInset(edge: .top) {
                Color.clear.frame(height: 28)
            }
            Divider()
            bottomBar
        }
        .background {
            if colorScheme == .light {
                Color(red: 0xF9 / 255, green: 0xFA / 255, blue: 0xFB / 255)
            }
        }
        .onChange(of: newTitleFocused) { _, focused in
            if !focused {
                addingList = false
                newTitle = ""
            }
        }
    }

    private func listRow(_ list: TodoList) -> some View {
        ZStack {
            Text(list.title)
                .frame(maxWidth: .infinity, alignment: .leading)
                .opacity(collapsed ? 0 : 1)

            Text(String(list.title.prefix(1)).uppercased())
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color.black.opacity(0.7))
                .frame(width: 42, height: 42)
                .background(swatchColor(for: list).opacity(0.8), in: RoundedRectangle(cornerRadius: 10))
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(collapsedBoxBorderColor, lineWidth: 1.5)
                }
                .overlay {
                    if store.selectedListID == list.id {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(red: 0x00 / 255, green: 0x62 / 255, blue: 0xC1 / 255), lineWidth: 2)
                    }
                }
                .opacity(collapsed ? 1 : 0)
        }
        .frame(maxWidth: .infinity)
        .frame(height: collapsed ? 58 : 30)
        .listRowInsets(EdgeInsets(top: 2, leading: collapsed ? 0 : 10, bottom: 2, trailing: collapsed ? 0 : 10))
        .background(SelectionHighlightTuner(isEnabled: !collapsed, toolTip: collapsed ? list.title : ""))
        .animation(.default, value: collapsed)
    }

    private var addButtonRow: some View {
        ZStack {
            Button(action: startAdding) {
                Image(systemName: "plus")
                    .frame(maxWidth: .infinity)
                    .frame(height: 28)
                    .background {
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color.secondary.opacity(0.5), lineWidth: 1.5)
                    }
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("New List")
            .opacity(collapsed ? 0 : 1)

            Button(action: startAdding) {
                Image(systemName: "plus")
                    .frame(width: 42, height: 42)
                    .background {
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(collapsedBoxBorderColor, lineWidth: 1.5)
                    }
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("New List")
            .opacity(collapsed ? 1 : 0)
        }
        .frame(maxWidth: .infinity)
        .frame(height: collapsed ? 58 : 40)
        .listRowInsets(EdgeInsets(top: 2, leading: collapsed ? 0 : 10, bottom: 2, trailing: collapsed ? 0 : 10))
        .background(SelectionHighlightTuner(isEnabled: !collapsed))
        .animation(.default, value: collapsed)
    }

    private var newTitleRow: some View {
        TextField("List name", text: $newTitle)
            .textFieldStyle(.roundedBorder)
            .focused($newTitleFocused)
            .frame(height: 28)
            .listRowInsets(EdgeInsets(top: 2, leading: 10, bottom: 2, trailing: 10))
            .background(SelectionHighlightTuner(isEnabled: true))
            .onSubmit {
                store.addList(title: newTitle)
                newTitle = ""
                addingList = false
            }
            .onExitCommand {
                newTitle = ""
                addingList = false
            }
    }

    private var bottomBar: some View {
        HStack(spacing: 8) {
            Spacer()
            collapseButton
            if collapsed {
                Spacer()
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
    }

    private func startAdding() {
        let previousSelection = store.selectedListID
        newTitle = ""
        addingList = true
        if collapsed { collapsed = false }
        DispatchQueue.main.async {
            if store.selectedListID == nil {
                store.selectedListID = previousSelection
            }
            newTitleFocused = true
        }
    }

    private var collapseButton: some View {
        Button {
            collapsed.toggle()
        } label: {
            Image(systemName: "sidebar.left")
        }
        .buttonStyle(.plain)
        .help(collapsed ? "Show Sidebar" : "Hide Sidebar")
    }

    private var collapsedBoxBorderColor: Color {
        Color(red: 0xCB / 255, green: 0xE2 / 255, blue: 0xFF / 255)
    }

    private func swatchColor(for list: TodoList) -> Color {
        guard let hex = list.colorHex, let color = Color(hex: hex) else {
            return Color.secondary.opacity(0.25)
        }
        return color
    }
}

extension Color {
    init?(hex: String) {
        var value = hex.trimmingCharacters(in: .whitespaces)
        if value.hasPrefix("#") { value.removeFirst() }
        guard value.count == 6, let raw = UInt64(value, radix: 16) else { return nil }
        self.init(
            red: Double((raw >> 16) & 0xFF) / 255,
            green: Double((raw >> 8) & 0xFF) / 255,
            blue: Double(raw & 0xFF) / 255
        )
    }
}
