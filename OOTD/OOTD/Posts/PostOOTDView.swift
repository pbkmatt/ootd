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

    @State private var taggedItems: [TaggedItem] = []

    @State private var currentItemName: String = ""
    @State private var currentItemLink: String = ""

    @Environment(\.presentationMode) private var presentationMode
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                
                // MARK: - Captured Photo
                Image(uiImage: capturedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 300)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                // MARK: - Caption
                TextField("Add a caption...", text: $caption)
                    .font(.custom("OpenSans", size: 15))
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal)

                // MARK: - Tagged Items
                taggedItemsSection

                // MARK: - Upload Action
                if isUploading {
                    VStack(spacing: 8) {
                        ProgressView(value: uploadProgress, total: 1.0)
                            .progressViewStyle(LinearProgressViewStyle(tint: Color.blue))
                            .padding(.horizontal)
                        
                        Text("Uploading…")
                            .font(.custom("OpenSans", size: 14))
                            .foregroundColor(.gray)
                    }
                } else {
                    Button(action: uploadPost) {
                        Text("Share OOTD")
                            .font(.custom("BebasNeue-Regular", size: 18))
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(caption.isEmpty ? Color.gray : Color.blue)
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                    .disabled(caption.isEmpty)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarTitle("Post Your OOTD")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .font(.custom("OpenSans", size: 16))
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"),
                      message: Text(alertMessage),
                      dismissButton: .default(Text("OK")))
            }
        }
    }

    // MARK: - Tagged Items Section
    private var taggedItemsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tag your items (up to five):")
                .font(.custom("BebasNeue-Regular", size: 16))
                .padding(.horizontal)
                .padding(.top, 4)
            
            // List of existing tagged items
            ForEach(taggedItems) { item in
                HStack {
                    Text(item.name)
                        .font(.custom("OpenSans", size: 14))
                        .fontWeight(.semibold)
                    
                    // Only show link if it exists
                    if let link = item.link, !link.isEmpty {
                        Text("(Link: \(link))")
                            .font(.custom("OpenSans", size: 12))
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
            }
            
            // Add new item fields
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Item name", text: $currentItemName)
                        .font(.custom("OpenSans", size: 14))
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .disableAutocorrection(true)
                        .autocapitalization(.none)
                    
                    TextField("Optional link", text: $currentItemLink)
                        .font(.custom("OpenSans", size: 14))
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .disableAutocorrection(true)
                        .autocapitalization(.none)
                }
                .frame(minWidth: 0, maxWidth: .infinity)
                
                Button(action: addTaggedItem) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(taggedItems.count >= 5 || currentItemName.isEmpty ? .gray : .blue)
                }
                .disabled(taggedItems.count >= 5 || currentItemName.isEmpty)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .background(Color.white)
    }
    
    // MARK: - Add a tagged item
    private func addTaggedItem() {
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
    private func uploadPost() {
        isUploading = true
        
        // 1) Fetch user’s profile so we can attach username & profileImage
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
                    uploadProgress = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
                }
            }
        }
    }

    // MARK: - Save Post to Firestore
    private func savePostToFirestore(imageURL: String,
                                     userProfile: (uid: String, username: String, profileImg: String)) {
        let db = Firestore.firestore()

        // Convert array of TaggedItem to an array of dictionaries
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
            "taggedItems": taggedItemsData,
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

    // MARK: - Fetch user’s profile
    private func fetchUserProfile(completion: @escaping ((uid: String, username: String, profileImg: String)) -> Void) {
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
