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

    struct UserProfileDetailView: View {
        let user: UserModel
        @State private var isFollowing: Bool = false
        @State private var isPrivate: Bool = false
        @State private var posts: [OOTDPost] = []

        var body: some View {
            NavigationView {
                ScrollView {
                    VStack(spacing: 16) {
                        // Profile Header
                        ProfileHeader(user: user, isFollowing: $isFollowing, isPrivate: $isPrivate)

                        // Posts Section
                        if isPrivate && !isFollowing {
                            Text("This profile is private.")
                                .font(.headline)
                                .foregroundColor(.gray)
                        } else {
                            PostGrid(posts: posts)
                        }
                    }
                    .padding()
                }
                .navigationTitle(user.username)
                .navigationBarTitleDisplayMode(.inline)
                .onAppear {
                    checkIfFollowing()
                    fetchPosts()
                }
            }
        }

        // MARK: - Check If Following
        private func checkIfFollowing() {
            guard let currentUserId = Auth.auth().currentUser?.uid else { return }

            let db = Firestore.firestore()
            db.collection("users")
                .document(user.id)
                .collection("followers")
                .document(currentUserId)
                .getDocument { document, _ in
                    DispatchQueue.main.async {
                        self.isFollowing = document?.exists ?? false
                    }
                }
        }

        // MARK: - Fetch Posts
        private func fetchPosts() {
            let db = Firestore.firestore()
            db.collection("users")
                .document(user.id)
                .collection("posts")
                .order(by: "timestamp", descending: true)
                .getDocuments { snapshot, error in
                    DispatchQueue.main.async {
                        if let snapshot = snapshot {
                            self.posts = snapshot.documents.compactMap { doc -> OOTDPost? in
                                try? doc.data(as: OOTDPost.self)
                            }
                        } else {
                            print("Error fetching posts: \(error?.localizedDescription ?? "Unknown error")")
                        }
                    }
                }
        }
    }
    
    struct ProfileHeader: View {
        let user: UserModel
        @Binding var isFollowing: Bool
        @Binding var isPrivate: Bool

        var body: some View {
            VStack(spacing: 16) {
                if let url = URL(string: user.profilePictureURL), !user.profilePictureURL.isEmpty {
                    AsyncImage(url: url) { image in
                        image.resizable()
                            .scaledToFill()
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.gray.opacity(0.5), lineWidth: 2))
                    } placeholder: {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 120, height: 120)
                    }
                }

                Text(user.username)
                    .font(.title2)
                    .bold()

                if !user.bio.isEmpty {
                    Text(user.bio)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }

                // Follow/Unfollow Button
                Button(action: {
                    isFollowing ? unfollowUser() : followUser()
                }) {
                    Text(isFollowing ? "Unfollow" : "Follow")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFollowing ? Color.red : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            }
        }

        // MARK: - Follow User
        private func followUser() {
            guard let currentUserId = Auth.auth().currentUser?.uid else { return }
            let db = Firestore.firestore()

            // Add current user to target user's followers
            db.collection("users").document(user.id).collection("followers").document(currentUserId).setData([:])

            // Add target user to current user's following
            db.collection("users").document(currentUserId).collection("following").document(user.id).setData([:])

            isFollowing = true
        }

        // MARK: - Unfollow User
        private func unfollowUser() {
            guard let currentUserId = Auth.auth().currentUser?.uid else { return }
            let db = Firestore.firestore()

            // Remove current user from target user's followers
            db.collection("users").document(user.id).collection("followers").document(currentUserId).delete()

            // Remove target user from current user's following
            db.collection("users").document(currentUserId).collection("following").document(user.id).delete()

            isFollowing = false
        }
    }



}
