import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ClosetsView: View {
    @StateObject private var closetVM = ClosetViewModel()
    
    // Dictionary: ClosetID -> Cover Image URL
    @State private var closetCoverImages: [String: String] = [:]
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack {
            // Title
            Text("My Closets")
                .font(.largeTitle)
                .bold()
                .padding(.top, 16)
            
            // 2-column grid of closets
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(closetVM.closets) { closet in
                        NavigationLink(destination: ClosetDetailView(closet: closet)) {
                            closetBox(for: closet)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationBarTitle("", displayMode: .inline)
        .navigationBarHidden(true) // Hides the top bar if you like
        .onAppear {
            closetVM.fetchUserClosets()
        }
        .onDisappear {
            closetVM.stopListening()
        }
        // Whenever closets change, fetch covers
        .onReceive(closetVM.$closets) { newClosets in
            fetchCoverImages()
        }
    }
    
    // MARK: - Closet Box (with cover image)
    @ViewBuilder
    private func closetBox(for closet: Closet) -> some View {
        VStack {
            if let coverURL = closetCoverImages[closet.id ?? ""],
               !coverURL.isEmpty {
                // Show the most recent post's image
                AsyncImage(url: URL(string: coverURL)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(height: 120)
                        .clipped()
                } placeholder: {
                    Color.gray
                        .frame(height: 120)
                }
            } else {
                // If no posts, or not yet loaded, show a gray box
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 120)
            }
            
            Text(closet.name)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("\(closet.postIds.count) items")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: .gray.opacity(0.2), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Fetch Cover Images
    private func fetchCoverImages() {
        let db = Firestore.firestore()
        
        for closet in closetVM.closets {
            // If empty, just set blank
            guard let closetID = closet.id,
                  let lastPostId = closet.postIds.last,
                  !lastPostId.isEmpty else {
                closetCoverImages[closet.id ?? ""] = ""
                continue
            }
            
            db.collection("posts").document(lastPostId).getDocument { snapshot, error in
                guard let doc = snapshot, doc.exists else {
                    closetCoverImages[closetID] = ""
                    return
                }
                // Try decoding the doc
                if let post = try? doc.data(as: OOTDPost.self) {
                    closetCoverImages[closetID] = post.imageURL
                } else {
                    closetCoverImages[closetID] = ""
                }
            }
        }
    }
}
