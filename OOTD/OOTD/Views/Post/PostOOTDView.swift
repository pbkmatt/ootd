import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import AVFoundation

struct PostOOTDView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var capturedImage: UIImage?
    @State private var caption = ""
    @State private var taggedItems: [OOTDItem] = []
    @State private var itemTitle = ""
    @State private var itemLink = ""
    @State private var isUploading = false
    @State private var showCamera = false
    @State private var cameraPermissionDenied = false

    var body: some View {
        NavigationView {
            VStack {
                if let capturedImage = capturedImage {
                    VStack {
                        Image(uiImage: capturedImage)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(10)
                            .padding()

                        TextField("Write a caption...", text: $caption)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()

                        HStack {
                            TextField("Item title", text: $itemTitle)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            TextField("Item link", text: $itemLink)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            Button("Add") {
                                addItem()
                            }
                            .disabled(itemTitle.isEmpty || itemLink.isEmpty)
                        }
                        .padding()

                        List(taggedItems) { item in
                            VStack(alignment: .leading) {
                                Text(item.title).bold()
                                Text(item.link).foregroundColor(.blue)
                            }
                        }

                        Button(action: {
                            applyWatermarkAndUpload()
                        }) {
                            HStack {
                                Text("POST")
                                    .font(.system(size: 24, weight: .bold))
                                Image(systemName: "arrow.right")
                            }
                            .frame(maxWidth: .infinity, minHeight: 50)
                            .background(isUploading ? Color.gray : Color.black)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        .disabled(isUploading || caption.isEmpty || capturedImage == nil)
                        .padding(.vertical)
                    }
                } else {
                    Button(action: {
                        showCamera = true
                    }) {
                        VStack {
                            Image(systemName: "camera")
                                .resizable()
                                .frame(width: 100, height: 100)
                                .foregroundColor(.gray)
                            Text("Capture OOTD")
                                .font(.headline)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding()
                }
            }
            .padding()
            .navigationTitle("Post OOTD")
            .fullScreenCover(isPresented: $showCamera) {
                CameraCaptureView(image: $capturedImage)
            }
            .alert(isPresented: $cameraPermissionDenied) {
                Alert(
                    title: Text("Camera Access Denied"),
                    message: Text("Please enable camera access in Settings."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }

    private func addItem() {
        let newItem = OOTDItem(title: itemTitle, link: itemLink)
        taggedItems.append(newItem)
        itemTitle = ""
        itemLink = ""
    }

    private func applyWatermarkAndUpload() {
        guard let capturedImage = capturedImage else { return }
        
        if let watermarkedImage = addWatermark(to: capturedImage, username: authViewModel.currentUsername) {
            uploadImage(watermarkedImage)
        } else {
            print("Error applying watermark")
        }
    }

    private func addWatermark(to image: UIImage, username: String) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: image.size)
        return renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: image.size))
            
            let text = "OOTD/\(username)"
            let fontSize = image.size.width * 0.08
            let font = UIFont(name: "BebasNeue-Regular", size: fontSize) ?? UIFont.systemFont(ofSize: fontSize)

            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.white
            ]

            let textSize = text.size(withAttributes: attributes)
            let padding: CGFloat = 30
            let textRect = CGRect(
                x: image.size.width - textSize.width - padding,
                y: image.size.height - textSize.height - padding,
                width: textSize.width,
                height: textSize.height
            )

            text.draw(in: textRect, withAttributes: attributes)
        }
    }

    private func uploadImage(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 1.0) else { return }

        isUploading = true
        let filename = "OOTDPosts/\(UUID().uuidString).jpg"
        let storageRef = Storage.storage().reference().child(filename)
        storageRef.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                print("Upload failed: \(error.localizedDescription)")
                isUploading = false
                return
            }

            storageRef.downloadURL { url, error in
                if let url = url {
                    savePostData(imageURL: url.absoluteString)
                } else {
                    print("Failed to get download URL")
                    isUploading = false
                }
            }
        }
    }

    private func savePostData(imageURL: String) {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("No authenticated user found")
            return
        }

        let post = OOTDPost(
            imageURL: imageURL,
            caption: caption,
            taggedItems: taggedItems,
            timestamp: Date(),
            userID: uid
        )

        let db = Firestore.firestore()
        do {
            _ = try db.collection("users").document(uid).collection("posts").addDocument(from: post)
            isUploading = false
            resetForm()
        } catch {
            print("Error saving post: \(error.localizedDescription)")
            isUploading = false
        }
    }

    private func resetForm() {
        capturedImage = nil
        caption = ""
        taggedItems.removeAll()
    }

    private func checkCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                if granted {
                    self.showCamera = true
                } else {
                    self.cameraPermissionDenied = true
                }
            }
        }
    }
}
