import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth

struct OtherProfileView: View {
    let initialUser: UserModel

    @State private var user: UserModel
    @State private var isFollowing: Bool = false
    @State private var isLoading: Bool = true
    @State private var errorMessage: String?

    @State private var todaysOOTD: OOTDPost?
    @State private var pastOOTDs: [OOTDPost] = []

    init(user: UserModel) {
        self.initialUser = user
        _user = State(initialValue: user)
    }

    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView("Loading \(user.username)…")
                        .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                        .scaleEffect(1.3)
                }
                .padding(.top, 50)
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        // MARK: - Profile Header
                        ProfileHeaderView(user: $user, isFollowing: $isFollowing)

                        // MARK: - Today's OOTD
                        if let post = todaysOOTD {
                            VStack(alignment: .leading, spacing: 8) {
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
                                    .padding(.horizontal, 16)
                                }
                            }
                        }

                        // MARK: - Past OOTDs
                        if !pastOOTDs.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("\(user.username)’s Past OOTDs")
                                    .font(.custom("BebasNeue-Regular", size: 20))
                                    .padding(.leading, 8)

                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())],
                                          spacing: 16) {
                                    ForEach(pastOOTDs) { post in
                                        NavigationLink(destination: PostView(post: post)) {
                                            AsyncImage(url: URL(string: post.imageURL)) { image in
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(
                                                        width: UIScreen.main.bounds.width/2 - 20,
                                                        height: UIScreen.main.bounds.width/2 - 20
                                                    )
                                                    .cornerRadius(10)
                                                    .clipped()
                                            } placeholder: {
                                                Color.gray
                                                    .frame(
                                                        width: UIScreen.main.bounds.width/2 - 20,
                                                        height: UIScreen.main.bounds.width/2 - 20
                                                    )
                                                    .cornerRadius(10)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        } else if todaysOOTD == nil {
                            Text("No OOTDs yet!")
                                .font(.custom("OpenSans", size: 14))
                                .foregroundColor(.gray)
                                .padding(.top, 16)
                        }
                    }
                    .padding(.top, 12)
                }
                .refreshable {
                    await reloadProfileAndPosts()
                }
            }

            // MARK: - Error
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.custom("OpenSans", size: 14))
                    .foregroundColor(.red)
                    .padding()
                    .multilineTextAlignment(.center)
            }
        }
        .navigationTitle("@\(user.username)")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemBackground).ignoresSafeArea())
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

            guard let _ = document.data() else {
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

            let todays = posts.first(where: { $0.timestamp.dateValue() >= boundary })
            let past = posts.filter { $0.timestamp.dateValue() < boundary }

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
                self.isLoading = false
            }
        }
    }
}

// MARK: - ProfileHeaderView Subview
struct ProfileHeaderView: View {
    @Binding var user: UserModel
    @Binding var isFollowing: Bool

    var body: some View {
        VStack(spacing: 12) {
            // MARK: - Profile Picture
            if let url = URL(string: user.profilePictureURL), !user.profilePictureURL.isEmpty {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
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

            // MARK: - Full Name + Username
            Text(user.fullName)
                .font(.custom("BebasNeue-Regular", size: 22))

            Text("@\(user.username)")
                .font(.custom("BebasNeue-Regular", size: 16))
                .foregroundColor(.secondary)

            // MARK: - Stats
            HStack(spacing: 24) {
                VStack {
                    Text("\(user.followersCount)")
                        .font(.custom("BebasNeue-Regular", size: 18))
                    Text("Followers")
                        .font(.custom("OpenSans", size: 14))
                        .foregroundColor(.secondary)
                }
                VStack {
                    Text("\(user.followingCount)")
                        .font(.custom("BebasNeue-Regular", size: 18))
                    Text("Following")
                        .font(.custom("OpenSans", size: 14))
                        .foregroundColor(.secondary)
                }
            }

            // MARK: - Follow/Unfollow
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
                        .padding(.vertical, 8)
                        .padding(.horizontal, 24)
                        .background(isFollowing ? Color.red : Color.blue)
                        .cornerRadius(8)
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 12)
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
                user.followersCount = max(0, user.followersCount - 1)
            }
        }
    }
}
