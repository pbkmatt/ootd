import SwiftUI
import AVFoundation

struct CameraCaptureView: View {
    @Binding var capturedImage: UIImage?
    @StateObject private var cameraModel = CameraModel()

    var body: some View {
        ZStack {
            // Camera preview
            if cameraModel.previewLayer != nil {
                CameraPreview(cameraModel: cameraModel)
                    .ignoresSafeArea(edges: .all) // Camera occupies the full screen
            } else {
                Text("Loading Camera...")
                    .foregroundColor(.white)
                    .font(.title)
                    .onAppear {
                        cameraModel.checkAuthorization()
                    }
            }

            // Overlay UI for buttons
            VStack {
                Spacer()

                // Buttons section
                HStack(spacing: 40) {
                    // Flip Camera Button
                    Button(action: {
                        cameraModel.toggleCamera()
                    }) {
                        Image(systemName: "arrow.triangle.2.circlepath.camera")
                            .foregroundColor(.white)
                            .font(.system(size: 30))
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .clipShape(Circle())
                    }

                    // Capture Photo Button
                    Button(action: {
                        cameraModel.takePhoto()
                    }) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Circle()
                                    .stroke(Color.black, lineWidth: 4)
                                    .frame(width: 90, height: 90)
                            )
                    }

                    // Flash Toggle Button
                    Button(action: {
                        cameraModel.flashMode = cameraModel.flashMode == .off ? .on : .off
                    }) {
                        Image(systemName: cameraModel.flashMode == .off ? "bolt.slash" : "bolt.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 30))
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .clipShape(Circle())
                    }
                }
                .padding(.bottom, 40) // Add spacing at the bottom
            }
        }
        .onDisappear {
            if cameraModel.capturedImage == nil {
                cameraModel.stopSession()
            }
        }
        .onChange(of: cameraModel.capturedImage) { newImage in
            if let newImage = newImage {
                capturedImage = newImage
            }
        }
    }
}
