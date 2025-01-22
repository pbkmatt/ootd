import SwiftUI
import AVFoundation

struct CameraCaptureView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode
    let session = AVCaptureSession()

    class Coordinator: NSObject, AVCapturePhotoCaptureDelegate {
        var parent: CameraCaptureView
        var output = AVCapturePhotoOutput()

        init(parent: CameraCaptureView) {
            self.parent = parent
        }

        @objc func capturePhoto() {
            let settings = AVCapturePhotoSettings()
            output.capturePhoto(with: settings, delegate: self)
        }

        func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
            guard let data = photo.fileDataRepresentation(),
                  var uiImage = UIImage(data: data) else { return }

            // Mirror the front camera image correctly
            if let connection = output.connection(with: .video),
               connection.isVideoMirroringSupported {
                uiImage = UIImage(cgImage: uiImage.cgImage!, scale: uiImage.scale, orientation: .upMirrored)
            }

            DispatchQueue.main.async {
                self.parent.image = uiImage
                self.parent.presentationMode.wrappedValue.dismiss()
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        session.sessionPreset = .photo

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            print("Front camera not available")
            return controller
        }

        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
            }
        } catch {
            print("Error accessing front camera: \(error.localizedDescription)")
        }

        if session.canAddOutput(context.coordinator.output) {
            session.addOutput(context.coordinator.output)
        }

        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = controller.view.bounds
        controller.view.layer.addSublayer(previewLayer)

        session.startRunning()

        // UI buttons
        let captureButton = UIButton(type: .custom)
        captureButton.frame = CGRect(x: controller.view.frame.midX - 35, y: controller.view.frame.height - 100, width: 70, height: 70)
        captureButton.setImage(UIImage(systemName: "circle.fill"), for: .normal)
        captureButton.tintColor = .white
        captureButton.addTarget(context.coordinator, action: #selector(Coordinator.capturePhoto), for: .touchUpInside)

        let closeButton = UIButton(type: .custom)
        closeButton.frame = CGRect(x: 20, y: 50, width: 40, height: 40)
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .white
        closeButton.addTarget(controller, action: #selector(controller.dismiss), for: .touchUpInside)

        controller.view.addSubview(captureButton)
        controller.view.addSubview(closeButton)

        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    func teardown() {
        session.stopRunning()
    }
}
