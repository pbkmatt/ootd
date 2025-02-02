import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth

struct OtherProfileView: View {
    let user: UserModel

    @State private var isFollowing: Bool = false
    @State private var todaysOOTD: OOTDPost?
    @State private var pastOOTDs: [OOTDPost] = []
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // A big header with user's profile
                ProfileHeaderView(user: user, isFollowing: $isFollowing)
                
                // Display OOTDs
                if let todaysOOTD = todaysOOTD {
                    Text("Today's OOTD")
                        .font(.headline)
                    PostView(post: todaysOOTD)
                        .cornerRadius(10)
                }
                
                if !pastOOTDs.isEmpty {
                    Text("\(user.username)'s Past OOTDs")
                        .font(.headline)
                    // show them in a grid
                }
            }
            .padding()
        }
        .navigationTitle(user.username)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            checkFollowStatus()
            fetchUserPosts()
        }
    }

    private func checkFollowStatus() {
        let currentUid = Auth.auth().currentUser?.uid
        if currentUid == user.uid { return } // can't follow ourselves

        // e.g. /users/{user.uid}/followers/{currentUid}
        Firestore.firestore()
            .collection("users")
            .document(user.uid)
            .collection("followers")
            .document(currentUid ?? "")
            .getDocument { snapshot, error in
                DispatchQueue.main.async {
                    self.isFollowing = snapshot?.exists ?? false
                }
            }
    }

    private func fetchUserPosts() {
        Firestore.firestore().collection("posts")
            .whereField("uid", isEqualTo: user.uid)
            .order(by: "timestamp", descending: true)
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {
                    guard let docs = snapshot?.documents else { return }
                    let posts = docs.compactMap { try? $0.data(as: OOTDPost.self) }
                    self.todaysOOTD = posts.first(where: {
                        Calendar.current.isDateInToday($0.timestamp.dateValue())
                    })
                    self.pastOOTDs = posts.filter {
                        !Calendar.current.isDateInToday($0.timestamp.dateValue())
                    }
                }
            }
    }
}

struct ProfileHeaderView: View {
    let user: UserModel
    @Binding var isFollowing: Bool

    var body: some View {
        VStack(spacing: 8) {
            // Profile Pic
            AsyncImage(url: URL(string: user.profilePictureURL)) { image in
                image.resizable()
                     .scaledToFill()
                     .frame(width: 120, height: 120)
                     .clipShape(Circle())
            } placeholder: {
                Circle().fill(Color.gray.opacity(0.3))
                       .frame(width: 120, height: 120)
            }

            // Username, Full Name
            Text(user.username)
                .font(.title2)
            if !user.fullName.isEmpty {
                Text(user.fullName)
                    .foregroundColor(.secondary)
            }

            // Follow/Unfollow if not your own profile
            let currentUid = Auth.auth().currentUser?.uid
            if currentUid != user.uid {
                Button(isFollowing ? "Unfollow" : "Follow") {
                    if isFollowing {
                        unfollowUser()
                    } else {
                        followUser()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(isFollowing ? Color.red : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding(.top)
    }

    private func followUser() {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users")
            .document(user.uid)
            .collection("followers")
            .document(currentUid)
            .setData(["followedAt": Timestamp()]) { error in
                if let error = error {
                    print("Error following: \(error.localizedDescription)")
                } else {
                    isFollowing = true
                    // increment counters
                    db.collection("users").document(user.uid)
                        .updateData(["followersCount": FieldValue.increment(Int64(1))])
                    db.collection("users").document(currentUid)
                        .updateData(["followingCount": FieldValue.increment(Int64(1))])
                }
            }
    }

    private func unfollowUser() {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        db.collection("users")
            .document(user.uid)
            .collection("followers")
            .document(currentUid)
            .delete { error in
                if let error = error {
                    print("Error unfollowing: \(error.localizedDescription)")
                } else {
                    isFollowing = false
                    // decrement counters
                    db.collection("users").document(user.uid)
                        .updateData(["followersCount": FieldValue.increment(Int64(-1))])
                    db.collection("users").document(currentUid)
                        .updateData(["followingCount": FieldValue.increment(Int64(-1))])
                }
            }
    }
}
