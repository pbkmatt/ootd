import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

struct PostOOTDView: View {
    let capturedImage: UIImage
    @State private var caption: String = ""
    @State private var tags: [String] = []
    @State private var isUploading: Bool = false
    @State private var uploadProgress: Double = 0.0
    @Environment(\.presentationMode) private var presentationMode
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationView {
            VStack {
                Image(uiImage: capturedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .cornerRadius(10)
                    .padding()

                TextField("Write a caption...", text: $caption)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                TagInputView(tags: $tags)
                    .padding()

                if isUploading {
                    ProgressView(value: uploadProgress, total: 1.0)
                        .padding()
                } else {
                    Button(action: uploadPost) {
                        Text("Post OOTD")
                            .bold()
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                    .disabled(caption.isEmpty)
                }
            }
            .navigationBarTitle("Post Your OOTD", displayMode: .inline)
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }

    func uploadPost() {
        isUploading = true

        // Convert UIImage to Data
        guard let imageData = capturedImage.jpegData(compressionQuality: 0.8) else {
            alertMessage = "Failed to process the image."
            showAlert = true
            isUploading = false
            return
        }

        // Create unique filename
        let fileName = UUID().uuidString + ".jpg"
        let storageRef = Storage.storage().reference().child("posts/\(fileName)")

        // Upload image to Firebase Storage
        let uploadTask = storageRef.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                alertMessage = "Image upload failed: \(error.localizedDescription)"
                showAlert = true
                isUploading = false
                return
            }

            // Retrieve the download URL
            storageRef.downloadURL { url, error in
                if let error = error {
                    alertMessage = "Failed to retrieve download URL: \(error.localizedDescription)"
                    showAlert = true
                    isUploading = false
                    return
                }

                guard let url = url else {
                    alertMessage = "Download URL is nil."
                    showAlert = true
                    isUploading = false
                    return
                }

                // Save post data to Firestore
                savePostToFirestore(imageURL: url.absoluteString)
            }
        }

        // Monitor upload progress
        uploadTask.observe(.progress) { snapshot in
            if let progress = snapshot.progress {
                uploadProgress = progress.fractionCompleted
            }
        }
    }

    func savePostToFirestore(imageURL: String) {
        let db = Firestore.firestore()
        let postsCollection = db.collection("posts")

        let postData: [String: Any] = [
            "imageURL": imageURL,
            "caption": caption,
            "tags": tags,
            "timestamp": Timestamp(),
            "likes": 0,
            "comments": 0,
            "userId": Auth.auth().currentUser?.uid ?? "guest"
        ]

        postsCollection.addDocument(data: postData) { error in
            isUploading = false
            if let error = error {
                alertMessage = "Failed to save post: \(error.localizedDescription)"
                showAlert = true
                return
            }

            presentationMode.wrappedValue.dismiss()
        }
    }
}
