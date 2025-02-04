import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct PostView: View {
    let post: OOTDPost

    // Comments
    @State private var comments: [Comment] = []
    @State private var newComment = ""
    
    // Favorites
    @State private var isFavorited = false
    @State private var favoriteCount: Int
    
    // Closet
    @State private var isInCloset = false
    @State private var closetsCount: Int
    
    // Show the “tagged items” sheet
    @State private var showTaggedItemsSheet = false
    
    // Show the “add to closet” sheet (if you want a separate flow)
    // or simply do the closet add inline. This code does it inline for clarity.
    @State private var isAddToClosetSheetPresented = false
    
    init(post: OOTDPost) {
        self.post = post
        _favoriteCount = State(initialValue: post.favoritesCount)
        _closetsCount = State(initialValue: post.closetsCount)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Post Image
            AsyncImage(url: URL(string: post.imageURL)) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: UIScreen.main.bounds.width)
                    .clipped()
            } placeholder: {
                ProgressView()
            }

            // Action Buttons
            HStack(spacing: 20) {
                // Favorite
                Button(action: toggleFavorite) {
                    Image(systemName: isFavorited ? "star.fill" : "star")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                        .foregroundColor(isFavorited ? .yellow : .gray)
                }
                Text("\(favoriteCount)")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                // Comment
                Image(systemName: "bubble.right")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .foregroundColor(.gray)
                Text("\(comments.count)")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                // “Add to Closet” button
                Button(action: toggleCloset) {
                    Image(systemName: isInCloset ? "briefcase.fill" : "briefcase")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 22, height: 22)
                        .foregroundColor(.gray)
                }
                Text("\(closetsCount)")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                // Show tagged items
                if !post.taggedItems.isEmpty {
                    Button(action: {
                        showTaggedItemsSheet = true
                    }) {
                        Image(systemName: "bag")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                            .foregroundColor(.gray)
                    }
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
                    .padding(.top, 5)
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
            checkClosetStatus()
        }
        .navigationTitle("Post")
        .navigationBarTitleDisplayMode(.inline)

        // Tagged Items Sheet
        .sheet(isPresented: $showTaggedItemsSheet) {
            TaggedItemsSheet(items: post.taggedItems)
                .presentationDetents([.medium, .large])
        }
    }

    // MARK: - Load Comments
    private func loadComments() {
        guard let postId = post.id else { return }
        let db = Firestore.firestore()
        db.collection("posts").document(postId)
            .collection("comments")
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error loading comments: \(error.localizedDescription)")
                    return
                }
                if let snapshot = snapshot {
                    self.comments = snapshot.documents.compactMap { doc in
                        try? doc.data(as: Comment.self)
                    }
                }
            }
    }

    // MARK: - Add a Comment
    private func addComment() {
        guard !newComment.isEmpty,
              let uid = Auth.auth().currentUser?.uid,
              let postId = post.id
        else { return }

        let db = Firestore.firestore()
        let postRef = db.collection("posts").document(postId)

        // Fetch my user info to embed in the comment
        db.collection("users").document(uid).getDocument { document, error in
            if let error = error {
                print("Error fetching user data: \(error.localizedDescription)")
                return
            }
            guard
                let data = document?.data(),
                let username = data["username"] as? String,
                let profileImage = data["profilePictureURL"] as? String
            else { return }

            let newCommentDoc = postRef
                .collection("comments")
                .document()

            let commentData: [String: Any] = [
                "userId": uid,
                "username": username,
                "profileImage": profileImage,
                "text": newComment,
                "timestamp": Timestamp()
            ]

            newCommentDoc.setData(commentData) { error in
                if let error = error {
                    print("Error adding comment: \(error.localizedDescription)")
                } else {
                    // Update local UI immediately
                    let postedComment = Comment(
                        id: newCommentDoc.documentID,
                        userId: uid,
                        username: username,
                        profileImage: profileImage,
                        text: newComment,
                        timestamp: Timestamp()
                    )
                    self.comments.insert(postedComment, at: 0)
                    self.newComment = ""

                    // Also increment the post’s commentsCount in Firestore
                    postRef.updateData(["commentsCount": FieldValue.increment(Int64(1))])
                }
            }
        }
    }

    // MARK: - Favorite
    private func checkFavoriteStatus() {
        guard let uid = Auth.auth().currentUser?.uid,
              let postID = post.id
        else { return }

        let db = Firestore.firestore()
        db.collection("posts")
            .document(postID)
            .collection("favorites")
            .document(uid)
            .getDocument { document, error in
                if let error = error {
                    print("Error checking favorite status: \(error.localizedDescription)")
                    return
                }
                self.isFavorited = document?.exists ?? false
            }
    }

    private func toggleFavorite() {
        guard let uid = Auth.auth().currentUser?.uid,
              let postID = post.id
        else { return }

        let db = Firestore.firestore()
        let postRef = db.collection("posts").document(postID)
        let favoriteRef = postRef.collection("favorites").document(uid)

        if isFavorited {
            // Unfavorite
            favoriteRef.delete()
            postRef.updateData(["favoritesCount": FieldValue.increment(Int64(-1))])
            favoriteCount -= 1
        } else {
            // Favorite
            favoriteRef.setData(["favoritedAt": Timestamp()])
            postRef.updateData(["favoritesCount": FieldValue.increment(Int64(1))])
            favoriteCount += 1
        }
        isFavorited.toggle()
    }

    // MARK: - Closet
    private func checkClosetStatus() {
        guard let uid = Auth.auth().currentUser?.uid,
              let postID = post.id
        else { return }

        let db = Firestore.firestore()
        db.collection("posts")
            .document(postID)
            .collection("closets")
            .document(uid)
            .getDocument { document, error in
                if let error = error {
                    print("Error checking closet status: \(error.localizedDescription)")
                    return
                }
                self.isInCloset = document?.exists ?? false
            }
    }

    private func toggleCloset() {
        guard let uid = Auth.auth().currentUser?.uid,
              let postID = post.id
        else { return }

        let db = Firestore.firestore()
        let postRef = db.collection("posts").document(postID)
        let closetRef = postRef.collection("closets").document(uid)

        if isInCloset {
            // Possibly remove from closet if that’s desired.
            // If you want only "one-way add," remove this block.
            closetRef.delete()
            postRef.updateData(["closetsCount": FieldValue.increment(Int64(-1))])
            closetsCount -= 1
            isInCloset = false
        } else {
            // Add to closet
            closetRef.setData(["addedAt": Timestamp()])
            postRef.updateData(["closetsCount": FieldValue.increment(Int64(1))])
            closetsCount += 1
            isInCloset = true
        }
    }

    // MARK: - Navigation
    private func navigateToProfile(userId: String) {
        // Show user’s OtherProfileView or handle differently in your Nav stack
    }
}

// MARK: - TaggedItemsSheet
struct TaggedItemsSheet: View {
    let items: [TaggedItem]

    var body: some View {
        NavigationView {
            List(items) { item in
                // Attempt to sanitize the link
                if let link = item.link?.sanitizedAsURL(),
                   let url = URL(string: link) {
                    // If valid link -> clickable
                    Link(destination: url) {
                        Text(item.name)
                    }
                } else {
                    // No link or invalid -> plain text
                    Text(item.name)
                }
            }
            .navigationTitle("Tagged Items")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
