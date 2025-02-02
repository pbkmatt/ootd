
import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ClosetDetailView: View {
    let closet: Closet
    
    @State private var posts: [OOTDPost] = []
    @State private var isLoading = true
    @State private var errorMessage: String? = nil
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack {
            Text(closet.name)
                .font(.largeTitle)
                .bold()
                .padding(.top, 16)
            
            if isLoading {
                ProgressView("Loading posts...")
                    .padding()
            } else if let errorMessage = errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
                    .padding()
            } else if posts.isEmpty {
                Text("No posts in this closet yet!")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(posts) { post in
                            // Tapping opens PostView
                            NavigationLink(destination: PostView(post: post)) {
                                AsyncImage(url: URL(string: post.imageURL)) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: UIScreen.main.bounds.width / 2 - 20,
                                               height: UIScreen.main.bounds.width / 2 - 20)
                                        .clipped()
                                        .cornerRadius(8)
                                } placeholder: {
                                    Color.gray
                                        .frame(width: UIScreen.main.bounds.width / 2 - 20,
                                               height: UIScreen.main.bounds.width / 2 - 20)
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            fetchPosts()
        }
    }
    
    // MARK: - Fetch All Posts in This Closet
    private func fetchPosts() {
        guard !closet.postIds.isEmpty else {
            isLoading = false
            return
        }
        
        let db = Firestore.firestore()
        
        // Firestore "in" queries can only handle up to 10 IDs at a time
        // If you may have more, chunk them. For simplicity, assume <= 10.
        db.collection("posts")
            .whereField(FieldPath.documentID(), in: closet.postIds)
            .getDocuments { snapshot, error in
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    return
                }
                
                guard let docs = snapshot?.documents else {
                    self.isLoading = false
                    return
                }
                
                let fetchedPosts = docs.compactMap { doc -> OOTDPost? in
                    try? doc.data(as: OOTDPost.self)
                }
                
                // You might want them sorted by the order they appear in closet.postIds
                // but Firestore doesn't preserve that. We'll just keep them as is, or you
                // can do a custom reorder pass if needed.
                
                DispatchQueue.main.async {
                    self.posts = fetchedPosts
                    self.isLoading = false
                }
            }
    }
}
