import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct PostView: View {
    var post: OOTDPost
    @State private var comments: [Comment] = []
    @State private var newComment = ""
    @State private var isFavorited = false
    @State private var favoriteCount = 0
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        VStack {
            // Display Post Image
            AsyncImage(url: URL(string: post.imageURL)) { image in
                image.resizable()
                    .scaledToFit()
                    .frame(maxHeight: 400)
                    .cornerRadius(10)
            } placeholder: {
                ProgressView()
            }

            HStack {
                // Favorite Button
                Button(action: {
                    toggleFavorite()
                }) {
                    Image(systemName: isFavorited ? "star.fill" : "star")
                        .foregroundColor(isFavorited ? .yellow : .gray)
                    Text("\(favoriteCount)")
                        .font(.subheadline)
                }

                // Comments Button
                Button(action: {
                    // Open comments section
                }) {
                    Image(systemName: "message")
                    Text("\(comments.count)")
                        .font(.subheadline)
                }

                // Tagged Items Button
                if !post.taggedItems.isEmpty {
                    Button(action: {
                        // Open tagged items section
                    }) {
                        Image(systemName: "bag.fill")
                        Text("\(post.taggedItems.count)")
                            .font(.subheadline)
                    }
                }

                Spacer()

                // Share Button
                Button(action: {
                    sharePost()
                }) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
            .padding()

            // Comments Section
            VStack(alignment: .leading) {
                Text("Comments")
                    .font(.headline)
                if comments.isEmpty {
                    Text("No comments yet.")
                        .foregroundColor(.gray)
                } else {
                    ForEach(comments) { comment in
                        HStack {
                            Text(comment.username).bold()
                            Text(comment.text)
                        }
                    }
                }

                HStack {
                    TextField("Add a comment...", text: $newComment)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button("Post") {
                        addComment()
                    }
                }
                .padding(.top, 8)
            }
            .padding()
        }
        .onAppear {
            loadComments()
            checkFavoriteStatus()
        }
        .navigationTitle("Post")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Load Comments
    private func loadComments() {
        let db = Firestore.firestore()
        guard let postId = post.id else { return }

        db.collection("posts")
            .document(postId)
            .collection("comments")
            .order(by: "timestamp", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error loading comments: \(error.localizedDescription)")
                    return
                }

                if let snapshot = snapshot {
                    self.comments = snapshot.documents.compactMap { doc -> Comment? in
                        try? doc.data(as: Comment.self)
                    }
                    print("Loaded \(self.comments.count) comments.")
                }
            }
    }

    // MARK: - Add Comment
    private func addComment() {
        guard !newComment.isEmpty, let uid = Auth.auth().currentUser?.uid else { return }

        // Fetch Username from Firestore
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { document, error in
            if let error = error {
                print("Error fetching username: \(error.localizedDescription)")
                return
            }

            guard let data = document?.data(), let username = data["username"] as? String else {
                print("Username not found")
                return
            }

            // Create Comment object
            let comment = Comment(
                id: UUID().uuidString,
                username: username,
                text: newComment,
                timestamp: Timestamp(date: Date())
            )

            // Add comment to Firestore
            db.collection("posts")
                .document(post.id ?? "")
                .collection("comments")
                .document(comment.id)
                .setData(comment.toDict()) { error in
                    if let error = error {
                        print("Error adding comment: \(error.localizedDescription)")
                    } else {
                        self.comments.append(comment)
                        self.newComment = "" // Clear the input field
                    }
                }
        }
    }

    // MARK: - Toggle Favorite
    private func toggleFavorite() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let postRef = Firestore.firestore().collection("posts").document(post.id ?? "")
        
        if isFavorited {
            postRef.updateData(["favoritesCount": FieldValue.increment(Int64(-1))])
            postRef.collection("favorites").document(uid).delete()
        } else {
            postRef.updateData(["favoritesCount": FieldValue.increment(Int64(1))])
            postRef.collection("favorites").document(uid).setData(["favoritedAt": Timestamp()])
        }
        
        isFavorited.toggle()
    }

    // MARK: - Check Favorite Status
    private func checkFavoriteStatus() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore().collection("posts").document(post.id ?? "")
            .collection("favorites").document(uid)
            .getDocument { document, _ in
                if document?.exists == true {
                    self.isFavorited = true
                }
            }
    }

    // MARK: - Share Post
    private func sharePost() {
        let urlString = "https://ootdapp.com/post/\(post.id ?? "")"
        let activityVC = UIActivityViewController(activityItems: [urlString], applicationActivities: nil)
        UIApplication.shared.windows.first?.rootViewController?.present(activityVC, animated: true)
    }
}
