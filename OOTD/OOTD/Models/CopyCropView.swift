import SwiftUI

struct CropView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var rotation: Angle = .zero
    @State private var lastRotation: Angle = .zero

    private let image: UIImage
    @Binding var croppedImage: UIImage?
    private let maskShape: MaskShape

    init(image: UIImage, croppedImage: Binding<UIImage?>, maskShape: MaskShape = .circle) {
        self.image = image
        self._croppedImage = croppedImage
        self.maskShape = maskShape
    }

    var body: some View {
        VStack {
            Text("Adjust & Crop Your Image")
                .font(Font.custom("BebasNeue-Regular", size: 20))
                .padding(.top, 20)

            ZStack {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .rotationEffect(rotation)
                    .scaleEffect(scale)
                    .offset(offset)
                    .mask(MaskShapeView(maskShape: maskShape))
                    .gesture(pinchGesture)
                    .gesture(dragGesture)
                    .gesture(rotationGesture)
            }
            .frame(width: 300, height: 300)
            .clipShape(MaskShapeView(maskShape: maskShape))

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray.opacity(0.3))
                .cornerRadius(10)

                Button("Crop & Save") {
                    croppedImage = cropImage()
                    dismiss()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding()
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Gestures
    private var pinchGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                let newScale = value.magnitude * lastScale
                scale = min(max(newScale, 1.0), 4.0) // Limit zoom
            }
            .onEnded { _ in
                lastScale = scale
            }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = CGSize(width: value.translation.width + lastOffset.width,
                                height: value.translation.height + lastOffset.height)
            }
            .onEnded { _ in
                lastOffset = offset
            }
    }

    private var rotationGesture: some Gesture {
        RotationGesture()
            .onChanged { value in
                rotation = value + lastRotation
            }
            .onEnded { _ in
                lastRotation = rotation
            }
    }

    // MARK: - Crop Image
    private func cropImage() -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 300, height: 300))
        return renderer.image { context in
            let rect = CGRect(origin: CGPoint(x: -offset.width, y: -offset.height), size: CGSize(width: 300, height: 300))
            image.draw(in: rect)
        }
    }
}

// MARK: - Mask Shape View
private struct MaskShapeView: Shape {
    let maskShape: MaskShape

    func path(in rect: CGRect) -> Path {
        switch maskShape {
        case .circle:
            return Path(ellipseIn: rect)
        case .rectangle, .square:
            return Path(rect)
        }
    }
}

// MARK: - Mask Shape Enum
enum MaskShape {
    case circle, square, rectangle
}
