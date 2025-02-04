import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ClosetsView: View {
    @StateObject private var closetVM = ClosetViewModel()
    
    @State private var closetCoverImages: [String: String] = [:]
    
    // 2-column grid
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Title
            Text("My Closets")
                .font(.custom("BebasNeue-Regular", size: 28))
                .padding(.top, 20)
            
            // Scrollable grid of closets
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(closetVM.closets) { closet in
                        NavigationLink(destination: ClosetDetailView(closet: closet)) {
                            closetBox(for: closet)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 16)
            }
        }
        .background(Color(.systemBackground))
        .navigationBarTitle("", displayMode: .inline)
        .navigationBarHidden(true)
        .onAppear {
            closetVM.fetchUserClosets()
        }
        .onDisappear {
            closetVM.stopListening()
        }
        // Whenever closets change, fetch cover images
        .onReceive(closetVM.$closets) { _ in
            fetchCoverImages()
        }
    }
    
    // MARK: - Closet Box
    @ViewBuilder
    private func closetBox(for closet: Closet) -> some View {
        VStack(spacing: 8) {
            // Cover image or placeholder
            if let coverURL = closetCoverImages[closet.id ?? ""],
               !coverURL.isEmpty {
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
                // If no posts or not yet loaded
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 120)
            }
            
            // Closet name
            Text(closet.name)
                .font(.custom("BebasNeue-Regular", size: 16))
                .foregroundColor(.primary)
            
            // # of items
            Text("\(closet.postIds.count) items")
                .font(.custom("OpenSans", size: 14))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.07), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Fetch Cover Images
    private func fetchCoverImages() {
        let db = Firestore.firestore()
        
        for closet in closetVM.closets {
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
                // try decoding
                if let post = try? doc.data(as: OOTDPost.self) {
                    closetCoverImages[closetID] = post.imageURL
                } else {
                    closetCoverImages[closetID] = ""
                }
            }
        }
    }
}
