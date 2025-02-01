import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ExploreView: View {
    @State private var searchText: String = ""
    @State private var users: [UserModel] = []
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
                        .onChange(of: searchText) { _ in
                            searchUsers()
                        }
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    Button(action: searchUsers) {
                        Image(systemName: "magnifyingglass")
                            .font(.title2)
                            .padding(.leading, 8)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)

                // Loading Indicator
                if isLoading {
                    ProgressView("Searching...")
                        .padding(.top)
                }

                // Users List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(users) { user in
                            NavigationLink(destination: OtherProfileView(user: user)) {
                                UserCard(user: user)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top)
                }
            }
            .navigationTitle("Explore")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Search Users (Real-Time Suggestions)
    private func searchUsers() {
        guard !searchText.isEmpty else {
            users = []
            return
        }

        isLoading = true
        
        let db = Firestore.firestore()
        db.collection("users")
            .order(by: "username")
            .start(at: [searchText.lowercased()])
            .end(at: [searchText.lowercased() + "\u{f8ff}"])
            .limit(to: 10) // Limit results for better performance
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
                    }
                }
            }
    }
}

// MARK: - UserCard Component
struct UserCard: View {
    let user: UserModel

    var body: some View {
        HStack {
            if let url = URL(string: user.profilePictureURL), !user.profilePictureURL.isEmpty {
                AsyncImage(url: url) { image in
                    image.resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 50, height: 50)
                }
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
            }

            VStack(alignment: .leading) {
                Text(user.username)
                    .font(Font.custom("BebasNeue-Regular", size: 16))
                    .foregroundColor(.primary)

                if !user.bio.isEmpty {
                    Text(user.bio)
                        .font(Font.custom("OpenSans", size: 14))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }

            Spacer()
        }
        .padding(.horizontal)
        .frame(height: 60)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}
