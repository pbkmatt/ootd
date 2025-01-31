import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct UserProfileDetailView: View {
    let user: UserModel
    @State private var isFollowing: Bool = false
    @State private var posts: [OOTDPost] = []
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
                TodayOOTDSection(userID: user.id ?? "")

                // User's Posts Grid
                Text("\(user.username)'s OOTDs")
                    .font(Font.custom("BebasNeue-Regular", size: 20))
                    .padding(.leading, 8)

                PostGrid(filterType: "profilePosts")

            }
            .padding()
        }
        .navigationTitle(user.username)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            checkIfFollowing()
        }
    }

    // MARK: - Check If Following
    private func checkIfFollowing() {
        guard let currentUserId = Auth.auth().currentUser?.uid, let targetUserId = user.id else { return }
        
        let db = Firestore.firestore()
        db.collection("following")
            .document(currentUserId)
            .collection("users")
            .document(targetUserId)
            .getDocument { document, error in
                DispatchQueue.main.async {
                    if let document = document, document.exists {
                        self.isFollowing = true
                    } else {
                        self.isFollowing = false
                    }
                }
            }
    }

    // MARK: - Follow User
    private func followUser() {
        guard let currentUserId = Auth.auth().currentUser?.uid, let targetUserId = user.id else { return }
        
        let db = Firestore.firestore()
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
    }

    // MARK: - Unfollow User
    private func unfollowUser() {
        guard let currentUserId = Auth.auth().currentUser?.uid, let targetUserId = user.id else { return }
        
        let db = Firestore.firestore()
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

// MARK: - Today's OOTD Section
struct TodayOOTDSection: View {
    let userID: String
    @State private var todaysOOTD: OOTDPost?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let post = todaysOOTD {
                Text("Today's OOTD")
                    .font(Font.custom("BebasNeue-Regular", size: 18))

                PostView(post: post)
                    .cornerRadius(10)
            }
        }
        .onAppear {
            fetchTodaysOOTD()
        }
    }

    private func fetchTodaysOOTD() {
        let db = Firestore.firestore()
        db.collection("posts")
            .whereField("userID", isEqualTo: userID)
            .whereField("timestamp", isGreaterThanOrEqualTo: Calendar.current.startOfDay(for: Date()))
            .order(by: "timestamp", descending: true)
            .getDocuments { snapshot, error in
                if let snapshot = snapshot {
                    let allPosts = snapshot.documents.compactMap { try? $0.data(as: OOTDPost.self) }
                    DispatchQueue.main.async {
                        self.todaysOOTD = allPosts.first
                    }
                }
            }
    }
}
