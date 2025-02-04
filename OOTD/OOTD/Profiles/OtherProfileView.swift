import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth

struct OtherProfileView: View {
    // We receive a user object, but we’ll re-fetch it to ensure
    // we have the latest data (followersCount, followingCount, etc.).
    let initialUser: UserModel

    @State private var user: UserModel
    @State private var isFollowing: Bool = false
    @State private var isLoading: Bool = true
    @State private var errorMessage: String?

    @State private var todaysOOTD: OOTDPost?
    @State private var pastOOTDs: [OOTDPost] = []

    init(user: UserModel) {
        self.initialUser = user
        // Make a local copy we can update after fetch
        _user = State(initialValue: user)
    }

    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                ProgressView("Loading \(user.username)…")
                    .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                    .scaleEffect(1.3)
                    .padding(.top, 50)
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        // Header w/ profile pic, username, follow button, etc.
                        ProfileHeaderView(user: $user, isFollowing: $isFollowing)

                        // Show "Today's OOTD" (if any)
                        if let post = todaysOOTD {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Today's OOTD")
                                    .font(.custom("BebasNeue-Regular", size: 20))
                                    .padding(.leading, 8)

                                NavigationLink(destination: PostView(post: post)) {
                                    AsyncImage(url: URL(string: post.imageURL)) { image in
                                        image
                                            .resizable()
                                            .scaledToFit()
                                            .cornerRadius(10)
                                    } placeholder: {
                                        ProgressView()
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }

                        // Show Past OOTDs in a 2-column grid
                        if !pastOOTDs.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("\(user.username)’s Past OOTDs")
                                    .font(.custom("BebasNeue-Regular", size: 20))
                                    .padding(.leading, 8)

                                LazyVGrid(columns: [GridItem(.flexible()),
                                                    GridItem(.flexible())],
                                          spacing: 16) {
                                    ForEach(pastOOTDs) { post in
                                        NavigationLink(destination: PostView(post: post)) {
                                            AsyncImage(url: URL(string: post.imageURL)) { image in
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: UIScreen.main.bounds.width / 2 - 20,
                                                           height: UIScreen.main.bounds.width / 2 - 20)
                                                    .cornerRadius(10)
                                                    .clipped()
                                            } placeholder: {
                                                Color.gray
                                                    .frame(width: UIScreen.main.bounds.width / 2 - 20,
                                                           height: UIScreen.main.bounds.width / 2 - 20)
                                                    .cornerRadius(10)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        } else if todaysOOTD == nil {
                            // If they have no posts at all:
                            Text("No OOTDs yet!")
                                .foregroundColor(.gray)
                                .padding(.top, 20)
                        }
                    }
                    .padding(.top, 12)
                }
                .refreshable {
                    await reloadProfileAndPosts()
                }
            }

            // If any error
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .navigationTitle("@\(user.username)")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                await reloadProfileAndPosts()
            }
        }
    }

    // MARK: - Reload
    private func reloadProfileAndPosts() async {
        await fetchUser()
        await fetchUserPosts()
    }

    // MARK: - Fetch This User’s Latest Info
    private func fetchUser() async {
        do {
            let document = try await Firestore.firestore()
                .collection("users")
                .document(initialUser.uid)
                .getDocument()

            guard let data = document.data() else {
                DispatchQueue.main.async {
                    self.errorMessage = "User not found or has been deleted."
                    self.isLoading = false
                }
                return
            }

            let freshUser = try document.data(as: UserModel.self)
            DispatchQueue.main.async {
                self.user = freshUser
            }
            await checkFollowStatus()
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to load user: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Fetch This User’s Posts
    private func fetchUserPosts() async {
        let db = Firestore.firestore()
        do {
            let snapshot = try await db.collection("posts")
                .whereField("uid", isEqualTo: user.uid)
                .order(by: "timestamp", descending: true)
                .getDocuments()

            let posts = snapshot.documents.compactMap { try? $0.data(as: OOTDPost.self) }
            let boundary = Date.today4AMInEST()

            // "Today’s" = any post with timestamp >= boundary
            let todays = posts.first(where: {
                $0.timestamp.dateValue() >= boundary
            })

            let past = posts.filter {
                $0.timestamp.dateValue() < boundary
            }

            DispatchQueue.main.async {
                self.todaysOOTD = todays
                self.pastOOTDs = past
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to load posts: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }

    // MARK: - Check Follow Status
    private func checkFollowStatus() async {
        guard let currentUid = Auth.auth().currentUser?.uid,
              currentUid != user.uid else {
            DispatchQueue.main.async {
                self.isFollowing = false
                self.isLoading = false
            }
            return
        }

        FollowService.shared.isFollowing(targetUserId: user.uid) { following in
            DispatchQueue.main.async {
                self.isFollowing = following
            }
        }
    }
}

// MARK: - ProfileHeaderView Subview
struct ProfileHeaderView: View {
    @Binding var user: UserModel
    @Binding var isFollowing: Bool

    var body: some View {
        VStack(spacing: 8) {
            // Profile Picture
            if let url = URL(string: user.profilePictureURL), !user.profilePictureURL.isEmpty {
                AsyncImage(url: url) { image in
                    image.resizable()
                         .scaledToFill()
                         .frame(width: 120, height: 120)
                         .clipShape(Circle())
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 120, height: 120)
                }
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 120, height: 120)
            }

            // Full Name + Username
            Text(user.fullName)
                .font(.custom("BebasNeue-Regular", size: 22))

            Text("@\(user.username)")
                .font(.custom("BebasNeue-Regular", size: 16))
                .foregroundColor(.secondary)

            // Stats Row
            HStack(spacing: 24) {
                VStack {
                    Text("\(user.followersCount)")
                        .font(.headline)
                    Text("Followers")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                VStack {
                    Text("\(user.followingCount)")
                        .font(.headline)
                    Text("Following")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 4)

            // Follow/Unfollow (if it’s not my own profile)
            if let currentUid = Auth.auth().currentUser?.uid,
               currentUid != user.uid {
                Button(action: {
                    if isFollowing {
                        unfollowUser()
                    } else {
                        followUser()
                    }
                }) {
                    Text(isFollowing ? "Unfollow" : "Follow")
                        .font(.custom("BebasNeue-Regular", size: 16))
                        .foregroundColor(.white)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 24)
                        .background(isFollowing ? Color.red : Color.blue)
                        .cornerRadius(8)
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical)
    }

    // MARK: - Follow
    private func followUser() {
        FollowService.shared.followUser(targetUserId: user.uid) { error in
            if let error = error {
                print("Error following user: \(error.localizedDescription)")
                return
            }
            DispatchQueue.main.async {
                self.isFollowing = true
                // Also increment the local counts immediately for UI
                user.followersCount += 1
            }
        }
    }

    // MARK: - Unfollow
    private func unfollowUser() {
        FollowService.shared.unfollowUser(targetUserId: user.uid) { error in
            if let error = error {
                print("Error unfollowing user: \(error.localizedDescription)")
                return
            }
            DispatchQueue.main.async {
                self.isFollowing = false
                // Decrement local counts
                user.followersCount = max(0, user.followersCount - 1)
            }
        }
    }
}
