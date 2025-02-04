import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct PostCard: View {
    let post: OOTDPost

    @State private var isFavorited = false
    @State private var favoriteCount: Int
    @State private var commentsCount: Int
    @State private var closetsCount: Int

    init(post: OOTDPost) {
        self.post = post
        _favoriteCount = State(initialValue: post.favoritesCount)
        _commentsCount = State(initialValue: post.commentsCount)
        _closetsCount = State(initialValue: post.closetsCount)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // MARK: - Header: Profile Picture & Username
            HStack {
                // Profile Picture
                AsyncImage(url: URL(string: post.profileImage)) { image in
                    image.resizable()
                         .scaledToFill()
                         .frame(width: 40, height: 40)
                         .clipShape(Circle())
                } placeholder: {
                    Circle().fill(Color.gray.opacity(0.3))
                           .frame(width: 40, height: 40)
                }

                // Username (Navigates to OtherProfileView)
                VStack(alignment: .leading, spacing: 4) {
                    NavigationLink(destination: OtherProfileView(user: UserModel(
                        uid: post.uid,
                        username: post.username,
                        fullName: "",
                        bio: "",
                        instagramHandle: "",
                        profilePictureURL: post.profileImage,
                        followersCount: 0,
                        followingCount: 0
                    ))) {
                        Text("@\(post.username)")
                            .font(Font.custom("BebasNeue-Regular", size: 14))
                    }
                    Text(post.timestamp.dateValue(), style: .time)
                        .font(Font.custom("OpenSans", size: 12))
                        .foregroundColor(.gray)
                }

                Spacer()
            }

            // MARK: - Post Image (Tapping navigates to PostView)
            NavigationLink(destination: PostView(post: post)) {
                if let url = URL(string: post.imageURL) {
                    AsyncImage(url: url) { image in
                        image.resizable()
                             .scaledToFill()
                             .frame(maxHeight: 300)
                             .cornerRadius(10)
                             .clipped()
                    } placeholder: {
                        Color.gray
                            .frame(maxHeight: 300)
                            .cornerRadius(10)
                    }
                }
            }
            .buttonStyle(.plain) // Ensures it looks like a normal view, not a button

            // MARK: - Interaction Buttons (Favorites, Comments, Closet)
            HStack(spacing: 16) {
                // Favorite Button
                Button(action: toggleFavorite) {
                    HStack(spacing: 4) {
                        Image(systemName: isFavorited ? "star.fill" : "star")
                            .foregroundColor(isFavorited ? .yellow : .gray)
                        Text("\(favoriteCount)")
                            .font(Font.custom("OpenSans", size: 12))
                    }
                }

                // Comments Button
                HStack(spacing: 4) {
                    Image(systemName: "bubble.right")
                        .foregroundColor(.gray)
                    Text("\(commentsCount)")
                        .font(Font.custom("OpenSans", size: 12))
                }

                // Closet Button
                Button(action: toggleCloset) {
                    HStack(spacing: 4) {
                        Image(systemName: "briefcase.fill")
                            .foregroundColor(.gray)
                        Text("\(closetsCount)")
                            .font(Font.custom("OpenSans", size: 12))
                    }
                }

                Spacer()
            }
            .padding(.top, 4)
            .font(.subheadline)
            .foregroundColor(.gray)

            // MARK: - Caption
            if !post.caption.isEmpty {
                Text(post.caption)
                    .font(Font.custom("OpenSans", size: 14))
                    .foregroundColor(.primary)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1),
                radius: 4, x: 0, y: 2)
        .onAppear {
            checkFavoriteStatus()
        }
    }

    // MARK: - Toggle Favorite
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

    // MARK: - Closet Feature
    private func toggleCloset() {
        guard let uid = Auth.auth().currentUser?.uid,
              let postID = post.id
        else { return }

        let db = Firestore.firestore()
        let postRef = db.collection("posts").document(postID)
        let closetRef = postRef.collection("closets").document(uid)

        closetRef.getDocument { document, error in
            if let error = error {
                print("Error checking closet status: \(error.localizedDescription)")
                return
            }

            if document?.exists == true {
                // Remove from Closet
                closetRef.delete()
                postRef.updateData(["closetsCount": FieldValue.increment(Int64(-1))])
                closetsCount -= 1
            } else {
                // Add to Closet
                closetRef.setData(["addedAt": Timestamp()])
                postRef.updateData(["closetsCount": FieldValue.increment(Int64(1))])
                closetsCount += 1
            }
        }
    }
}
