import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct OtherProfileView: View {
    let user: UserModel
    @State private var isFollowing: Bool = false
    @State private var todaysOOTD: OOTDPost?
    @State private var pastOOTDs: [OOTDPost] = []
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Profile Header
                ProfileHeader(
                    user: user,
                    isFollowing: $isFollowing,
                    onFollow: followUser,
                    onUnfollow: unfollowUser
                )

                // Today's OOTD
                if let todaysOOTD = todaysOOTD {
                    todaysOOTDSection(todaysOOTD)
                }

                // Past OOTDs
                if !pastOOTDs.isEmpty {
                    pastOOTDsSection
                }
            }
            .padding()
        }
        .navigationTitle(user.username)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            checkIfFollowing()
            fetchUserPosts()
        }
    }

    // MARK: - Check If Following
    private func checkIfFollowing() {
        guard let currentUserId = Auth.auth().currentUser?.uid, let targetUserId = user.id else { return }

        Firestore.firestore().collection("following")
            .document(currentUserId)
            .collection("users")
            .document(targetUserId)
            .getDocument { document, _ in
                DispatchQueue.main.async {
                    isFollowing = document?.exists ?? false
                }
            }
    }

    // MARK: - Follow User
    private func followUser() {
        guard let currentUserId = Auth.auth().currentUser?.uid, let targetUserId = user.id else { return }

        let db = Firestore.firestore()
        
        // Add follow relationship
        db.collection("following")
            .document(currentUserId)
            .collection("users")
            .document(targetUserId)
            .setData(["followedAt": Timestamp()]) { error in
                DispatchQueue.main.async {
                    if error == nil {
                        self.isFollowing = true
                    } else {
                        print("Error following user: \(error!.localizedDescription)")
                    }
                }
            }

        // Increment followers count for target user
        db.collection("users").document(targetUserId).updateData([
            "followersCount": FieldValue.increment(Int64(1))
        ])

        // Increment following count for current user
        db.collection("users").document(currentUserId).updateData([
            "followingCount": FieldValue.increment(Int64(1))
        ])
    }

    // MARK: - Unfollow User
    private func unfollowUser() {
        guard let currentUserId = Auth.auth().currentUser?.uid, let targetUserId = user.id else { return }

        let db = Firestore.firestore()

        // Remove follow relationship
        db.collection("following")
            .document(currentUserId)
            .collection("users")
            .document(targetUserId)
            .delete { error in
                DispatchQueue.main.async {
                    if error == nil {
                        self.isFollowing = false
                    } else {
                        print("Error unfollowing user: \(error!.localizedDescription)")
                    }
                }
            }

        // Decrement followers count for target user
        db.collection("users").document(targetUserId).updateData([
            "followersCount": FieldValue.increment(Int64(-1))
        ])

        // Decrement following count for current user
        db.collection("users").document(currentUserId).updateData([
            "followingCount": FieldValue.increment(Int64(-1))
        ])
    }

    // MARK: - Today's OOTD Section
    private func todaysOOTDSection(_ post: OOTDPost) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today's OOTD")
                .font(Font.custom("BebasNeue-Regular", size: 20))

            PostView(post: post)
                .cornerRadius(10)
        }
    }

    // MARK: - Past OOTDs Section
    private var pastOOTDsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("\(user.username)'s Past OOTDs")
                .font(Font.custom("BebasNeue-Regular", size: 20))
                .padding(.leading, 8)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(pastOOTDs) { post in
                    NavigationLink(destination: PostView(post: post)) {
                        AsyncImage(url: URL(string: post.imageURL ?? "")) { image in
                            image.resizable()
                                .scaledToFill()
                                .frame(width: UIScreen.main.bounds.width / 2 - 20, height: UIScreen.main.bounds.width / 2 - 20)
                                .cornerRadius(10)
                        } placeholder: {
                            Color.gray
                                .frame(width: UIScreen.main.bounds.width / 2 - 20, height: UIScreen.main.bounds.width / 2 - 20)
                                .cornerRadius(10)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Fetch User Posts
    private func fetchUserPosts() {
        guard let userId = user.id else { return }

        Firestore.firestore().collection("posts")
            .whereField("uid", isEqualTo: userId)
            .order(by: "timestamp", descending: true)
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {
                    if let snapshot = snapshot {
                        let posts = snapshot.documents.compactMap { try? $0.data(as: OOTDPost.self) }
                        todaysOOTD = posts.first(where: { Calendar.current.isDateInToday($0.timestamp.dateValue()) })
                        pastOOTDs = posts.filter { !Calendar.current.isDateInToday($0.timestamp.dateValue()) }
                    }
                }
            }
    }
}

// MARK: - ProfileHeader Component
struct ProfileHeader: View {
    let user: UserModel
    @Binding var isFollowing: Bool
    let onFollow: () -> Void
    let onUnfollow: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            // Profile Picture
            AsyncImage(url: URL(string: user.profilePictureURL)) { image in
                image.resizable()
                    .scaledToFill()
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.gray.opacity(0.5), lineWidth: 2))
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 120, height: 120)
            }

            // Username, Instagram Handle, and Bio
            VStack(spacing: 4) {
                Text(user.username)
                    .font(Font.custom("BebasNeue-Regular", size: 20))

                if !user.instagramHandle.isEmpty {
                    Text("@\(user.instagramHandle)")
                        .font(Font.custom("OpenSans", size: 14))
                        .foregroundColor(.blue)
                        .onTapGesture {
                            openInstagram(username: user.instagramHandle)
                        }
                }

                if !user.bio.isEmpty {
                    Text(user.bio)
                        .font(Font.custom("OpenSans", size: 14))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
            }

            // Follow/Unfollow Button
            Button(action: {
                isFollowing ? onUnfollow() : onFollow()
            }) {
                Text(isFollowing ? "Unfollow" : "Follow")
                    .font(Font.custom("BebasNeue-Regular", size: 16))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isFollowing ? Color.red : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Open Instagram Profile
private func openInstagram(username: String) {
    let appURL = URL(string: "instagram://user?username=\(username)")!
    let webURL = URL(string: "https://www.instagram.com/\(username)/")!

    if UIApplication.shared.canOpenURL(appURL) {
        UIApplication.shared.open(appURL)
    } else {
        UIApplication.shared.open(webURL)
    }
    

}
