import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth

struct PostOOTDView: View {
    let capturedImage: UIImage
    
    @State private var caption: String = ""
    @State private var isUploading: Bool = false
    @State private var uploadProgress: Double = 0.0

    // Replace old tags array with an array of TaggedItem
    @State private var taggedItems: [TaggedItem] = []

    // For adding a new item
    @State private var currentItemName: String = ""
    @State private var currentItemLink: String = ""

    @Environment(\.presentationMode) private var presentationMode
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationView {
            VStack {
                // The captured photo
                Image(uiImage: capturedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .cornerRadius(10)
                    .padding()

                // Caption
                TextField("Write a caption...", text: $caption)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                // MARK: - Tagged Items UI
                taggedItemsSection

                // Upload Progress or Upload Button
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
                Alert(title: Text("Error"),
                      message: Text(alertMessage),
                      dismissButton: .default(Text("OK")))
            }
        }
    }

    // MARK: - Tagged Items Section
    private var taggedItemsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Tag up to 5 items:")
                .font(.headline)
                .padding(.horizontal)

            // A list of existing items
            ForEach(taggedItems) { item in
                HStack {
                    Text(item.name)
                        .fontWeight(.medium)
                    if let link = item.link, !link.isEmpty {
                        Text("(Link: \(link))")
                            .font(.footnote)
                            .foregroundColor(.blue)
                    }
                    Spacer()
                }
                .padding(.horizontal)
            }

            // Add new item fields
            HStack {
                VStack(alignment: .leading) {
                    TextField("Item name", text: $currentItemName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disableAutocorrection(true)
                        .autocapitalization(.none)
                    TextField("Optional link", text: $currentItemLink)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .disableAutocorrection(true)
                        .autocapitalization(.none)
                }
                .frame(minWidth: 0, maxWidth: .infinity)

                Button(action: addTaggedItem) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .padding(.leading, 8)
                }
                .disabled(taggedItems.count >= 5 || currentItemName.isEmpty)
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Add a tagged item
    private func addTaggedItem() {
        // Validate name
        guard TaggedItem.isValidName(currentItemName) else {
            alertMessage = "Item name must be letters/numbers/spaces only (1–40 chars)."
            showAlert = true
            return
        }
        if taggedItems.count >= 5 {
            alertMessage = "You can only add up to 5 items."
            showAlert = true
            return
        }

        let newItem = TaggedItem(name: currentItemName, link: currentItemLink)
        taggedItems.append(newItem)
        currentItemName = ""
        currentItemLink = ""
    }

    // MARK: - Upload Post
    func uploadPost() {
        isUploading = true

        // 1) Fetch the user’s profile so we can attach username & profileImage
        fetchUserProfile { userProfile in
            // 2) Add watermark with the username
            let watermarked = capturedImage.addWatermark(
                username: userProfile.username,
                fontName: "BebasNeue-Regular",
                fontSize: max(capturedImage.size.width, capturedImage.size.height) / 20,
                textColor: .white
            )

            // 3) Convert watermarked image to Data
            guard let imageData = watermarked.jpegData(compressionQuality: 0.9) else {
                alertMessage = "Failed to process the image."
                showAlert = true
                isUploading = false
                return
            }

            // 4) Create unique file name in Firebase Storage
            let fileName = UUID().uuidString + ".jpg"
            let storageRef = Storage.storage().reference().child("posts/\(fileName)")

            // 5) Upload the image to Firebase Storage
            let uploadTask = storageRef.putData(imageData, metadata: nil) { _, error in
                if let error = error {
                    print("Error uploading image: \(error.localizedDescription)")
                    alertMessage = "Image upload failed: \(error.localizedDescription)"
                    showAlert = true
                    isUploading = false
                    return
                }
                // 6) Retrieve the download URL
                storageRef.downloadURL { url, error in
                    if let error = error {
                        print("Error getting download URL: \(error.localizedDescription)")
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
                    // 7) Save post to Firestore
                    savePostToFirestore(
                        imageURL: url.absoluteString,
                        userProfile: userProfile
                    )
                }
            }

            // Optionally track progress
            uploadTask.observe(.progress) { snapshot in
                if let progress = snapshot.progress {
                    uploadProgress = Double(progress.completedUnitCount)
                                   / Double(progress.totalUnitCount)
                }
            }
        }
    }

    // MARK: - Save Post to Firestore
    private func savePostToFirestore(imageURL: String, userProfile: (uid: String, username: String, profileImg: String)) {
        let db = Firestore.firestore()

        // Convert the array of TaggedItem to an array of dictionaries
        let taggedItemsData = taggedItems.map { item -> [String: Any] in
            [
                "id": item.id,
                "name": item.name,
                "link": item.link ?? ""
            ]
        }

        let postData: [String: Any] = [
            "uid": userProfile.uid,
            "username": userProfile.username,
            "profileImage": userProfile.profileImg,
            "caption": caption.isEmpty ? "No caption" : caption,
            "imageURL": imageURL,
            "taggedItems": taggedItemsData, // <— array of dictionaries
            "timestamp": Timestamp(),
            "visibility": "public",
            "commentsCount": 0,
            "favoritesCount": 0,
            "closetsCount": 0
        ]

        db.collection("posts").addDocument(data: postData) { error in
            isUploading = false
            if let error = error {
                print("Error saving post: \(error.localizedDescription)")
                alertMessage = "Failed to save post: \(error.localizedDescription)"
                showAlert = true
                return
            }
            print("✅ Post saved successfully in Firestore!")
            presentationMode.wrappedValue.dismiss()
        }
    }

    // MARK: - Fetch user’s profile (username, profilePictureURL)
    func fetchUserProfile(completion: @escaping ((uid: String, username: String, profileImg: String)) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            completion(("guestUID", "guest", ""))
            return
        }
        let db = Firestore.firestore()
        db.collection("users").document(currentUser.uid).getDocument { document, error in
            if let error = error {
                print("Error fetching user data: \(error.localizedDescription)")
                completion((currentUser.uid, "guest", ""))
                return
            }

            let data = document?.data() ?? [:]
            let username = data["username"] as? String ?? "guest"
            let profileImg = data["profilePictureURL"] as? String ?? ""
            completion((currentUser.uid, username, profileImg))
        }
    }
}
