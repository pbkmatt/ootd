import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct PostDetailView: View {
    let post: OOTDPost
    @State private var user: UserModel? = nil
    @State private var isFavorite: Bool = false
    @State private var favoritesCount: Int = 0
    @State private var comments: [Comment] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // User Info Section
                if let user = user {
                    HStack {
                        if let url = URL(string: user.profilePictureURL) {
                            AsyncImage(url: url) { image in
                                image.resizable()
                                    .scaledToFill()
                                    .frame(width: 50, height: 50)
                                    .clipShape(Circle())
                            } placeholder: {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 50, height: 50)
                            }
                        }

                        VStack(alignment: .leading) {
                            Text(user.username)
                                .font(Font.custom("BebasNeue-Regular", size: 18))
                            Text(post.timestamp.dateValue(), style: .time)
                                .font(Font.custom("OpenSans", size: 14))
                                .foregroundColor(.gray)
                        }

                        Spacer()
                    }
                }

                // Post Image
                if let url = URL(string: post.imageURL ?? "") {
                    AsyncImage(url: url) { image in
                        image.resizable()
                            .scaledToFit()
                            .cornerRadius(10)
                    } placeholder: {
                        Color.gray
                            .frame(height: 300)
                            .cornerRadius(10)
                    }
                }

                // Post Caption
                if !post.caption.isEmpty {
                    Text(post.caption)
                        .font(Font.custom("OpenSans", size: 14))
                        .foregroundColor(.primary)
                        .padding(.top, 8)
                }


                // Post Interactions
                HStack {
                    Button(action: toggleFavorite) {
                        HStack(spacing: 4) {
                            Image(systemName: isFavorite ? "star.fill" : "star")
                                .foregroundColor(isFavorite ? .yellow : .gray)
                            Text("\(favoritesCount)")
                                .font(Font.custom("OpenSans", size: 14))
                        }
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "message")
                            .foregroundColor(.gray)
                        Text("\(comments.count)")
                            .font(Font.custom("OpenSans", size: 14))
                    }
                }
                .padding(.vertical, 8)

                // Comments Section
                if comments.isEmpty {
                    Text("No comments yet.")
                        .font(Font.custom("OpenSans", size: 14))
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(comments) { comment in
                            HStack {
                                Text(comment.username)
                                    .font(Font.custom("BebasNeue-Regular", size: 14))
                                    .foregroundColor(.primary)

                                Text(comment.text)
                                    .font(Font.custom("OpenSans", size: 14))
                                    .foregroundColor(.secondary)

                                Spacer()
                            }
                        }
                    }
                    .padding(.top, 8)
                }
            }
            .padding()
        }
        .navigationTitle("Post Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            fetchUser()
            fetchComments()
            favoritesCount = post.favoritesCount ?? 0
            checkIfFavorite()
        }
    }

    // MARK: - Fetch User Info
    private func fetchUser() {
        let userId = post.userID // Use directly without unwrapping
        let db = Firestore.firestore()
        
        db.collection("users").document(userId).getDocument { document, error in
            if let error = error {
                print("Error fetching user: \(error.localizedDescription)")
                return
            }
            if let document = document, let data = document.data() {
                user = UserModel(
                    id: document.documentID,
                    username: data["username"] as? String ?? "Unknown",
                    bio: data["bio"] as? String ?? "",
                    profilePictureURL: data["profilePictureURL"] as? String ?? "",
                    isPrivate: data["isPrivateProfile"] as? Bool ?? false
                )
            }
        }
    }


    // MARK: - Fetch Comments
    private func fetchComments() {
        guard let postId = post.id else {
            print("Error: Post ID is nil.")
            return
        }

        let db = Firestore.firestore()
        db.collection("users").document(post.userID).collection("posts").document(postId).collection("comments")
            .order(by: "timestamp", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error fetching comments: \(error.localizedDescription)")
                    return
                }
                if let snapshot = snapshot {
                    comments = snapshot.documents.compactMap { doc -> Comment? in
                        try? doc.data(as: Comment.self)
                    }
                }
            }
    }

    // MARK: - Toggle Favorite
    private func toggleFavorite() {
        guard let postId = post.id else { return }
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }

        isFavorite.toggle()
        favoritesCount += isFavorite ? 1 : -1

        let db = Firestore.firestore()
        db.collection("users").document(post.userID).collection("posts").document(postId).updateData([
            "favoritesCount": favoritesCount
        ]) { error in
            if let error = error {
                print("Error updating favorites count: \(error.localizedDescription)")
            }
        }

        let favoritesCollection = db.collection("users").document(post.userID).collection("posts").document(postId).collection("favorites")
        if isFavorite {
            favoritesCollection.document(currentUserId).setData([:]) { error in
                if let error = error {
                    print("Error adding favorite: \(error.localizedDescription)")
                }
            }
        } else {
            favoritesCollection.document(currentUserId).delete { error in
                if let error = error {
                    print("Error removing favorite: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Check If Favorite
    private func checkIfFavorite() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        guard let postId = post.id else { return }

        let db = Firestore.firestore()
        db.collection("users").document(post.userID).collection("posts").document(postId).collection("favorites")
            .document(currentUserId).getDocument { document, error in
                if let error = error {
                    print("Error checking favorite status: \(error.localizedDescription)")
                    return
                }
                isFavorite = document?.exists ?? false
            }
    }
}
