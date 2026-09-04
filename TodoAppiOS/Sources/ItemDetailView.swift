import SwiftUI
import SwiftData

struct ItemDetailView: View {
    @Bindable var item: TodoItem
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var notes: String

    init(item: TodoItem) {
        self.item = item
        _title = State(initialValue: item.title)
        _notes = State(initialValue: item.notes)
    }

    var body: some View {
        Form {
            Section("Başlık") {
                TextField("Başlık", text: $title)
            }
            Section("Notlar") {
                TextField("Not ekle", text: $notes, axis: .vertical)
                    .lineLimit(4...10)
            }
            Section {
                Button(item.isDone ? "Tamamlanmadı olarak işaretle" : "Tamamlandı olarak işaretle") {
                    markDone()
                }
                Button("Sil", role: .destructive) {
                    deleteItem()
                }
            }
        }
        .navigationTitle("Madde")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button("Kaydet", action: save)
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.bar)
        }
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { item.title = title }
        item.notes = notes
        dismiss()
    }

    private func markDone() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { item.title = title }
        item.notes = notes
        item.isDone.toggle()
        dismiss()
    }

    private func deleteItem() {
        context.delete(item)
        dismiss()
    }
}
