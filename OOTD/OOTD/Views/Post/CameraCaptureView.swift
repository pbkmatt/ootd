import SwiftUI
import AVFoundation

struct CameraCaptureView: View {
    @Binding var capturedImage: UIImage?
    @StateObject private var cameraModel = CameraModel()
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        ZStack {
            if cameraModel.previewLayer != nil {
                CameraPreview(cameraModel: cameraModel)
                    .ignoresSafeArea()
            } else {
                Text("Loading Camera...")
                    .foregroundColor(.white)
                    .font(.title)
                    .onAppear {
                        cameraModel.checkAuthorization()
                    }
            }

            VStack {
                HStack {
                    // Flip Camera Button
                    Button(action: {
                        cameraModel.toggleCamera()
                    }) {
                        Image(systemName: "arrow.triangle.2.circlepath.camera")
                            .foregroundColor(.white)
                            .font(.system(size: 25))
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .clipShape(Circle())
                    }

                    Spacer()

                    // Flash Toggle Button
                    Button(action: {
                        cameraModel.flashMode = cameraModel.flashMode == .off ? .on : .off
                    }) {
                        Image(systemName: cameraModel.flashMode == .off ? "bolt.slash" : "bolt.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 25))
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .clipShape(Circle())
                    }
                }
                .padding([.top, .horizontal], 20)

                Spacer()

                // Capture Photo Button
                HStack {
                    Spacer()
                    Button(action: {
                        cameraModel.takePhoto()
                    }) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 70, height: 70)
                            .overlay(
                                Circle()
                                    .stroke(Color.black, lineWidth: 2)
                                    .frame(width: 80, height: 80)
                            )
                    }
                    Spacer()
                }
                .padding(.bottom, 20)
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

final class CameraModel: NSObject, ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var previewLayer: AVCaptureVideoPreviewLayer?
    @Published var flashMode: AVCaptureDevice.FlashMode = .off

    private var session: AVCaptureSession?
    private let output = AVCapturePhotoOutput()

    func checkAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.setupSession()
                    } else {
                        self?.showAccessDeniedAlert()
                    }
                }
            }
        default:
            showAccessDeniedAlert()
        }
    }

    func setupSession() {
        session = AVCaptureSession()
        guard let session = session else {
            print("Failed to create AVCaptureSession.")
            return
        }

        session.beginConfiguration()
        session.sessionPreset = .photo

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            print("Failed to add camera input.")
            session.commitConfiguration()
            return
        }
        session.addInput(input)

        if session.canAddOutput(output) {
            session.addOutput(output)
        } else {
            print("Failed to add photo output.")
            session.commitConfiguration()
            return
        }

        session.commitConfiguration()

        self.previewLayer = AVCaptureVideoPreviewLayer(session: session)
        self.previewLayer?.videoGravity = .resizeAspectFill
        print("Preview layer initialized successfully.")

        startSession()
    }

    func startSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let session = self?.session, !session.isRunning else { return }
            session.startRunning()
            print("Session started successfully.")
        }
    }

    func stopSession() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let session = self?.session, session.isRunning else { return }
            session.stopRunning()
            print("Session stopped successfully.")
        }
    }

    func takePhoto() {
        let settings = AVCapturePhotoSettings()
        settings.flashMode = flashMode

        if #available(iOS 16.0, *) {
            if let session = session,
               let currentInput = session.inputs.first as? AVCaptureDeviceInput {
                settings.maxPhotoDimensions = currentInput.device.activeFormat.supportedMaxPhotoDimensions.first ?? CMVideoDimensions(width: 1920, height: 1080)
            } else {
                print("Failed to get active format.")
            }
        }

        output.capturePhoto(with: settings, delegate: self)
    }

    func toggleCamera() {
        guard let session = session else { return }

        session.beginConfiguration()

        guard let currentInput = session.inputs.first as? AVCaptureDeviceInput else {
            print("No camera input found.")
            session.commitConfiguration()
            return
        }

        let newPosition: AVCaptureDevice.Position = currentInput.device.position == .back ? .front : .back

        guard let newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition),
              let newInput = try? AVCaptureDeviceInput(device: newDevice) else {
            print("Failed to switch camera.")
            session.commitConfiguration()
            return
        }

        session.removeInput(currentInput)
        if session.canAddInput(newInput) {
            session.addInput(newInput)
        } else {
            print("Cannot add new camera input.")
        }

        session.commitConfiguration()
    }

    private func showAccessDeniedAlert() {
        DispatchQueue.main.async {
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootVC = scene.windows.first?.rootViewController else { return }

            let alert = UIAlertController(
                title: "Camera Access Denied",
                message: "Please enable camera access in Settings to take photos.",
                preferredStyle: .alert
            )

            alert.addAction(UIAlertAction(title: "Go to Settings", style: .default) { _ in
                guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
                UIApplication.shared.open(settingsURL)
            })

            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            rootVC.present(alert, animated: true)
        }
    }
}

extension CameraModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error.localizedDescription)")
            return
        }

        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            print("Failed to process photo data.")
            return
        }

        DispatchQueue.main.async {
            self.capturedImage = image
        }
    }
}

struct CameraPreview: UIViewRepresentable {
    @ObservedObject var cameraModel: CameraModel

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        DispatchQueue.main.async {
            if let previewLayer = cameraModel.previewLayer {
                previewLayer.frame = view.bounds
                view.layer.addSublayer(previewLayer)
                print("Preview layer added to view in makeUIView.")
            } else {
                print("Preview layer is nil in makeUIView.")
            }
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            if let previewLayer = cameraModel.previewLayer {
                previewLayer.frame = uiView.bounds
                if previewLayer.superlayer == nil {
                    uiView.layer.addSublayer(previewLayer)
                    print("Preview layer added to view in updateUIView.")
                }
            } else {
                print("Preview layer is nil in updateUIView.")
            }
        }
    }
}
