import SwiftUI
import SwiftData
import PhotosUI

struct ItemDetailView: View {
    @Bindable var item: TodoItem
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var notes: String
    @State private var photoData: Data?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showingCamera = false

    init(item: TodoItem) {
        self.item = item
        _title = State(initialValue: item.title)
        _notes = State(initialValue: item.notes)
        _photoData = State(initialValue: item.photoData)
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
            Section("Fotoğraf") {
                if let photoData, let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                    Button("Fotoğrafı Kaldır", role: .destructive) {
                        self.photoData = nil
                        selectedPhotoItem = nil
                    }
                }
                HStack {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Label("Fotoğraf Ekle", systemImage: "photo")
                    }
                    Spacer()
                    Button {
                        showingCamera = true
                    } label: {
                        Label("Fotoğraf Çek", systemImage: "camera")
                    }
                    .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))
                }
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
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    photoData = data
                }
            }
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraPicker(imageData: $photoData)
                .ignoresSafeArea()
        }
    }

    private func save() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { item.title = title }
        item.notes = notes
        item.photoData = photoData
        dismiss()
    }

    private func markDone() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { item.title = title }
        item.notes = notes
        item.photoData = photoData
        item.isDone.toggle()
        dismiss()
    }

    private func deleteItem() {
        context.delete(item)
        dismiss()
    }
}
