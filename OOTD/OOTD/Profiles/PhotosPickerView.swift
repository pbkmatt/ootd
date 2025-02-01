import SwiftUI
import PhotosUI

struct PhotosPickerView: View {
    @Binding var profileImage: UIImage?
    @Binding var showCropView: Bool
    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        PhotosPicker(selection: $selectedItem, matching: .images) {
            VStack {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.gray)
                Text("Select Profile Picture")
                    .font(.headline)
            }
        }
        .onChange(of: selectedItem) { newItem in
            handleImageSelection(newItem)
        }
    }

    private func handleImageSelection(_ item: PhotosPickerItem?) {
        guard let item = item else { return }

        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                DispatchQueue.main.async {
                    profileImage = uiImage
                    showCropView = true
                }
            } else {
                print("❌ Failed to load image.")
            }
        }
    }
}
