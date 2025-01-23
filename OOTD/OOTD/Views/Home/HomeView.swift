import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct HomeView: View {
    @State private var selectedTab: Int = 0 // 0 for Following, 1 for Trending
    @State private var posts: [OOTDPost] = [] // Posts to display

    var body: some View {
        VStack(spacing: 0) {
            // Tab Selector
            HStack {
                Button(action: {
                    selectedTab = 0
                    fetchFollowingPosts()
                }) {
                    Text("FOLLOWING")
                        .font(Font.custom("BebasNeue-Regular", size: 16))
                        .foregroundColor(selectedTab == 0 ? .black : .gray)
                        .frame(maxWidth: .infinity)
                }

                Button(action: {
                    selectedTab = 1
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

            Divider()

            // Posts Section
            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach(posts) { post in
                        PostCard(post: post)
                    }
                }
                .padding()
            }
            .onAppear {
                selectedTab == 0 ? fetchFollowingPosts() : fetchTrendingPosts()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("OOTD")
                    .font(Font.custom("BebasNeue-Regular", size: 20))
            }
        }
    }

    // MARK: - Fetch Following Posts
    private func fetchFollowingPosts() {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()

        db.collection("users").document(currentUserId).collection("following").getDocuments { snapshot, error in
            if let snapshot = snapshot {
                let followedUserIds = snapshot.documents.map { $0.documentID }

                db.collectionGroup("posts")
                    .whereField("userID", in: followedUserIds)
                    .whereField("timestamp", isGreaterThanOrEqualTo: Calendar.current.startOfDay(for: Date()))
                    .getDocuments { postSnapshot, error in
                        if let postSnapshot = postSnapshot {
                            posts = postSnapshot.documents.compactMap { doc -> OOTDPost? in
                                try? doc.data(as: OOTDPost.self)
                            }
                        }
                    }
            }
        }
    }

    // MARK: - Fetch Trending Posts
    private func fetchTrendingPosts() {
        let db = Firestore.firestore()

        db.collectionGroup("posts")
            .whereField("timestamp", isGreaterThanOrEqualTo: Calendar.current.startOfDay(for: Date()))
            .whereField("visibility", isEqualTo: "public")
            .order(by: "favoritesCount", descending: true)
            .getDocuments { snapshot, error in
                if let snapshot = snapshot {
                    posts = snapshot.documents.compactMap { doc -> OOTDPost? in
                        try? doc.data(as: OOTDPost.self)
                    }
                }
            }
    }
}

// MARK: - PostCard Component
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
                        .font(Font.custom("YourFont-Regular", size: 12))
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "message")
                        .foregroundColor(.gray)
                    Text("\(post.commentsCount ?? 0)")
                        .font(Font.custom("YourFont-Regular", size: 12))
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
