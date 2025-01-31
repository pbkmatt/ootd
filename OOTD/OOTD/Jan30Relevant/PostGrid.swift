import SwiftUI

struct PostGrid: View {
    @State private var posts: [OOTDPost] = [] // Holds the fetched posts
    @State private var isLoading = false // Prevents duplicate fetches
    @State private var lastDocument: OOTDPost? // Tracks last loaded post for pagination
    
    let filterType: String // Determines what posts to fetch

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(posts) { post in
                    PostView(post: post)
                        .onAppear {
                            if post == posts.last { // Trigger infinite scrolling
                                fetchMorePosts()
                            }
                        }
                }
            }
            .padding(.horizontal, 8)
        }
        .onAppear {
            fetchInitialPosts()
        }
    }

    // Fetch initial posts based on filterType
    private func fetchInitialPosts() {
        guard !isLoading else { return }
        isLoading = true
        
        FirebaseManager.fetchPosts(filterType: filterType, lastDocument: nil) { newPosts, lastPost in
            self.posts = newPosts
            self.lastDocument = lastPost
            self.isLoading = false
        }
    }

    // Fetch more posts when user scrolls down
    private func fetchMorePosts() {
        guard !isLoading, let lastPost = lastDocument else { return }
        isLoading = true
        
        FirebaseManager.fetchPosts(filterType: filterType, lastDocument: lastPost) { newPosts, lastPost in
            self.posts.append(contentsOf: newPosts)
            self.lastDocument = lastPost
            self.isLoading = false
        }
    }
}
