import AVFoundation
import SwiftUI
import FirebaseAuth

final class CameraModel: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    @Published var capturedImage: UIImage?
    @Published var previewLayer: AVCaptureVideoPreviewLayer?
    @Published var flashMode: AVCaptureDevice.FlashMode = .off

    private var session: AVCaptureSession?
    private let output = AVCapturePhotoOutput()
    private var currentCameraPosition: AVCaptureDevice.Position = .back

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

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentCameraPosition),
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

        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer?.videoGravity = .resizeAspectFill
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

        currentCameraPosition = currentInput.device.position == .back ? .front : .back

        guard let newDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentCameraPosition),
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

        // Get the username dynamically
        let username = Auth.auth().currentUser?.displayName ?? "guest"

        // Add watermark
        let watermarkedImage = image.addWatermark(
            username: username,
            fontName: "BebasNeue-Regular",
            fontSize: max(image.size.width, image.size.height) / 0.0, // Dynamically scale font size
            textColor: .white
        )


        DispatchQueue.main.async {
            self.capturedImage = self.correctOrientation(for: watermarkedImage)
            print("Photo captured and watermarked with username: \(username).")
        }
    }


    private func correctOrientation(for image: UIImage) -> UIImage {
        guard let cgImage = image.cgImage else { return image }

        let orientation: UIImage.Orientation = currentCameraPosition == .front ? .upMirrored : .up
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: orientation)
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
