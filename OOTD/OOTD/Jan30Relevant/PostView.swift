import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct PostView: View {
    var post: OOTDPost
    @State private var comments: [Comment] = []
    @State private var newComment = ""
    @State private var isFavorited = false
    @State private var favoriteCount: Int
    @EnvironmentObject var authViewModel: AuthViewModel

    init(post: OOTDPost) {
        self.post = post
        _favoriteCount = State(initialValue: post.favoritesCount)
    }

    var body: some View {
        VStack(alignment: .leading) {
            // Post Image
            AsyncImage(url: URL(string: post.imageURL)) { image in
                image.resizable()
                    .scaledToFit()
                    .frame(maxHeight: 400)
                    .cornerRadius(10)
            } placeholder: {
                ProgressView()
            }

            // Action Buttons
            HStack(spacing: 20) {
                // Favorite Button
                Button(action: { toggleFavorite() }) {
                    Image(systemName: isFavorited ? "star.fill" : "star")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                        .foregroundColor(isFavorited ? .yellow : .gray)
                }
                Text("\(favoriteCount)")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                // Comment Button
                Button(action: {}) {
                    Image(systemName: "bubble.right")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                        .foregroundColor(.gray)
                }
                Text("\(comments.count)")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                // Shopping Bag Button (Tagged Items)
                if !post.taggedItems.isEmpty {
                    Button(action: { showTaggedItems() }) {
                        Image(systemName: "bag")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                            .foregroundColor(.gray)
                    }
                }

                // Add to Board Button (Placeholder)
                Button(action: {}) {
                    Image(systemName: "plus")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                        .foregroundColor(.gray)
                }

                Spacer()
            }
            .padding(.horizontal, 15)
            .padding(.top, 5)

            // Caption
            if !post.caption.isEmpty {
                Text(post.caption)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 15)
            }

            // Comments Section
            VStack(alignment: .leading, spacing: 5) {
                Text("Comments")
                    .font(.headline)
                    .padding(.bottom, 5)

                if comments.isEmpty {
                    Text("No comments yet. Be the first to comment!")
                        .foregroundColor(.gray)
                        .font(.subheadline)
                } else {
                    ForEach(comments) { comment in
                        HStack(spacing: 10) {
                            // Profile Picture
                            AsyncImage(url: URL(string: comment.profileImage)) { image in
                                image.resizable()
                                    .scaledToFill()
                                    .frame(width: 30, height: 30)
                                    .clipShape(Circle())
                            } placeholder: {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 30, height: 30)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                // Username & Comment Text
                                HStack {
                                    Text(comment.username)
                                        .bold()
                                        .onTapGesture {
                                            navigateToProfile(userId: comment.userId)
                                        }
                                    Spacer()
                                }
                                Text(comment.text)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                            }
                        }
                        .padding(.vertical, 5)
                    }
                }

                // Add Comment Input
                HStack {
                    TextField("Add a comment...", text: $newComment)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    Button("Post") {
                        addComment()
                    }
                    .padding(.horizontal, 8)
                    .disabled(newComment.isEmpty)
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 15)
            .padding(.bottom, 10)
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

        db.collection("posts").document(postId).collection("comments")
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error loading comments: \(error.localizedDescription)")
                    return
                }
                if let snapshot = snapshot {
                    self.comments = snapshot.documents.compactMap { doc -> Comment? in
                        try? doc.data(as: Comment.self)
                    }
                }
            }
    }

    // MARK: - Add Comment
    private func addComment() {
        guard !newComment.isEmpty, let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        db.collection("users").document(uid).getDocument { document, error in
            if let error = error {
                print("Error fetching user data: \(error.localizedDescription)")
                return
            }

            guard let data = document?.data(),
                  let username = data["username"] as? String,
                  let profileImage = data["profileImage"] as? String else { return }

            let comment = Comment(
                id: UUID().uuidString,
                userId: uid,
                username: username,
                profileImage: profileImage,
                text: newComment,
                timestamp: Timestamp(date: Date())
            )

            db.collection("posts").document(post.id ?? "")
                .collection("comments")
                .document(comment.id)
                .setData(comment.toDict()) { error in
                    if let error = error {
                        print("Error adding comment: \(error.localizedDescription)")
                    } else {
                        self.comments.append(comment) // **Optimized: Adds comment locally**
                        self.newComment = ""
                    }
                }
        }
    }

    // MARK: - Toggle Favorite
    private func toggleFavorite() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let db = Firestore.firestore()
        let favoriteRef = db.collection("users").document(uid).collection("favorites").document(post.id ?? "")

        if isFavorited {
            favoriteRef.delete()
            favoriteCount -= 1
        } else {
            favoriteRef.setData(["favoritedAt": Timestamp()])
            favoriteCount += 1
        }
        
        isFavorited.toggle()
    }

    // MARK: - Navigate to User Profile
    private func navigateToProfile(userId: String) {
        // Navigation logic to UserProfileDetailView
    }

    // MARK: - Show Tagged Items (Placeholder)
    private func showTaggedItems() {
        // Functionality to display tagged items
    }
}
