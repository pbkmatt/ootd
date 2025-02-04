import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct HomeView: View {
    @State private var selectedTab: Int = 0 // 0 for Following, 1 for Trending
    @State private var posts: [OOTDPost] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - Tab Selector
                HStack {
                    Button(action: {
                        switchToFollowing()
                    }) {
                        Text("FOLLOWING")
                            .font(.custom("BebasNeue-Regular", size: 16))
                            .foregroundColor(selectedTab == 0 ? .black : .gray)
                            .frame(maxWidth: .infinity)
                    }

                    Button(action: {
                        switchToTrending()
                    }) {
                        Text("TRENDING")
                            .font(.custom("BebasNeue-Regular", size: 16))
                            .foregroundColor(selectedTab == 1 ? .black : .gray)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding()
                .background(Color(.systemBackground))

                Divider()

                // MARK: - Content
                if isLoading {
                    ProgressView("Loading…")
                        .padding(.top, 50)
                } else if let msg = errorMessage {
                    Text(msg)
                        .foregroundColor(.gray)
                        .padding(.top, 50)
                } else if posts.isEmpty {
                    Text("No posts yet.")
                        .foregroundColor(.gray)
                        .padding(.top, 50)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            ForEach(posts) { post in
                                NavigationLink(destination: PostView(post: post)) {
                                    PostCard(post: post) // Ensure PostCard is a View
                                }
                                .buttonStyle(.plain) // Ensures no unwanted button styles
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationBarTitle("OOTD", displayMode: .inline)
            .onAppear {
                // Load whichever is currently selected
                if selectedTab == 0 {
                    fetchFollowingPosts()
                } else {
                    fetchTrendingPosts()
                }
            }
        }
    }

    // MARK: - Switch to Following
    private func switchToFollowing() {
        selectedTab = 0
        posts.removeAll()
        errorMessage = nil
        fetchFollowingPosts()
    }

    // MARK: - Switch to Trending
    private func switchToTrending() {
        selectedTab = 1
        posts.removeAll()
        errorMessage = nil
        fetchTrendingPosts()
    }

    // MARK: - Fetch Following Posts
    private func fetchFollowingPosts() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        errorMessage = nil
        posts = []

        // 1) Get the set of user IDs I follow
        FollowService.shared.fetchFollowing(currentUserId: currentUserId) { followedUserIds in
            if followedUserIds.isEmpty {
                self.isLoading = false
                self.errorMessage = "You're not following anyone yet."
                return
            }

            // 2) Filter today's posts from these users
            let boundary = Date.today4AMInEST()
            let db = Firestore.firestore()
            db.collection("posts")
                .whereField("uid", in: followedUserIds)
                .whereField("timestamp", isGreaterThanOrEqualTo: Timestamp(date: boundary))
                .order(by: "timestamp", descending: true)
                .getDocuments { snapshot, error in
                    self.isLoading = false
                    if let error = error {
                        self.errorMessage = "Error fetching posts: \(error.localizedDescription)"
                        return
                    }
                    guard let docs = snapshot?.documents else {
                        self.errorMessage = "No posts found."
                        return
                    }
                    let fetchedPosts = docs.compactMap { try? $0.data(as: OOTDPost.self) }
                    self.posts = fetchedPosts
                }
        }
    }

    // MARK: - Fetch Trending Posts
    private func fetchTrendingPosts() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        isLoading = true
        errorMessage = nil
        posts = []

        // 1) Fetch who I follow (plus my own uid)
        FollowService.shared.fetchFollowing(currentUserId: currentUserId) { followedUserIds in
            var excludeIds = followedUserIds
            excludeIds.append(currentUserId) // exclude myself

            let boundary = Date.today4AMInEST()
            let db = Firestore.firestore()

            // If excludeIds has 10 or fewer items, we can do a "not-in" query
            if excludeIds.count <= 10 {
                db.collection("posts")
                    .whereField("uid", notIn: excludeIds)
                    .whereField("visibility", isEqualTo: "public")
                    .whereField("timestamp", isGreaterThanOrEqualTo: Timestamp(date: boundary))
                    .order(by: "favoritesCount", descending: true)
                    .getDocuments { snapshot, error in
                        self.isLoading = false
                        if let error = error {
                            self.errorMessage = "Error fetching trending: \(error.localizedDescription)"
                            return
                        }
                        guard let docs = snapshot?.documents else {
                            self.errorMessage = "No trending posts found."
                            return
                        }
                        let fetchedPosts = docs.compactMap { try? $0.data(as: OOTDPost.self) }
                        self.posts = fetchedPosts
                    }
            } else {
                // Fallback for >10 excludes
                db.collection("posts")
                    .whereField("visibility", isEqualTo: "public")
                    .whereField("timestamp", isGreaterThanOrEqualTo: Timestamp(date: boundary))
                    .order(by: "favoritesCount", descending: true)
                    .getDocuments { snapshot, error in
                        self.isLoading = false
                        if let error = error {
                            self.errorMessage = "Error fetching trending: \(error.localizedDescription)"
                            return
                        }
                        guard let docs = snapshot?.documents else {
                            self.errorMessage = "No trending posts found."
                            return
                        }
                        var fetchedPosts = docs.compactMap { try? $0.data(as: OOTDPost.self) }
                        // Manually filter out the big exclude list
                        fetchedPosts.removeAll(where: { excludeIds.contains($0.uid) })
                        self.posts = fetchedPosts
                    }
            }
        }
    }
}
