import SwiftUI
import PhotosUI

struct SelectableImageView: View {
    @Binding var selectedItem: PhotosPickerItem?
    @Binding var selectedImageData: Data?
    let imageSize: CGFloat
    let iconSize: CGFloat
    
    var body: some View {
        PhotosPicker(selection: $selectedItem, matching: .images) {
            if let data = selectedImageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: imageSize, height: imageSize)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: imageSize, height: imageSize)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 15))
                            .foregroundColor(.white)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .onChange(of: selectedItem) {
            Task {
                if let data = try? await selectedItem?.loadTransferable(type: Data.self) {
                    selectedImageData = data
                }
            }
        }
    }
}
