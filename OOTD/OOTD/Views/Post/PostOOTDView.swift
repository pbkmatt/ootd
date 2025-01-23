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

        // Fetch the username from Firestore
        fetchUsername { username in
            // Add watermark with the username
            let watermarkedImage = capturedImage.addWatermark(
                username: username,
                fontName: "BebasNeue-Regular",
                fontSize: max(capturedImage.size.width, capturedImage.size.height) / 20, // Dynamically scale font size
                textColor: .white
            )

            // Convert the watermarked image to Data
            guard let imageData = watermarkedImage.jpegData(compressionQuality: 0.9) else {
                alertMessage = "Failed to process the image."
                showAlert = true
                isUploading = false
                return
            }

            // Create unique filename for Firebase Storage
            let fileName = UUID().uuidString + ".jpg"
            let storageRef = Storage.storage().reference().child("posts/\(fileName)")

            // Upload the image to Firebase Storage
            storageRef.putData(imageData, metadata: nil) { _, error in
                if let error = error {
                    print("Error uploading image to Firebase Storage: \(error.localizedDescription)")
                    alertMessage = "Image upload failed: \(error.localizedDescription)"
                    showAlert = true
                    isUploading = false
                    return
                }

                // Retrieve the download URL for the uploaded image
                storageRef.downloadURL { url, error in
                    if let error = error {
                        print("Error getting download URL: \(error.localizedDescription)")
                        alertMessage = "Failed to retrieve download URL: \(error.localizedDescription)"
                        showAlert = true
                        isUploading = false
                        return
                    }

                    guard let url = url else {
                        print("Download URL is nil.")
                        alertMessage = "Download URL is nil."
                        showAlert = true
                        isUploading = false
                        return
                    }

                    print("Image uploaded successfully. URL: \(url.absoluteString)")

                    // Save post to Firestore
                    self.savePostToFirestore(imageURL: url.absoluteString)
                }
            }
        }
    }

    
    func savePostToFirestore(imageURL: String) {
        guard let userId = Auth.auth().currentUser?.uid else {
            alertMessage = "Failed to retrieve user ID."
            showAlert = true
            isUploading = false
            return
        }

        let db = Firestore.firestore()
        let userPostsCollection = db.collection("users").document(userId).collection("posts")

        // Create post data
        let postData: [String: Any] = [
            "caption": caption.isEmpty ? "No caption" : caption,
            "imageURL": imageURL,
            "taggedItems": tags.isEmpty ? [] : tags,
            "timestamp": Timestamp(),
            "visibility": "public", // Default to public visibility
            "commentsCount": 0, // Default value
            "favoritesCount": 0, // Default value
            "userID": userId // Ensure userID is the authenticated user's UID
        ]

        // Save post to Firestore
        print("Saving post with data: \(postData)")
        userPostsCollection.addDocument(data: postData) { error in
            isUploading = false

            if let error = error {
                print("Error saving post to Firestore: \(error.localizedDescription)")
                alertMessage = "Failed to save post: \(error.localizedDescription)"
                showAlert = true
                return
            }

            print("Post saved successfully in Firestore!")
            presentationMode.wrappedValue.dismiss()
        }
    }
    func fetchUsername(completion: @escaping (String) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion("guest") // Default to "guest" if no authenticated user
            return
        }

        Firestore.firestore().collection("users").document(userId).getDocument { document, error in
            if let error = error {
                print("Error fetching username: \(error.localizedDescription)")
                completion("guest") // Default to "guest" on error
                return
            }

            let username = document?.data()?["username"] as? String ?? "guest"
            completion(username)
        }
    }


}
