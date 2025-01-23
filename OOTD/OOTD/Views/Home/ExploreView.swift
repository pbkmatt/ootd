import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ExploreView: View {
    @State private var searchText: String = ""
    @State private var users: [UserModel] = []
    @State private var selectedUser: UserModel? = nil
    @State private var isLoading: Bool = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                HStack {
                    TextField("Search by username", text: $searchText)
                        .padding(.horizontal, 16)
                        .frame(height: 44)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .onSubmit {
                            searchUsers()
                        }
                    Button(action: searchUsers) {
                        Image(systemName: "magnifyingglass")
                            .font(.title2)
                            .padding(.leading, 8)
                    }
                }
                .padding(.horizontal)
                
                // Loading Indicator
                if isLoading {
                    ProgressView("Searching...")
                        .padding(.top)
                }
                
                // User Grid
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                        ForEach(users) { user in
                            Button(action: {
                                selectedUser = user
                            }) {
                                UserCard(user: user)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)
                }
            }
            .navigationTitle("Explore")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $selectedUser) { user in
                UserProfileDetailView(user: user)
            }
        }
    }
    
    // MARK: - Search Users
    private func searchUsers() {
        guard !searchText.isEmpty else { return }
        isLoading = true
        
        let db = Firestore.firestore()
        db.collection("users")
            .whereField("username", isGreaterThanOrEqualTo: searchText)
            .whereField("username", isLessThanOrEqualTo: searchText + "\u{f8ff}")
            .getDocuments { snapshot, error in
                DispatchQueue.main.async {
                    isLoading = false
                    if let error = error {
                        print("Error searching users: \(error.localizedDescription)")
                        return
                    }
                    
                    if let snapshot = snapshot {
                        users = snapshot.documents.compactMap { doc -> UserModel? in
                            try? doc.data(as: UserModel.self)
                        }
                        print("Found \(users.count) users.")
                    }
                }
            }
    }
    
    struct UserCard: View {
        let user: UserModel
        
        var body: some View {
            VStack {
                if let url = URL(string: user.profilePictureURL), !user.profilePictureURL.isEmpty {
                    AsyncImage(url: url) { image in
                        image.resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    } placeholder: {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 100, height: 100)
                    }
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 100, height: 100)
                }
                
                Text(user.username)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if !user.bio.isEmpty {
                    Text(user.bio)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 4)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }
    
    
}
