import SwiftUI

struct CropView: View {
    var image: UIImage
    @Binding var croppedImage: UIImage?
    @Environment(\.presentationMode) private var presentationMode

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    private let circleSize: CGFloat = 300 // Size of the circular crop area

    var body: some View {
        VStack {
            // Cropping Area
            ZStack {
                Color.black.ignoresSafeArea()

                // Display the image with zoom and pan gestures
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                let delta = value / lastScale
                                lastScale = value
                                scale = max(1.0, min(scale * delta, 5.0)) // Limit zoom scale
                                print("Scale: \(scale)") // Debugging
                            }
                            .onEnded { _ in
                                lastScale = 1.0
                                print("Zoom ended. Final scale: \(scale)") // Debugging
                            }
                    )
                    .simultaneousGesture( // Add simultaneous gesture for panning
                        DragGesture()
                            .onChanged { value in
                                let newOffset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                                offset = newOffset
                                print("Offset: \(offset)") // Debugging
                            }
                            .onEnded { _ in
                                lastOffset = offset
                                print("Pan ended. Final offset: \(offset)") // Debugging
                            }
                    )
            }
            .frame(width: circleSize, height: circleSize)
            .clipped()

            // Crop Button
            Button(action: cropImage) {
                Text("Crop")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
                    .padding()
            }
        }
        .navigationTitle("Crop Image")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }

    // MARK: - Crop Image Function
    private func cropImage() {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: circleSize, height: circleSize))
        let cropped = renderer.image { context in
            // Calculate the crop rect based on zoom and offset
            let cropRect = CGRect(
                x: (image.size.width - circleSize) / 2 - offset.width / scale,
                y: (image.size.height - circleSize) / 2 - offset.height / scale,
                width: circleSize / scale,
                height: circleSize / scale
            )

            // Draw the cropped portion of the image
            if let cgImage = image.cgImage?.cropping(to: cropRect) {
                let croppedUIImage = UIImage(cgImage: cgImage)
                croppedUIImage.draw(in: CGRect(origin: .zero, size: CGSize(width: circleSize, height: circleSize)))
            }
        }

        // Set the cropped image and dismiss the view
        croppedImage = cropped
        presentationMode.wrappedValue.dismiss()
    }
}
