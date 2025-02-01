import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct HomeView: View {
    @State private var selectedTab: Int = 0 // 0 for Following, 1 for Trending
    @State private var posts: [OOTDPost] = [] // Posts to display
    @State private var lastDocument: DocumentSnapshot? // For pagination
    @State private var isLoading = false // Prevent duplicate fetches

    var body: some View {
        VStack(spacing: 0) {
            // Tab Selector
            TabSelector(selectedTab: $selectedTab, posts: $posts, lastDocument: $lastDocument, fetchFollowingPosts: fetchFollowingPosts, fetchTrendingPosts: fetchTrendingPosts)

            Divider()

            // Posts Section
            PostsSection(posts: $posts, selectedTab: $selectedTab, lastDocument: $lastDocument, isLoading: $isLoading, fetchFollowingPosts: fetchFollowingPosts, fetchTrendingPosts: fetchTrendingPosts)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("OOTD")
                    .font(Font.custom("BebasNeue-Regular", size: 20))
            }
        }
        .onAppear {
            selectedTab == 0 ? fetchFollowingPosts() : fetchTrendingPosts()
        }
    }

    // MARK: - Fetch Following Posts (Recent Posts from Followed Users)
    private func fetchFollowingPosts() {
        guard let currentUserId = Auth.auth().currentUser?.uid, !isLoading else { return }
        isLoading = true

        let db = Firestore.firestore()
        db.collection("users").document(currentUserId).collection("following").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching following list: \(error.localizedDescription)")
                isLoading = false
                return
            }

            let followedUserIds = snapshot?.documents.map { $0.documentID } ?? []
            guard !followedUserIds.isEmpty else {
                print("No followed users, skipping Firestore query.")
                isLoading = false
                return
            }

            var query = db.collection("posts")
                .whereField("userID", in: followedUserIds)
                .order(by: "timestamp", descending: true)
                .limit(to: 10)

            if let lastDoc = lastDocument {
                query = query.start(afterDocument: lastDoc)
            }

            query.getDocuments { postSnapshot, postError in
                defer { isLoading = false }
                if let postError = postError {
                    print("Error fetching posts: \(postError.localizedDescription)")
                    return
                }

                if let snapshot = postSnapshot {
                    let newPosts = snapshot.documents.compactMap { try? $0.data(as: OOTDPost.self) }
                    self.posts.append(contentsOf: newPosts)
                    self.lastDocument = snapshot.documents.last
                }
            }
        }
    }

    // MARK: - Fetch Trending Posts (Today's Most Favorited Posts)
    private func fetchTrendingPosts() {
        guard !isLoading else { return }
        isLoading = true

        let db = Firestore.firestore()
        let todayStart = Calendar.current.startOfDay(for: Date())

        var query = db.collection("posts")
            .whereField("timestamp", isGreaterThanOrEqualTo: todayStart)
            .whereField("visibility", isEqualTo: "public")
            .order(by: "favoritesCount", descending: true)
            .limit(to: 10)

        if let lastDoc = lastDocument {
            query = query.start(afterDocument: lastDoc)
        }

        query.getDocuments { snapshot, error in
            defer { isLoading = false }
            if let snapshot = snapshot {
                let newPosts = snapshot.documents.compactMap { try? $0.data(as: OOTDPost.self) }
                self.posts.append(contentsOf: newPosts)
                self.lastDocument = snapshot.documents.last
            }
        }
    }
}

// MARK: - Tab Selector Component
struct TabSelector: View {
    @Binding var selectedTab: Int
    @Binding var posts: [OOTDPost]
    @Binding var lastDocument: DocumentSnapshot?
    var fetchFollowingPosts: () -> Void
    var fetchTrendingPosts: () -> Void

    var body: some View {
        HStack {
            Button(action: {
                selectedTab = 0
                posts.removeAll()
                lastDocument = nil
                fetchFollowingPosts()
            }) {
                Text("FOLLOWING")
                    .font(Font.custom("BebasNeue-Regular", size: 16))
                    .foregroundColor(selectedTab == 0 ? .black : .gray)
                    .frame(maxWidth: .infinity)
            }

            Button(action: {
                selectedTab = 1
                posts.removeAll()
                lastDocument = nil
                fetchTrendingPosts()
            }) {
                Text("TRENDING")
                    .font(Font.custom("BebasNeue-Regular", size: 16))
                    .foregroundColor(selectedTab == 1 ? .black : .gray)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

// MARK: - Posts Section Component
struct PostsSection: View {
    @Binding var posts: [OOTDPost]
    @Binding var selectedTab: Int
    @Binding var lastDocument: DocumentSnapshot?
    @Binding var isLoading: Bool
    var fetchFollowingPosts: () -> Void
    var fetchTrendingPosts: () -> Void

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach(posts) { post in
                    PostCard(post: post)
                        .onAppear {
                            if post.id == posts.last?.id {
                                selectedTab == 0 ? fetchFollowingPosts() : fetchTrendingPosts()
                            }
                        }
                }
            }
            .padding()
        }
    }
}

// MARK: - PostCard Component (Unchanged)
struct PostCard: View {
    let post: OOTDPost

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Post Header
            HStack {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.gray)

                VStack(alignment: .leading, spacing: 4) {
                    Text(post.userID) // Replace with fetched username if available
                        .font(Font.custom("BebasNeue-Regular", size: 14))
                    Text(post.timestamp.dateValue(), style: .time)
                        .font(Font.custom("OpenSans", size: 12))
                        .foregroundColor(.gray)
                }

                Spacer()

                Image(systemName: "ellipsis")
                    .foregroundColor(.gray)
            }

            // Post Image
            if let url = URL(string: post.imageURL) {
                AsyncImage(url: url) { image in
                    image.resizable()
                        .scaledToFill()
                        .frame(maxHeight: 300)
                        .cornerRadius(10)
                } placeholder: {
                    Color.gray
                        .frame(maxHeight: 300)
                        .cornerRadius(10)
                }
            }

            // Post Footer
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "star")
                        .foregroundColor(.yellow)
                    Text("\(post.favoritesCount ?? 0)")
                        .font(Font.custom("OpenSans", size: 12))
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "message")
                        .foregroundColor(.gray)
                    Text("\(post.commentsCount ?? 0)")
                        .font(Font.custom("OpenSans", size: 12))
                }
            }
            .padding(.top, 8)
            .font(.subheadline)
            .foregroundColor(.gray)

            // Post Caption
            Text(post.caption)
                .font(Font.custom("OpenSans", size: 14))
                .foregroundColor(.black)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}
